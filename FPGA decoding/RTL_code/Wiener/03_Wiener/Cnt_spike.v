`timescale 1ns / 1ps
module Cnt_spike
(
    input clk,
    input rst,
    input[127:0]spike_data,
    input spike_data_valid,
    output reg data_v,
    output reg finish,
    output [7:0]cnt_s_o,
    output [7:0]ram_data_rd_o
);

wire [7:0]ram_data_rd;
assign ram_data_rd_o = ram_data_rd;
reg  [7:0]ram_data_wr = 'd0;
reg [7:0]cnt_s;
reg [7:0]ramaddr;
reg wr_en;
reg [7:0]cnt_num;
assign cnt_s_o = cnt_s;
always@(posedge clk or posedge rst) begin 
    if(rst) begin cnt_num<= 'd0; ramaddr<='d0; end
    else begin
        ramaddr<=#1 cnt_s;
        if(spike_data_valid) begin cnt_num<= (cnt_num=='d99)?'d0:cnt_num + 'd1; end
        else begin cnt_num<= cnt_num; end
     end
end

cnt_spike_ram cnt_spike_ram_u(
        .wr_clk_i   (clk), 
        .rd_clk_i   (clk), 
        .rst_i      (rst), 
        .wr_clk_en_i(1), 
        .rd_en_i    (1), 
        .rd_clk_en_i(1), 
        .wr_en_i    (wr_en), 
        .wr_data_i  (ram_data_wr), 
        .wr_addr_i  (ramaddr), 
        .rd_addr_i  (cnt_s), 
        .rd_data_o  (ram_data_rd) ) ;

reg [2:0]STATE;
localparam INIT = 0, 
           READ0= 1,
           READ1= 2,
           WR    =3,
           FINISH=4,
           RD_DATA = 5,
           RD_FINISH = 6;
           reg [127:0]data_d;
reg cal_finish;

always@(posedge clk or posedge rst) begin 
if(rst ) begin
    STATE <= 'd0;
    cnt_s <= 'd0;
    data_d<= 'd0;
    cal_finish <='d0;
    data_v<= 'd0;
    finish<='d0;
 end
else     begin
case(STATE)
INIT  :begin
    cal_finish <='d0;
    finish<='d0;
    data_v<= 'd0;
    if(spike_data_valid) begin 
        STATE<=READ0; 
        data_d <=spike_data;
     end
    else begin
        STATE<=INIT; 
        data_d <= 'd0;
     end
 end
READ0 :begin
    STATE <= READ1;
 end
READ1 :begin
    STATE <= WR;
 end
WR    :begin
   if(cnt_s < 'd127) begin
    cnt_s <= cnt_s + 'd1;
    STATE <= READ0;
    data_d<= data_d >>1;
    end
   else begin 
    cnt_s <= 0;
    STATE <= FINISH;
    data_d<= data_d;
   end
 end
FINISH:begin
    cal_finish <='d1;
    finish<='d0;
    if(cnt_num == 'd99) begin
        STATE <= RD_DATA;
        data_v<= 'd1;
     end
    else                begin
        STATE <= INIT;
        data_v<= 'd0;
     end
 end
 RD_DATA:begin
if(cnt_s < 'd127) begin cnt_s<= cnt_s + 'd1;STATE <=RD_DATA ; data_v<= 'd1; end
else              begin cnt_s<= 'd0;        STATE <=RD_FINISH;   data_v<= 'd0; end
  end
 RD_FINISH:begin
    STATE <= INIT;
    data_v<= 'd0;
    finish<='d1;
    cnt_s<='d0;
  end   
endcase
 end
end
wire zeros_cnt;
assign zeros_cnt = (cnt_num == 'd1)? 1:0;
always@(posedge clk or posedge rst) begin 
    if(rst) begin ram_data_wr<= 'd0; wr_en<='d0; end
    else begin 
    case(STATE) 
    WR:begin  if(zeros_cnt)begin ram_data_wr <=data_d[0]?0+'d1:0;  wr_en <= 1; end 
            else begin ram_data_wr <=data_d[0]?ram_data_rd+'d1:ram_data_rd;  wr_en <= 1;  end  end
    default:begin ram_data_wr <= ram_data_wr; wr_en <= 0; end
    endcase
end end
endmodule