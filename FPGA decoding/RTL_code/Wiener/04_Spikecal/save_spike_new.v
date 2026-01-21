module save_spike_new(
input clk ,
input rst , 
input [2:0]cntx,
input wr_start,

input [6:0]channel,
input [31:0]timestamp,
input fifo_ready,
output wire wr_fifo_o,
output reg [15:0]wr_data0,
output reg onepacket_finish,
output [7:0]wr_cnt0_o,
input [63:0]spike_data_0,
input [63:0]spike_data_1


);
reg [15:0]wr_data;
 wire [7:0]wr_cnt0/*synthesis loc = "SLICE_R22C27D"*/;
 assign wr_cnt0_o = wr_cnt0 - 'd1;
wire [31:0]timestamp0;
assign timestamp0 = {25'd0,channel};//timestamp - 32'd160;
reg cnt_start;/////开始对输出的数据进行计数
count count_wr_cnt
	 ( .clk_i(clk), 
        .clk_en_i(cnt_start), 
        .aclr_i(rst||onepacket_finish), 
        .q_o(wr_cnt0)
		) ;
reg wr_fifo;
assign wr_fifo_o = wr_fifo;

always@(posedge clk or posedge rst)
 begin
  if(rst) begin
 
    wr_fifo <='d0;

    cnt_start<= 'd0;

    onepacket_finish <= 'd0;
  end
  else if(fifo_ready)
  begin
   case(wr_cnt0)
    'd0: begin 
     onepacket_finish <= 'd0;
      if(wr_start&&cntx=='d7)
       begin

        wr_fifo <='d0; 
        cnt_start<= 'd1;
        end
       else 
        begin
         cnt_start<= 'd0;
   
         wr_fifo <='d0;         
        end
       end

     'd1: begin 
          onepacket_finish <= 'd0;
          cnt_start<= 'd1;
        wr_fifo <='d0; end
     'd2: begin 
        wr_fifo <='d0; end
             'd3: begin 
        wr_fifo <='d1; end
             'd4: begin 
        wr_fifo <='d1; end
             'd5: begin 
        wr_fifo <='d1; end
             'd6: begin 
        wr_fifo <='d1; end
             'd7: begin 
        wr_fifo <='d1; end
             'd8: begin 
        wr_fifo <='d1; end
             'd9: begin 
        wr_fifo <='d1; end
             'd10: begin 
        wr_fifo <='d1; end
             'd11: begin 
        wr_fifo <='d1; end
             'd12: begin 
        wr_fifo <='d1; end
             'd13: begin 
        wr_fifo <='d1; end
              'd14: begin 
        wr_fifo <='d1; end        
         'd15: begin 
        wr_fifo <='d1; end        
         'd16: begin 
        wr_fifo <='d1; end        
         'd17: begin 
        wr_fifo <='d1; end        
         'd18: begin 
        wr_fifo <='d1; end
        ////32~64    
     'd19: begin 
         wr_fifo <='d1; end
             'd20: begin 
        wr_fifo <='d1; end
             'd21: begin 
        wr_fifo <='d1; end
             'd22: begin 
        wr_fifo <='d1; end
             'd23: begin 
        wr_fifo <='d1; end
             'd24: begin 
        wr_fifo <='d1; end
             'd25: begin 
        wr_fifo <='d1; end
             'd26: begin 
        wr_fifo <='d1; end
             'd27: begin 
        wr_fifo <='d1; end
             'd28: begin 
        wr_fifo <='d1; end
             'd29: begin 
        wr_fifo <='d1; end
              'd30: begin 
        wr_fifo <='d1; end        
         'd31: begin 
        wr_fifo <='d1; end        
         'd32: begin 
        wr_fifo <='d1; end        
         'd33: begin 
        wr_fifo <='d1; end        
         'd34: begin 
        wr_fifo <='d1; end
         'd67: begin 
        wr_fifo <=0; 
        cnt_start<= 'd0;
        onepacket_finish <= 'd1;
        end
   endcase
  end 
   
 end
//reg [15:0]wr_data0;
always@(posedge clk)
 begin
   case(wr_cnt0)
        'd3 : begin        wr_data0 <= spike_data_0[15:0] ; end
        'd4 : begin        wr_data0 <= spike_data_0[31:16];end
        'd5 : begin        wr_data0 <= spike_data_0[47:32] ;end
        'd6 : begin        wr_data0 <= spike_data_0[63:48];end
        'd7 : begin        wr_data0 <= spike_data_0[15:0] ;end
        'd8 : begin        wr_data0 <= spike_data_0[31:16];end
        'd9 : begin        wr_data0 <= spike_data_0[47:32];end
        'd10: begin       wr_data0 <= spike_data_0[63:48];end
        'd11: begin       wr_data0 <= spike_data_0[15:0] ;end
        'd12: begin       wr_data0 <= spike_data_0[31:16];end
        'd13: begin       wr_data0 <= spike_data_0[47:32];end
        'd14: begin      wr_data0 <= spike_data_0[63:48]; end   
        'd15: begin           wr_data0 <= spike_data_0[15:0] ; end     
        'd16: begin           wr_data0 <= spike_data_0[31:16]; end     
        'd17: begin           wr_data0 <= spike_data_0[47:32]; end   
        'd18: begin           wr_data0 <= spike_data_0[63:48];end
        'd19: begin       wr_data0 <= spike_data_0[15:0] ;end
        'd20: begin       wr_data0 <= spike_data_0[31:16];end
        'd21: begin       wr_data0 <= spike_data_0[47:32];end
        'd22: begin       wr_data0 <= spike_data_0[63:48];end
        'd23: begin       wr_data0 <= spike_data_0[15:0] ;end
        'd24: begin       wr_data0 <= spike_data_0[31:16];end
        'd25: begin       wr_data0 <= spike_data_0[47:32];end
        'd26: begin       wr_data0 <= spike_data_0[63:48];end
        'd27: begin       wr_data0 <= spike_data_0[15:0] ;end
        'd28: begin       wr_data0 <= spike_data_0[31:16];end
        'd29: begin       wr_data0 <= spike_data_0[47:32];end
        'd30: begin       wr_data0 <= spike_data_0[63:48]; end    
        'd31: begin           wr_data0 <= spike_data_0[15:0] ; end     
        'd32: begin           wr_data0 <= spike_data_0[31:16]; end      
        'd33: begin           wr_data0 <= spike_data_0[47:32];  end    
        'd34: begin           wr_data0 <= spike_data_0[63:48];end
        'd35: begin   wr_data0 <= spike_data_1[15:0] ;end
        'd36: begin   wr_data0 <= spike_data_1[31:16];end
        'd37: begin   wr_data0 <= spike_data_1[47:32];end
        'd38: begin   wr_data0 <= spike_data_1[63:48];end
        'd39: begin   wr_data0 <= spike_data_1[15:0] ;end
        'd40: begin   wr_data0 <= spike_data_1[31:16];end
        'd41: begin   wr_data0 <= spike_data_1[47:32];end
        'd42: begin   wr_data0 <= spike_data_1[63:48];end
        'd43: begin   wr_data0 <= spike_data_1[15:0] ;end
        'd44: begin   wr_data0 <= spike_data_1[31:16];end
        'd45: begin   wr_data0 <= spike_data_1[47:32];end
        'd46: begin   wr_data0 <= spike_data_1[63:48];end
        'd47: begin   wr_data0 <= spike_data_1[15:0] ;end
        'd48: begin   wr_data0 <= spike_data_1[31:16];end
        'd49: begin   wr_data0 <= spike_data_1[47:32];end
        'd50: begin   wr_data0 <= spike_data_1[63:48];end
        'd51: begin   wr_data0 <= spike_data_1[15:0] ;end
        'd52: begin   wr_data0 <= spike_data_1[31:16];end
        'd53: begin   wr_data0 <= spike_data_1[47:32];end
        'd54: begin   wr_data0 <= spike_data_1[63:48];end
        'd55: begin   wr_data0 <= spike_data_1[15:0] ;end
        'd56: begin   wr_data0 <= spike_data_1[31:16];end
        'd57: begin   wr_data0 <= spike_data_1[47:32];end
        'd58: begin   wr_data0 <= spike_data_1[63:48];end
        'd59: begin   wr_data0 <= spike_data_1[15:0] ;end
        'd60: begin   wr_data0 <= spike_data_1[31:16];end
        'd61: begin   wr_data0 <= spike_data_1[47:32];end
        'd62: begin   wr_data0 <= spike_data_1[63:48];end
        'd63: begin   wr_data0 <= spike_data_1[15:0] ;end
        'd64: begin   wr_data0 <= spike_data_1[31:16];end
        'd65: begin   wr_data0 <= spike_data_1[47:32];end
        'd66: begin   wr_data0 <= spike_data_1[63:48];end



        default: begin wr_data0 <= 0; end 
   endcase
  end 



endmodule