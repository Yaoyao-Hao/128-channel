`timescale 1ns / 1ps
module rec_wiener_para(
input clk_in,
input rst,
input reset,
input data_valid,
input [15:0]ok2,
input [7:0]ep_addr,
input wireoutfinish,
input [5:0]channel,

output [15:0]wr_ram_data,
output wr_ram_en,
output [7:0]wr_ram_addr
//output reg [2:0]REC_STATE,
    );

reg[2:0]STATE/* synthesis loc = "R14C23A" */;
    reg[15:0]ep_dataout;    
    wire [15:0]ok1;
    assign ok1 = {ok2[7:0],ok2[15:8]};
// reg [2:0]STATE;
reg xa;assign flag = xa;
localparam HEADER = 16'hC7E5,

           START_THRE_REC = 8'hA5,
           UPDATAHEADER = 16'hB79E,
           IDLE = 0,
           SAVE = 1,
           FINISH = 2,
           WireOUT = 3;
 reg [9:0]data_cnt;          
always@(posedge clk_in)
 begin
  if(reset)
   begin
   // flag <='d0;
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
            
            if(ok1[7:0] == 0)   ep_dataout <= 'd1; 
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
      ep_dataout <= 'd0;
      STATE      <= IDLE;
     end
   endcase
  end
 end
////////////////////////////当接收到阈值头储存时，进行阈值储存////////////////
reg [2:0]REC_STATE;
reg [7:0]thre_channel;
reg [15:0]thre_data_out;
reg thre_data_valid_out;
localparam INIT_REC = 0;
localparam HEAD_REC = 1;
localparam THRE_REC = 2;
localparam FINISH_REC = 3;
always@(posedge clk_in)
 begin
  if(reset)
   begin
    REC_STATE <= INIT_REC;
    thre_channel <= 'd0;
    thre_data_out <= 'd0;
    thre_data_valid_out <= 'd0;
   end
  else 
   begin
    case(REC_STATE)
     INIT_REC:begin //初始化状态
        thre_channel <= 'd0;
        thre_data_out <= 'd0;
        thre_data_valid_out <= 'd0;
        xa <= 'd0;
      if(ep_dataout) 
      begin REC_STATE <= THRE_REC; end
      else begin REC_STATE <= REC_STATE; end end
     HEAD_REC:begin //接收头
        thre_channel <= thre_channel ;
        thre_data_out <= thre_data_out;
        thre_data_valid_out <= 'd0;
       // if(ok1[15:0] == HEADER&&data_valid) begin 
        if(data_valid) begin 
         REC_STATE <= THRE_REC; 
        end
        else begin
         REC_STATE <= REC_STATE; 
        end
     end
     THRE_REC:begin //储存接下来到来的阈值数据 
        if(data_valid) begin
         if(thre_channel<'d256 - 'd1) begin 
            thre_channel <= thre_channel + 'd1;
            thre_data_valid_out <= 'd1;
            thre_data_out <= ok1;
            REC_STATE <= THRE_REC; 
        end
        else //接收完64通道阈值数据之后进入结束状态
         begin
            thre_channel <= thre_channel + 'd1;
            thre_data_valid_out <= 'd1;
            thre_data_out <= ok1;
            REC_STATE <= FINISH_REC; 
         end
        end 
        else 
         begin
            thre_channel <= thre_channel;
            thre_data_valid_out <= 'd0;
            thre_data_out <= thre_data_out;
            REC_STATE <= REC_STATE;         
         end
        end
     FINISH_REC:begin //结束状态对状态清0并进入初始状态
        REC_STATE <= INIT_REC; 
        thre_channel <= 0;
        thre_data_valid_out <= 'd0;
        thre_data_out <= ok1;
     end
    endcase
   end
 end

assign wr_ram_data = thre_data_out;
assign wr_ram_en   = thre_data_valid_out;
assign wr_ram_addr = thre_channel;

endmodule