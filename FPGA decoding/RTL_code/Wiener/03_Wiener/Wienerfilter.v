`timescale 1ns / 1ps
module Wienerfilter#(
    parameter WIDTH    = 16,
    parameter COL_NUM  = 128, 
    parameter ROW_NUM  = 2,
    localparam ADDR_DEP  =  COL_NUM * ROW_NUM,
    localparam ADDR_WID  =  $clog2(ADDR_DEP) + 'd1,
    localparam Serial_COL  =  $clog2(COL_NUM) + 'd1,
    localparam Serial_ROW  =  $clog2(ROW_NUM) + 'd1
)
(
input clk,
input rst,
input start,
input [ADDR_WID-1:0]wr_addr,
input ram_wr_en,
input [WIDTH-1:0]ram_data_in,
input  wire[7:0]rd_wiener,
input [1:0]rd_bank,
input      rd_para,
input [Serial_COL-1:0]wr_data_addr,
input ram_wr_data_en,
input [WIDTH-1:0]ram_data_wr_in,
output [WIDTH*2-1:0]DSP_ADD_DATA_o,
output reg[WIDTH*4-1:0]Wiener_data,
output reg Wiener_data_v,
output finish_cal_o,
output wire [WIDTH/2-1:0]ram_data_out_o,
output data_wr_v_o

) ;

localparam INIT      = 0,
           START     = 1, 
           READ_DATA = 2,
           WAIT_READ = 3,
           MULT_CAL  = 4,
           WAIT_CAL  = 5,
           ADD_CAL   = 6,
           DET       = 7, 
           FINISH    = 8;

reg [6:0]STATE;
reg [Serial_COL - 1:0 ]COL_cnt;
reg [Serial_ROW - 1:0 ]ROW_cnt;

reg [ADDR_WID-1:0]rd_ad_para = 0;


reg [ADDR_WID-1:0]rd_addr;
always@(*) begin 
  rd_ad_para = rd_para? {rd_bank,rd_wiener[5:0]}:rd_addr;
end
// reg ram_wr_en;
// reg [WIDTH-1:0]ram_data_in;
wire [WIDTH/2-1:0]ram_data_out;
assign ram_data_out_o=ram_data_out;
wire [WIDTH-1:0]ram_data_data_out;

pmi_ram_dp
#(
  .pmi_wr_addr_depth    (ADDR_DEP ), // integer
  .pmi_wr_addr_width    (ADDR_WID ), // integer
  .pmi_wr_data_width    (WIDTH/2 ), // integer
  .pmi_rd_addr_depth    (ADDR_DEP ), // integer
  .pmi_rd_addr_width    (ADDR_WID ), // integer
  .pmi_rd_data_width    (WIDTH/2 ), // integer
  .pmi_regmode          ( "reg" ), // "reg"|"noreg"
  .pmi_resetmode        ("async" ), // "async"|"sync"
  .pmi_init_file        (),//("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/W_q.hex" ), // string
  .pmi_init_file_format ("hex" ), // "binary"|"hex"
  .pmi_family           ("common" )  // "iCE40UP"|"common"
) pmi_ram_dp_inst (
  .Data      (ram_data_in ),  // I:
  .WrAddress (wr_addr ),  // I:
  .RdAddress (rd_ad_para),//rd_addr ),  // I:
  .WrClock   (clk   ),  // I:
  .RdClock   (clk   ),  // I:
  .WrClockEn (1 ),  // I:
  .RdClockEn (1 ),  // I:
  .WE        (ram_wr_en),//||ram_wr[i] ),  // I:
  .Reset     (rst),  // I:
  .Q         (ram_data_out )   // O:
);

pmi_ram_dp
#(
  .pmi_wr_addr_depth    (COL_NUM ), // integer
  .pmi_wr_addr_width    (Serial_COL ), // integer
  .pmi_wr_data_width    (WIDTH ), // integer
  .pmi_rd_addr_depth    (COL_NUM ), // integer
  .pmi_rd_addr_width    (Serial_COL ), // integer
  .pmi_rd_data_width    (WIDTH ), // integer
  .pmi_regmode          ( "reg" ), // "reg"|"noreg"
  .pmi_resetmode        ("async" ), // "async"|"sync"
  .pmi_init_file        ( ), // string
  .pmi_init_file_format ( ), // "binary"|"hex"
  .pmi_family           ("common" )  // "iCE40UP"|"common"
) pmi_ram_dp_inst_data (
  .Data      (ram_data_wr_in ),  // I:
  .WrAddress (wr_data_addr ),  // I:
  .RdAddress (COL_cnt ),  // I:
  .WrClock   (clk   ),  // I:
  .RdClock   (clk   ),  // I:
  .WrClockEn (1 ),  // I:
  .RdClockEn (1 ),  // I:
  .WE        (ram_wr_data_en),//||ram_wr[i] ),  // I:
  .Reset     (rst),  // I:
  .Q         (ram_data_data_out )   // O:
);
reg finish_cal;

reg [WIDTH*2-1:0]DSP_ADD_DATA;
wire [WIDTH*2-1:0]result;
reg start_mult,start_mult_d,start_mult_dd;
reg data_wr_v;
always@(posedge clk or posedge rst) begin 
 if(rst) begin 
    STATE <= INIT;
    ROW_cnt <= 'd0;
    COL_cnt <= 'd0;
    start_mult <= 'd0;
    finish_cal <= 'd0;
    DSP_ADD_DATA <= 'd0;
    data_wr_v <='d0;
 end
 else begin 
   case(STATE) 
   INIT      :begin
    ROW_cnt <= 'd0;
    COL_cnt <= 'd0;  
    start_mult <= 'd0;
    finish_cal <= 'd0;
    DSP_ADD_DATA <= 'd0;
    data_wr_v <='d0;
    if(start) begin
        STATE <= START;
     end
    else      begin
        STATE <= INIT;
     end
        end
   START     :begin  
       STATE <= READ_DATA;
       start_mult <= 'd0;
       DSP_ADD_DATA <= DSP_ADD_DATA;
       data_wr_v <='d0;
        end
   READ_DATA :begin  
       STATE <= WAIT_READ;
       start_mult <= 'd0;
        end
   WAIT_READ :begin  
       STATE <= MULT_CAL;  
       start_mult <= 'd1;
        end
   MULT_CAL  :begin  
    STATE <= WAIT_CAL;  
    start_mult <= 'd0;
        end
   WAIT_CAL  :begin  
      if(start_mult_dd) begin STATE <= ADD_CAL;  end
      else begin STATE <= WAIT_CAL;  end
        end
   ADD_CAL :begin 
     if(COL_cnt <  COL_NUM - 'd1) begin
        COL_cnt <= COL_cnt + 'd1;
        STATE   <= START;
        data_wr_v <='d0;
        DSP_ADD_DATA <= DSP_ADD_DATA + result;
      end
     else begin
        COL_cnt <= 0;
        STATE   <= DET;
        data_wr_v <='d1;
        DSP_ADD_DATA <= DSP_ADD_DATA+ result;
      end 
   end    
   DET       :begin  
     DSP_ADD_DATA <= 'd0;
     data_wr_v <='d0;
     if(ROW_cnt <  ROW_NUM - 'd1) begin
        ROW_cnt <= ROW_cnt + 'd1;
        STATE   <= START;
        finish_cal <= 'd0;
      end
     else begin 
        ROW_cnt <= 'd0;
        STATE   <= FINISH;
        finish_cal <= 'd1;
     end
        end
   FINISH    :begin  
    data_wr_v <='d0;
    DSP_ADD_DATA <= 'd0;
    finish_cal <= 'd0;
    STATE   <= INIT;
        end
   endcase
 end
end
assign finish_cal_o = finish_cal;
assign DSP_ADD_DATA_o = DSP_ADD_DATA;

always@(posedge clk or posedge rst) begin 
    if(rst) begin 
        start_mult_d<= 'd0;
        start_mult_dd<= 'd0;
    end
    else begin 
        start_mult_d <=#1 start_mult;
        start_mult_dd<=#1 start_mult_d;
    end
   end
   always@(*) begin 
case(ROW_cnt) 
  'd0: rd_addr =  COL_cnt  ;
  'd1: rd_addr =  COL_NUM + COL_cnt ;
  'd2: rd_addr = {COL_NUM,1'd0 } + COL_cnt ;
  'd3: rd_addr = {COL_NUM,1'd0 } + COL_cnt + COL_NUM ;

endcase
   end


wire [WIDTH-1:0]data_in0,data_in1;
assign data_in0 = {{8{ram_data_out[WIDTH/2-1]}},ram_data_out};
 assign data_in1 = ram_data_data_out;
   pmi_mult
   #(
     .pmi_dataa_width         (WIDTH), // integer
     .pmi_datab_width         (WIDTH ), // integer
     .pmi_sign                ("on" ), // "on"|"off"
     .pmi_additional_pipeline (1 ), // integer
     .pmi_input_reg           ( "on" ), // "on"|"off"
     .pmi_output_reg          ( "on" ), // "on"|"off"
     .pmi_family              ("common"  ), // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common" 
     .pmi_implementation      ("DSP" )  // "DSP"|"LUT"
   ) pmi_mult_dsp (
     .DataA  (data_in0 ),  // I:
     .DataB  (data_in1 ),  // I:
     .Clock  (clk ),  // I:
     .ClkEn  (1 ),  // I:
     .Aclr   (rst ),  // I:
     .Result (result )   // O:
   );
assign data_wr_v_o = data_wr_v;

always@(posedge clk or posedge rst)
 begin 
   if(rst) begin 
    Wiener_data  <='d0;
    Wiener_data_v<='d0;
   end
   else begin
case(ROW_cnt)
 'd0:begin if(data_wr_v) begin Wiener_data[WIDTH*1-1:WIDTH*0] <= DSP_ADD_DATA[15:0];  Wiener_data_v<='d0; end else begin Wiener_data <= Wiener_data; Wiener_data_v<='d0; end end
 'd1:begin if(data_wr_v) begin Wiener_data[WIDTH*2-1:WIDTH*1] <= DSP_ADD_DATA[15:0];  Wiener_data_v<='d0; end else begin Wiener_data <= Wiener_data; Wiener_data_v<='d0; end end
 'd2:begin if(data_wr_v) begin Wiener_data[WIDTH*3-1:WIDTH*2] <= DSP_ADD_DATA[23:8];  Wiener_data_v<='d0; end else begin Wiener_data <= Wiener_data; Wiener_data_v<='d0; end end
 'd3:begin if(data_wr_v) begin Wiener_data[WIDTH*4-1:WIDTH*3] <= DSP_ADD_DATA[23:8];  Wiener_data_v<='d1; end else begin Wiener_data <= Wiener_data; Wiener_data_v<='d0; end end
endcase 
    end
 end



endmodule