`timescale 1ns / 1ps


module RAM_1024x16bit
#( parameter ram_chose = 0)
(
	input wire 				   clk_A,
	input wire  				clk_B,
	input wire  [9:0] 		RAM_addr_A,
	input wire  [9:0] 		RAM_addr_B,
	input	wire  [15:0] 		RAM_data_in,
	output wire [15:0]	   RAM_data_out_A,
	output wire [15:0]	   RAM_data_out_B,
	input	wire				   RAM_we,
	input wire				   reset
);

	// wire [31:0] RAM_data_out_A_0, RAM_data_out_B_0;
	
	// assign RAM_data_out_A = RAM_data_out_A_0[15:0];
	// assign RAM_data_out_B = RAM_data_out_B_0[15:0];
assign RAM_data_out_A = RAM_data_out_B;

//  testdq dq16x64(
//         .wr_clk_i(clk_A), 
//         .rd_clk_i(clk_B), 
//         .rst_i(reset), 
//         .wr_clk_en_i(1'd1), 
//         .rd_en_i(1'd1), 
//         .rd_clk_en_i(1'd1), 
//         .wr_en_i(RAM_we), 
//         .wr_data_i(RAM_data_in), 
//         .wr_addr_i(RAM_addr_A[6:0]), 
//         .rd_addr_i(RAM_addr_B[6:0]), 
//         .rd_data_o(RAM_data_out_B)) ;
wire [9:0]RAM_ADDR_in;
assign RAM_ADDR_in = RAM_we? RAM_addr_A:RAM_addr_B;
generate if(ram_chose == 'd0) begin

	para_mem0 para_mem0_inst(
	.clk_i    (clk_A), 
	.rst_i    (0), 
	.clk_en_i (1'd1), 
	.wr_en_i  (RAM_we), 
	.wr_data_i(RAM_data_in), 
	.addr_i   (RAM_ADDR_in[3:0]), 
	.rd_data_o(RAM_data_out_B)) ;

 end
	    else if(ram_chose == 'd1) begin

			para_mem1 para_mem1_inst(
				.clk_i    (clk_A), 
				.rst_i    (0), 
				.clk_en_i (1'd1), 
				.wr_en_i  (RAM_we), 
				.wr_data_i(RAM_data_in), 
				.addr_i   (RAM_ADDR_in[3:0]), 
				.rd_data_o(RAM_data_out_B)) ;
		 end
		else begin
			para_mem2 para_mem2_inst(
				.clk_i    (clk_A), 
				.rst_i    (0), 
				.clk_en_i (1'd1), 
				.wr_en_i  (RAM_we), 
				.wr_data_i(RAM_data_in), 
				.addr_i   (RAM_ADDR_in[3:0]), 
				.rd_data_o(RAM_data_out_B)) ;

		 end
endgenerate

endmodule
