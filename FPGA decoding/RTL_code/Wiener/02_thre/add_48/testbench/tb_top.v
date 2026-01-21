// =============================================================================
// >>>>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
// -----------------------------------------------------------------------------
//   Copyright (c) 2018 by Lattice Semiconductor Corporation
//   ALL RIGHTS RESERVED
// --------------------------------------------------------------------
//
//   Permission:
//
//      Lattice SG Pte. Ltd. grants permission to use this code
//      pursuant to the terms of the Lattice Reference Design License Agreement.
//
//
//   Disclaimer:
//
//      This VHDL or Verilog source code is intended as a design reference
//      which illustrates how these types of functions can be implemented.
//      It is the user's responsibility to verify their design for
//      consistency and functionality through the use of formal
//      verification methods.  Lattice provides no warranty
//      regarding the use or functionality of this code.
//
// -----------------------------------------------------------------------------
//
//                  Lattice SG Pte. Ltd.
//                  101 Thomson Road, United Square #07-02
//                  Singapore 307591
//
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                       +65-6631-2000 (Singapore)
//                       +1-503-268-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
// -----------------------------------------------------------------------------
//
// =============================================================================
//                         FILE DETAILS
// Project               :
// File                  : tb_top.v
// Title                 : Testbench for Adder - Subtractor.
// Dependencies          : 1.
//                       : 2.
// Description           :
// =============================================================================
//                        REVISION HISTORY
// Version               : 1.0
// Author(s)             :
// Mod. Date             : 
// Changes Made          : Initial version of testbench for Adder - Subtractor.
//                       : 
// =============================================================================

`ifndef TB_TOP
`define TB_TOP

//==========================================================================
// Module : tb_top
//==========================================================================

`timescale 1ns/1ps

module tb_top();

`include "dut_params.v"

// -----------------------------------------------------------------------------
// ----- Parameter -----
// -----------------------------------------------------------------------------
parameter [ 0:0]  PIPE_4BIT = 1'b0;

// -----------------------------------------------------------------------------
// ----- TB Limited Configurations -----
// -----------------------------------------------------------------------------
localparam integer SYS_CLK_PERIOD = (FAMILY == "iCE40UP") ? 40 : 10;
localparam integer I_WDT = (D_WIDTH < 1) ? 1 : D_WIDTH;
localparam integer MAX_PIPES = ((I_WDT - 1) >> (3 - PIPE_4BIT));
localparam integer PIPES = (PIPELINES > MAX_PIPES) ? MAX_PIPES :
                                                     PIPELINES ;
