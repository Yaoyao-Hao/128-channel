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
// Title                 : Testbench for distributed_dpram.
// Dependencies          : 1.
//                       : 2.
// Description           :
// =============================================================================
//                        REVISION HISTORY
// Version               : 1.0.1
// Author(s)             :
// Mod. Date             : 11/21/2018
// Changes Made          : Initial version of testbench for distributed_dpram
// =============================================================================

`ifndef TB_TOP
`define TB_TOP

//==========================================================================
// Module : tb_top
//==========================================================================

`timescale 1ns/1ns

`include "clk_rst_gen.v"
`include "dist_mem_master.v"
`include "dist_mem_model.v"

module tb_top();

localparam CLK_PERIOD0 = 10;
localparam CLK_PERIOD1 = 10;
localparam RST_GEN     = 35;
localparam TIMEOUT     = 2000000;

`include "dut_params.v"
					   
wire                   wr_clk_i;
wire                   rd_clk_i;
wire                   rst_i;
wire                   wr_clk_en_i;
wire                   rd_clk_en_i;
					   
wire                   rd_out_clk_en_i;
					   
wire                   wr_en_i;
wire [WDATA_WIDTH-1:0] wr_data_i;
wire [WADDR_WIDTH-1:0] wr_addr_i;
wire                   rd_en_i;
wire [RADDR_WIDTH-1:0] rd_addr_i;
					   
wire [RDATA_WIDTH-1:0] rd_data_o;
wire [RDATA_WIDTH-1:0] mem_rdout_o;

// ----------------------------
// GSR instance
// ----------------------------
`ifndef ICE40UP
    GSR GSR_INST ( .GSR_N(1'b1), .CLK(1'b0));
`endif

`include "dut_inst.v"

clk_rst_gen # (
    .CLK_PERIOD0 (CLK_PERIOD0),
    .CLK_PERIOD1 (CLK_PERIOD1),
    .RST_GEN     (RST_GEN),
    .TIMEOUT     (TIMEOUT)
) u_clk0 (
    .clk0_o      (wr_clk_i),
    .clk1_o      (rd_clk_i),
    .rst_o       (rst_i),
    .rst_n_o     ()
);

dist_mem_master # (
    .DIST_MEM_TYPE    ("distributed_dpram"),
    .ADDR_DEPTH       (WADDR_DEPTH),
    .DATA_WIDTH       (WDATA_WIDTH),
    .ADDR_WIDTH       (WADDR_WIDTH),
    .REGMODE          (REGMODE),
    .RESETMODE        (RESETMODE),
    .INIT_MODE        (INIT_MODE),
    .INIT_FILE        (INIT_FILE),
    .INIT_FILE_FORMAT (INIT_FILE_FORMAT)
) u_master0 (
    .wr_clk_i         (wr_clk_i   ),
    .rd_clk_i         (rd_clk_i   ),
    .rst_i            (rst_i      ),
    .wr_clk_en_i      (wr_clk_en_i),
    .rd_clk_en_i      (rd_clk_en_i),
                       
	.wr_en_i          (wr_en_i    ),
	.wr_data_i        (wr_data_i  ),
	.wr_addr_i        (wr_addr_i  ),
	.rd_en_i          (rd_en_i    ),
	.rd_addr_i        (rd_addr_i  ),
							   
	.rd_data_o        (rd_data_o),
    .mem_rdout_o      (mem_rdout_o)
);

dist_mem_model # (
    .ADDR_DEPTH       (WADDR_DEPTH),
    .DATA_WIDTH       (WDATA_WIDTH),
    .ADDR_WIDTH       (WADDR_WIDTH),
    .REGMODE          (REGMODE),
    .RESETMODE        (RESETMODE),
    .INIT_MODE        (INIT_MODE),
    .INIT_FILE        (INIT_FILE),
    .INIT_FILE_FORMAT (INIT_FILE_FORMAT)
) u_mem0 (
    .wr_clk_i         (wr_clk_i   ),
    .rd_clk_i         (rd_clk_i   ),
    .rst_i            (rst_i      ),
    .wr_clk_en_i      (wr_clk_en_i),
    .rd_clk_en_i      (rd_clk_en_i),
                       
	.wr_en_i          (wr_en_i    ),
	.wr_data_i        (wr_data_i  ),
	.wr_addr_i        (wr_addr_i  ),
	.rd_en_i          (rd_en_i    ),
	.rd_addr_i        (rd_addr_i  ),
							   
	.rd_data_o        (mem_rdout_o)
);
endmodule
`endif
