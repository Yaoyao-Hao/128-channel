`ifndef _DIST_MEM_MODEL_
`define _DIST_MEM_MODEL_

module dist_mem_model # (
    parameter ADDR_DEPTH       = 128,
    parameter DATA_WIDTH       = 8,
    parameter ADDR_WIDTH       = clog2(ADDR_DEPTH),
    parameter REGMODE          = "reg",
    parameter RESETMODE        = "sync",
    parameter INIT_MODE        = "none",
    parameter INIT_FILE        = "none",
    parameter INIT_FILE_FORMAT = "hex"
)(
	input                     wr_clk_i,
	input                     rd_clk_i,
	input                     rst_i,
	input                     wr_clk_en_i,
	input                     rd_clk_en_i,
							   
	input                     wr_en_i,
	input [DATA_WIDTH-1:0]    wr_data_i,
	input [ADDR_WIDTH-1:0]    wr_addr_i,
	input                     rd_en_i,
	input [ADDR_WIDTH-1:0]    rd_addr_i,
							   
	output [DATA_WIDTH-1:0]   rd_data_o
);

reg [DATA_WIDTH-1:0] mem [2**ADDR_WIDTH-1:0];

initial
    begin
        if (((INIT_MODE == "mem_file") && (INIT_FILE != "none"))) 
            begin
                if ((INIT_FILE_FORMAT == "hex")) 
                    begin
                        $readmemh (INIT_FILE, mem, 0, (ADDR_DEPTH - 1)) ;
                    end
                else
                    begin
                        $readmemb (INIT_FILE, mem, 0, (ADDR_DEPTH - 1)) ;
                    end
            end
    end

always @ (posedge wr_clk_i) begin
    if(wr_clk_en_i & wr_en_i) begin
        mem[wr_addr_i] <= wr_data_i;
    end
end

if(REGMODE == "noreg") begin
    assign rd_data_o = mem[rd_addr_i];
end
else begin
    reg [DATA_WIDTH-1:0] rd_data_reg;
    assign rd_data_o = rd_data_reg;

    always @ (posedge rd_clk_i) begin
        if(rd_clk_en_i & rd_en_i) begin
            rd_data_reg <= mem[rd_addr_i];
        end
    end
end

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