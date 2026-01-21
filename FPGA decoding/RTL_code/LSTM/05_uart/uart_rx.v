`timescale 1ns / 1ps
//
// Company: 
// Engineer: 
// 
// Create Date: 2022/02/26 16:25:38
// Design Name: 
// Module Name: uart_rx_sim
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//


module uart_rx
#(parameter BPS=434)
(
input clk,
input rst_n,
input rs232_rx,
output wire valid_out,
output reg [7:0] recv_data = 0
    );
    localparam BPS_a = BPS/2;
parameter IDLE = 0;
parameter START = 1;
parameter RECV = 2;
parameter STOP =3;
//parameter BPS=5208;
//
reg sample_edge;
reg [2:0] cur_state;
reg [2:0] next_state;
reg [31:0] count;
reg [2:0] recv_cnt;                //0-7
reg rs232_rx_ff1;                  //检测到IDLE状态下tx信号拉低
//rs232_tx_ff1
always@(posedge clk)
   rs232_rx_ff1<=rs232_rx;
//
always@(posedge clk,negedge rst_n)
if(~rst_n)
    cur_state<=IDLE;
else
    cur_state<=next_state;
//
always@(*)
begin
    case(cur_state)
        IDLE:if(~rs232_rx&&rs232_rx_ff1)           //检测到下降沿
                 next_state=START;
             else
                 next_state=IDLE;
        START:if(count>=BPS-2)                      //检测到下降沿占去一个周期
                  next_state=RECV;
              else
                  next_state=START;
        RECV:if(recv_cnt>=8-1&&count>=BPS-1)
                  next_state=STOP;
             else
                  next_state=RECV;
        STOP:if(count>=BPS-1)
                 next_state=IDLE;
             else
                 next_state=STOP;
        default:next_state=IDLE;
    endcase
end
//count
always@(posedge clk,negedge rst_n)
if(~rst_n)
    count<=0;
else 
case(cur_state)
    IDLE:count<=0;
    START:if(count>=BPS-2)
             count<=0;
          else
             count<=count+1;
    RECV:if(count>=BPS-1)
             count<=0;
         else
             count<=count+1;
    STOP:if(count>=BPS-1)
             count<=0;
         else
             count<=count+1;
    default:count<=0;
endcase
//recv_cnt
always@(posedge clk,negedge rst_n)
if(~rst_n)
    recv_cnt<=0;
else if(cur_state==RECV&&count==BPS-1)
    recv_cnt<=recv_cnt+1;
else if(cur_state==STOP)
    recv_cnt<=0;
//sample_edge
reg sample_edge_d;
wire sample_flag = ~sample_edge_d&&sample_edge;
always@(posedge clk,negedge rst_n)
if(~rst_n)
   sample_edge<=0;
else if(cur_state==RECV&&count[31:2]==BPS_a[31:2])                //在数据最中间采用
   sample_edge<=1;
else
   sample_edge<=0;
//recv_data
always@(posedge clk)
if(cur_state==RECV&&sample_flag)
begin
    recv_data <= {rs232_rx,recv_data[7:1]};end
    else begin 

        recv_data<=recv_data;
    //case(recv_cnt)
    //    0:recv_data[0]<=rs232_rx;
    //    1:recv_data[1]<=rs232_rx;
    //    2:recv_data[2]<=rs232_rx;
    //    3:recv_data[3]<=rs232_rx;
    //    4:recv_data[4]<=rs232_rx;
    //    5:recv_data[5]<=rs232_rx;
    //    6:recv_data[6]<=rs232_rx;
    //    7:recv_data[7]<=rs232_rx;
    //    default:;
    // endcase
end
//valid
reg valid,valid_d,valid_dd;
always@(posedge clk,negedge rst_n)
if(~rst_n)
    valid<=0;
    
else if(cur_state==STOP)
    valid<=1;
else if(~rs232_rx&&rs232_rx_ff1&&cur_state==IDLE)
    valid<=0;
always@(posedge clk,negedge rst_n) begin 
if(~rst_n) begin 
    valid_d<=0;
    valid_dd <= 'd0;
    sample_edge_d<= 0;
end
else  begin valid_d<=valid; 
    valid_dd<= valid_d;
    sample_edge_d<= sample_edge;
end end
    assign valid_out = ~valid_dd&&valid_d;
endmodule

