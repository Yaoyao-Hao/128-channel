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
// Title                 : Testbench for Adder.
// Dependencies          : 1.
//                       : 2.
// Description           :
// =============================================================================
//                        REVISION HISTORY
// Version               : 1.0
// Author(s)             :
// Mod. Date             : 
// Changes Made          : Initial version of testbench for Adder.
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
// ----- TB Limited Configurations -----
// -----------------------------------------------------------------------------
localparam integer SYS_CLK_PERIOD = (FAMILY == "iCE40UP") ? 40 : 10;
localparam integer I_WDT = D_WIDTH;
localparam integer MULT_STAGES = (USE_OREG == "off") ? PIPELINES: PIPELINES + 1;
localparam [I_WDT-1:0] I_VAL_0 = {I_WDT{1'b0}};

// ----- Monitor & Scoreboard -----
reg [I_WDT-1:0] data_a_re_i;
reg [I_WDT-1:0] data_a_im_i;
reg [I_WDT-1:0] data_b_re_i;
reg [I_WDT-1:0] data_b_im_i;
reg             cin_re_i   ;
reg             cin_im_i   ;

wire [I_WDT-1:0] result_re_o;
wire [I_WDT-1:0] result_im_o;
wire [I_WDT-1:0] tb_ApB_Re  ;
wire [I_WDT-1:0] tb_ApB_Im  ;
wire             cout_re_o  ;
wire             cout_im_o  ;
wire             tb_Co_Re   ;
wire             tb_Co_Im   ;

// -----------------------------------------------------------------------------
// Clock Generator
// -----------------------------------------------------------------------------
reg              clk_i      ;
reg              clk_en_i   ;
reg              rst_i      ;
reg              rst_n_i    ;

initial begin
  clk_i     = 0;
  clk_en_i  = 1;
end

always #(SYS_CLK_PERIOD/2) clk_i = ~clk_i;

// -----------------------------------------------------------------------------
// Reset Signals
// -----------------------------------------------------------------------------
initial begin
  rst_i     = 1;
  rst_n_i   = 0;
  #(10*SYS_CLK_PERIOD)
  rst_i     = 0;
  rst_n_i   = 1;
end

reg  test_done              ;
reg  test_sts               ;
reg [10:0]test_count        ;
reg  vld_sts [MULT_STAGES:0];
wire cnum_en    = USE_CNUM  ;
wire cout_en    = USE_COUT  ;
wire sign_en    = (SIGNED == "on") ? 1'b1: 0;

wire opr_sts = (vld_sts[0] |
               ((tb_ApB_Re === result_re_o) &
                ((tb_ApB_Im === result_im_o ) | (cnum_en === 0)) &
                ((tb_Co_Re  === cout_re_o )   | (cout_en === 0)) &
                ((tb_Co_Im   === cout_im_o)   | (cout_en === 0) | (cnum_en === 0))));
                  
initial
begin
  // ----- Test/Scenario Print -----
  $display();
  $display("---------------------------------------");
  $display("----- Test/Scenario Configuration -----");
  $display("---------------------------------------");
  $display(                                         );
  $display("Input Width            : %d", I_WDT     );
  $display("Input Signed           : %s", SIGNED    );
  $display("Use Complex Numbers    : %d", USE_CNUM  );
  $display("Use Carry-In           : %d", USE_CIN   );
  $display("Use Carry-Out          : %d", USE_COUT  );
  $display("O Registered           : %s", USE_OREG  );
  $display("Pipelines              : %d", PIPELINES );
  $display("Device Family          : %s", FAMILY    );
  $display("---------------------------------------");
end
                  
always @(posedge clk_i or negedge rst_n_i)
begin
  if(!rst_n_i)
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
always @ (posedge clk_i or negedge rst_n_i) begin
 if (!rst_n_i)begin
  data_a_re_i <= {I_WDT{1'b0}};
  data_a_im_i <= {I_WDT{1'b0}};
  data_b_re_i <= {I_WDT{1'b0}};
  data_b_im_i <= {I_WDT{1'b0}};
  cin_re_i    <= {I_WDT{1'b0}};
  cin_im_i    <= {I_WDT{1'b0}};
 end
 else begin
  data_a_re_i <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  data_a_im_i <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  data_b_re_i <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  data_b_im_i <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  cin_re_i    <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
  cin_im_i    <= $urandom_range({I_WDT{1'b0}}, {I_WDT{1'b1}});
 end
end

// ----- TB Calculations -----
wire [I_WDT-1:0]  A_Re =                         data_a_re_i  ;
wire [I_WDT-1:0]  B_Re =                         data_b_re_i  ;
wire [I_WDT-1:0]  A_Im = ({I_WDT{cnum_en}}  & data_a_im_i );
wire [I_WDT-1:0]  B_Im = ({I_WDT{cnum_en}}  & data_b_im_i );
wire             Ci_Im = (USE_CIN & cnum_en & cin_im_i);
wire             Ci_Re = (USE_CIN           & cin_re_i);

reg  [I_WDT-1:0] ApB_Re                  ;
reg  [I_WDT-1:0] ApB_Im                  ;
reg               Co_Re                  ;
reg               Co_Im                  ;
reg  [I_WDT-1:0] ApB_Re_r [MULT_STAGES:0];
reg  [I_WDT-1:0] ApB_Im_r [MULT_STAGES:0];
reg               Co_Re_r [MULT_STAGES:0];
reg               Co_Im_r [MULT_STAGES:0];

wire   A_Re_msb =   A_Re[I_WDT-1];
wire   B_Re_msb =   B_Re[I_WDT-1];
wire ApB_Re_msb = ApB_Re[I_WDT-1];
wire   A_Im_msb =   A_Im[I_WDT-1];
wire   B_Im_msb =   B_Im[I_WDT-1];
wire ApB_Im_msb = ApB_Im[I_WDT-1];

always @( * )
begin
  ApB_Re = {A_Re + B_Re + Ci_Re};
  ApB_Im = {A_Im + B_Im + Ci_Im};

  if(sign_en == 1'b1)
  begin
    case({A_Re_msb, B_Re_msb})
    2'b00: Co_Re =  ApB_Re_msb;
    2'b11: Co_Re = ~ApB_Re_msb;
    2'b01,
    2'b10: Co_Re = 1'b0       ;
    endcase

    case({A_Im_msb, B_Im_msb})
    2'b00: Co_Im =  ApB_Im_msb;
    2'b11: Co_Im = ~ApB_Im_msb;
    2'b01,
    2'b10: Co_Im = 1'b0       ;
    endcase
  end
  else
  begin
    case({A_Re_msb, B_Re_msb})
    2'b00: Co_Re = 1'b0       ;
    2'b11: Co_Re = 1'b1       ;
    2'b01,
    2'b10: Co_Re = ~ApB_Re_msb;
    endcase

    case({A_Im_msb, B_Im_msb})
    2'b00: Co_Im = 1'b0       ;
    2'b11: Co_Im = 1'b1       ;
    2'b01,
    2'b10: Co_Im = ~ApB_Im_msb;
    endcase
  end
end
wire Co_Re_c = (cout_en & Co_Re);
wire Co_Im_c = (cout_en & Co_Im);

generate
if(MULT_STAGES > 1)
begin : STAGES_GT_1
  integer i;
  always @(posedge clk_i or negedge rst_n_i)
  begin
    if(!rst_n_i)
    begin
      for(i = MULT_STAGES ; i > 0 ; i = i - 1)
      begin
        vld_sts [i-1] <= 1'b1   ;
        ApB_Re_r[i-1] <= I_VAL_0;
        ApB_Im_r[i-1] <= I_VAL_0;
         Co_Re_r[i-1] <= 1'b0   ;
         Co_Im_r[i-1] <= 1'b0   ;
      end
    end
    else
    begin
      vld_sts [MULT_STAGES-1] <= 1'b0    ;
      ApB_Re_r[MULT_STAGES-1] <= ApB_Re  ;
      ApB_Im_r[MULT_STAGES-1] <= ApB_Im  ;
       Co_Re_r[MULT_STAGES-1] <=  Co_Re_c;
       Co_Im_r[MULT_STAGES-1] <=  Co_Im_c;
      for(i = MULT_STAGES-1 ; i > 0 ; i = i - 1)
      begin
        vld_sts [i-1] <= vld_sts [i];
        ApB_Re_r[i-1] <= ApB_Re_r[i];
        ApB_Im_r[i-1] <= ApB_Im_r[i];
         Co_Re_r[i-1] <=  Co_Re_r[i];
         Co_Im_r[i-1] <=  Co_Im_r[i];
      end
    end
  end
end  // STAGES_GT_1
else if(MULT_STAGES == 1)
begin : STAGES_EQ_1
  always @(posedge clk_i or negedge rst_n_i)
  begin
    if(!rst_n_i)
    begin
      vld_sts [0] <= 1'b1    ;
      ApB_Re_r[0] <= I_VAL_0 ;
      ApB_Im_r[0] <= I_VAL_0 ;
       Co_Re_r[0] <= 1'b0    ;
       Co_Im_r[0] <= 1'b0    ;
    end
    else
    begin
      vld_sts [0] <= 1'b0    ;
      ApB_Re_r[0] <= ApB_Re  ;
      ApB_Im_r[0] <= ApB_Im  ;
       Co_Re_r[0] <=  Co_Re_c;
       Co_Im_r[0] <=  Co_Im_c;
    end
  end
end  // STAGES_EQ_1
else
begin : STAGES_LT_1
  always @( * )
  begin
    vld_sts [0] = 1'b0    ;
    ApB_Re_r[0] = ApB_Re  ;
    ApB_Im_r[0] = ApB_Im  ;
     Co_Re_r[0] =  Co_Re_c;
     Co_Im_r[0] =  Co_Im_c;
  end
end  // STAGES_LT_1
endgenerate

assign tb_ApB_Re = ApB_Re_r[0];
assign tb_ApB_Im = ApB_Im_r[0];
assign tb_Co_Re  =  Co_Re_r[0];
assign tb_Co_Im  =  Co_Im_r[0];

// ----------------------------
// GSR instance
// ----------------------------
`ifndef iCE40UP
GSR GSR_INST ( .GSR_N(1'b1), .CLK(1'b0));
`endif

`include "dut_inst.v"

// ----- Limiting TEST COUNT -----
initial begin
 test_done = 0;
end

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
  $monitor("Test Count: %d, data_a_re_i: %d data_b_re_i : %d, data_a_im_i : %d, data_b_im_i : %d, result_re_o : %d, result_im_o : %d", test_count, data_a_re_i, data_b_re_i, data_a_im_i, data_b_im_i, result_re_o, result_im_o);
 end
 else if ((USE_CNUM == 1'b0) && (SIGNED == "off")) begin
   $monitor("Test Count: %d, data_a_re_i: %d data_b_re_i : %d, result_re_o : %d", 
           test_count,     data_a_re_i,    data_b_re_i,      result_re_o);
 end
 else if ((USE_CNUM == 1'b1) && (SIGNED == "on")) begin
  $monitor("Test Count: %d, data_a_re_i: %d data_b_re_i : %d, data_a_im_i : %d, data_b_im_i : %d, result_re_o : %d, result_im_o : %d", test_count, data_a_re, data_b_re, data_a_im, data_b_im, result_re, result_im);
 end
 else begin //if ((USE_CNUM == 1'b0) && (SIGNED == "on"))
  $monitor("Test Count: %d, data_a_re_i: %d data_b_re_i : %d, result_re_o : %d", 
           test_count,     data_a_re,    data_b_re,      result_re);
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

endmodule //tb_top
`endif // TB_TOP