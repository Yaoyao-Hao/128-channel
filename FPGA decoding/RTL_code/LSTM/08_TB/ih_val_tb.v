`timescale 1ns / 1ps







module ih_cal_tb();

GSR GSR_INST( .GSR_N(1'b1), .CLK(1'b0));

reg clk;
reg clk_200m;
reg rst_n;

initial begin  
clk = 0;
clk_200m = 0;end
	always #10 clk = ~clk;
	always #2 clk_200m = ~clk_200m;
	initial begin
		rst_n = 1;
		#200;
		rst_n = 0;
		#390;
		rst_n = 1;
		//$stop;
	end

reg [23:0]test_data;
reg [31:0]cnt;

wire data_read;
reg data_valid;
always@(posedge clk)
 begin
     if(~rst_n) begin 
        cnt <= 'd0;
        data_valid <= 'd0;
     end
     else begin 
        cnt <= cnt + 1;
        data_valid <= data_read;
     end
 end


//assign data_valid = &cnt[20:0];
always@(posedge clk)
 begin
     if(~rst_n) begin 
        test_data <= 'd0;
        
     end
     else if(data_valid) begin 
        test_data <= test_data + 1;
     end
     else begin
        test_data <= test_data ;
     end
 end


localparam PARALL_NUM = 8;
wire [15:0]data_out;
reg [31:0]cnt_read;


localparam hidden_size = 512; //隐藏层特征数)
localparam ADDR_WIDTHBIAS = $clog2(hidden_size*4);

wire fifo_ready_r;
wire [ADDR_WIDTHBIAS-1:0]cnt_hidden_size0;
wire [16*4-1:0]bias_gate;
wire rd_weight_en;
wire weight_out_valid;
wire [24*4-1:0]weight_out;



wire fifo_ready;


wire [8-1:0]weight_out_fc;
wire fifo_ready_fc;
wire rd_en_fc;
localparam output_size = 2;
localparam OS_W = $clog2(output_size)+1;
wire [OS_W-1:0]fc_bais_adr;
wire  [16-1:0]fc_bais_data;
wire  [ADDR_WIDTHBIAS-1:0]h_rd_adr_i;
wire [8:0]fc_w_adr;
LSTM
 #(
.DEBUG(1),

 .input_size       (96), //输入特征数
 .hidden_size      (512), //隐藏层特征数
 .num_layers       (1), //LSTM层数
 .output_size      (output_size) , //输出类别数
 .batch_size       (1), //批大小
 .sequence_length  (140), //序列长度
 .PARALL_NUM       (1),//并行计算规模 必须为2的倍数

.QZ_R(8),//整数部分量化
.QZ_D(16),//小数部分量化
 .QZ(16+8) //数据量化位宽
 )uu
 (
 .clk            (clk)  ,
 .clk_200m       (clk_200m),
 .rst_n          (rst_n)  ,
 .start          (1'b1)  , //开始计算
 .data_in        ({PARALL_NUM{24'd32768}})  ,
 .data_in_valid  (data_valid)  ,
 .data_read(data_read),
 .fifo_ready_w(fifo_ready),

//.wr_fifo_data_valid(valid),
//.wr_fifo_data(data_out),

 .fc_w_adr(fc_w_adr),
.fifo_ready_r(fifo_ready_r),
.fifo_ready_fc(fifo_ready_fc),
.cnt_hidden_size0(cnt_hidden_size0),
.bias_gate(bias_gate),
.rd_weight_en(rd_weight_en),
.rd_weight_fc(rd_en_fc),
.weight_out_valid(weight_out_valid),
.weight_out_fc(weight_out_fc),
.weight_out(weight_out),
.fc_bais_adr(fc_bais_adr),
.h_rd_adr_i(h_rd_adr_i),
.fc_bais_data(fc_bais_data)
 //    input [QZ-1: 0]ad
 );


 weight_save
 #(.QZ(16),
   .input_size( 96), //输入特征数
   .output_size      (output_size) , //输出类别数
   .hidden_size (512)

  )weight_save_inst//隐藏层特征数)
 (
   .clk_200m(clk_200m),
   .user_clk(clk),//user_clk_50),
   .rst(~rst_n),

   .wr_fifo_data_valid(valid),
   .wr_fifo_data(data_out),
   .addr_rd_h(fc_w_adr[8:0]),
//.addr_rd_h(h_rd_adr_i),
   .wr_ram_valid(),
   .wr_ram_data(),
   .fifo_ready_r(fifo_ready_r),
   .fifo_ready_fc(fifo_ready_fc),
   .fifo_ready(fifo_ready),
   .cnt_hidden_size0(cnt_hidden_size0),
   .bias_gate(bias_gate),
   .weight_out(weight_out),
   .weight_out_valid_o(weight_out_valid),

.uart_data(uart_data),
.weight_out_fc(weight_out_fc),

   .rd_en(rd_weight_en),//(rd_weight_en),
   .rd_en_fc(rd_en_fc),
   .fc_bais_adr(fc_bais_adr),
  .fc_bais_data(fc_bais_data)



 );
/*
 ah_cal uuad
 (
 .clk          (clk)    ,
 .rst_n        (rst_n)    ,
 .ahcal_busy   (0)    , //ah计算忙
 .start        (1)    , //开始计算LSTM
 .whh          ('d32)    ,
 .whh_valid    (&cnt[3:0])    ,
 .data_in      ('d32)    ,
 .new_cal      (&cnt[25:0])  //开始新的求和计算
 
 
 );
*/
localparam num_data = (96*512*4+512*512*4);

assign valid = fifo_ready;

always@(posedge clk_200m)
 begin
     if(~rst_n) begin 
      cnt_read <= 'd0;
        
     end
     else if(fifo_ready) begin 
      if(cnt_read>num_data/2-2) begin cnt_read <= 0; end
         else begin cnt_read <= cnt_read + 1; end 
      
     end
     else begin
      cnt_read <= cnt_read ;
     end
 end

 test_weight
 #(
    .DEBUG (1),

    .col(512),
    .cow(96),
    .QZ(16) //数据量化位宽

  )test_weight_inst
  (
    .addr_wih(cnt_read),
   .weight_out_wih(data_out)


  );

wire htvalid;
assign htvalid = (&cnt[3:0])?1:0;


endmodule