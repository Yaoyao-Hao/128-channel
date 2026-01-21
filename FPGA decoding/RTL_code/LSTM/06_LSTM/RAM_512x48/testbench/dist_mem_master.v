`ifndef _DIST_MEM_MASTER_
`define _DIST_MEM_MASTER_

module dist_mem_master # (
    parameter DIST_MEM_TYPE     = "distributed_dpram",
    parameter ADDR_DEPTH        = 128,
    parameter DATA_WIDTH        = 8,
    parameter ADDR_WIDTH        = clog2(ADDR_DEPTH),
    parameter REGMODE           = "reg",
    parameter RESETMODE         = "sync",
    parameter INIT_MODE         = "none",
    parameter INIT_FILE         = "none",
    parameter INIT_FILE_FORMAT  = "hex"
)(
	input                       wr_clk_i,
	input                       rd_clk_i,
	input                       rst_i,
	output reg                  wr_clk_en_i,
	output reg                  rd_clk_en_i,
							    
	output reg                  wr_en_i,
	output reg [DATA_WIDTH-1:0] wr_data_i,
	output reg [ADDR_WIDTH-1:0] wr_addr_i,
	output reg                  rd_en_i,
	output reg [ADDR_WIDTH-1:0] rd_addr_i,
							   
	input [DATA_WIDTH-1:0]      rd_data_o,
	input [DATA_WIDTH-1:0]      mem_rdout_o
);

localparam REG_CNTR = (REGMODE == "reg") ? 1 : 0;

reg [DATA_WIDTH-1:0] exp_dout;
reg [DATA_WIDTH-1:0] act_dout;
reg [511:0]          data_in;

reg one_err;
reg seg_err;
reg tb_err;

genvar din0;
generate
    for(din0 = 0; din0 < 16; din0 = din0 + 1) begin
        always @ (posedge wr_clk_i) begin
            data_in[din0*32 +: 32] <= $urandom_range({32{1'b0}}, {32{1'b1}});
        end
    end
endgenerate

always @ (posedge rd_clk_i) begin
    exp_dout <= mem_rdout_o;
    act_dout <= rd_data_o;
end

initial begin
    wr_clk_en_i <= 1'b0;
    wr_en_i     <= 1'b0;
    rd_clk_en_i <= 1'b0;
    rd_en_i     <= 1'b0;
    wr_addr_i   <= {ADDR_WIDTH{1'b0}};
    rd_addr_i   <= {ADDR_WIDTH{1'b0}};
    wr_data_i   <= {DATA_WIDTH{1'b0}};
    one_err     <= 1'b1;
    seg_err     <= 1'b1;
    tb_err      <= 1'b1;
end

initial begin
    @(negedge rst_i);
    @(posedge wr_clk_i);
    if(INIT_MODE != "none") begin
        ReadData(1);
    end
    if(DIST_MEM_TYPE != "distributed_rom") begin
        WriteData();
        ReadData(0);
    end
    @(posedge wr_clk_i);
    if(tb_err) begin
        $display("-----------------------------------------------------");
        $display("----------------- SIMULATION PASSED -----------------");
        $display("-----------------------------------------------------");
    end
    else begin
        $display("-----------------------------------------------------");
        $display("!!!!!!!!!!!!!!!!! SIMULATION FAILED !!!!!!!!!!!!!!!!!");
        $display("-----------------------------------------------------");
    end
    $finish;
end

//------------------------------------------------------------------------------
// Task Definition
//------------------------------------------------------------------------------

task WriteData;
    integer i0;
    begin
        wr_en_i     <= 1'b1;
        wr_clk_en_i <= 1'b1;
        wr_addr_i   <= {ADDR_WIDTH{1'b0}};
        wr_data_i   <= data_in[DATA_WIDTH-1:0];
        for(i0 = 0; i0 < ADDR_DEPTH; i0 = i0 + 1) begin
            @(posedge wr_clk_i);
            wr_addr_i <= wr_addr_i + 1'b1;
            wr_data_i <= data_in[DATA_WIDTH-1:0];
        end
        wr_en_i <= 1'b0;
        wr_clk_en_i <= 1'b0;
        @(posedge wr_clk_i);
    end
endtask

task ReadData;
    input init_i;
    integer i0;
    begin
        if(init_i) begin
            $display(" Initialization Test Started");
        end
        else begin
            $display(" Read Test Started");
        end
        rd_en_i     <= 1'b1;
        rd_clk_en_i <= 1'b1;
        rd_addr_i   <= {ADDR_WIDTH{1'b0}};
        one_err     <= 1'b1;
        seg_err     <= 1'b1;
        for(i0 = 0; i0 < ADDR_DEPTH; i0 = i0 + 1) begin
            @(posedge rd_clk_i);
            rd_addr_i <= rd_addr_i + 1'b1;
            if(i0 > REG_CNTR) begin
                if(exp_dout !== act_dout) begin
                    $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", exp_dout, act_dout, $time);
                    one_err <= 1'b0;
                    seg_err <= 1'b0;
                    tb_err  <= 1'b0;
                end
                else begin
                    one_err <= 1'b1;
                end
            end
        end
        @(posedge rd_clk_i);
        rd_en_i <= 1'b0;
        rd_clk_en_i <= 1'b0;
        if(REGMODE == "reg") begin
            if(exp_dout !== act_dout) begin
                $display("Data MISMATCH : EXPECTED_DATA=%h, ACTUAL_DATA=%h, time=%0t", exp_dout, act_dout, $time);
                one_err <= 1'b0;
                seg_err <= 1'b0;
                tb_err  <= 1'b0;
            end
            else begin
                one_err <= 1'b1;
            end
        end
        @(posedge rd_clk_i);
        if(seg_err == 1'b1) begin
            if(init_i) begin
                $display(" Initialization Test : PASSED");
            end
            else begin
                $display(" Read Test : PASSED");
            end
        end
        else begin
            if(init_i) begin
                $display(" Initialization Test : FAILED");
            end
            else begin
                $display(" Read Test : FAILED");
            end
        end
        @(posedge rd_clk_i);
        seg_err <= 1'b1;
        @(posedge rd_clk_i);
    end
endtask

//------------------------------------------------------------------------------
// Function Definition
//------------------------------------------------------------------------------

function [31:0] clog2;
  input [31:0] value;
  reg   [31:0] num;
  begin
    num = value - 1;
    for (clog2=0; num>0; clog2=clog2+1) num = num>>1;
  end
endfunction

endmodule
`endif