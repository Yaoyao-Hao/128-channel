`timescale 1ns / 1ps
module wiener_data_ready
(
    input [31:0]data_num,//单通道1ms数据量 

    input clk,
    input rst,
    input[63:0]data_in,
    input data_valid,
    output reg data_v,
    output reg finish,
    output reg[15:0]cnt_s_o,
    output [7:0]ram_data_rd_o
);

//wire [7:0]ram_data_rd;
//assign ram_data_rd_o = ram_data_rd;
reg  [7:0]ram_data_wr = 'd0;
reg [7:0]cnt_s;
reg [7:0]ramaddr;
reg wr_en;
reg [31:0]cnt_num;
//assign cnt_s_o = cnt_s;
reg start_wiener;
always@(posedge clk or posedge rst) begin 
    if(rst) begin cnt_num<= 'd0; ramaddr<='d0; start_wiener <= 'd0; end
    else begin
        ramaddr<=#1 cnt_s;
        if(data_valid) begin cnt_num<= (cnt_num=={data_num[28:0],3'd0} - 'd1)?'d0:cnt_num + 'd1;
                             start_wiener <= (cnt_num=={data_num[30:0],1'd0})?'d1:'d0;
        end
        else begin cnt_num<= cnt_num; 
            start_wiener  <= 'd0;
end
    end
end


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
   // data_v<= 'd0;
    finish<='d0;
 end
else     begin
case(STATE)
INIT  :begin
    cal_finish <='d0;
    
    //data_v<= 'd0;
    if(start_wiener) begin 
        STATE<=RD_FINISH; 
        finish<='d0;
     end
    else begin
        STATE<=INIT; 
        finish<='d0;
     end
 end
 RD_FINISH:begin
    STATE <= INIT;
    //data_v<= 'd0;
    finish<='d1;
    cnt_s<='d0;
  end   
endcase
 end
end
wire [31:0]cnt_num0;
assign cnt_num0 = cnt_num - 'd4;
reg [3:0]data_in_v;
always@(posedge clk or posedge rst) begin 
    if(rst) begin data_in_v<= 'd0;  end
    else begin
        data_in_v <= {data_in_v[2:0],data_valid};
         end
    end
reg [2:0]addr_3;
always@(posedge clk)
 begin 
    case(data_in_v)
     4'b0001:begin addr_3 <= 3'd0; data_v <= (|cnt_num0[31:5])? 0:1; cnt_s_o <= data_in[15:0]; end
     4'b0010:begin addr_3 <= 3'd1; data_v <= (|cnt_num0[31:5])? 0:1; cnt_s_o <= data_in[15+16:0+16]; end
     4'b0100:begin addr_3 <= 3'd2; data_v <= (|cnt_num0[31:5])? 0:1; cnt_s_o <= data_in[15+32:0+32]; end
     4'b1000:begin addr_3 <= 3'd3; data_v <= (|cnt_num0[31:5])? 0:1; cnt_s_o <= data_in[15+48:0+48]; end
     default:begin addr_3 <= 3'd0; data_v <= (|cnt_num0[31:5])? 0:0; cnt_s_o <= 0; end
    endcase
 end

assign ram_data_rd_o = {addr_3,cnt_num0[4:0]};
endmodule