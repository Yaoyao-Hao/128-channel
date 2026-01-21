`timescale 1ns / 1ps



module okTriggerln0(
input clk_in,
input rst,
input data_valid,
input [15:0]ok2,
input [7:0]ep_addr,
input wireoutfinish,
output reg[2:0]STATE,
output reg[15:0]ep_dataout
    );
    wire [15:0]ok1;
    assign ok1 = {ok2[7:0],ok2[15:8]};
// reg [2:0]STATE;
localparam HEADER = 16'hC7E5,
           UPDATAHEADER = 16'hB79E,
           IDLE = 0,
           SAVE = 1,
           FINISH = 2,
           WireOUT = 3;
 reg [9:0]data_cnt;          
always@(posedge clk_in)
 begin
  if(rst)
   begin
    ep_dataout <= 16'd0;
    data_cnt  <= 10'd0;
    STATE <= IDLE; 
   end
 else 
  begin
   case(STATE)
    IDLE: begin 
     //ep_dataout <= ep_dataout;
     ep_dataout <= 0;
	 data_cnt  <= 10'd0;


     if(ok1[15:0] == HEADER&&data_valid)
      begin
       STATE <= SAVE;
       data_cnt  <= 10'd1;
      end

     else 
      begin
       STATE <= IDLE;
       data_cnt <= data_cnt;
      end
    end
    
    SAVE:begin
      if(data_valid)
       begin
        data_cnt  <= data_cnt + 'd1;
		
        if(ok1[15:8] == ep_addr)
          begin
            case(ok1[7:0])
             'd0:begin ep_dataout <= 'd1; end
             'd1:begin ep_dataout <= 'd3; end
             'd2:begin ep_dataout <= 'd5; end
             'd3:begin ep_dataout <= 'd7; end
             'd4:begin ep_dataout <= 'h0d; end
             'd5:begin ep_dataout <= 'h1d; end
             'd6:begin ep_dataout <= 'h2d; end
             'd7:begin ep_dataout <= 'h3d; end
             default:begin ep_dataout <= 'd0; end 
            endcase
		  //  if(ok1[7:0] == 0) begin ep_dataout <= 'd1; end
      //  else if(ok1[7:0] == 1) begin ep_dataout <= 'd3; end
      //  else if(ok1[7:0] == 2) begin ep_dataout <= 'd7; end
       //else if(ok1[7:0] == 1) begin ep_dataout <= 'd1; end
			   STATE      <= FINISH; 
          end
        else 
             begin
               ep_dataout <= ep_dataout;
               STATE      <= IDLE; 
             end
           end
      else 
       begin
        data_cnt  <= data_cnt;
        STATE     <= STATE;
       end
       end


     FINISH: begin
      ep_dataout <= 0;
      STATE      <= IDLE;
     end
   endcase
  end
 end



endmodule
