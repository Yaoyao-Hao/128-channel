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
// Title                 : Testbench for Counter.
// Dependencies          : 1.
//                       : 2.
// Description           :
// =============================================================================
//                        REVISION HISTORY
// Version               : 1.0
// Author(s)             :
// Mod. Date             : 
// Changes Made          : Initial version of testbench for Counter.
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

// -----------------------------------------------------------------------------
// ----- Internal Derivations/Computations -----
// -----------------------------------------------------------------------------
localparam integer CNTR_WDT = (CNTR_WIDTH < 2) ? 2 : CNTR_WIDTH;
localparam [0:0] HVAL_EQ_0    = (CNTR_HVALUE == {CNTR_WDT{1'b0}});
localparam [0:0] HVAL_LE_LVAL = (CNTR_HVALUE <=  CNTR_LVALUE    );
localparam [CNTR_WDT-1:0] CNTR_HVAL = HVAL_EQ_0    ?  1                :
                                                      CNTR_HVALUE      ;
localparam [CNTR_WDT-1:0] CNTR_LVAL = HVAL_LE_LVAL ? (CNTR_HVALUE - 1) :
                                                      CNTR_LVALUE      ;
localparam [CNTR_WDT-1:0] CNTR_STEP = 1;

initial
begin
// -----------------------------------------------------------------------------
// ----- Test/Scenario Print -----
// -----------------------------------------------------------------------------
  $display();
  $display("-----------------------------------------");
  $display("------ Test/Scenario Configuration ------");
  $display("-----------------------------------------");
  $display("Counter Width           : %d", CNTR_WIDTH );
  $display("Counter Direction       : %b", CNTR_DIR   );
  $display("Lowest Counter Value    : %d", CNTR_LVALUE);
  $display("Highest Counter Value   : %d", CNTR_HVALUE);
  $display("Device Family           : %s", FAMILY     );
  $display("-----------------------------------------");
end


//--------------------------------------------------------------------------
//--- Registers ---
//--------------------------------------------------------------------------
reg clk_i;
reg rst_n;
reg updown_i;
reg load_i;
reg load;
reg  [CNTR_WDT-1:0] ldata_i;
reg clk_en_i = 1'b1;

reg test_done;
reg test_sts;
reg [10:0]test_count;
reg [CNTR_WDT-1:0] o_q;
reg test_end;
//--------------------------------------------------------------------------
//--- Wires ---
//-------------------------------------------------------------------------- 
wire [CNTR_WDT-1:0] q_o;

wire aclr_i = ~rst_n;
wire UpDown_w = CNTR_DIR[1] ? updown_i : CNTR_DIR[0];
wire lwrap = (o_q <= CNTR_LVAL);
wire hwrap = (o_q >= CNTR_HVAL);
wire opr_sts = (o_q === q_o);

// -----------------------------------------------------------------------------
// Clock Generator
// -----------------------------------------------------------------------------
initial begin
  clk_i     = 0;
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
// Initialize all variables
// -----------------------------------------------------------------------------
initial begin
  updown_i = 0;
  load = 0;
  load_i = 0;
  ldata_i = 0;
end 

// ----- Input Generation -----
always @ (posedge clk_i or negedge rst_n) begin
 if (!rst_n)begin
  updown_i <= 1'b0;
  load     <= 1'b0;
  ldata_i  <= {CNTR_WDT{1'b0}};
 end
 else begin
  updown_i <= $urandom_range(1'b0, 1'b1);
  load     <= $urandom_range(1'b0, 1'b1);
  ldata_i  <= $urandom_range({CNTR_WDT{1'b0}}, {CNTR_WDT{1'b1}});
 end
end

// -----------------------------------------------------------------------------
// ----- Monitor & Scoreboard -----
// -----------------------------------------------------------------------------
always @ (*)
begin
if (CNTR_LOAD)
 load_i = load;
end

always @(posedge clk_i or negedge rst_n)
begin
  if(!rst_n)
  begin
    test_done <= 1'b0;
    test_sts  <= 1'b1;
  end
  else if(!test_done)
  begin
    test_done <= test_end;
    test_sts  <= (test_sts & opr_sts);
  end
end

always @(posedge clk_i or posedge rst_n) begin
 if (test_count == {10{1'b1}}) begin
 	test_end <= 1;
 end
 else begin
	test_end <= 0;
 end
end
// -----------------------------------------------------------------------------
// ----- TB Calculations -----
// -----------------------------------------------------------------------------
always @(posedge clk_i or posedge aclr_i)
begin
       if(aclr_i    ) o_q <= CNTR_LVAL                            ;
  else if(!clk_en_i ) o_q <= o_q                                  ;
  else if(load_i )    o_q <= ldata_i                              ;
  else if(UpDown_w)   o_q <= hwrap ? CNTR_LVAL : {o_q + CNTR_STEP};
  else                o_q <= lwrap ? CNTR_HVAL : {o_q - CNTR_STEP};
end

// ----------------------------
// GSR instance
// ----------------------------
`ifndef iCE40UP
GSR GSR_INST ( .GSR_N(1'b1), .CLK(1'b0));
`endif

`include "dut_inst.v"

// ----- Limiting TEST COUNT -----
always @(posedge clk_i or negedge rst_n)
begin
  if(!rst_n) begin
	test_count <= {10{1'b0}};
  end
  else begin
	test_count <= test_count + 1'b1;
  end
end

always @* begin
 if (!rst_n) begin
	  test_done = 0;
	end
	 else begin
	    if (test_count === 1000) begin
		  test_done = 1;
		end
	 end
end

// ----- Display Debug Log -----
initial begin
$monitor("Test Count: %d, updown_i: %b, ldata_i : %d, , q_o : %d", test_count, updown_i, ldata_i, ldata_i, q_o);
end

// ----- Display Test Status -----
initial
begin
  repeat(1000) @(posedge clk_i);
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

endmodule   // tb_top
`endif // TB_TOP