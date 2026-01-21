`timescale 1ns / 1ps


module command_selector (
	input wire [5:0] 		channel,
	input wire				DSP_settle,
	input wire [15:0] 	aux_cmd,
	input wire				digout_override,
	output reg [15:0] 	MOSI_cmd
	//input [5:0]channel_read
	);
	//2'd0,channel,8'd0
wire [15:0]test_cmd0,test_cmd1,test_cmd2;
	always @(*) begin
		case (channel)
			0:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			1:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			2:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			3:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			4:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			5:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			6:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			7:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			8:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			9:       MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			10:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			11:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			12:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			13:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			14:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			15:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			16:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			17:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			18:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			19:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			20:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			21:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			22:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			23:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			24:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			25:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			26:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			27:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			28:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			29:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			30:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };
			31:      MOSI_cmd <= { 2'b00, channel, 7'b0000000, DSP_settle };

			// 0:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 1:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 2:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 3:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 4:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 5:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 6:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 7:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 8:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 9:       MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 10:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 11:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 12:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 13:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 14:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 15:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 16:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 17:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 18:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 19:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 20:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 21:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 22:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 23:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 24:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 25:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 26:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 27:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 28:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 29:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 30:      MOSI_cmd <= { 2'd3,channel,8'd0 };
			// 31:      MOSI_cmd <= { 2'd3,channel,8'd0 };


			32:		MOSI_cmd <=aux_cmd;// (aux_cmd[15:8] == 8'h83) ? {aux_cmd[15:1], digout_override} : aux_cmd; // If we detect a write to Register 3, overridge the digout value.
			33:		MOSI_cmd <=aux_cmd;// (aux_cmd[15:8] == 8'h83) ? {aux_cmd[15:1], digout_override} : aux_cmd; // If we detect a write to Register 3, overridge the digout value.
			34:		MOSI_cmd <=aux_cmd;// (aux_cmd[15:8] == 8'h83) ? {aux_cmd[15:1], digout_override} : aux_cmd; // If we detect a write to Register 3, overridge the digout value.
			default: MOSI_cmd <= 16'b0;
			endcase
	end	
	
//test

 //assign test_cmd0=16'b1110100000000000;//register 40
 //assign test_cmd1=16'b1110100100000000;//register 41
 //assign test_cmd2=16'b1110101000000000;//register 42


endmodule