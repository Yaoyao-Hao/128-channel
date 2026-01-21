module LSTM_config
  #(
     parameter input_size = 1, //输入特征数
     parameter hidden_size = 1, //隐藏层特征数
     parameter num_layers = 1, //LSTM层数
     parameter output_size = 1, //输出类别数
     parameter batch_size = 1, //批大小
     parameter sequence_length = 1, //序列长度
     parameter WIDTH_CNT = $clog2(input_size)+1,  //输入特征累加防止溢出
     parameter QZ = 16, //数据量化位宽
     parameter QZ_R = 8,
     parameter QZ_D = 16,
     parameter DATA_WITCH =  WIDTH_CNT + QZ,
     //计算余数与所需并行计算次数  余数将使最后一次并行计算包含0值
     parameter PARALL_NUM = 10 ,//并行计算规模 必须为2的倍数
     parameter INPUTSIZE = input_size/PARALL_NUM,
     parameter REMAINDER = input_size - INPUTSIZE * PARALL_NUM, // 计算余数
     parameter INPUTSIZE_AD = hidden_size/PARALL_NUM,
     parameter REMAINDER_AD = hidden_size - INPUTSIZE_AD * PARALL_NUM,// 计算余数
     parameter LENGTH_DATA = $clog2(hidden_size),
     parameter INGATE_ADDR = hidden_size * input_size * 0,
     parameter FORGET_ADDR = hidden_size * input_size * 1,
     parameter CELL_ADDR =   hidden_size * input_size * 2,
     parameter OUT_ADDR =    hidden_size * input_size * 3

   )
   (
     input clk,
     input rst_n,
     input start, //开始计算

     input [ PARALL_NUM*QZ-1: 0 ]data_in,
     input data_in_valid,
     input [PARALL_NUM *QZ*4-1: 0 ]wih,
     input fifo_ready,
     output reg cnt_input_size_valid,
     output reg cnt_hidden_size_valid,
     output reg rd_weight,
     input wire last_eigenvalue,
     output reg cnt_input_size_valid_ad,
     output reg cnt_hidden_size_valid_ad,
     output reg [2:0]STATE_HID,//隐藏层状态机
     output wire [LENGTH_DATA - 1 +2: 0]data_addr_ram_o,
     output wire ram_valid_wr,
     output wire [QZ*4*2-1:0]ram_data_in0,
     input  wire [QZ*4*2-1:0]ram_data_out0,
     output reg [10:0]STATE_SUM, //输出当前计算哪个门的状态
     output reg [10:0]STATE_SUM_dd, //输出当前计算哪个门的状态
     output wire Gate_Cal, //指示权重读取模块从mem中读出相应权重值
     input weight_out_valid,
     output reg add_finish,//////四个门矩阵计算完成,
     input  gate_cal_finish,
     output reg [10:0]cal_cnt,
     output HID_CYCLE_FINISH
   );







  reg [8:0]STATE_AD;
  reg [7:0]cnt_data;//对输入的数据进行计数

  reg [9:0]STATE_CAL;
  reg [9:0]NEXT_STATE_CAL;

  wire valid_data_out;//计算数据输出

  reg [LENGTH_DATA - 1 : 0]data_addr;


  //reg [10:0]STATE_SUM;
  localparam INIT = 0,
             INGA = 1,
             FORGET = 2,
             FINISH1 = 3,
             FINISH0 = 4,
             FINISH = 5,
             WAIT_WEIGHT = 6;


  wire cal_finish_valid;
  wire cal_valid;
  reg cnt_add;////指示一个并行周期计算完成
  reg [ PARALL_NUM*QZ-1: 0 ]cal_data_in;



  reg [QZ*2-1:0]ingate_data;
  reg [QZ*2-1:0]forgetgate_data;
  reg [QZ*2-1:0]cellgate_data;
  reg [QZ*2-1:0]outgate_data;



  /////隐藏层节点循环计算
  reg [10:0]hid_cnt;//数据输入后隐藏层计算
  reg [10:0]hid_cnt_ad;//数据输入后隐藏层计算

  reg HIDcyc_finish;
  reg start_sum_cal;////开始隐藏层循环计算
  localparam INIT_HID = 0,
             HID_CYCLE_ah = 1,
             CYCLE_END = 2;
  wire valid_hid_cycle;
  assign valid_hid_cycle = (hid_cnt==hidden_size-1 )?cnt_add:0;
  wire valid_hid_cycle_ad;
  assign valid_hid_cycle_ad = (hid_cnt_ad==hidden_size-1 )?cnt_add:0;

  reg cal_ad_finish;

  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      STATE_HID<= INIT;
      cal_data_in <= 'd0;
      hid_cnt <= 'd0;
      hid_cnt_ad <= 0;
      HIDcyc_finish <= 'd0;
      start_sum_cal <= 'd0;
      // valid_hid_cycle <= 'd0;
      cnt_hidden_size_valid <= 'd0;
      cnt_hidden_size_valid_ad <= 'd0;
    end
    else
    begin
      case(STATE_HID)
        INIT_HID :
        begin

          hid_cnt <= 'd0;
          HIDcyc_finish <= 'd0;
          cnt_hidden_size_valid <= 'd0;
          //valid_hid_cycle <= 'd0;
          if(data_in_valid)
          begin
            cal_data_in <= data_in;
            STATE_HID <= HID_CYCLE_ah;
            start_sum_cal <= 'd1;
          end
          else
          begin
            cal_data_in <= cal_data_in;
            STATE_HID <= STATE_HID;
            start_sum_cal <= 'd0;
          end
        end
        HID_CYCLE_ah:
        begin

          if(cnt_add)
          begin

            if(hid_cnt>=hidden_size-1)
            begin
              hid_cnt <= 0;
              STATE_HID <= CYCLE_END;
              start_sum_cal <= 0;
              cnt_hidden_size_valid <= 'd0;
              //  valid_hid_cycle <= 'd1;
            end
            else
            begin
              hid_cnt <= hid_cnt + 1;
              STATE_HID <= STATE_HID;
              start_sum_cal <= start_sum_cal;
              cnt_hidden_size_valid <= 'd1;
              //valid_hid_cycle <= 'd0;
            end
          end
          else
          begin
            cnt_hidden_size_valid <= 'd0;
            hid_cnt <= hid_cnt;
            STATE_HID <= STATE_HID;
            start_sum_cal <= start_sum_cal;
            //valid_hid_cycle <= 'd0;
          end
        end

        CYCLE_END:
        begin
          cnt_hidden_size_valid <= 'd0;
          cnt_hidden_size_valid_ad<= 'd0;
          STATE_HID <= INIT_HID;
          HIDcyc_finish <= 'd1;
          start_sum_cal <= 0;
          //valid_hid_cycle <= 'd0;
        end
      endcase
    end
  end
  /*
  always@(posedge clk or negedge rst_n)
  begin
      if(~rst_n) begin 
          hid_cnt<= 'd0;
      end
      else 
          begin 
              if(cnt_add) begin 
                  if(hid_cnt >=INPUTSIZE)
                   begin hid_cnt<= 0; 
                       add_finish <= 1;
                   end
                   else begin 
                      hid_cnt<= hid_cnt + 1;  
                   add_finish <= 0;
                  end
                end
                else 
                    begin 
                      hid_cnt<= hid_cnt;  
                       add_finish <= 0;
                    end
           
            end 
          end
  end 
  */





  ////////数据到来时进行四个门的运算
  //reg rd_weight;

  reg start_cal;//控制乘法单元开始计算
  assign Gate_Cal =  start_cal;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      STATE_SUM <= INIT;
      start_cal <= 'd0;
      cnt_add <= 0;
      rd_weight <= 'd0;
    end
    else
    begin
      case(STATE_SUM)
        INIT    :
        begin

          cnt_add <= 0;
          if(start_sum_cal)
          begin
            STATE_SUM <= WAIT_WEIGHT;
            start_cal <= 'd1;
            rd_weight <= 'd1;

          end
          else
          begin
            STATE_SUM <= INIT;
            start_cal <= 'd0;
            rd_weight <= 'd0;
          end
        end
        WAIT_WEIGHT:
        begin

          if(fifo_ready)
          begin
            STATE_SUM <= INGA;
            rd_weight <= 'd0;
          end
          else
          begin
            STATE_SUM <= STATE_SUM;
            rd_weight <= 'd1;
          end
        end

        INGA    :
        begin
          if(cal_valid)
          begin
            STATE_SUM <= FINISH;
            start_cal <= 'd1;
            cnt_add <= 0;
          end
          else
          begin
            STATE_SUM <= INGA;
            start_cal <= 'd0;
            cnt_add <= 0;
          end
        end

        FINISH  :
        begin
          if(last_eigenvalue)
          begin
            if(gate_cal_finish)
            begin
              STATE_SUM <= FINISH0;
              cnt_add <= 1;
              start_cal <= 'd0;
            end
            else
            begin
              STATE_SUM <= STATE_SUM;
              cnt_add <= 0;
              start_cal <= 'd0;
            end
          end
          else
          begin
            STATE_SUM <= INIT;
            cnt_add <= 1;
            start_cal <= 'd0;
          end
        end
        FINISH0 :
        begin
          STATE_SUM <= FINISH1;
          cnt_add <= 0;
        end

        FINISH1 :
        begin
          STATE_SUM <= INIT;
        end

      endcase
    end
  end


  /////////////累加求和
  wire [QZ*2*4-1:0]mult_out;////乘法模块输出
  reg  [QZ*2*4-1:0]ram_data_wr;
  reg  [3:0]ram_wr_valid;
  //reg [QZ*2*4-1:0]ram_data_in;
  //wire [QZ*2*4-1:0]ram_data_out;
  reg [QZ*2*4-1:0]ram_data_in;
  wire [QZ*2*4-1:0]ram_data_out;


  reg [10:0]STATE_SUM_d;//,STATE_SUM_dd;
  /*
  always@(posedge clk or negedge rst_n)
   begin
       if(~rst_n) begin 
          ram_data_in       <= 'd0 ;
          
          ram_wr_valid <= 'd0;
   
       end
    else begin 
      case(STATE_SUM_dd) 
      INGA    :begin
   
       if(cal_valid) begin 
          ram_data_in[31:0]       <= ram_data_out[31:0]      +   mult_out ;
   
   
          ram_wr_valid <= 'd1;
   
       end
        else begin
          ram_data_in[31:0]        <=  ram_data_in[31:0]  ;
   
          ram_wr_valid <= 'd0;
        end
       end
      FORGET  :begin 
          if(cal_valid) begin 
              ram_data_in [31+32:32]        <= ram_data_out[31+32:32]       +   mult_out ;
   
   
              ram_wr_valid <= 'd1;
           end
            else begin
              ram_data_in[31+32:32]        <= ram_data_in[31+32:32]  ;
   
              ram_wr_valid <= 'd0;
            end
   
      end
      CELL    :begin
          if(cal_valid) begin 
              ram_data_in[31+32*2:32*2]         <= ram_data_out[31+32*2:32*2]       +   mult_out ;
   
   
              ram_wr_valid <= 'd1;
           end
            else begin
              ram_data_in[31+32*2:32*2]         <= ram_data_in[31+32*2:32*2]   ;
   
              ram_wr_valid <= 'd0;
            end
   
       end
          OUTGATE :begin
              if(cal_valid) begin 
                  ram_data_in[31+32*3:32*3]           <= ram_data_out[31+32*3:32*3]        +   mult_out ;
   
   
                  ram_wr_valid <= 'd1;
               end
                else begin
                  ram_data_in[31+32*3:32*3]         <= ram_data_in[31+32*3:32*3]   ;
   
                  ram_wr_valid <= 'd0;
                end
           end
           default:begin
              ram_data_in       <= ram_data_in ;
   
              ram_wr_valid <= 'd0;
            end
  endcase
   end
   end
  */



  wire [QZ*2-1:0]mult_out_TEST,ram_data_in_TEST,ram_data_out0_TEST;
  assign mult_out_TEST =  mult_out[QZ*2-1:0];
  assign ram_data_in_TEST = ram_data_in[QZ*2-1:0];
  assign ram_data_out0_TEST = ram_data_out0[QZ*2-1:0];

  //reg [10:0]cal_cnt;

  genvar i ;
  generate for (i=0;i<4;i=i+1)
    begin: addd
      always@(posedge clk or negedge rst_n)
      begin
        if(~rst_n)
        begin
          ram_data_in[QZ*(i+1)*2-1:QZ*2*(i)]       <= 'd0 ;
          ram_wr_valid[i] <= 'd0;

        end
        else
        begin
          case(STATE_SUM_dd)
            INGA    :
            begin

              if(cal_valid)
              begin
                ram_data_in[QZ*(i+1)*2-1:QZ*2*(i)]     <=(|cal_cnt)? ram_data_out0[QZ*2*(i+1)-1:QZ*2*(i)]     +   mult_out[QZ*2*(i+1)-1:QZ*2*(i)]:mult_out[QZ*2*(i+1)-1:QZ*2*(i)] ;
                ram_wr_valid[i] <= 'd1;
              end
              else
              begin
                ram_data_in[QZ*2*(i+1)-1:QZ*2*(i)]    <=  ram_data_in[QZ*2*(i+1)-1:QZ*2*(i)]  ;
                ram_wr_valid[i]  <= 'd0;
              end
            end
            /*
            FORGET  :begin 
               if(cal_valid) begin 
                   ram_data_in        <= ram_data_out0     +   mult_out ;
                   ram_wr_valid <= 'd1;
                end
                 else begin
                   ram_data_in       <= ram_data_in  ;
                   ram_wr_valid <= 'd0;
                 end

            end
            CELL    :begin
               if(cal_valid) begin 
                   ram_data_in      <= ram_data_out0     +   mult_out ;
                   ram_wr_valid <= 'd1;
                end
                 else begin
                   ram_data_in         <= ram_data_in   ;
                   ram_wr_valid <= 'd0;
                 end

            end
               OUTGATE :begin
                   if(cal_valid) begin 
                       ram_data_in        <= ram_data_out0      +   mult_out ;
                       ram_wr_valid <= 'd1;
                    end
                     else begin
                       ram_data_in      <= ram_data_in   ;
                       ram_wr_valid <= 'd0;
                     end
                end
                */
            default:
            begin
              ram_data_in[QZ*2*(i+1)-1:QZ*2*(i)]       <= ram_data_in[QZ*2*(i+1)-1:QZ*2*(i)] ;
              ram_wr_valid[i]  <= 'd0;
            end
          endcase
        end
      end
    end
  endgenerate
  assign ram_valid_wr = ram_wr_valid[0] ;










  /////////完整一个数组计算控制

  //reg add_finish;//////四个门矩阵计算完成
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      cal_cnt <= 'd0;
      cnt_input_size_valid <= 'd0;
      add_finish <= 'd0;
    end
    else
    begin
      if(valid_hid_cycle)
      begin
        cnt_input_size_valid <= 'd1;
        if(cal_cnt >=INPUTSIZE-1)
        begin
          cal_cnt<= 0;
          add_finish <= 1;
        end
        else
        begin
          cal_cnt<= cal_cnt + 1;
          add_finish <= 0;
        end
      end
      else
      begin
        cal_cnt<= cal_cnt;
        add_finish <= 0;
        cnt_input_size_valid <= 'd0;
      end

    end
  end
  //////ad计算模组
  reg [10:0]cal_cnt_ad;
  reg add_finish_ad;//////四个门矩阵计算完成
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      cal_cnt_ad <= 'd0;
      cnt_input_size_valid_ad <= 'd0;
      add_finish_ad <= 'd0;
    end
    else
    begin
      if(valid_hid_cycle_ad)
      begin
        cnt_input_size_valid_ad <= 'd1;
        if(cal_cnt_ad >=INPUTSIZE_AD-1)
        begin
          cal_cnt_ad<= 0;
          add_finish_ad <= 1;
        end
        else
        begin
          cal_cnt_ad<= cal_cnt_ad + 1;
          add_finish_ad <= 0;
        end
      end
      else
      begin
        cal_cnt_ad<= cal_cnt_ad;
        add_finish_ad <= 0;
        cnt_input_size_valid_ad <= 'd0;
      end

    end
  end
  ///////////////////////////////////////////////////////////////////////////////




  //////////ram读写地址
  reg [ $clog2(hidden_size*4)-1:0]addr_rd_wr;

  localparam ingate_data_addr     = hidden_size * 0,
             forgetgate_data_addr = hidden_size * 0,
             cellgate_data_addr   = hidden_size * 0,
             outgate_data_addr    = hidden_size * 0;



  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin

      STATE_SUM_d <= 'd0;
      STATE_SUM_dd<= 'd0;
    end
    else
    begin
      STATE_SUM_d <= STATE_SUM;
      STATE_SUM_dd<= STATE_SUM_d;

    end
  end


  //////////计算参数控制状态机






  /*
   
  MEM_DATA#(
    .DATA_WIDTH(QZ),
    .hidden_size(hidden_size) 
  )MEM_DATA_ram
  (
  .clk         (clk),
  .rst_n       (rst_n),
   
  .ram_wr_valid(wr_mem),
  .data_in     (ram_data_in),
  .data_out    (ram_data_out),
  .addr_in     (addr_rd_wr)
  );
   
  */




  ih_cal
    #(
      .input_size(input_size), //输入特征数
      .hidden_size(hidden_size), //隐藏层特征数
      .num_layers(num_layers), //LSTM层数
      .output_size(output_size), //输出类别数
      .batch_size(batch_size), //批大小
      .sequence_length(sequence_length), //序列长度
      .QZ_R(QZ_R),//整数部分量化
      .QZ_D(QZ_D),//小数部分量化
      .QZ(QZ), //数据量化位宽
      //计算余数与所需并行计算次数  余数将使最后一次并行计算包含0值
      .PARALL_NUM(4)//并行计算规模 必须为2的倍数

    )cal_cum
    (
      .clk(clk),
      .rst_n(rst_n),
      .start(weight_out_valid), //开始计算

      .data_in({4{data_in}}),
      .data_in_valid(weight_out_valid),//(start_cal),
      .wih(wih),
      .sumout_m(mult_out),
      .sumout_m_valid(cal_valid)
      //    input [QZ-1: 0]ad
    );









  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      data_addr <= 'd0;
    end
    else
    begin
      case(STATE_HID)
        HID_CYCLE_ah:
        begin
          if(cnt_add)
          begin
            data_addr <= data_addr + 'd1 ;
          end
          else
          begin
            data_addr <= data_addr;
          end
        end
        default:
        begin
          data_addr <= 0;
        end
      endcase
    end
  end
  /*
  reg [LENGTH_DATA - 1 : 0]data_addr_ad;
   
  always@(posedge clk or negedge rst_n)
   begin 
   if(~rst_n)
    begin 
      data_addr_ad <= 'd0;
    end
   else begin 
     case(STATE_HID)
     HID_CYCLE_ad: begin if(cnt_add) 
    begin data_addr_ad <= data_addr_ad + 'd1 ; end
    else begin data_addr_ad <= data_addr_ad; end
  end
  default: begin data_addr_ad <= 0; end
  endcase
    end 
  end
  */

  reg[LENGTH_DATA - 1 : 0]data_addr_ram;
  reg [2:0]adr_add;//////////四个门的数据依次排列
  assign data_addr_ram_o = {2'd0,data_addr};
  //always@(*)
  // begin
  //    case(STATE_SUM_dd)
  //    INGA:begin           data_addr_ram =data_addr;end//{data_addr[LENGTH_DATA-3:0],2'b00} +  {{LENGTH_DATA-3{1'b0}},2'd0};    end
  //    FORGET:begin         data_addr_ram ={data_addr[LENGTH_DATA-3:0],2'b00} +  {{LENGTH_DATA-3{1'b0}},2'd1};    end
  //    CELL:begin           data_addr_ram ={data_addr[LENGTH_DATA-3:0],2'b00} +  {{LENGTH_DATA-3{1'b0}},2'd2};    end
  //    OUTGATE:begin        data_addr_ram ={data_addr[LENGTH_DATA-3:0],2'b00} +  {{LENGTH_DATA-3{1'b0}},2'd3};    end
  //    default:begin        data_addr_ram ={data_addr[LENGTH_DATA-3:0],2'b00} +  {{LENGTH_DATA-3{1'b0}},2'd0};    end
  //
  //endcase

  // end
  assign ram_data_in0 = ram_data_in;
  assign HID_CYCLE_FINISH = HIDcyc_finish;

endmodule
