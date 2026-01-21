localparam WADDR_DEPTH = 64;
localparam WDATA_WIDTH = 16;
localparam RADDR_DEPTH = 128;
localparam RDATA_WIDTH = 8;
localparam FIFO_CONTROLLER = "FABRIC";
localparam FORCE_FAST_CONTROLLER = 0;
localparam IMPLEMENTATION = "EBR";
localparam WADDR_WIDTH = 6;
localparam RADDR_WIDTH = 7;
localparam REGMODE = "noreg";
localparam RESETMODE = "async";
localparam ENABLE_ALMOST_FULL_FLAG = "TRUE";
localparam ALMOST_FULL_ASSERTION = "static-single";
localparam ALMOST_FULL_ASSERT_LVL = 32;
localparam ALMOST_FULL_DEASSERT_LVL = 31;
localparam ENABLE_ALMOST_EMPTY_FLAG = "FALSE";
localparam ALMOST_EMPTY_ASSERTION = "static-dual";
localparam ALMOST_EMPTY_ASSERT_LVL = 1;
localparam ALMOST_EMPTY_DEASSERT_LVL = 2;
localparam ENABLE_DATA_COUNT_WR = "TRUE";
localparam ENABLE_DATA_COUNT_RD = "TRUE";
localparam FAMILY = "LIFCL";
`define LIFCL
`define je5d00
`define LIFCL_40
