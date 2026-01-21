`timescale 1ns / 1ps
module Ct_Ht_cal#(
    parameter DEBUG = 1,


    parameter input_size = 1, //输入特征数
    parameter hidden_size = 64, //隐藏层特征数
    parameter num_layers = 1, //LSTM层数
    parameter output_size = 1, //输出类别数
    parameter batch_size = 1, //批大小
    parameter sequence_length = 1, //序列长度


    parameter LENGTH_DATA = $clog2(hidden_size),
    parameter QZ_R = 8,
    parameter QZ_D = 16,
    parameter QZ = 16 //数据量化位宽)
  )(
    input clk ,
    input rst_n ,

    input [QZ*2*4-1:0]sum_data_reg,
    input last_eigenvalue,
    input wire ad_data_in_valid,
    input wire [QZ*2*4-1:0]ad_data_in,

    input wire [10:0]STATE_SUM,
    input weight_out_valid,
    output wire [QZ-1:0]ht_data,
    output wire [QZ-1:0]ht_out_fc,
    output wire data_elu_out_v,
    output wire [QZ-1:0]ht_wr_fifo,
    output reg ht_wr_valid_ram,
    input wire [LENGTH_DATA-1:0]ht_rdaddr,
    output reg data_save_reg,//将数据存到对应寄存器中
    output reg gate_cal_finish_o,


    input [LENGTH_DATA-1:0]addr_rd_h,
    output wire cal_finish//指示一组特征数计算完成

  );
  reg gate_cal_finish;
  reg [QZ-1:0]ft;
  reg [QZ-1:0]it;
  reg [QZ-1:0]ot;
  reg [QZ-1:0]gt;

  reg [3:0]STATE;
  localparam INIT = 0,
             Act_cal_INGA  = 1,
             Act_cal_FORGET  = 2,
             Act_cal_CELL  = 3,
             Act_cal_OUTGATE  = 4,
             FINISH = 5;
  reg [10:0]STATE_SUMd;

  reg actcal_start;

  reg [QZ*2*4-1:0]ACT_data_i;


reg [8:0]cnt_batch_size;//批大小计数器





  localparam
    INGA = 1,
    FORGET = 2,
    CELL = 3,
    OUTGATE = 4;
  ////激活函数选择
  reg [QZ-1:0]ACT_data_out;
  reg [QZ-1:0]ACT_data_outd;
  reg ACT_data_out_valid;

  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin

      STATE_SUMd <= 'd0;
      actcal_start <= 0;
      ACT_data_i <= 'd0;
      data_save_reg <= 'd0;
      STATE <= INIT;
      gate_cal_finish <= 'd0;
    end
    else
    begin
      case(STATE)
        INIT :
        begin
          data_save_reg <= 'd0;
          gate_cal_finish <= 'd0;
          if(last_eigenvalue&&ad_data_in_valid)
          begin
            STATE_SUMd <= STATE_SUM;
            STATE <= Act_cal_INGA;
            actcal_start <= 1;

            ACT_data_i[QZ*2*1-1:QZ*2*0]<= sum_data_reg[QZ*2*1-1:QZ*2*0] + ad_data_in[QZ*2*1-1:QZ*2*0];
            ACT_data_i[QZ*2*2-1:QZ*2*1]<= sum_data_reg[QZ*2*2-1:QZ*2*1] + ad_data_in[QZ*2*2-1:QZ*2*1];
            ACT_data_i[QZ*2*3-1:QZ*2*2]<= sum_data_reg[QZ*2*3-1:QZ*2*2] + ad_data_in[QZ*2*3-1:QZ*2*2];
            ACT_data_i[QZ*2*4-1:QZ*2*3]<= sum_data_reg[QZ*2*4-1:QZ*2*3] + ad_data_in[QZ*2*4-1:QZ*2*3];

          end
          else
          begin
            STATE_SUMd <= STATE_SUMd;
            STATE <= INIT;
            actcal_start <= 0;
            ACT_data_i <= 0;
          end
        end
        Act_cal_INGA:
        begin

          if(ACT_data_out_valid)
          begin
            STATE <= Act_cal_FORGET  ;
            data_save_reg <= 'd1;
            actcal_start <= 1;
            ACT_data_i   <= {{QZ*2-1{1'b0}},ACT_data_i[QZ*2*4-1:QZ*2*1]};
          end
          else
          begin
            STATE <= STATE;
            data_save_reg <= 'd0;
            actcal_start <= 0;
            ACT_data_i <= ACT_data_i;
          end

        end
        Act_cal_FORGET  :
        begin
          actcal_start <= 0;
          if(ACT_data_out_valid)
          begin
            STATE <= Act_cal_CELL  ;
            data_save_reg <= 'd1;
            actcal_start <= 1;
            ACT_data_i   <= {{QZ*2-1{1'b0}},ACT_data_i[QZ*2*4-1:QZ*2*1]};
          end
          else
          begin
            STATE <= STATE;
            data_save_reg <= 'd0;
            actcal_start <= 0;
            ACT_data_i <= ACT_data_i;
          end

        end
        Act_cal_CELL  :
        begin
          actcal_start <= 0;
          if(ACT_data_out_valid)
          begin
            STATE <= Act_cal_OUTGATE  ;
            data_save_reg <= 'd1;
            actcal_start <= 1;
            ACT_data_i   <= {{QZ*2-1{1'b0}},ACT_data_i[QZ*2*4-1:QZ*2*1]};
          end
          else
          begin
            STATE <= STATE;
            data_save_reg <= 'd0;
            actcal_start <= 0;
            ACT_data_i <= ACT_data_i;
          end

        end
        Act_cal_OUTGATE  :
        begin
          actcal_start <= 0;
          if(ACT_data_out_valid)
          begin
            STATE <= FINISH;
            data_save_reg <= 'd1;
            actcal_start <= 0;
            ACT_data_i   <= {{QZ*2-1{1'b0}},ACT_data_i[QZ*2*4-1:QZ*2*1]};
          end
          else
          begin
            STATE <= STATE;
            data_save_reg <= 'd0;
            actcal_start <= 0;
            ACT_data_i <= ACT_data_i;
          end

        end
        FINISH:
        begin

          //if(weight_out_valid) begin
          STATE <= INIT;
          data_save_reg <= 'd0;
          gate_cal_finish <= 'd1;
          //end
          //  else begin STATE <= STATE;
          //      data_save_reg <= 'd1; end
        end
      endcase
    end

  end



  wire Sigmoid_out_valid;
  wire Tanh_out_valid;
  wire [QZ-1:0]Sigmoid_out;
  wire [QZ-1:0]Tanh_out;


  always@(*)
  begin
    case(STATE)
      Act_cal_INGA     :
      begin
        ACT_data_out <=  Sigmoid_out;
        ACT_data_out_valid <= Sigmoid_out_valid;
      end
      Act_cal_FORGET   :
      begin
        ACT_data_out <=  Sigmoid_out;
        ACT_data_out_valid <= Sigmoid_out_valid;
      end
      Act_cal_CELL     :
      begin
        ACT_data_out <=  Tanh_out;
        ACT_data_out_valid <= Tanh_out_valid;
      end
      Act_cal_OUTGATE  :
      begin
        ACT_data_out <=  Sigmoid_out;
        ACT_data_out_valid <= Sigmoid_out_valid;
      end
      default:
      begin
        ACT_data_out <=  0;
        ACT_data_out_valid <= 0;
      end
    endcase
  end

  reg data_save_reg_d;
  reg Sigmoid_out_valid_d;
  reg [3:0]STATEd;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      ACT_data_outd<= 'd0;
      data_save_reg_d <= 'd0;
      Sigmoid_out_valid_d <= 'd0;
      STATEd <='d0;
      gate_cal_finish_o <= 'd0;
    end
    else
    begin
      data_save_reg_d <= data_save_reg;
      ACT_data_outd<= ACT_data_out;
      Sigmoid_out_valid_d <= Sigmoid_out_valid;
      STATEd <=STATE;
      gate_cal_finish_o <= gate_cal_finish;
    end
  end
  wire save_data;
  assign save_data = ~data_save_reg_d&&data_save_reg;


  reg [LENGTH_DATA-1:0]addr_ct_ht;
  reg start_cal_ct_ht;//开始ht ct计算指示
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin

      addr_ct_ht <= 'd0;
    end
    else
    begin
      if(start_cal_ct_ht)
      begin
        if(addr_ct_ht>= hidden_size-1)
        begin
          addr_ct_ht <= 0;
        end
        else
        begin
          addr_ct_ht <= addr_ct_ht + 'd1;
        end
      end
      else
      begin
        addr_ct_ht <= addr_ct_ht;
      end
    end
  end




  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      ft<= 'd0;
      it<= 'd0;
      ot<= 'd0;
      gt<= 'd0;
      start_cal_ct_ht <= 'd0;
    end
    else if(Sigmoid_out_valid_d)
    begin
      case(STATEd)
        Act_cal_INGA   :
        begin
          ft<= ACT_data_outd;
          it<= it;
          ot<= ot;
          gt<= gt;
          start_cal_ct_ht <= 'd0;
        end
        Act_cal_FORGET :
        begin
          ft<= ft;
          it<= ACT_data_outd;
          ot<= ot;
          gt<= gt;
          start_cal_ct_ht <= 'd0;
        end
        Act_cal_CELL   :
        begin

          ft<= ft;
          it<= it;
          ot<= ACT_data_outd;
          gt<= gt;
          start_cal_ct_ht <= 'd0;
        end
        Act_cal_OUTGATE:
        begin
          ft<= ft;
          it<= it;
          ot<= ot;
          gt<= ACT_data_outd;
          start_cal_ct_ht <= 'd1;
        end
        default:
        begin
          ft<= ft;
          it<= it;
          ot<= ot;
          gt<= gt;
          start_cal_ct_ht <= 'd0;
        end
      endcase
    end
    else
    begin
      ft<= ft;
      it<= it;
      ot<= ot;
      gt<= gt;
      start_cal_ct_ht <= 'd0;
    end
  end




  Sigmoid
    #(
      .QZ_R(QZ_R),
      .QZ_D(QZ_D),
      .QZ(QZ) //数据量化位宽
    )Sigmoid_u
    (
      .clk(clk),
      .rst_n(rst_n),

      .data_valid(actcal_start),
      .data_in(ACT_data_i[QZ*2-1:0]),


      .data_out_valid(Sigmoid_out_valid),
      .data_out_o(Sigmoid_out)
    );


  Tanh
    #(
      .QZ_R(QZ_R),
      .QZ_D(QZ_D),
      .QZ(QZ) //数据量化位宽
    )Tanhu
    (
      .clk(clk),
      .rst_n(rst_n),

      .data_valid(actcal_start),
      .data_in(ACT_data_i[QZ*2-1:0]),


      .data_out_valid(Tanh_out_valid),
      .data_out_o(Tanh_out)
    );

  reg [1:0]STATECH;
  localparam INIT_CH    = 0,
             CAL_C      = 1,
             CAL_H      = 2,
             CAL_FINISH =3;
  reg valid_cal_c;
  reg valid_cal_h;
  wire [QZ-1:0]ct_out;
  reg [QZ*2-1:0]ct_in;
  wire [QZ*2-1:0]CT_multout0,CT_multout1;
  reg [QZ-1:0]ht_out;
  reg [6:0]valid_ct;
  wire ct_wr_valid;
  wire ht_wr_valid;
  reg ct_wr_valid_ram;

  assign ct_wr_valid = valid_ct[5];

  reg [6:0]valid_ht;
  assign ht_wr_valid = valid_ht[5];
  reg [LENGTH_DATA-1:0]addrctht;
  wire tanh_ct_out_valid;
  wire [QZ-1:0]tanh_ct_out;
  wire [QZ*2-1:0]CT_multout2;
  addct addctu(
    .data_a_re_i(CT_multout0), 
   .data_b_re_i(CT_multout1), 
   .result_re_o(CT_multout2)) ;
  //assign CT_multout2 = CT_multout0[QZ*2-1:0] + CT_multout1[QZ*2-1:0];
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      STATECH <= INIT_CH;
      valid_cal_c <= 0;
      addrctht <= 'd0;
      ct_in <= 0;
      ht_out <= 'd0;
      ct_wr_valid_ram <= 'd0;
      ht_wr_valid_ram <= 'd0;
    end
    else
    begin
      case(STATECH)
        INIT_CH   :
        begin
          ct_wr_valid_ram <= 'd0;
          ht_wr_valid_ram <= 'd0;
          ct_in <= ct_in;
          ht_out <=     ht_out ;
          if(addrctht>=hidden_size)
          begin
            addrctht <= 0;
          end
          else
          begin
            addrctht <= addrctht;
          end
          if(start_cal_ct_ht)
          begin
            STATECH <= CAL_C;
            valid_cal_c <= 1;
          end
          else
          begin
            STATECH <= INIT_CH;
            valid_cal_c <= 0;
          end
        end
        CAL_C     :
        begin
          valid_cal_c <= 0;
          if(ct_wr_valid)
          begin
            STATECH <= CAL_H;
            if(cnt_batch_size!='d0) begin ct_in<=CT_multout2;  end
            else begin ct_in<=CT_multout0; end
            //ct_in <= (|cnt_batch_size)?CT_multout2:CT_multout0;
            //ct_in <= CT_multout0;
            ct_wr_valid_ram <= 'd1;
          end
          else
          begin
            STATECH <= CAL_C;
            ct_wr_valid_ram <= 'd0;
          end
        end
        CAL_H     :
        begin
          ct_in <= ct_in;
          ct_wr_valid_ram <= 'd0;
          if(ht_wr_valid)
          begin
            STATECH <= CAL_FINISH;
            ht_out <= CT_multout1[QZ_D+QZ-1:QZ_D];
            ht_wr_valid_ram <= 'd1;
          end
          else
          begin
            STATECH <= CAL_H;
            ht_wr_valid_ram <= 'd0;
          end
        end
        CAL_FINISH:
        begin
          ct_in <= ct_in;
          ht_wr_valid_ram <= 'd0;
          ct_wr_valid_ram <= 'd0;
          ht_out <=    ht_out  ;
          addrctht  <= addrctht + 'd1;
          STATECH <= INIT_CH;
        end
      endcase

    end
  end


  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      valid_ct <='d0;
    end
    else
    begin
      valid_ct <={valid_ct[5:0],valid_cal_c};
    end

  end


  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      valid_ht <='d0;
    end
    else
    begin
      valid_ht <={valid_ht[5:0],tanh_ct_out_valid};
    end

  end


  mult_sigmoid FXG(
                 .clk_i(clk),
                 .clk_en_i(1),
                 .rst_i(~rst_n),
                 .data_a_i(ft),
                 .data_b_i(ot),
                 .result_o(CT_multout0)) ;


  reg [QZ-1:0]MULT_INA;
  reg [QZ-1:0]MULT_INB;
  wire [QZ-1:0]ct_in_a;
  assign ct_in_a = ct_in[QZ_D+QZ-1:QZ_D];
  always@(posedge clk)
  begin
    case(STATECH)
      CAL_C     :
      begin
        MULT_INA <= it;
        MULT_INB <= ct_out;
      end
      CAL_H     :
      begin
        MULT_INA <= gt;
        MULT_INB <= tanh_ct_out;
      end
      default:
      begin
        MULT_INA <= it;
        MULT_INB <= ct_out;
      end
    endcase
  end



  mult_sigmoid IXC(
                 .clk_i(clk),
                 .clk_en_i(1),
                 .rst_i(~rst_n),
                 .data_a_i(MULT_INA),
                 .data_b_i(MULT_INB),
                 .result_o(CT_multout1)) ;




  /////////////////////////ctram///////////
  /*
  generate if(DEBUG)
  begin
  ramdata
  #(
  .addr_width(LENGTH_DATA),
  .data_width(QZ),
  .data_deepth(hidden_size),
  .INITdata('d0)
  )ramdatau_c
  (
  .clka(clk),
  .clkb(clk),
  .rst_n(rst_n),
  .cs(1),
  //wr
  .wr_addr(addrctht),
  .wr_data(ct_in_a),
  .wr_en(ct_wr_valid_ram),
  //rd
  .rd_addr(addrctht),
  .rd_en(1),
  .rd_data(ct_out)
  );
  /////////////////////////htram///////////
  ramdata
  #(
  .addr_width(LENGTH_DATA),
  .data_width(QZ),
  .data_deepth(hidden_size),
  .INITdata('d65536)
  )ramdatau_h
  (
  .clka(clk),
  .clkb(clk),
  .rst_n(rst_n),
  .cs(1),
  //wr
  .wr_addr(addrctht),
  .wr_data(ht_out),
  .wr_en(ht_wr_valid_ram),
  //rd
  .rd_addr(ht_rdaddr),
  .rd_en(1),
  .rd_data(ht_data)
  );
  end
  else
  begin
  pmi_ram_dp
  #(
  .pmi_wr_addr_depth    (hidden_size), // integer
  .pmi_wr_addr_width    (LENGTH_DATA ), // integer
  .pmi_wr_data_width    (QZ ), // integer
  .pmi_rd_addr_depth    (hidden_size), // integer
  .pmi_rd_addr_width    (LENGTH_DATA ), // integer
  .pmi_rd_data_width    (QZ ), // integer
  .pmi_regmode          ("reg" ), // "reg"|"noreg"
  .pmi_resetmode        ("sync" ), // "async"|"sync"
  .pmi_init_file        ( ), // string
  .pmi_init_file_format ( ), // "binary"|"hex"
  .pmi_family           ("common" )  // "iCE40UP"|"common"
  ) pmi_ram_dp_c (
  .Data      (ct_in_a ),  // I:
  .WrAddress (addrctht ),  // I:
  .RdAddress (addrctht ),  // I:
  .WrClock   (clk ),  // I:
  .RdClock   (clk ),  // I:
  .WrClockEn (1 ),  // I:
  .RdClockEn (1 ),  // I:
  .WE        (ct_wr_valid_ram ),  // I:
  .Reset     (~rst_n ),  // I:
  .Q         (ct_out )   // O:
  );
  pmi_ram_dp
  #(
  .pmi_wr_addr_depth    (hidden_size), // integer
  .pmi_wr_addr_width    (LENGTH_DATA ), // integer
  .pmi_wr_data_width    (QZ ), // integer
  .pmi_rd_addr_depth    (hidden_size), // integer
  .pmi_rd_addr_width    (LENGTH_DATA ), // integer
  .pmi_rd_data_width    (QZ ), // integer
  .pmi_regmode          ("reg" ), // "reg"|"noreg"
  .pmi_resetmode        ("sync" ), // "async"|"sync"
  .pmi_init_file        ( ), // string
  .pmi_init_file_format ( ), // "binary"|"hex"
  .pmi_family           ("common" )  // "iCE40UP"|"common"
  ) pmi_ram_dp_h (
  .Data      (ht_out ),  // I:
  .WrAddress (addrctht ),  // I:
  .RdAddress (ht_rdaddr ),  // I:
  .WrClock   (clk ),  // I:
  .RdClock   (clk ),  // I:
  .WrClockEn (1 ),  // I:
  .RdClockEn (1 ),  // I:
  .WE        (ht_wr_valid_ram ),  // I:
  .Reset     (~rst_n ),  // I:
  .Q         (ht_data )   // O:
  );
  end
  endgenerate
  */

  /////////////////////////htram///////////

  ram_24x512 ram_dp_c(
              .wr_clk_i    (clk),
              .rd_clk_i    (clk),
              .rst_i       (~rst_n),
              .wr_clk_en_i (1),
              .rd_en_i     (1),
              .rd_clk_en_i (1),
              .wr_en_i     (ct_wr_valid_ram),
              .wr_data_i   (ct_in_a),
              .wr_addr_i   ({3'b000,addrctht}),
              .rd_addr_i   ({3'b000,addrctht}),
              .rd_data_o   (ct_out)) ;
  ram_24x512 ram_dp_h(
              .wr_clk_i    (clk),
              .rd_clk_i    (clk),
              .rst_i       (~rst_n),
              .wr_clk_en_i (1),
              .rd_en_i     (1),
              .rd_clk_en_i (1),
              .wr_en_i     (ht_wr_valid_ram),
              .wr_data_i   (ht_out),
              .wr_addr_i   ({3'b000,addrctht}),
              .rd_addr_i   ({3'b000,addr_rd_h}),
              .rd_data_o   (ht_data)) ;

//assign ht_data =  24'd32768;
assign ht_wr_fifo = ht_out;
  Tanh
    #(
      .QZ_R(QZ_R),
      .QZ_D(QZ_D),
      .QZ(QZ) //数据量化位宽
    )Tanhht
    (
      .clk(clk),
      .rst_n(rst_n),

      .data_valid(ct_wr_valid_ram),
      .data_in(ct_in),


      .data_out_valid(tanh_ct_out_valid),
      .data_out_o(tanh_ct_out)
    );

/*
  wr_file#(
           .WIDTH(QZ),
           .LENGTH(hidden_size)


         )cesh
         (.clk(clk),
          .rst_n(rst_n),
          .data_in(ht_out),
          .data_in_valid(ht_wr_valid_ram)
         );
*/



  assign cal_finish = (addrctht>=hidden_size-1)&&ht_wr_valid_ram;

/*

  wire [QZ*2-1:0]sum_data_reg0[0:3],ad_data_in0[0:3],ACT_data_i0[0:3];
  genvar i;
  generate for(i=0;i<4;i=i+1)
    begin:debug
      assign sum_data_reg0[i] = sum_data_reg[QZ*2*(i+1)-1:QZ*2*i];
      assign ad_data_in0[i]   = ad_data_in[QZ*2*(i+1)-1:QZ*2*i];
      assign ACT_data_i0[i]   = ACT_data_i[QZ*2*(i+1)-1:QZ*2*i];

    end
  endgenerate
*/
  always@(posedge clk or negedge rst_n)
  begin 
    if(~rst_n) begin cnt_batch_size<= 'd0; end
      else begin if(cal_finish) 
            begin cnt_batch_size<=(cnt_batch_size==sequence_length-1)?'d0:cnt_batch_size+1; end 
        else begin
          cnt_batch_size<= cnt_batch_size;
         end
      end
  end

/////////////////////////////////////////////
////elu_cal


  reg [LENGTH_DATA-1:0]addrctht0,addrctht1,addrctht2,addrctht3,addrctht4;
  always@(posedge clk or negedge rst_n)
  begin 
    if(~rst_n) begin addrctht0<= 'd0;addrctht1<= 'd0;addrctht2<= 'd0;addrctht3<= 'd0;addrctht4<= 'd0;end
        else begin
          addrctht0<= addrctht;addrctht1<= addrctht0;addrctht2<= addrctht1;addrctht3<= addrctht2;addrctht4<= addrctht3;
         end
  end

//wire data_elu_out_v;
wire [QZ-1:0]data_out_o;
 
  felu ua
  (
  .clk(clk),
  .rst_n(rst_n),
  
  .data_valid(ht_wr_valid_ram),
  .data_in(ht_out),
  
  .data_out_valid(data_elu_out_v),
  .data_out_o(data_out_o)
  );
 /*
wire [QZ-1:0]eluout;

  ram_24x512 ram_24x512elu(
              .wr_clk_i    (clk),
              .rd_clk_i    (clk),
              .rst_i       (~rst_n),
              .wr_clk_en_i (1),
              .rd_en_i     (1),
              .rd_clk_en_i (1),
              .wr_en_i     (data_elu_out_v),
              .wr_data_i   (data_out_o),
              .wr_addr_i   ({3'b000,addrctht4}),
              .rd_addr_i   ({3'b000,ht_rdaddr}),
              .rd_data_o   (eluout)) ;*/
              assign  ht_out_fc = data_out_o;
  
endmodule
