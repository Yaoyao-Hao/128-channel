`timescale 1ns / 1ps
module kalman_Iteration_ldl
  #(
     parameter MAX_COL = 4,
     parameter MAX_ROW = 4,
     parameter Seq_szie = 2,
     parameter DATA_W = 32,
     parameter Q = 16)
   (
     input clk,
     input rst,
     input start,
     input [Seq_szie*DATA_W-1:0]data_in,
     output [32*2-1:0]data_o,
     output data_o_v,
     output reg finsh_o,
     output reg             cal_data_o_v,
     output reg [DATA_W-1:0]cal_data_o,

     output wire  [$clog2(MAX_COL*MAX_COL)  :0]Address_rd,


     output  [$clog2(MAX_ROW)  :0]cnt_b_o,
     input   [DATA_W-1:0]Z_in



   );
  wire [DATA_W-1:0]INV_TEST_DATA;
  localparam A_size = Seq_szie;
  localparam max_size = MAX_ROW * MAX_ROW;
  wire data_Matrix_mult_v;
  wire[DATA_W-1:0] data_Matrix_mult;
  reg [DATA_W-1:0]x_prev[A_size-1:0];
  reg [DATA_W-1:0]x_prev_buf[A_size-1:0];
  reg [DATA_W-1:0]P_pred_Q0[A_size-1:0][A_size-1:0];
  reg [DATA_W-1:0]P_pred_Q1[A_size-1:0][A_size-1:0];
  wire [DATA_W-1:0]A  [A_size-1:0][A_size-1:0];
  wire [DATA_W-1:0]A_N[A_size-1:0][A_size-1:0];
  reg  [DATA_W-1:0]P  [A_size-1:0][A_size-1:0];
  reg  [DATA_W-1:0]P_buf[A_size-1:0][A_size-1:0];
  wire  [DATA_W-1:0]Qa  [A_size-1:0][A_size-1:0];
  reg  [DATA_W-1:0]dataA;
  reg  [DATA_W-1:0]dataB;
  wire [$clog2(MAX_ROW)  :0]cnt_a;
  reg [$clog2(MAX_ROW)  :0] cnt_a_d,cnt_a_dd,cnt_a_ddd;
  wire [$clog2(MAX_ROW)  :0]cnt_b;
  reg [$clog2(MAX_ROW)  :0] cnt_b_d,cnt_b_dd,cnt_b_ddd,cnt_b_dddd;
  wire [$clog2(MAX_COL)  :0]cnt_c;
  reg [$clog2(MAX_COL)  :0] cnt_c_d,cnt_c_dd,cnt_c_ddd;
  assign cnt_b_o = cnt_b_dd;
  reg[$clog2(MAX_COL):0]COL;
  reg[$clog2(MAX_ROW):0]ROW0,ROW1;
  assign A[0][0] = -'d1368;
  assign A[0][1] = 'd497;
  assign A[1][0] = -'d343;
  assign A[1][1] = -'d1151;
  assign A_N[0][0] = -'d1368;
  assign A_N[0][1] = -'d343;
  assign A_N[1][0] = 'd497;
  assign A_N[1][1] = -'d1151;
  // assign P[0][0] = 'd32767;
  // assign P[0][1] = 0;
  // assign P[1][0] = 0;
  // assign P[1][1] = 'd32767;
  assign Qa[0][0] = 'd560415;
  assign Qa[0][1] = 'd116889;
  assign Qa[1][0] = 'd116889;
  assign Qa[1][1] = 'd518343;
  localparam INIT    = 0 ,
             X_PRED  = 1 ,
             P_PRED0 = 2 ,
             P_PRED1 = 3 ,
             P_PRED2 = 4 ,
             K0      = 5 ,
             K1      = 6 ,
             TRA_Ma  = 7 ,
             K2      = 8 ,
             K3      = 9 ,
             x_curr0 = 10,
             x_curr_save = 15,
             x_curr1 = 11,
             P0      = 12,
             P1      = 13,
             FINISH  = 14
             ;
  wire [DATA_W-1:0]C;
  wire [DATA_W-1:0]C_N;
  reg  [$clog2(MAX_COL*MAX_COL)  :0]cnt_tra_ma;
  reg [$clog2(MAX_COL):0]C_RD_ADDR;
  reg [4:0]STATE;

  always@(*)
  begin
    case(STATE)
      default :
      begin
        C_RD_ADDR= {cnt_c[$clog2(MAX_ROW)-1  :0],1'b0} + cnt_a ;
      end
      x_curr0 :
      begin
        C_RD_ADDR= {cnt_b,1'b0}+ cnt_a;
      end
      P0     :
      begin
        C_RD_ADDR= {cnt_a,1'b0}  + cnt_c;
      end
    endcase
  end

  pmi_rom
    #(
      .pmi_addr_depth       (MAX_COL*2 ), // integer
      .pmi_addr_width       ($clog2(MAX_COL*2) ), // integer
      .pmi_data_width       (DATA_W ), // integer
      .pmi_regmode          ("noreg" ), // "reg"|"noreg"
      .pmi_resetmode        ("async"  ), // "async"|"sync"
      .pmi_init_file        ("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/C.hex" ), // string
      .pmi_init_file_format ("hex" ), // "binary"|"hex"
      .pmi_family           ("common" )  // "common"
    ) pmi_rom_C(
      .Address    (C_RD_ADDR ),  // I:
      .OutClock   (clk ),  // I:
      .OutClockEn (1   ),  // I:
      .Reset      (rst ),  // I:
      .Q          (C )   // O:
    );

  //assign C_RD_ADDR = {cnt_c[$clog2(MAX_ROW)-1  :0],1'b0} + cnt_a ;
  pmi_rom
    #(
      .pmi_addr_depth       (MAX_COL*2 ), // integer
      .pmi_addr_width       ($clog2(MAX_COL*2) ), // integer
      .pmi_data_width       (DATA_W ), // integer
      .pmi_regmode          ("noreg" ), // "reg"|"noreg"
      .pmi_resetmode        ("async"  ), // "async"|"sync"
      .pmi_init_file        ("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/C_N.hex" ), // string
      .pmi_init_file_format ("hex" ), // "binary"|"hex"
      .pmi_family           ("common" )  // "common"
    ) pmi_rom_C_N(
      .Address    (C_RD_ADDR ),  // I:
      .OutClock   (clk ),  // I:
      .OutClockEn (1   ),  // I:
      .Reset      (rst ),  // I:
      .Q          (C_N )   // O:
    );
  reg             wr_ram;
  reg [DATA_W-1:0]Q_ram;
  wire [DATA_W-1:0]Q_ram_out;
  reg [$clog2(MAX_COL*2):0]K_Q0_ADDR;
  wire[$clog2(MAX_COL*2):0]K_RD_ADDR;
  reg [$clog2(MAX_COL*2):0]K_ADDR,K_ADDR_k;
  wire [$clog2(MAX_COL*2):0]K_Q1_ADDR;
  always@(*)
  begin
    case(STATE)
      K0 :
      begin
        K_ADDR = K_Q0_ADDR;
      end
      K1 :
      begin
        K_ADDR = K_RD_ADDR;
      end
      K2 :
      begin
        K_ADDR = K_Q1_ADDR;
      end
      K3 :
      begin
        K_ADDR = {cnt_a,1'd0} + cnt_c;
      end
      x_curr0 :
      begin
        K_ADDR = cnt_b_dddd;
      end
      x_curr1 :
      begin
        K_ADDR = cnt_a;
      end
    endcase
  end
  reg [DATA_W-1:0]K_Q1;
  wire [DATA_W-1:0]K_Q1_OUT;
  pmi_ram_dq
    #(
      .pmi_addr_depth       (MAX_COL*2         ), // integer
      .pmi_addr_width       ($clog2(MAX_COL*2) ), // integer
      .pmi_data_width       (DATA_W            ), // integer
      .pmi_regmode          ("noreg" ), // "reg"|"noreg"
      .pmi_gsr              ("disable" ), // "enable"|"disable"
      .pmi_resetmode        ("async"  ), // "async"|"sync"
      .pmi_init_file        ("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/ram_init.hex"), // string
      .pmi_init_file_format ("hex"), // "binary"|"hex"
      .pmi_family           ("common" )  // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
    )pmi_ram_dp_be_cal_save (
      .Data      (Q_ram ),  // I:
      .Address   (K_ADDR ),  // I:
      .Clock     (clk ),  // I:
      .ClockEn   ( 1),  // I:
      .WE        (wr_ram&&(STATE == K0) ),  // I:
      .Reset     (rst ),  // I:
      .Q         (Q_ram_out )   // O:
    );
  pmi_ram_dq
    #(
      .pmi_addr_depth       (MAX_COL*2         ), // integer
      .pmi_addr_width       ($clog2(MAX_COL*2) ), // integer
      .pmi_data_width       (DATA_W            ), // integer
      .pmi_regmode          ("noreg" ), // "reg"|"noreg"
      .pmi_gsr              ("disable" ), // "enable"|"disable"
      .pmi_resetmode        ("async"  ), // "async"|"sync"
      .pmi_init_file        ("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/ram_init.hex"), // string
      .pmi_init_file_format ("hex"), // "binary"|"hex"
      .pmi_family           ("common" )  // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
    )pmi_ram_dp_be_k_Q1 (
      .Data      (Q_ram ),  // I:
      .Address   (K_ADDR ),  // I:
      .Clock     (clk ),  // I:
      .ClockEn   ( 1),  // I:
      .WE        (wr_ram&&((STATE == K2)||(STATE == x_curr0)) ),  // I:
      .Reset     (rst ),  // I:
      .Q         (K_Q1_OUT )   // O:
    );

  reg [$clog2(MAX_COL*MAX_COL):0]K_Q0_ADDR0;
  wire[$clog2(MAX_COL*MAX_COL):0]K_RD_ADDR0;
  reg [$clog2(MAX_COL*MAX_COL):0]K_ADDR0,K_ADDR1;
  reg [$clog2(MAX_COL*MAX_COL):0]KADDR_CAL;



  always@(*)
  begin
    case(STATE)
      K0 :
      begin
        K_ADDR0 = K_Q0_ADDR0;
      end
      K1 :
      begin
        K_ADDR0 = K_RD_ADDR0;
      end
    endcase
  end
  //???·????
  wire [$clog2(MAX_COL*MAX_COL):0]MAX_COL_ADD;
  wire [$clog2(MAX_COL*MAX_COL)+$clog2(MAX_COL):0]MAX_COL_ADD0;
  pmi_mult
    #(
      .pmi_dataa_width         ($clog2(MAX_COL*MAX_COL+1)), // integer
      .pmi_datab_width         ($clog2(MAX_COL)+1 ), // integer
      .pmi_sign                ("on" ), // "on"|"off"
      .pmi_additional_pipeline (0 ), // integer
      .pmi_input_reg           ( "on" ), // "on"|"off"
      .pmi_output_reg          ( "off"), // "on"|"off"
      .pmi_family              ("common"  ), // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
      .pmi_implementation      ("DSP" )  // "DSP"|"LUT"
    ) add_cal (
      .DataA  (MAX_COL ),  // I:
      .DataB  (cnt_c_dd),  // I:
      .Clock  (clk ),  // I:
      .ClkEn  (1 ),  // I:
      .Aclr   (rst ),  // I:
      .Result (MAX_COL_ADD0 )   // O:
    );
  always@(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      KADDR_CAL<='d0;
    end
    else
    begin
      KADDR_CAL <= {{($clog2(MAX_COL*MAX_COL)-$clog2(MAX_ROW)){1'd0}},cnt_b_ddd}  + MAX_COL_ADD0[$clog2(MAX_COL*MAX_COL):0]; //+ MAX_COL<<cnt_c_ddd - MAX_COL + MAX_COL_ADD ;
    end
  end
  always@(*)
  begin
    case(STATE)
      K1 :
      begin
        K_ADDR1 = KADDR_CAL;
      end
      TRA_Ma:
      begin
        K_ADDR1 = cnt_tra_ma;
      end
      K2 :
      begin
        K_ADDR1 = K_RD_ADDR0;
      end
      K3 :
      begin
        K_ADDR1 = cnt_c_ddd + {cnt_b_dddd,1'b0};
      end
      x_curr1 :
      begin
        K_ADDR1 = {cnt_a,1'd0} + cnt_b;
      end
      P0 :
      begin
        K_ADDR1 = {cnt_a,1'd0} + cnt_b;
      end
      default:
      begin
        K_ADDR1 = 0;
      end
    endcase
  end
  wire [DATA_W-1:0]Q_ram_out0;
  pmi_ram_dq
    #(
      .pmi_addr_depth       (MAX_COL*MAX_COL         ), // integer
      .pmi_addr_width       ($clog2(MAX_COL*MAX_COL) ), // integer
      .pmi_data_width       (DATA_W            ), // integer
      .pmi_regmode          ("noreg" ), // "reg"|"noreg"
      .pmi_gsr              ("disable" ), // "enable"|"disable"
      .pmi_resetmode        ("sync" ), // "async"|"sync"
      .pmi_init_file        ( ), // string
      .pmi_init_file_format ( ), // "binary"|"hex"
      .pmi_family           ("common" )  // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
    )pmi_ram_dp_MAX_COLxMAX_COL0 (
      .Data      (Q_ram ),  // I:
      .Address   (K_ADDR1 ),  // I:
      .Clock     (clk ),  // I:
      .ClockEn   ( 1),  // I:
      .WE        (wr_ram&&((STATE == K1)||(STATE == K3) )),  // I:
      .Reset     (rst ),  // I:
      .Q         (Q_ram_out0 )   // O:
    );



  integer i;
  wire cal_finish_LU;
  wire cal_finish_LU_o;
  reg Mar_cal_start;
  wire Mar_cal_finish;
  always@(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      STATE <= INIT;
      Mar_cal_start <='d0;
      COL<='d0;
      ROW0<='d0;
      ROW1<='d0;
      cnt_tra_ma <='d0;
      finsh_o <='d0;
      for (i=0;i<=A_size-1;i=i+1)
      begin
        x_prev[i] <='d0;
        x_prev_buf[i] <= 'd0;
      end
    end
    else
    begin
      case(STATE)
        INIT   :
        begin
          if(start)
          begin
            STATE <= X_PRED;
            Mar_cal_start <='d1;
            COL<='d1;
            ROW0<=A_size;
            ROW1<=A_size;
            finsh_o <='d0;
            for (i=0;i<=A_size-1;i=i+1)
            begin
              x_prev[i] <=data_in[(i)*DATA_W+:DATA_W];
            end

          end
          else
          begin
            STATE <= INIT  ;
            finsh_o<='d0;
            Mar_cal_start <='d0;
            COL<='d0;
            ROW0<='d0;
            ROW1<='d0;
            for (i=0;i<=A_size-1;i=i+1)
            begin
              x_prev[i] <= x_prev[i] ;
            end
          end
        end
        X_PRED :
        begin

          for (i=0;i<=A_size-1;i=i+1)
          begin
            x_prev_buf[i] <=(data_Matrix_mult_v&&(cnt_b_ddd==i))?data_Matrix_mult:x_prev_buf[i] ;
          end
          if(Mar_cal_finish)
          begin
            STATE <= P_PRED0;
            Mar_cal_start <='d1;
            COL<=2;
            ROW0<='d2;
            ROW1<='d2;
          end
          else
          begin
            STATE <= X_PRED;
            Mar_cal_start <='d0;
            COL<=COL;
            ROW0<=ROW0;
            ROW1<=ROW1;
          end
        end
        P_PRED0 :
        begin
          if(Mar_cal_finish)
          begin
            STATE <= P_PRED1   ;
            Mar_cal_start <='d1;
            COL<=2;
            ROW0<='d2;
            ROW1<='d2;
          end
          else
          begin
            STATE <= P_PRED0;
            Mar_cal_start <='d0;
            COL<=COL;
            ROW0<=ROW0;
            ROW1<=ROW1;
          end
        end
        P_PRED1 :
        begin
          if(Mar_cal_finish)
          begin
            STATE <= K0   ;
            Mar_cal_start <='d1;
            COL<=96;
            ROW0<='d2;
            ROW1<='d2;
          end
          else
          begin
            STATE <= P_PRED1;
            Mar_cal_start <='d0;
            COL<=2;
            ROW0<=ROW0;
            ROW1<=ROW1;
          end
        end
        K0      :
        begin
          if(Mar_cal_finish)
          begin
            STATE <= K1     ;
            COL<='d96;
            ROW0<='d2;
            ROW1<='d96;
            Mar_cal_start <='d1;
          end
          else
          begin
            STATE <= K0          ;
            Mar_cal_start <='d0;
            COL<=COL;
            ROW0<=ROW0;
            ROW1<=ROW1;
          end
        end
        K1      :
        begin
          if(Mar_cal_finish)
          begin
            STATE <= TRA_Ma     ;
            COL<='d2;
            ROW0<=ROW0;
            ROW1<=ROW1;
            Mar_cal_start <='d0;
          end
          else
          begin
            STATE <= K1     ;
            COL<=COL;
            ROW0<=ROW0;
            ROW1<=ROW1;
            Mar_cal_start <='d0;
          end
        end
        TRA_Ma  :
        begin
          if(cnt_tra_ma>=max_size - 'd1)
          begin
            STATE <= K2     ;
            COL<='d96;
            ROW0<='d2;
            ROW1<='d2;
            Mar_cal_start <='d1;
            cnt_tra_ma    <='d0;
          end
          else
          begin
            STATE <= TRA_Ma     ;
            COL<=COL;
            ROW0<=ROW0;
            ROW1<=ROW1;
            Mar_cal_start <='d0;
            cnt_tra_ma  <= cnt_tra_ma  +'d1;
          end
        end
        K2      :
        begin
          //if(Mar_cal_finish)
          if(cal_finish_LU)
          begin
            STATE <= K3     ;
            ROW0<='d96;
            ROW1<='d96;
            COL <='d2;
            Mar_cal_start <='d1;
            cnt_tra_ma    <='d0;
          end
          else
          begin
            STATE <= K2     ;
            COL<='d96;
            ROW0<='d2;
            ROW1<='d2;
            Mar_cal_start <='d0;
            cnt_tra_ma    <='d0;
          end
        end
        K3      :
        begin
          if(Mar_cal_finish)
          begin
            STATE <= x_curr0     ;
            ROW0<='d2 ;
            ROW1<='d2 ;
            COL <= 'd96;
            Mar_cal_start <='d1;
            cnt_tra_ma    <='d0;
          end
          else
          begin
            STATE <= K3     ;
            ROW0<= 'd96;
            ROW1<='d96;
            COL <='d2;
            Mar_cal_start <='d0;
            cnt_tra_ma    <='d0;
          end
        end
        x_curr0      :
        begin
          if(Mar_cal_finish)
          begin
            STATE <= x_curr1     ;
            ROW0<= 'd96;
            ROW1<='d2;
            COL <='d1;
            Mar_cal_start <='d1;
          end
          else
          begin
            STATE <= x_curr0     ;
            ROW0<= 'd2;
            ROW1<='d96;
            COL <='d1;
            Mar_cal_start <='d0;
          end
        end


        x_curr1 :
        begin
          if(Mar_cal_finish)
          begin
            STATE <= P0     ;
            ROW0<= 'd96;
            ROW1<='d2;
            COL <='d2;
            Mar_cal_start <='d1;
          end
          else
          begin
            STATE <= x_curr1     ;
            ROW0<= 'd96;
            ROW1<='d2;
            COL <='d1;
            Mar_cal_start <='d0;
          end
        end
        P0:
        begin
          if(Mar_cal_finish)
          begin
            STATE <= P1     ;
            ROW0<= 'd2;
            ROW1<='d2;
            COL <='d2;
            Mar_cal_start <='d1;
          end
          else
          begin
            STATE <= P0     ;
            ROW0<= 'd96;
            ROW1<='d2;
            COL <='d2;
            Mar_cal_start <='d0;
          end
        end
        P1:
        begin
          if(Mar_cal_finish)
          begin
            STATE <= FINISH     ;
            ROW0<= 'd2;
            ROW1<='d2;
            COL <='d2;
            Mar_cal_start <='d0;
          end
          else
          begin
            STATE <= P1     ;
            ROW0<= 'd2      ;
            ROW1<='d2       ;
            COL <='d2       ;
            Mar_cal_start <='d0;
          end
        end
        FINISH:
        begin
          STATE <= INIT     ;
          ROW0<= 'd2;
          ROW1<='d2;
          COL <='d2;
          Mar_cal_start <='d0;
          finsh_o <='d1;
        end
      endcase
    end
  end



  always@(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      cnt_a_d<='d0;
      cnt_a_dd <='d0;
      cnt_a_ddd<='d0;
      cnt_b_d<='d0;
      cnt_b_dd <='d0;
      cnt_b_ddd<='d0;
      cnt_c_d<='d0;
      cnt_c_dd <='d0;
      cnt_c_ddd<='d0;


    end
    else
    begin
      cnt_a_d<=#1 cnt_a;
      cnt_a_dd <=#1 cnt_a_d;
      cnt_a_ddd <=#1 cnt_a_dd;
      cnt_b_d<=#1 cnt_b;
      cnt_b_dd <=#1 cnt_b_d;
      cnt_b_ddd <=#1 cnt_b_dd;
      cnt_b_dddd <=#1 cnt_b_ddd;
      cnt_c_d<=#1 cnt_c;
      cnt_c_dd <=#1 cnt_c_d;
      cnt_c_ddd <=#1 cnt_c_dd;

    end
  end

  assign K_RD_ADDR = cnt_a + {cnt_b[$clog2(MAX_ROW)-1  :0],1'b0};
  assign K_Q1_ADDR = cnt_a_d + {cnt_c_ddd[$clog2(MAX_ROW)-1  :0],1'b0};





  Matrix_mult
    #(.MAX_COL  (MAX_COL),
      .MAX_ROW0 (MAX_ROW),
      .MAX_ROW1 (MAX_ROW),
      .DATA_W  (DATA_W),
      .Q       (16)

     )Matrix_mult_inst
    (
      .clk_i             (clk),
      .rst_i             (rst),
      .start_i           (Mar_cal_start),
      .COL               (COL),
      .ROW0              (ROW0),
      .ROW1              (ROW1),
      .cal_finish_o      (Mar_cal_finish),
      .cnt_a             (cnt_a),
      .cnt_b             (cnt_b),
      .cnt_c             (cnt_c),
      .dataA             (dataA),
      .dataB             (dataB),
      .data_o_v          (data_Matrix_mult_v),
      .data_o            (data_Matrix_mult)
    );
  reg [$clog2(MAX_COL*MAX_ROW):0]data_out_cnt;
  /////////////////////TEST_ROM
  /*INV_DATA*/
  //wire  [DATA_W-1:0]INV_TEST_DATA;
  //wire  [$clog2(MAX_COL*MAX_COL)  :0]Address_rd;
  reg  [$clog2(MAX_COL*MAX_COL)  :0]cnt_addr_wr;

  always@(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      cnt_addr_wr <='d0;
    end
    else
    begin
      if(data_o_v)
      begin
        if(cnt_addr_wr >= MAX_ROW*MAX_ROW - 'd1)
        begin
          cnt_addr_wr <= 'd0;
        end
        else
        begin
          cnt_addr_wr <=cnt_addr_wr + 'd1;
        end
      end
      else
      begin
        cnt_addr_wr <=cnt_addr_wr;
      end
    end
  end
  wire [DATA_W-1:0]wrbe_luinv_data;
  pmi_ram_dq
    #(
      .pmi_addr_depth       (MAX_COL*MAX_COL         ), // integer
      .pmi_addr_width       ($clog2(MAX_COL*MAX_COL) ), // integer
      .pmi_data_width       (DATA_W            ), // integer
      .pmi_regmode          ("noreg" ), // "reg"|"noreg"
      .pmi_gsr              ("disable" ), // "enable"|"disable"
      .pmi_resetmode        ("async"  ), // "async"|"sync"
      .pmi_init_file        ("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/K_Q00_vector.hex" ), // string
      .pmi_init_file_format ("hex"), // "binary"|"hex"
      .pmi_family           ("common" )  // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
    )pmi_ram_dp_be_luinv (
      .Data      (wrbe_luinv_data ),  // I:
      .Address   (Address_rd ),  // I:
      .Clock     (clk ),  // I:
      .ClockEn   ( 1),  // I:
      .WE        (data_o_v ),  // I:
      .Reset     (rst ),  // I:
      .Q         (INV_TEST_DATA )   // O:
    );


  // pmi_rom
  // #(
  //   .pmi_addr_depth       (MAX_COL*MAX_COL ), // integer
  //   .pmi_addr_width       ($clog2(MAX_COL*MAX_COL) ), // integer
  //   .pmi_data_width       (DATA_W ), // integer
  //   .pmi_regmode          ("noreg" ), // "reg"|"noreg"
  //   .pmi_resetmode        ("async"  ), // "async"|"sync"
  //   .pmi_init_file        ("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/K_Q00_vector.hex" ), // string
  //   .pmi_init_file_format ("hex" ), // "binary"|"hex"
  //   .pmi_family           ("common" )  // "common"
  // ) pmi_rom_TEST_INV(
  //   .Address    (Address_rd ),  // I:
  //   .OutClock   (clk ),  // I:
  //   .OutClockEn (1   ),  // I:
  //   .Reset      (rst ),  // I:
  //   .Q          (INV_TEST_DATA )   // O:
  // );

  wire  [$clog2(MAX_COL*MAX_COL)  :0]cnt_b_addr;
  assign cnt_b_addr = MAX_COL*cnt_b;

  assign Address_rd =data_o_v? cnt_addr_wr:cnt_a + cnt_b_addr;

  ///////////////////
  always@(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      dataA<= 'd0;
      dataB<= 'd0;
      wr_ram <='d0;
      Q_ram  <='d0;
      P[0][0] <= 'd32767;
      P[0][1] <= 0;
      P[1][0] <= 0;
      P[1][1] <= 'd32767;

      P_buf[0][0] <= 0;
      P_buf[0][1] <= 0;
      P_buf[1][0] <= 0;
      P_buf[1][1] <= 0;



    end
    else
    begin
      case(STATE)
        INIT   :
        begin
          dataA<= 'd0;
          dataB<= 'd0;
          wr_ram <='d0;
          Q_ram  <='d0;
          P[0][0] <=P[0][0];
          P[0][1] <=P[0][1];
          P[1][0] <=P[1][0];
          P[1][1] <=P[1][1];
          P_buf[0][0] <= P_buf[0][0];
          P_buf[0][1] <= P_buf[0][1];
          P_buf[1][0] <= P_buf[1][0];
          P_buf[1][1] <= P_buf[1][1];
        end
        X_PRED :
        begin
          wr_ram <='d0;
          Q_ram  <='d0;
          dataA<= x_prev[cnt_a];
          dataB<= A[cnt_b][cnt_a];
        end
        P_PRED0:
        begin
          wr_ram <='d0;
          Q_ram  <='d0;
          dataA<= A[cnt_c][cnt_a];
          dataB<= P[cnt_a][cnt_b];
          if(data_Matrix_mult_v)
          begin
            P_pred_Q0[cnt_c_ddd][cnt_b_ddd]<=data_Matrix_mult;
          end
        end
        P_PRED1:
        begin
          wr_ram <='d0;
          Q_ram  <='d0;
          dataA<= P_pred_Q0[cnt_c][cnt_a];
          dataB<= A_N[cnt_a][cnt_b];
          if(data_Matrix_mult_v)
          begin
            P_pred_Q1[cnt_c_ddd][cnt_b_ddd]<=data_Matrix_mult + Qa[cnt_c_ddd][cnt_b_ddd];
          end
        end
        K0     :
        begin
          wr_ram <=data_Matrix_mult_v;
          Q_ram  <=data_Matrix_mult;
          K_Q0_ADDR <= {cnt_c_ddd[$clog2(MAX_ROW)-1  :0],1'b0} + cnt_b_ddd ;
          dataA<= C;
          dataB<= P_pred_Q1[cnt_a_d][cnt_b_d];
        end
        K1     :
        begin
          wr_ram <=data_Matrix_mult_v;
          Q_ram  <=data_Matrix_mult;
          dataA<= Q_ram_out;
          dataB<= C_N;
        end
        K2     :
        begin
          wr_ram <=data_Matrix_mult_v;
          Q_ram  <=data_Matrix_mult;
          dataA<= P_pred_Q1[cnt_a_d][cnt_b_d];
          dataB<= C_N;
        end
        K3     :
        begin
          wr_ram <=data_Matrix_mult_v;
          Q_ram  <=data_Matrix_mult;
          dataA<= K_Q1_OUT;//P_pred_Q1[cnt_a_d][cnt_b_d];
          dataB<= INV_TEST_DATA;
        end
        x_curr0     :
        begin
          wr_ram <=data_Matrix_mult_v;
          Q_ram  <=Z_in - data_Matrix_mult;
          dataA<= x_prev_buf[cnt_a_d];//P_pred_Q1[cnt_a_d][cnt_b_d];
          dataB<= C;
        end
        x_curr1 :
        begin
          wr_ram <=data_Matrix_mult_v;
          Q_ram  <=x_prev_buf[cnt_b_dddd] + data_Matrix_mult;
          dataA<= K_Q1_OUT  ;//P_pred_Q1[cnt_a_d][cnt_b_d];
          dataB<= Q_ram_out0;
        end
        P0:
        begin
          wr_ram <=data_Matrix_mult_v;
          Q_ram  <=(cnt_b_dddd == cnt_c_ddd)? ('d32767)-data_Matrix_mult:-data_Matrix_mult;
          dataA<= Q_ram_out0  ;//P_pred_Q1[cnt_a_d][cnt_b_d];
          dataB<= C;
          if(wr_ram)
          begin
            P[cnt_b_dddd][cnt_c_ddd] <= Q_ram;
          end
        end
        P1 :
        begin
          wr_ram <=data_Matrix_mult_v;
          Q_ram  <=data_Matrix_mult;
          dataA<=         P[cnt_c_d][cnt_a_d] ;
          dataB<= P_pred_Q1[cnt_b_d][cnt_a_d];
          if(wr_ram)
          begin
            P_buf[cnt_b_dddd][cnt_c_ddd] <= Q_ram;
          end
        end
        FINISH:
        begin
          wr_ram <=0;
          Q_ram  <=0;

          P[0][0] <=P_buf[0][0];
          P[0][1] <=P_buf[0][1];
          P[1][0] <=P_buf[1][0];
          P[1][1] <=P_buf[1][1];
          P_buf[0][0] <= P_buf[0][0];
          P_buf[0][1] <= P_buf[0][1];
          P_buf[1][0] <= P_buf[1][0];
          P_buf[1][1] <= P_buf[1][1];



        end


      endcase
    end
  end


  /**/
  wire Ma_tr;
  reg Ma_tr_d,Ma_tr_dd;
  assign Ma_tr = (STATE == TRA_Ma)?'d1:'d0;
  reg [DATA_W-1:0]Ma_data_tra;
  reg [$clog2(MAX_ROW) :0]cnt_row;
  reg wr_ram_v;
  wire [DATA_W-1:0]K_Q_add;
  wire [DATA_W-1:0]R_Q;
  assign K_Q_add = Q_ram_out0 + R_Q;
  always@(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      Ma_data_tra <='d0;
      Ma_tr_d     <='d0;
      Ma_tr_dd    <='d0;
      cnt_row     <='d0;
      wr_ram_v    <='d0;
    end
    else
    begin
      Ma_tr_d     <=Ma_tr  ;
      Ma_tr_dd    <=Ma_tr_d;
      if(Ma_tr_d)
      begin
        Ma_data_tra <= K_Q_add;//{K_Q_add,Ma_data_tra[(MAX_ROW)*DATA_W-1:DATA_W]};
        cnt_row     <= (cnt_row>=MAX_ROW - 'd1)? 0:cnt_row+'d1;
        wr_ram_v    <= 1;
      end
      else
      begin
        Ma_data_tra <='d0;
        cnt_row     <='d0;
        wr_ram_v    <='d0;
      end
    end
  end
  wire start_LU;
  assign start_LU = Ma_tr_dd&&~Ma_tr_d;
  reg [$clog2(MAX_ROW*MAX_ROW) :0]LUcal_addr;
  always@(posedge clk or posedge rst)
  begin
    if(rst)
    begin
      LUcal_addr <='d0;
      cal_data_o_v<='d0;
      cal_data_o  <='d0;

    end
    else
    begin
      cal_data_o_v<=wr_ram&&(STATE==x_curr1);
      cal_data_o  <=Q_ram;


      if(Ma_tr_d)
      begin
        LUcal_addr <=wr_ram_v?LUcal_addr+'d1:LUcal_addr;
      end
      else
      begin
        LUcal_addr <='d0;
      end
    end
  end

  pmi_rom
    #(
      .pmi_addr_depth       (MAX_COL*MAX_ROW ), // integer
      .pmi_addr_width       ($clog2(MAX_COL*MAX_ROW) ), // integer
      .pmi_data_width       (DATA_W ), // integer
      .pmi_regmode          ("noreg" ), // "reg"|"noreg"
      .pmi_resetmode        ("async"  ), // "async"|"sync"
      .pmi_init_file        ("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/R_Q.hex"), // string
      .pmi_init_file_format ("hex" ), // "binary"|"hex"
      .pmi_family           ("common" )  // "common"
    ) pmi_rom_R_Q(
      .Address    (cnt_tra_ma ),  // I:
      .OutClock   (clk ),  // I:
      .OutClockEn (1   ),  // I:
      .Reset      (rst ),  // I:
      .Q          (R_Q )   // O:
    );
  localparam WIDTH_LU = 64;
  localparam Q_LU     = 24;
  wire [$clog2(MAX_ROW*MAX_ROW)-1:0]WrAddress_a;
  wire wr_A_ram;
  wire [WIDTH_LU - 1:0] Data_a;
  assign WrAddress_a = LUcal_addr;
  assign wr_A_ram    = wr_ram_v;
  assign Data_a      = {{(WIDTH_LU-DATA_W){Ma_data_tra[DATA_W - 1]}},Ma_data_tra,{(Q_LU-Q){1'b0}}};



  LDL_TOP #(
            .N    (MAX_ROW),              // 矩阵大小
            .Q    (Q_LU),             // 定点小数位
            .WIDTH(WIDTH_LU)         // 数据宽度
          )LDL_TOP_inst(
            .clk                 (clk),
            .rst_n               (~(rst||finsh_o)),
            .start               (start_LU),
            .done                (cal_finish_LU_o),
            .WrAddress_a (WrAddress_a),
            .wr_A_ram    (wr_A_ram),
            .Data_a      (Data_a),
            .data_Matrix_mult_o  (data_o),
            .data_Matrix_mult_v_o(data_o_v)
          );
  assign cal_finish_LU =cal_finish_LU_o;
  assign wrbe_luinv_data = data_o[DATA_W+'d10:10];

endmodule
