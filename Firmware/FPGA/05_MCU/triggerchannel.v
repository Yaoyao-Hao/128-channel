`timescale 1ns / 1ps



module triggerchannel(
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
           UPDATAHEADER = 16'hE97B,
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
     ep_dataout <= ep_dataout;
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
           ep_dataout <= ok1[7:0];
           STATE      <= IDLE; 
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
      ep_dataout <= ep_dataout;
      STATE      <= IDLE;
     end
   endcase
  end
 end



endmodule