localparam integer MULT_STAGES = (USE_OREG + PIPES);
localparam [I_WDT-1:0] I_VAL_0 = {I_WDT{1'b0}};

initial
begin
// -----------------------------------------------------------------------------
// ----- Test/Scenario Print -----
// -----------------------------------------------------------------------------
  $display();
  $display("---------------------------------------");
  $display("----- Test/Scenario Configuration -----");
  $display("---------------------------------------");
  $display(                                         );
  $display("Input Width            : %d", D_WIDTH   );
  $display("Input Signed           : %s", SIGNED   );
  $display("Use Complex Numbers    : %d", USE_CNUM  );
  $display("Use Carry-In           : %d", USE_CIN   );
  $display("Use Carry-Out          : %d", USE_COUT  );
  $display("O Registered           : %d", USE_OREG  );
  $display("Pipelines              : %d", PIPELINES );
  $display("Pipelines Valid        : %d", PIPES     );
  $display("Pipeline 4-bit         : %d", PIPE_4BIT );
  $display("Device Family          : %s", FAMILY    );
  $display("---------------------------------------");
end

// -----------------------------------------------------------------------------
// Clock Generator
// -----------------------------------------------------------------------------
reg clk_i;
reg rst_n;
reg clk_en_i;

initial begin
  clk_i     = 0;
  clk_en_i  = 1;
end

always #(SYS_CLK_PERIOD/2) clk_i = ~clk_i;

// -----------------------------------------------------------------------------
// Reset Signals
// -----------------------------------------------------------------------------
initial begin
  rst_n   = 0;
  #(10*SYS_CLK_PERIOD)
  rst_n   = 1;
end

// -----------------------------------------------------------------------------
// ----- Monitor & Scoreboard -----
// -----------------------------------------------------------------------------
reg             add_sub_i   ;
reg [I_WDT-1:0] data_a_re_i ;
reg [I_WDT-1:0] data_a_im_i ;
reg [I_WDT-1:0] data_b_re_i ;
reg [I_WDT-1:0] data_b_im_i ;
reg             cin_re_i    ;
reg             cin_im_i    ;

wire [I_WDT-1:0] result_re_o ;
wire [I_WDT-1:0] result_im_o ;

wire [I_WDT-1:0] tb_result_Re;
wire [I_WDT-1:0] tb_result_Im;
wire             cout_re_o   ;
wire             cout_im_o   ;
wire             tb_Co_Re    ;
wire             tb_Co_Im    ;
wire             rst_i = ~rst_n;
 
wire cnum_en    = USE_CNUM        ;
wire cout_en    = USE_COUT        ;
wire sign_en    = (SIGNED == "on") ? 1'b1: 0;

reg  test_done               ;
reg  test_sts                ;
reg [10:0]test_count         ;
reg   vld_sts [MULT_STAGES:0];
wire  opr_sts = (vld_sts[0] |
                ((tb_result_Re === result_re_o) &
                 ((tb_result_Im === result_im_o) | (cnum_en === 0)) &
                 ((tb_Co_Re  === cout_re_o )     | (cout_en === 0)) &
                 ((tb_Co_Im   === cout_im_o)     | (cnum_en ===0) | (cout_en === 0))));
                  
always @(posedge clk_i or negedge rst_n)
begin
  if(!rst_n)
  begin
    test_done <= 1'b0;
    test_sts  <= 1'b1;
  end
  else if(!test_done)
  begin
    test_done <= (test_count === 1000);
    test_sts  <= (test_sts & opr_sts);
  end
end

// ----- Input Generation -----
always @ (posedge clk_i or negedge rst_n) begin
 if (!rst_n)begin
  add_sub_i   <= 1'b0;
  data_a_re_i <= {I_WDT{1'b0}};
  data_a_im_i <= {I_WDT{1'b0}};
  data_b_re_i <= {I_WDT{1'b0}};
  data_b_im_i <= {I_WDT{1'b0}};
  cin_re_i    <= {I_WDT{1'b0}};
  cin_im_i    <= {I_WDT{1'b0}};
 end
 else begin
  add_sub_i   <= $urandom_range(1'b0, 1'b1);
  data_a_re_i <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  data_a_im_i <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  data_b_re_i <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  data_b_im_i <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  cin_re_i    <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  cin_im_i    <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
 end
end

// -----------------------------------------------------------------------------
// ----- TB Calculations -----
// -----------------------------------------------------------------------------
wire [I_WDT-1:0]   A_Re =                      data_a_re_i  ;
wire [I_WDT-1:0]   B_Re =                      data_b_re_i  ;
wire [I_WDT-1:0]   A_Im = ({I_WDT{cnum_en}}  & data_a_im_i );
wire [I_WDT-1:0]   B_Im = ({I_WDT{cnum_en}}  & data_b_im_i );
wire             pCi_Im = (USE_CIN & cnum_en & cin_im_i);
wire             pCi_Re = (USE_CIN           & cin_re_i);
wire             mCi_Im = (USE_CIN & cnum_en & cin_im_i);
wire             mCi_Re = (USE_CIN           & cin_re_i);

reg  [I_WDT-1:0] ApB_Re                     ;
reg  [I_WDT-1:0] ApB_Im                     ;
reg              pCo_Re                     ;
reg              pCo_Im                     ;
reg  [I_WDT-1:0] AmB_Re                     ;
reg  [I_WDT-1:0] AmB_Im                     ;
reg              mCo_Re                     ;
reg              mCo_Im                     ;
reg  [I_WDT-1:0] result_Re_r [MULT_STAGES:0];
reg  [I_WDT-1:0] result_Im_r [MULT_STAGES:0];
reg                  Co_Re_r [MULT_STAGES:0];
reg                  Co_Im_r [MULT_STAGES:0];

wire   A_Re_msb =   A_Re[I_WDT-1];
wire   B_Re_msb =   B_Re[I_WDT-1];
wire   A_Im_msb =   A_Im[I_WDT-1];
wire   B_Im_msb =   B_Im[I_WDT-1];
wire ApB_Re_msb = ApB_Re[I_WDT-1];
wire ApB_Im_msb = ApB_Im[I_WDT-1];
wire AmB_Re_msb = AmB_Re[I_WDT-1];
wire AmB_Im_msb = AmB_Im[I_WDT-1];

always @( * )
begin
  if(sign_en == 1'b1)
  begin
    // Addition
    ApB_Re =  {A_Re + B_Re + pCi_Re};
    ApB_Im =  {A_Im + B_Im + pCi_Im};
    pCo_Re = ({A_Re_msb, B_Re_msb} == {2{~ApB_Re_msb}});
    pCo_Im = ({A_Im_msb, B_Im_msb} == {2{~ApB_Im_msb}});

    // Subtraction
    AmB_Re =  {A_Re - B_Re - mCi_Re};
    AmB_Im =  {A_Im - B_Im - mCi_Im};
    mCo_Re = ({A_Re_msb, B_Re_msb} == {~AmB_Re_msb, AmB_Re_msb});
    mCo_Im = ({A_Im_msb, B_Im_msb} == {~AmB_Im_msb, AmB_Im_msb});
  end
  else
  begin
    // Addition
    {pCo_Re, ApB_Re} = (A_Re + B_Re + pCi_Re);
    {pCo_Im, ApB_Im} = (A_Im + B_Im + pCi_Im);

    // Subtraction
    {mCo_Re, AmB_Re} = (A_Re - B_Re - mCi_Re);
    {mCo_Im, AmB_Im} = (A_Im - B_Im - mCi_Im);
  end
end

wire pCo_Re_c = (cout_en &              pCo_Re );
wire pCo_Im_c = (cout_en &              pCo_Im );
wire mCo_Re_c = (cout_en & (~sign_en ^ mCo_Re));
wire mCo_Im_c = (cout_en & (~sign_en ^ mCo_Im));

wire [I_WDT-1:0] result_Re_c = add_sub_i ? ApB_Re   : AmB_Re  ;
wire [I_WDT-1:0] result_Im_c = add_sub_i ? ApB_Im   : AmB_Im  ;
wire                 Co_Re_c = add_sub_i ? pCo_Re_c : (sign_en ^ (~mCo_Re_c));
wire                 Co_Im_c = add_sub_i ? pCo_Im_c : (sign_en ^ (~mCo_Im_c));

generate
if(MULT_STAGES > 1)
begin : STAGES_GT_1
  integer i;
  always @(posedge clk_i or negedge rst_n)
  begin
    if(!rst_n)
    begin
      for(i = MULT_STAGES ; i > 0 ; i = i - 1)
      begin
        vld_sts    [i-1] <= 1'b1   ;
        result_Re_r[i-1] <= I_VAL_0;
        result_Im_r[i-1] <= I_VAL_0;
            Co_Re_r[i-1] <= 1'b0   ;
            Co_Im_r[i-1] <= 1'b0   ;
      end
    end
    else
    begin
      vld_sts    [MULT_STAGES-1] <= 1'b0       ;
      result_Re_r[MULT_STAGES-1] <= result_Re_c;
      result_Im_r[MULT_STAGES-1] <= result_Im_c;
          Co_Re_r[MULT_STAGES-1] <=     Co_Re_c;
          Co_Im_r[MULT_STAGES-1] <=     Co_Im_c;
      for(i = MULT_STAGES-1 ; i > 0 ; i = i - 1)
      begin
        vld_sts    [i-1] <= vld_sts    [i];
        result_Re_r[i-1] <= result_Re_r[i];
        result_Im_r[i-1] <= result_Im_r[i];
            Co_Re_r[i-1] <=     Co_Re_r[i];
            Co_Im_r[i-1] <=     Co_Im_r[i];
      end
    end
  end
end  // STAGES_GT_1
else if(MULT_STAGES == 1)
begin : STAGES_EQ_1
  always @(posedge clk_i or negedge rst_n)
  begin
    if(!rst_n)
    begin
      vld_sts    [0] <= 1'b1   ;
      result_Re_r[0] <= I_VAL_0;
      result_Im_r[0] <= I_VAL_0;
          Co_Re_r[0] <= 1'b0   ;
          Co_Im_r[0] <= 1'b0   ;
    end
    else
    begin
      vld_sts    [0] <= 1'b0       ;
      result_Re_r[0] <= result_Re_c;
      result_Im_r[0] <= result_Im_c;
          Co_Re_r[0] <=     Co_Re_c;
          Co_Im_r[0] <=     Co_Im_c;
    end
  end
end  // STAGES_EQ_1
else
begin : STAGES_LT_1
  always @( * )
  begin
    vld_sts    [0] = 1'b0       ;
    result_Re_r[0] = result_Re_c;
    result_Im_r[0] = result_Im_c;
        Co_Re_r[0] =     Co_Re_c;
        Co_Im_r[0] =     Co_Im_c;
  end
end  // STAGES_LT_1
endgenerate

assign tb_result_Re = result_Re_r[0];
assign tb_result_Im = result_Im_r[0];
assign tb_Co_Re     =     Co_Re_r[0];
assign tb_Co_Im     =     Co_Im_r[0];

//localparam SIGNED = I_SIGNED ? "on" : "off";

// ----------------------------
// GSR instance
// ----------------------------
`ifndef iCE40UP
GSR GSR_INST ( .GSR_N(1'b1), .CLK(1'b0));
`endif

`include "dut_inst.v"

// ----- Limiting TEST COUNT -----
always @(posedge clk_i or posedge rst_i)
begin
  if(rst_i) begin
	test_count <= {10{1'b0}};
  end
  else begin
	test_count <= test_count + 1'b1;
  end
end

always @* begin
 if (rst_i) begin
	  test_done = 0;
	end
	 else begin
	    if (test_count === 1000) begin
		  test_done = 1;
		end
	 end
end

//Declaration of Signed inputs and outputs for the Log file
reg signed [I_WDT-1:0] data_a_re;
reg signed [I_WDT-1:0] data_b_re;
reg signed [I_WDT-1:0] data_a_im;
reg signed [I_WDT-1:0] data_b_im;

wire signed [I_WDT-1:0] result_re;
wire signed [I_WDT-1:0] result_im;

assign result_re = result_re_o;
assign result_im = result_im_o;

always @* begin
	data_a_re = data_a_re_i[I_WDT-1:0];
	data_b_re = data_b_re_i[I_WDT-1:0];
	data_a_im = data_a_im_i[I_WDT-1:0];
	data_b_im = data_b_im_i[I_WDT-1:0];
end

// ----- Display Debug Log -----
initial begin
 if ((USE_CNUM == 1'b1) && (SIGNED == "off")) begin
  $monitor("Test Count: %d, add_sub_i : %d, data_a_re_i: %d, data_b_re_i : %d, data_a_im_i : %d, data_b_im_i : %d, result_re_o : %d, result_im_o : %d", test_count, add_sub_i, data_a_re_i, data_b_re_i, data_a_im_i, data_b_im_i, result_re_o, result_im_o);
 end
 else if ((USE_CNUM == 1'b0) && (SIGNED == "off")) begin
  $monitor("Test Count: %d, add_sub_i : %d, data_a_re_i: %d data_b_re_i : %d, result_re_o : %d", 
           test_count,     add_sub_i,      data_a_re_i,    data_b_re_i,      result_re_o);
 end
  else if ((USE_CNUM == 1'b1) && (SIGNED == "on")) begin
  $monitor("Test Count: %d, add_sub_i : %d, data_a_re_i: %d, data_b_re_i : %d, data_a_im_i : %d, data_b_im_i : %d, result_re_o : %d, result_im_o : %d", test_count, add_sub_i, data_a_re, data_b_re, data_a_im, data_b_im, result_re, result_im);
 end
 else begin //if ((USE_CNUM == 1'b0) && (SIGNED == "on"))
  $monitor("Test Count: %d, add_sub_i : %d, data_a_re_i: %d data_b_re_i : %d, result_re_o : %d", 
           test_count,     add_sub_i,      data_a_re,    data_b_re,      result_re);
 end
end

// ----- Display Test Status -----
initial
begin
  wait(test_done);

  repeat(MULT_STAGES+1) @(posedge clk_i);
  $display();
        $write  ("------ TEST DONE @Time: %t ------- ", $time);
  $display();
  if(test_sts) begin
		$display("-----------------------------------------");
		$display("------------ SIMULATION PASSED ----------");
		$display("-----------------------------------------");
  end 
  else begin
		$display("-----------------------------------------");
		$display("---------!!! SIMULATION FAILED !!!-------");
		$display("-----------------------------------------");
  end

  $finish();
end

endmodule  // tb_top
`endif // TB_TOP