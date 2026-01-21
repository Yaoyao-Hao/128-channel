`timescale 1ns / 1ps



module WireIn(
input clk_in,
input rst,
input data_valid,
input [15:0]ok1,
input [7:0]ep_addr,
input wireoutfinish,
input  wire [4:0]data_cnt_num,
output reg[2:0]STATE,
output reg[15:0]ep_dataout
    );
// reg [2:0]STATE;
localparam HEADER = 16'h9B5D,
           UPDATAHEADER = 16'hB79E,
           IDLE = 0,
           SAVE = 1,
           FINISH = 2,
           WireOUT = 3;
 reg [4:0]data_cnt;          
always@(posedge clk_in or posedge rst)
 begin
  if(rst)
   begin
    ep_dataout <= 16'd0;
   // data_cnt  <= 8'd0;
    STATE <= IDLE; 
   end
 else 
  begin
   case(STATE)
    IDLE: begin 
     ep_dataout <= ep_dataout;
     //data_cnt  <= 8'd0;


     if(ok1[15:0] == HEADER&&data_valid)
      begin
       STATE <= SAVE;
       //data_cnt  <=8'd0;
      end
     else if((ok1[15:0] == UPDATAHEADER)&&data_valid)
      begin
       STATE <= WireOUT;
       //data_cnt <= data_cnt;
      end
     else 
      begin
       STATE <= IDLE;
       //data_cnt <= data_cnt;
      end
    end
    
    SAVE:begin
      if(data_valid)
       begin
        //data_cnt  <= data_cnt + 'd1;
        if(data_cnt == ep_addr&&(data_cnt<data_cnt_num))
          begin
           ep_dataout <= ok1[15:0];
           STATE      <= SAVE; 
          end
        else 
          begin
            if(data_cnt == ep_addr&&(data_cnt>=data_cnt_num))
              begin
               ep_dataout <= ok1[15:0];
               STATE      <= FINISH;         
              end
            else if((data_cnt>=data_cnt_num))
             begin
               ep_dataout <= ep_dataout;
               STATE      <= FINISH; 
             end 
           end
       end

      else 
       begin
        //data_cnt  <= data_cnt;
        STATE     <= STATE;
       end
       end

       WireOUT: begin
         if(wireoutfinish)
          begin
             STATE <= FINISH;
          end
         else 
          begin
            STATE <= STATE;
          end
       end
     FINISH: begin
      ep_dataout <= ep_dataout;
      STATE      <= IDLE;
     end
   endcase
  end
 end

always@(posedge clk_in or posedge rst )
 begin
  if(rst)
   begin 
    data_cnt  <= 0;
   end
  else if(STATE == SAVE) 
   begin
     if(data_valid) begin data_cnt  <= data_cnt + 'd1; end
     else begin data_cnt  <= data_cnt; end
   end
  else begin
   data_cnt <='d0;
  end
 end

endmodule
