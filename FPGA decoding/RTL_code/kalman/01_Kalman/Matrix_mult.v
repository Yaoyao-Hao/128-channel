`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/07/04 15:22:09
// Design Name:
// Module Name: Matrix_mult
// Project Name:
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////


module Matrix_mult
  #(parameter MAX_COL = 4,
    parameter MAX_ROW0 = 4,
    parameter MAX_ROW1 = 4,
    parameter DATA_W= 16,
    parameter Q = 16,
    parameter ram_data = 1//1表示数据来自ram，0表示数据来自寄存器

   )
   (
     input clk_i                          ,
     input rst_i                          ,
     input start_i                        ,
     input [$clog2(MAX_COL):0]COL         ,
     input [$clog2(MAX_ROW0):0]ROW0         ,
     input [$clog2(MAX_ROW1):0]ROW1         ,
     output reg cal_finish_o              ,
     output reg [$clog2(MAX_ROW0)  :0]cnt_a,
     output reg [$clog2(MAX_ROW1)  :0]cnt_b,
     output reg [$clog2(MAX_COL)   :0]cnt_c,
     input wire [DATA_W-1:0]dataA         ,
     input wire [DATA_W-1:0]dataB         ,
     output wire data_o_v,
     output [DATA_W-1:0] data_o

   );


//   reg [$clog2(ROW)  :0]cnt_a;
//   reg [$clog2(ROW)  :0]cnt_b;
//   reg [$clog2(COL)  :0]cnt_c;

  //reg [DATA_W*2+$clog2(MAX_ROW)-1:0]data_add,data_add_d;
  reg [DATA_W*2-1:0]data_add,data_add_d;
  wire [DATA_W*2-1:0]P;
reg cal_finish;
  reg [3:0]STATE;
  localparam INIT = 0 ,
             CNT_0 = 1,
             CNT_1 = 2,
             CNT_2 = 3,
             FINISH= 4;
  reg add_v;
  always@(posedge clk_i or posedge rst_i)
  begin
    if(rst_i)
    begin
      STATE <= INIT;
      cnt_a <= 'd0;
      cnt_b <= 'd0;
      cnt_c <= 'd0;
      add_v <= 'd0;
      cal_finish <='d0;
    end
    else
    begin
      case(STATE)
        INIT  :
        begin
          add_v <= 'd0;  
          cal_finish <='d0;
          if(start_i)
          begin
            STATE <= CNT_0;
          end
          else
          begin
            STATE <= INIT;
          end
        end
        CNT_0 :
        begin
            cal_finish <='d0;
          if(cnt_a<ROW0-'d1) begin cnt_a <= cnt_a + 'd1;  STATE<=CNT_0; add_v <= 'd1;    end
          else           begin cnt_a <= 'd0;             STATE<=CNT_1; add_v <= 'd1;    end
        end
        CNT_1 :
        begin
            add_v <= 'd0;  
            cal_finish <='d0;
          if(cnt_b<ROW1-'d1) begin cnt_b <= cnt_b + 'd1;  STATE<=CNT_0;  end
          else           begin cnt_b <= 'd0;             STATE<=CNT_2;  end
        end
        CNT_2 :
        begin
            add_v <= 'd0;  
            cal_finish <='d0;
          if(cnt_c<COL-'d1) begin cnt_c<= cnt_c + 'd1;   STATE<=CNT_0;  end
          else           begin cnt_c <= 'd0;             STATE<=FINISH; end
        end
        FINISH:
        begin
          STATE<=INIT;
          cal_finish <='d1;
          cnt_a <= 'd0;
          cnt_b <= 'd0;
          cnt_c <= 'd0;
        end
      endcase
    end
  end
  reg add_v_d,add_v_dd,add_v_ddd;
  always@(posedge clk_i or posedge rst_i) 
  begin
    if(rst_i) begin 
        data_add <='d0;
    end
    else      begin 
       if(add_v_dd) begin
          data_add <=  data_add + P ;
        end
       else      begin
          data_add <= 'd0;
        end
    end
  end

 always@(posedge clk_i or posedge rst_i) 
  begin
    if(rst_i) begin 
        add_v_d <='d0;
        add_v_dd<='d0;
        add_v_ddd<='d0;
        data_add_d<='d0;
        cal_finish_o <='d0;
    end
    else      begin 
        add_v_d <=#1 add_v;
        add_v_dd<=#1 add_v_d;
        add_v_ddd<=#1 add_v_dd;
        data_add_d <= data_add;
        cal_finish_o <=cal_finish;
    end
  end
  
  assign data_o_v = ~add_v_dd&&add_v_ddd;
  assign data_o   = data_add[Q+DATA_W-1:Q -1];
  pmi_mult
  #(
    .pmi_dataa_width         (DATA_W), // integer
    .pmi_datab_width         (DATA_W ), // integer
    .pmi_sign                ("on" ), // "on"|"off"
    .pmi_additional_pipeline (0 ), // integer
    .pmi_input_reg           ( "on" ), // "on"|"off"
    .pmi_output_reg          ( "off"), // "on"|"off"
    .pmi_family              ("common"  ), // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common" 
    .pmi_implementation      ("DSP" )  // "DSP"|"LUT"
  ) pmi_mult_dsp (
    .DataA  (dataA ),  // I:
    .DataB  (dataB ),  // I:
    .Clock  (clk_i ),  // I:
    .ClkEn  (1 ),  // I:
    .Aclr   (rst_i ),  // I:
    .Result (P )   // O:
  );

endmodule
