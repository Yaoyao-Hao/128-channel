`timescale 1ns / 1ps
//
// Company: 
// Engineer: 
// 
// Create Date: 2022/02/26 15:27:26
// Design Name: 
// Module Name: uart_tx_sim
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


module uart_tx
#(parameter BPS=434)
(
input clk,
input rst_n,
input start,
input [7:0] send_data,
output reg rs232_tx,
output reg tx_ready
    );

//
// parameter BPS=5208;          //计算传输一次的计数时间：
//                              //计数时间 = 1000000000ns/9600 = 104166.7ns
//                              //50MHz的时钟周期为20ns,所以计数传输一个比特的次数为104166.7 / 20 = 5208
parameter IDLE = 0;
parameter START = 1;      //起始位
parameter SEND = 2;       //8bit数据发送,最低位开始传送，靠时钟定位。
parameter STOP =3;        //停止位
reg [2:0] cur_state;
reg [2:0] next_state;
reg [31:0] count;         //计数器
reg [31:0] send_cnt;      //发送bit计数器
//三段式状态机
always@(posedge clk,negedge rst_n)
if(~rst_n)
    cur_state<=IDLE;
else
    cur_state<=next_state;
//
always@(*)
case(cur_state)
    IDLE:if(start)
             next_state=START;
         else
             next_state=IDLE;
    START:if(count==BPS-1)
             next_state=SEND;
          else
             next_state=START;
    SEND:if(send_cnt==8-1&&count==BPS-1)
             next_state=STOP;
         else
             next_state=SEND;
    STOP:if(count==BPS-1)
             next_state=IDLE;
         else
             next_state=STOP;
    default:next_state=IDLE;
endcase
//count
always@(posedge clk,negedge rst_n)
if(~rst_n)
    count<=0;
else if(cur_state!=IDLE)
begin
    if(count==BPS-1)
        count<=0;
    else
        count<=count+1;
end
else
    count<=0;
//send_cnt
always@(posedge clk,negedge rst_n)
if(~rst_n)
    send_cnt<=0;
else if(cur_state==SEND&&count==BPS-1)
    send_cnt<=send_cnt+1;
else if(cur_state!=SEND)
    send_cnt<=0;
//rs232_tx
always@(*)
case(cur_state)
    IDLE: begin rs232_tx=1; tx_ready = 1; end
    START:begin rs232_tx=0; tx_ready = 0; end
    SEND:begin
         case(send_cnt)
            0:rs232_tx=send_data[0];
            1:rs232_tx=send_data[1];
            2:rs232_tx=send_data[2];
            3:rs232_tx=send_data[3];
            4:rs232_tx=send_data[4];
            5:rs232_tx=send_data[5];
            6:rs232_tx=send_data[6];
            7:rs232_tx=send_data[7];
            default:rs232_tx=1;
        endcase
    end
    STOP:rs232_tx=1;
    default:rs232_tx=1;
endcase
endmodule

