`timescale 1ns / 1ps
module LSTM
  #(
     parameter DEBUG = 0,

     parameter input_size = 96, //输入特征数
     parameter hidden_size = 512, //隐藏层特征数
     parameter num_layers = 1, //LSTM层数
     parameter output_size = 96, //输出类别数
     parameter batch_size = 1, //批大小
     parameter sequence_length = 1, //序列长度


     parameter LENGTH_DATA = $clog2(hidden_size),

     parameter WIDTH_CNT = $clog2(input_size)+1,  //输入特征累加防止溢出
     parameter QZ_R = 8,
     parameter QZ_D = 16,
     parameter QZ = QZ_R + QZ_D, //数据量化位宽
     parameter DATA_WITCH =  WIDTH_CNT + QZ,
     //计算余数与所需并行计算次数  余数将使最后一次并行计算包含0值
     parameter PARALL_NUM = 1 ,//并行计算规模 必须为2的幂次
     parameter INPUTSIZE = input_size/PARALL_NUM,
     parameter REMAINDER = input_size - INPUTSIZE * PARALL_NUM,// 计算余数
     parameter ADDR_WIDTHBIAS = $clog2(hidden_size*4),

     parameter OS_W = $clog2(output_size)+1,






     parameter H_ADDR_WIDTH = $clog2(hidden_size*4),





     parameter INGATE_ADDR = hidden_size * input_size * 0,
     parameter FORGET_ADDR = hidden_size * input_size * 1,
     parameter CELL_ADDR =   hidden_size * input_size * 2,
     parameter OUT_ADDR =    hidden_size * input_size * 3

   )
   (
     input clk,
     input rst_n,
     input start, //开始计算
     input clk_200m,

     input [ PARALL_NUM*QZ-1: 0 ]data_in,
     input data_in_valid,

     output data_read,

     output [QZ-1:0]ht_out,
     output wire [QZ-1:0]ht_wr_fifo,
     output ht_valid,
     output   wire fifo_ready_w,

     //input wr_fifo_data_valid,
     //input [15:0]wr_fifo_data,
     input  wire fifo_ready_r,
     input wire fifo_ready_fc,
     output  wire [ADDR_WIDTHBIAS-1:0]cnt_hidden_size0,
     input  wire [QZ_D*4-1:0]bias_gate,
     output rd_weight_en,
     output rd_weight_fc,
     input wire weight_out_valid,
     input wire [QZ*4-1:0]weight_out,
     input wire [QZ_R-1:0]weight_out_fc,
     output [OS_W-1:0]fc_bais_adr,
     input  [QZ-QZ_R-1:0]fc_bais_data,
     output   wire [H_ADDR_WIDTH-1:0]h_rd_adr_i,
     output wire [LENGTH_DATA:0]fc_w_adr,
     ///////debug
     output   wire cal_Chara_finish,
     output   wire [47:0]data_debug,
     output   wire data_debug_valid,
     output wire [10:0]cal_cnt,
     ////////////////
     output wire [QZ*2-1:0]output_data,
     output wire         output_data_valid

     ////


   );

  wire [QZ-1:0]ht;
  assign ht_out = ht;
  //assign htout = &ht;
  //wire [ PARALL_NUM*QZ-1: 0 ]data_in;
  //assign data_in = 0;
  wire last_eigenvalue;//最后一个特征值，当处于改状态时将进行C,H参数计算

  ////////////////////////////////计算类状态机

  wire rd_busy; //当ad计算读取参数时占用spi总线
  wire cal_finish;//指示一组特征数计算完成
  wire cal_finish_ah;
  reg [2:0]STATE_TYPE;
  wire HID_CYCLE_FINISH;
  reg ahcal_busy ;

  reg start_ah_cal;
  wire rd_weight;
  localparam INIT = 0,
             CAL_AD = 1,
             CAL_AH = 2,
             WAIT   = 3;
  reg start_cala;
  wire htcal_finish;
  wire gate_cal_finish;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      STATE_TYPE <= INIT;
      ahcal_busy <= 'd0;
      start_ah_cal <= 'd0;
      start_cala <= 'd0;
    end
    else
    begin
      case(STATE_TYPE)
        INIT:
        begin
          ahcal_busy <= 'd0;
          start_cala <= 'd0;
          if(start)
          begin
            STATE_TYPE <= CAL_AH;
            start_ah_cal <= 'd0;
          end
          else
          begin
            STATE_TYPE <= INIT;
            start_ah_cal <= 'd0;
          end
        end
        CAL_AD:
        begin
          ahcal_busy <= 'd1;
          start_ah_cal <= 'd0;
          start_cala <= 'd1;
          if(htcal_finish)
          begin
            STATE_TYPE <= INIT;
          end
          else
          begin
            STATE_TYPE <= CAL_AD;
          end
        end
        CAL_AH:
        begin
          ahcal_busy <= 'd0;
          start_ah_cal <= 'd0;
          start_cala <= 'd1;
          if(cal_finish_ah)
          begin
            STATE_TYPE <= WAIT;
          end
          else
          begin
            STATE_TYPE <= CAL_AH;
          end
        end
        WAIT:
        begin
          ahcal_busy <= 'd1;
          start_cala <= 'd1;
          STATE_TYPE <= CAL_AD;
          start_ah_cal <= 'd1;
        end
        //  if(weight_out_valid||cal_finish_ah) begin STATE_TYPE <= CAL_AD; start_ah_cal <= 'd1;end
        //   else begin STATE_TYPE <= STATE_TYPE; start_ah_cal <= 'd0;  end end
      endcase


    end
  end



  /////////////////////////////////////////////////////////////////////////////////
  wire [2:0]STATE_HID;//隐藏层状态机
  wire cnt_input_size_valid;
  wire cnt_hidden_size_valid;
  wire cnt_input_size_valid_ad;
  wire cnt_hidden_size_valid_ad;
  //wire [PARALL_NUM*QZ*4-1:0]weight_out;
  wire [LENGTH_DATA - 1+ 2 : 0]data_addr_ram;
  wire                         ram_valid_wr;
  wire [QZ*2*4-1:0]              ram_data_in0;
  wire [QZ*2*4-1:0]              ram_data_out0;

  wire [10:0]STATE_SUM;
  wire Gate_Cal; //指示权重读取模块从mem中读出相应权重值

  reg valid_weight;
  wire [10:0]STATE_SUM_dd;

  LSTM_config
    #(
      .input_size       (input_size), //输入特征数
      .hidden_size      (hidden_size), //隐藏层特征数
      .num_layers       (num_layers), //LSTM层数
      .output_size      (output_size) , //输出类别数
      .batch_size       (batch_size), //批大小
      .sequence_length  (sequence_length), //序列长度
      .QZ_R(QZ_R),//整数部分量化
      .QZ_D(QZ_D),//小数部分量化
      .QZ(QZ),


      .PARALL_NUM(PARALL_NUM)//并行计算规模 必须为2的倍数

    )ad
    (
      .clk            (clk)  ,
      .rst_n          (rst_n)  ,
      .start          (start)  , //开始计算
      .data_in        (data_in)  ,
      .data_in_valid  (data_in_valid)  ,
      .wih            (weight_out),
      .cnt_input_size_valid(cnt_input_size_valid),
      .cnt_hidden_size_valid(cnt_hidden_size_valid),
      .cnt_input_size_valid_ad(cnt_input_size_valid_ad),
      .cnt_hidden_size_valid_ad(cnt_hidden_size_valid_ad),

      .fifo_ready(fifo_ready_r),
      .rd_weight(rd_weight),
      .STATE_HID(STATE_HID),
      .STATE_SUM(STATE_SUM),
      .STATE_SUM_dd(STATE_SUM_dd),
      .HID_CYCLE_FINISH(HID_CYCLE_FINISH),
      .data_addr_ram_o     (data_addr_ram),
      .ram_valid_wr      (ram_valid_wr),
      .ram_data_in0      (ram_data_in0),
      .ram_data_out0     (ram_data_out0),
      .Gate_Cal          (Gate_Cal),
      .cal_cnt(cal_cnt),
      .add_finish(htcal_finish),
      .last_eigenvalue(last_eigenvalue),
      .gate_cal_finish(gate_cal_finish),
      .weight_out_valid(weight_out_valid&&~valid_weight)
      //    input [QZ-1: 0]ad
    );

  always@(*)
  begin
    case(STATE_TYPE)
      CAL_AD:
      begin
        valid_weight= 'd0;
      end
      CAL_AH:
      begin
        valid_weight = 'd1;
      end
      default:
      begin
        valid_weight = 'd1;
      end
    endcase
  end


  localparam AD_ADR_WIDTH =  $clog2(hidden_size*hidden_size*4);
  wire [AD_ADR_WIDTH-1:0]addr_ram_ad;


  wire [H_ADDR_WIDTH-1:0]h_rd_adr;


  // wire [ADDR_WIDTHBIAS-1:0]cnt_hidden_size0;

  wire [QZ*4-1:0]bih;
  wire [QZ*4-1:0]bhh;

  assign bhh = 0;
  wire [QZ-1:0]ht_data;
  wire data_save_reg;//将数据存到对应寄存器中
  //wire rd_weight_en ;
  assign rd_weight_en = (rd_busy||rd_weight);


  /*
    weight_save
    #(.QZ(16),
      .input_size( input_size), //输入特征数
      .hidden_size (hidden_size) 
   
     )weight_save_inst//隐藏层特征数)
     (
       .clk_200m(clk_200m),
       .user_clk(clk),
       .rst(~rst_n),
   
       .wr_fifo_data_valid(wr_fifo_data_valid),
       .wr_fifo_data(wr_fifo_data),
   
   
       .wr_ram_valid(),
       .wr_ram_data(),
       .fifo_ready_r(fifo_ready_r),
       .fifo_ready(fifo_ready_w),
       .cnt_hidden_size0(cnt_hidden_size0),
       .bias_gate(bias_gate),
       .weight_out(),
       .weight_out_valid_o(),
   
       .rd_en(rd_weight_en),
       .rd_en_fc(1)
     );*/
  genvar i;

  generate for(i=0;i<4;i=i+1)
    begin:bias_save
      assign bih[QZ*(i+1)-1:QZ*(i)] ={{QZ_R{bias_gate[QZ_D*(i+1)-1]}},bias_gate[QZ_D*(i+1)-1:QZ_D*(i)]};
    end
  endgenerate


  wire[LENGTH_DATA-1:0]addr_rd_h;

  wire [LENGTH_DATA+2-1:0]ht_rdaddr;
  assign ht = ht_data;
  weight_read
    #(
      .DEBUG(DEBUG),
      . input_size        (input_size      ) , //输入特征数
      . hidden_size       (hidden_size     ) , //隐藏层特征数
      . num_layers        (num_layers      ) , //LSTM层数
      . output_size       (output_size     ) , //输出类别数
      . batch_size        (batch_size      ) , //批大小
      . sequence_length   (sequence_length ) , //序列长度
      .QZ_R(QZ_R),//整数部分量化
      .QZ_D(QZ_D),//小数部分量化
      . QZ                (QZ) , //数据量化位宽
      . PARALL_NUM        (PARALL_NUM)   //并行计算规模 必须为2的幂次
    ) weight_read_u
    (
      .clk  (clk),
      .rst_n(rst_n) ,
      .STATE_HID(STATE_HID),
      .cnt_input_size_valid(cnt_input_size_valid),
      .cnt_hidden_size_valid(cnt_hidden_size_valid),


      .cal_Chara_finish(),
      .STATE_TYPE(STATE_TYPE),
      .Gate_Cal          (Gate_Cal),
      .STATE(STATE_SUM),
      .start_read(start_ah_cal),

      .rd_busy_ah(rd_weight),
      .HID_CYCLE_FINISH(HID_CYCLE_FINISH),
      .last_eigenvalue(last_eigenvalue),

      .addr_ram_ad(addr_ram_ad),/////////////whh参数读取地址
      .data_save_reg(data_save_reg),

      .bih(),
      .bhh(),
      .cnt_hidden_size0(cnt_hidden_size0),
      .rd_busy      (rd_busy),
      .fifo_ready(fifo_ready),
      .weight_out_o(),
      .weight_out_valid_o()
    );

  //wire ram_wr_valid_h;
  wire ram_wr_valid_ah;
  wire  [QZ*2*4-1:0]ram_data_in_ah;
  wire  [QZ*2*4-1:0]ram_data_out_ah;

  assign data_debug = {24'd0,ht_data};//ram_data_in0[47:0];

  /*统计数据长度*/
  reg [10:0]lengthcnt;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      lengthcnt<='d0;
    end
    else if(htcal_finish)
    begin
      if(lengthcnt==140-1)
      begin
        lengthcnt<=0;
      end
      else
      begin
        lengthcnt<=lengthcnt+ 'd1;
      end
    end
    else
    begin
      lengthcnt<=lengthcnt;
    end
  end
  wire [QZ-1:0]ht_data_in;
  assign ht_data_in =(|lengthcnt)? ht_data:'d0;//'d0;

  /************/






  wire[7-1:0]cnt_row0;
  ah_cal#(
          .QZ(QZ),
          .hidden_size(hidden_size)
        ) uuah
        (
          .clk          (clk)    ,
          .rst_n        (rst_n)    ,
          .ahcal_busy   (ahcal_busy)    , //ah计算忙
          .start        (start_cala)    , //开始计算LSTM
          .whh         (weight_out),//(weight_out)    ,
          .whh_valid    (weight_out_valid&&valid_weight)    ,
          .data_in      (ht_data_in)    ,
          .rd_busy      (rd_busy),
          .new_cal      (cal_Chara_finish),  //开始新的求和计算

          .h_rd_adr     (h_rd_adr),

          .addr_ram_whho(addr_ram_ad),
          .ht_rdaddr(ht_rdaddr),
          .ram_data_in (ram_data_in_ah),
          .ram_data_out(ram_data_out_ah),
          .ram_wr_valid(ram_wr_valid_ah),
          .fifo_ready(fifo_ready_r),
          .cal_finish_o(cal_finish_ah),

          .cnt_row0(cnt_row0)


        );







  wire [H_ADDR_WIDTH-1:0]h_rd_adr_cal;


  localparam INIT0 = 0,
             INGA = 1,
             FORGET = 2,
             CELL = 3,
             OUTGATE = 4,
             FINISH = 5;
  ///////////////////////////读地址计算
  reg [ADDR_WIDTHBIAS-1:0]     gate_num;
  always@(*)
  begin
    case(STATE_SUM)
      INGA:
      begin
        gate_num = hidden_size * 0;
      end
      FORGET:
      begin
        gate_num = hidden_size * 1;
      end
      CELL:
      begin
        gate_num = hidden_size * 2;
      end
      OUTGATE:
      begin
        gate_num = hidden_size * 3;
      end
      default:
      begin
        gate_num = 'd0;
      end
    endcase
  end
  assign h_rd_adr_cal = cnt_hidden_size0  + gate_num;
  assign   h_rd_adr_i  =  last_eigenvalue? h_rd_adr_cal :h_rd_adr;

  /*
  generate if(DEBUG) begin 
      ///////////////////////////////////////////////1
      ramdata
     #(
         .addr_width($clog2(hidden_size)),
         .data_width(QZ*2*4),
         .data_deepth(hidden_size),
         .INITdata('d0)
     )ramdatau_gate
     (
        .clka(clk),
        .clkb(clk),
        .rst_n(rst_n),
        .cs(1),
         //wr
         .wr_addr(data_addr_ram),
         .wr_data(ram_data_in0),
         .wr_en  (ram_valid_wr),
         //rd
         .rd_addr(data_addr_ram),
         .rd_en(1),
         .rd_data(ram_data_out0)
         );
   
         ramdata
         #(
             .addr_width($clog2(hidden_size)),
             .data_width(QZ*2*4),
             .data_deepth(hidden_size),
             .INITdata('d0)
         )ramdatau_ah
         (
            .clka(clk),
            .clkb(clk),
            .rst_n(rst_n),
            .cs(1),
             //wr
             .wr_addr(h_rd_adr),
             .wr_data(ram_data_in_ah),
             .wr_en(ram_wr_valid_ah),
             //rd
             .rd_addr(h_rd_adr_i),
             .rd_en(1),
             .rd_data(ram_data_out_ah)
             );
             //////////////////////////////////////
             
     end
     else begin 
         pmi_ram_dp
         #(
           .pmi_wr_addr_depth    (hidden_size*4 ), // integer
           .pmi_wr_addr_width    ($clog2(hidden_size*4) ), // integer
           .pmi_wr_data_width    (QZ*2 ), // integer
           .pmi_rd_addr_depth    (hidden_size*4 ), // integer
           .pmi_rd_addr_width    ($clog2(hidden_size*4) ), // integer
           .pmi_rd_data_width    (QZ*2 ), // integer
           .pmi_regmode          ("reg" ), // "reg"|"noreg"
           .pmi_resetmode        ("sync" ), // "async"|"sync"
           .pmi_init_file        ( ), // string
           .pmi_init_file_format ( ), // "binary"|"hex"
           .pmi_family           ("common" )  // "iCE40UP"|"common"
         ) pmi_ram_dp_gate (
           .Data      (ram_data_in0 ),  // I:
           .WrAddress (data_addr_ram ),  // I:
           .RdAddress (data_addr_ram ),  // I:
           .WrClock   (clk ),  // I:
           .RdClock   (clk ),  // I:
           .WrClockEn (1 ),  // I:
           .RdClockEn (1 ),  // I:
           .WE        (ram_valid_wr ),  // I:
           .Reset     (~rst_n ),  // I:
           .Q         (ram_data_out0 )   // O:
         );
         pmi_ram_dp
         #(
           .pmi_wr_addr_depth    (hidden_size*4 ), // integer
           .pmi_wr_addr_width    ($clog2(hidden_size*4) ), // integer
           .pmi_wr_data_width    (QZ*2 ), // integer
           .pmi_rd_addr_depth    (hidden_size*4 ), // integer
           .pmi_rd_addr_width    ($clog2(hidden_size*4) ), // integer
           .pmi_rd_data_width    (QZ*2 ), // integer
           .pmi_regmode          ("reg" ), // "reg"|"noreg"
           .pmi_resetmode        ("sync" ), // "async"|"sync"
           .pmi_init_file        ( ), // string
           .pmi_init_file_format ( ), // "binary"|"hex"
           .pmi_family           ("common" )  // "iCE40UP"|"common"
         ) pmi_ram_dp_ah (
           .Data      (ram_data_in_ah ),  // I:
           .WrAddress (h_rd_adr ),  // I:
           .RdAddress (h_rd_adr_i ),  // I:
           .WrClock   (clk ),  // I:
           .RdClock   (clk ),  // I:
           .WrClockEn (1 ),  // I:
           .RdClockEn (1 ),  // I:
           .WE        (ram_wr_valid_ah ),  // I:
           .Reset     (~rst_n ),  // I:
           .Q         (ram_data_out_ah )   // O:
         ); 
     
     end
     endgenerate

  RAM_2048X48 pmi_ram_dp_gate(
                .wr_clk_i      (clk),
                .rd_clk_i      (clk),
                .rst_i         (~rst_n),
                .wr_clk_en_i   (1),
                .rd_en_i       (1),
                .rd_clk_en_i   (1),
                .wr_en_i       (ram_valid_wr),
                .wr_data_i     (ram_data_in0),
                .wr_addr_i     ({3'b000,data_addr_ram}),
                .rd_addr_i     ({3'b000,data_addr_ram}),
                .rd_data_o     (ram_data_out0)) ;
                
  RAM_2048X48 pmi_ram_dp_ah(
    .wr_clk_i      (clk),
    .rd_clk_i      (clk),
    .rst_i         (~rst_n),
    .wr_clk_en_i   (1),
    .rd_en_i       (1),
    .rd_clk_en_i   (1),
    .wr_en_i       (ram_wr_valid_ah),
    .wr_data_i     (ram_data_in_ah),
    .wr_addr_i     ({3'b000,h_rd_adr  }),
    .rd_addr_i     ({3'b000,h_rd_adr_i}),
    .rd_data_o     (ram_data_out_ah)) ;

  */
  wire [(QZ*2-23)*4-1:0]dp_gate_in,dp_ah_in;
  wire [(QZ*2-23)*4-1:0]dp_gate_out,dp_ah_out;
  generate for(i=0;i<4;i=i+1)
    begin :ramrw
      assign dp_gate_in[(QZ*2-23)*(i+1)-1:(QZ*2-23)*i]=  ram_data_in0[(QZ*2)*(i+1)-1:(QZ*2)*i+23];
      assign dp_ah_in[(QZ*2-23)*(i+1)-1:(QZ*2-23)*i]=  ram_data_in_ah[(QZ*2)*(i+1)-1:(QZ*2)*i+23];
      // assign ram_data_out0[(QZ*2)*(i+1)-1:(QZ*2)*i] = {dp_gate_out[(QZ*2-23)*(i+1)-1:(QZ*2-23)*i],23'd0};
      // assign ram_data_out_ah[(QZ*2)*(i+1)-1:(QZ*2)*i] =  {dp_ah_out[(QZ*2-23)*(i+1)-1:(QZ*2-23)*i],23'd0};
    end
  endgenerate

  /*
    ram512x4x48dp pmi_ram_dp_gate(
                    .wr_clk_i(clk),
                    .rd_clk_i(clk),
                    .rst_i(~rst_n),
                    .wr_clk_en_i(1),
                    .rd_en_i(1),
                    .rd_clk_en_i(1),
                    .wr_en_i  (ram_valid_wr),
                    .wr_data_i(ram_data_in0),
                    .wr_addr_i({3'b000,data_addr_ram}),
                    .rd_addr_i({3'b000,data_addr_ram}),
                    .rd_data_o(ram_data_out0)) ;
                    
    ram512x4x48dp pmi_ram_dp_ah(
                    .wr_clk_i(clk),
                    .rd_clk_i(clk),
                    .rst_i(~rst_n),
                    .wr_clk_en_i(1),
                    .rd_en_i(1),
                    .rd_clk_en_i(1),
                    .wr_en_i  (ram_wr_valid_ah),
                    .wr_data_i(ram_data_in_ah),
                    .wr_addr_i({3'b000,h_rd_adr}),
                    .rd_addr_i({3'b000,h_rd_adr_i}),
                    .rd_data_o(ram_data_out_ah)) ;
  */

  ram512x4x48dp pmi_ram_dp_gate(
                  .wr_clk_i(clk),
                  .rd_clk_i(clk),
                  .rst_i(~rst_n),
                  .wr_clk_en_i(1),
                  .rd_en_i(1),
                  .rd_clk_en_i(1),
                  .wr_en_i  (ram_valid_wr),
                  .wr_data_i(ram_data_in0),//(dp_gate_in),
                  .wr_addr_i({3'b000,data_addr_ram}),
                  .rd_addr_i({3'b000,data_addr_ram}),
                  .rd_data_o(ram_data_out0));//(dp_gate_out)
  ram512x4x48dp pmi_ram_dp_ah(
                  .wr_clk_i(clk),
                  .rd_clk_i(clk),
                  .rst_i(~rst_n),
                  .wr_clk_en_i(1),
                  .rd_en_i(1),
                  .rd_clk_en_i(1),
                  .wr_en_i  (ram_wr_valid_ah),
                  .wr_data_i(ram_data_in_ah),//(dp_ah_in),
                  .wr_addr_i({3'b000,h_rd_adr}),
                  .rd_addr_i({3'b000,h_rd_adr_i}),
                  .rd_data_o(ram_data_out_ah));//(dp_ah_out)


  /*
   
                    ramdata
                    #(
                        .addr_width($clog2(hidden_size)),
                       // .data_width((QZ*2-23)*4),
                        .data_width((QZ*2)*4),
                        .data_deepth(hidden_size),
                        .INITdata('d0)
                    )ramdatau_gate
                    (
                       .clka(clk),
                       .clkb(clk),
                       .rst_n(rst_n),
                       .cs(1),
                        //wr
                        .wr_addr(data_addr_ram),
                        .wr_data(ram_data_in0),//(dp_gate_in),
                        .wr_en  (ram_valid_wr),
                        //rd
                        .rd_addr(data_addr_ram),
                        .rd_en(1),
                        .rd_data(ram_data_out0)//(dp_gate_out)
                        );
                  
                        ramdata
                        #(
                            .addr_width($clog2(hidden_size)),
                            // .data_width((QZ*2-23)*4),
                            .data_width((QZ*2)*4),
                            .data_deepth(hidden_size),
                            .INITdata('d0)
                        )ramdatau_ah
                        (
                           .clka(clk),
                           .clkb(clk),
                           .rst_n(rst_n),
                           .cs(1),
                            //wr
                            .wr_addr(h_rd_adr),
                            .wr_data(ram_data_in_ah),//(dp_ah_in),
                            .wr_en(ram_wr_valid_ah),
                            //rd
                            .rd_addr(h_rd_adr_i),
                            .rd_en(1),
                            .rd_data(ram_data_out_ah)//(dp_ah_out)
                            );
                            wire ht_wr_valid_ram ;
                            assign ht_wr_valid_ram = (h_rd_adr =='d0)&&ram_wr_valid_ah;
                            wr_file#(
                                .WIDTH(25),
                                .LENGTH(512)
                            
                            
                              )cesh
                              (.clk(clk),
                               .rst_n(rst_n),
                               .data_in(dp_ah_in[24:0]),
                               .data_in_valid(ht_wr_valid_ram)
                              );*/

  wire [QZ*2*4-1:0]bhh_d;
  wire [QZ*2*4-1:0]bih_d;
  reg [QZ*2*4-1:0]sum_data_reg;//循环求和计算寄存器
  wire [47:0]sum_data_reg_test,ram_data_ah,ram_data_out_ah_test,bih_d_test,ram_data_out0_test;
  wire [23:0]weight_out_test;
  assign sum_data_reg_test =  sum_data_reg[47:0];
  assign ram_data_ah = ram_data_in0[47:0];
  assign ram_data_out_ah_test = ram_data_out_ah[47:0];
  assign bih_d_test = bih_d[47:0];
  assign ram_data_out0_test = ram_data_out0[47:0];
  assign weight_out_test = weight_out[23:0];


  reg weight_out_valid_d;
  reg weight_out_valid_dd;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      weight_out_valid_d<= 0;
      weight_out_valid_dd<= 0;
    end
    else
    begin
      weight_out_valid_d<= weight_out_valid;
      weight_out_valid_dd<= weight_out_valid_d;
    end
  end

  generate for(i=0;i<4;i=i+1)
    begin
      assign bhh_d[QZ*2*(i+1)-1:QZ*2*(i)] = {{(QZ_R+1){bhh[QZ*(i+1)-1]}},bhh[QZ*(i+1)-1:QZ*(i)],{(QZ_D-1){1'b0}}};
      assign bih_d[QZ*2*(i+1)-1:QZ*2*(i)] = {{(QZ_R+1){bih[QZ*(i+1)-1]}},bih[QZ*(i+1)-1:QZ*(i)],{(QZ_D-1){1'b0}}};



      always@(posedge clk or negedge rst_n)
      begin
        if(~rst_n)
        begin
          sum_data_reg[QZ*2*(i+1)-1:QZ*2*(i)] <= 'd0;
        end
        else if(last_eigenvalue)
        begin
          if(weight_out_valid_dd)
          begin
            sum_data_reg[QZ*2*(i+1)-1:QZ*2*(i)] <= ram_data_out_ah[QZ*2*(i+1)-1:QZ*2*(i)]+bhh_d[QZ*2*(i+1)-1:QZ*2*(i)]+ bih_d[QZ*2*(i+1)-1:QZ*2*(i)];
          end
          else
          begin
            sum_data_reg[QZ*2*(i+1)-1:QZ*2*(i)] <= sum_data_reg[QZ*2*(i+1)-1:QZ*2*(i)] ;
          end
        end
        else
        begin
          sum_data_reg[QZ*2*(i+1)-1:QZ*2*(i)] <= 0 ;
        end
      end

    end
  endgenerate


  wire [QZ*2-1:0]ram_data_out_ah0[0:3],bih_d0[0:3],bhh_d0[0:3];

  generate for(i=0;i<4;i=i+1)
    begin:debug
      assign ram_data_out_ah0[i] = ram_data_out_ah[QZ*2*(i+1)-1:QZ*2*i];
      assign bhh_d0[i]   = bhh_d[QZ*2*(i+1)-1:QZ*2*i];
      assign bih_d0[i]   = bih_d[QZ*2*(i+1)-1:QZ*2*i];

    end
  endgenerate


  wire data_elu_out_v;
  assign addr_rd_h = ht_rdaddr;
  wire [QZ-1:0]ht_out_fc;
  Ct_Ht_cal#(
             .DEBUG(DEBUG),
             .hidden_size(hidden_size),
             .QZ_R (QZ_R+1),
             .QZ_D (QZ_D-1),
             .sequence_length('d140),
             .QZ   (QZ  ) //数据量化位宽)
           )
           Ct_Ht_calu(
             .clk                (clk)     ,
             .rst_n              (rst_n)     ,
             .sum_data_reg       (sum_data_reg)     ,
             .last_eigenvalue    (last_eigenvalue)  ,
             .ad_data_in_valid   (ram_valid_wr)     ,
             .ad_data_in         (ram_data_in0)     ,
             .STATE_SUM          (STATE_SUM_dd),
             .weight_out_valid   (weight_out_valid_d),
             .data_save_reg      (data_save_reg),
             .ht_rdaddr(ht_rdaddr[LENGTH_DATA-1:0]),
             .gate_cal_finish_o(gate_cal_finish),
             .addr_rd_h(addr_rd_h),
             .ht_data(ht_data),
             .ht_out_fc(ht_out_fc),
             .data_elu_out_v(data_elu_out_v),
             .ht_wr_fifo(ht_wr_fifo),
             .ht_wr_valid_ram(ht_valid),
             .cal_finish()

           );
  reg last_eigenvalue_d;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      last_eigenvalue_d<='d0;
    end
    else
    begin
      last_eigenvalue_d<=last_eigenvalue;
    end
  end
  assign cal_Chara_finish = htcal_finish;
  assign data_read = last_eigenvalue_d? 0:HID_CYCLE_FINISH||start_ah_cal;



  wire ht_valid_in_fc;

  ///////////////////////////fc_cal//////////
  reg ht_valid_d,ht_valid_dd;
  reg ahcal_busyd;
  reg rd_busy_d;
  wire start_cal_fc;
  assign start_cal_fc = start&&~ahcal_busy;
  reg start_cal_fc_d,start_cal_fc_dd;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      ahcal_busyd <= 'd0;
      ht_valid_d <= 'd0;
      ht_valid_dd <= 'd0;
      start_cal_fc_d <= 'd0;
      start_cal_fc_dd<= 'd0;
    end
    else
    begin
      ahcal_busyd <= ahcal_busy;
      ht_valid_d <= ht_valid_in_fc;
      ht_valid_dd <= ht_valid_d;
      start_cal_fc_d <= start_cal_fc;
      start_cal_fc_dd<= start_cal_fc_d;
    end
  end


  assign ht_valid_in_fc = (weight_out_valid&&valid_weight)&&(h_rd_adr==0);

  wire start_cal;
  assign start_cal =~start_cal_fc_dd&&start_cal_fc_d;
  /*
    fc_cell#(
             .QZ(QZ),
             .output_size(output_size), //输入特征数
             .hidden_size(hidden_size) //隐藏层特征数
           )fc_cellu(
             .clk  (clk),
             .rst_n(rst_n),
   
             .start_cal(start_cal),
             .ht_in(ht_out_fc),
             .ht_valid(ht_valid_in_fc),
   
             .fifo_ready(fifo_ready_fc),
             .rd_weight_en(rd_weight_fc),
             .weight_in(weight_out_fc),
             .fc_bais_adr(fc_bais_adr),
  .fc_bais_data(fc_bais_data),
   
  .output_data(output_data),
  .output_data_valid(output_data_valid)
   
   
           );
  */
  FC_C#(
        .QZ(QZ),
        .output_size(output_size), //输入特征数
        .hidden_size(hidden_size) //隐藏层特征数
      )FC_Cu(
        .clk  (clk),
        .rst_n(rst_n),

        .ht_in(ht_out_fc),
        .ht_valid(data_elu_out_v),

        .weight_in(weight_out_fc),
        .fc_bais_adr(fc_bais_adr),
        .fc_bais_data(fc_bais_data),
        .fc_w_adr(fc_w_adr),
        .output_data(output_data),
        .output_data_valid(output_data_valid)


      );



  //assign rd_weight_fc = rd_busy;
  assign   data_debug_valid = ht_valid;//(last_eigenvalue)&&ram_valid_wr;
endmodule
