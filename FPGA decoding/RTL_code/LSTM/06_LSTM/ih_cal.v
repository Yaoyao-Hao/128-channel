`timescale 1ns / 1ps
module ih_cal
#(
parameter input_size = 1, //输入特征数
parameter hidden_size = 1, //隐藏层特征数
parameter num_layers = 1, //LSTM层数
parameter output_size = 1, //输出类别数
parameter batch_size = 1, //批大小
parameter sequence_length = 1, //序列长度


parameter WIDTH_CNT = $clog2(input_size)+1,  //输入特征累加防止溢出
parameter QZ = 24, //数据量化位


parameter QZ_R = 8,
parameter QZ_D = 16,
parameter DATA_WITCH =  WIDTH_CNT + QZ,
//计算余数与所需并行计算次数  余数将使最后一次并行计算包含0值
parameter PARALL_NUM = 10 ,//并行计算规模 必须为2的倍数
parameter INPUTSIZE = input_size/PARALL_NUM,
parameter REMAINDER = input_size - INPUTSIZE * PARALL_NUM // 计算余数
)
(
    input clk,
    input rst_n,
    input start, //开始计算
    
    input [ PARALL_NUM*QZ-1: 0 ]data_in,
    input data_in_valid,
    input [PARALL_NUM *QZ-1: 0 ]wih,


    output [QZ*2*4-1:0]sumout_m,
    output sumout_m_valid
//    input [QZ-1: 0]ad
);


wire [PARALL_NUM *QZ*2-1: 0]mult_out;
wire [PARALL_NUM *QZ*2-1: 0]ad_data;

reg [PARALL_NUM *QZ*2-1: 0]ad_data_s;



genvar i;

    

////////////打拍时序对齐
reg [4:0]valid_d;
always@(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin 
        valid_d <= 'd0;
    end else begin 
        valid_d <= {valid_d[3:0],data_in_valid};
        end
    end
wire mult_valid;//乘法器输出
wire add_valid;//累加输出有效
assign mult_valid = valid_d[4];
assign add_valid  = valid_d[4];
wire [(QZ+8)*4:0]mult248_out;
generate
    for (i=0;i<PARALL_NUM;i=i+1) begin: multaa
/*
    mult24x24 datamult1(
        .clk_i    (clk)     , 
        .clk_en_i (1'b1)   , 
        .rst_i    (~rst_n) , 
        .data_a_i (data_in[QZ*(i+1)-1:QZ*(i)])  , 
        .data_b_i (wih[QZ*(i+1)-1:QZ*(i)] )   , 
        .result_o (mult_out[2*QZ*(i+1)-1:2*QZ*(i)]  ) );
*/
      /*  MULT24X8 datamult24X8(
       .data_a_i(data_in[QZ*(i+1)-1:QZ*(i)]), 
       .data_b_i(wih[QZ*(i+1)-1-8:QZ*(i)+8]), 
       .result_o(mult248_out[(QZ+8)*(i+1)-1:(QZ+8)*(i)])) ;*/
       mult24x8t datamult24X8(
        .clk_i(clk), 
        .clk_en_i(1'b1), 
        .rst_i(~rst_n), 
        .data_a_i(data_in[QZ*(i+1)-1:QZ*(i)]), 
        .data_b_i(wih[QZ*(i+1)-1-8:QZ*(i)+8]),//[QZ*i-1:QZ*(i-1)]), 
        .result_o(mult248_out[(QZ+8)*(i+1)-1:(QZ+8)*(i)])) ;
assign mult_out[QZ*2*(i+1)-1:QZ*2*(i)] = {{8{mult248_out[(QZ+8)*(i+1)-1]}},mult248_out[(QZ+8)*(i+1)-1:(QZ+8)*(i)],8'd0};



    end
    
wire [7:0]test_wih; assign test_wih = wih[15:8];
wire [23:0]test_data_in;assign test_data_in = data_in[23:0];

    
    
    endgenerate
reg [PARALL_NUM *QZ*2-1: 0]data_save;
always@(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        data_save <= 'd0;
    end else begin
     if(mult_valid) begin 
        data_save <= mult_out;
    end
     else begin
        data_save <= data_save>>QZ*2;
     end
    end
end
reg [PARALL_NUM *QZ*2-1: 0]data_save_i;//移位寄存器
reg [7:0]add_cau_cnt;////计算并行数组和
reg SUMCAL;//求和指示
reg add_out_valid;//数组和输出
always@(posedge clk or negedge rst_n)
begin
    if(~rst_n) begin
        add_cau_cnt <= 'd0;
        add_out_valid <= 'd0;
    end else if(SUMCAL) begin
        if(add_cau_cnt >= PARALL_NUM-1) begin 
        add_cau_cnt <= 0;
        add_out_valid <= 'd1;
        end else begin
        add_cau_cnt <= add_cau_cnt + 1;    
        add_out_valid <= 'd0;
        end
     end
     else begin
        add_cau_cnt <= 0;    
        add_out_valid <= 'd0;      
        end
end

localparam INIT = 0,
           CAL  = 1,
           SUM  = 2,
           FINISH = 3;
reg [3:0]STATE;
reg [QZ*2-1:0]SUMOUT;//输出计算和
reg SUMOUT_valid;
wire [QZ*2-1:0]ADD_DATA;
assign ADD_DATA =data_save;// {{QZ_D{data_save[QZ*2-1]}},data_save[QZ*2-1:QZ_D]};
always@(posedge clk or negedge rst_n)
 begin 
  if(~rst_n) begin 
    STATE <= INIT;
    SUMOUT <= 'd0;
    SUMOUT_valid <= 'd0;
    SUMCAL <='d0;
end
  else begin 
   case(STATE) 
     INIT:begin 
       if(mult_valid) begin STATE <= FINISH; SUMCAL <='d1; end
       else      begin STATE <= INIT; SUMCAL <='d0;end
        SUMOUT <= 'd0;
        SUMOUT_valid <= 'd0;
     //   SUMCAL <='d0;
     end

     SUM:begin 
        if(add_out_valid) begin STATE <= FINISH; SUMCAL <='d0;end
        else           begin STATE <= SUM; SUMCAL <=SUMCAL;end     
        SUMOUT <= SUMOUT + ADD_DATA;//data_save[QZ*2-1:0];
        SUMOUT_valid <= 'd0;
        //SUMCAL <='d0;   
     end
     FINISH:begin 
        SUMOUT_valid <= 'd1;
        SUMOUT <= SUMOUT;
        STATE <= INIT;
        SUMCAL <= 0;
     end            
   endcase
end
 end
assign sumout_m = mult_out;//{{QZ_D{SUMOUT[QZ*2-1]}},SUMOUT[QZ*2-1:QZ_D]};
assign sumout_m_valid = mult_valid;
/*
    ramdata
    #(
        .addr_width($clog2(hidden_size*4)),
        .data_width(QZ*2),
        .data_deepth(hidden_size*4),
        .INITdata('d0)
    )ramdatau_h
    (
       .clka(clk),
       .clkb(clk),
       .rst_n(rst_n),
       .cs(1),
        //wr
        .wr_addr(h_rd_adr),
        .wr_data(ram_data_in_ah),
        .wr_en(ram_wr_valid_ah),
        //rd
        .rd_addr(h_rd_adr_i),
        .rd_en(1),
        .rd_data(ram_data_out_ah)
        );*/
endmodule