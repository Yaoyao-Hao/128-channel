`timescale 1ns / 1ps
module TB_LUcal();



reg clk;
reg rst_n;
integer file0,file1,file2,file3,file4,file5,file6,file7,file8,file9,file10;           // 文件句柄
integer file11,file12,file13,file14,file15;
integer file1_winere;
integer file1_winere_data;
integer i, j;

reg [15:0]val0 ;
reg [15:0]val1 ;
reg [15:0]val2 ;
reg [15:0]val3 ;
reg [15:0]val4 ;
reg [15:0]val5 ;
reg [15:0]val6 ;
reg [15:0]val7 ;
reg [15:0]val8 ;
reg [15:0]val9 ;
reg [15:0]val10 ;
reg [15:0]val11 ;
reg [15:0]val12 ;
reg [15:0]val13 ;
reg [15:0]val14 ;
reg [15:0]val15 ;


reg start;
 reg [7:0] matrix[0:15][0:15];  // 假设我们要读取 8 位的 16x16 矩阵
reg [15:0] matrix_w[167:0];
reg [15:0] wiener_cal_data[10000:0];
initial clk = 0;
	always #5 clk = ~clk;

	initial begin
    file0 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_1.txt", "r");
    file1 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_2.txt", "r");
    file2 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_3.txt", "r");
    file3 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_4.txt", "r");
    file4 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_5.txt", "r");
    file5 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_6.txt", "r");
    file6 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_7.txt", "r");
    file7 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_8.txt", "r");
    file8 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_9.txt", "r");
    file9 =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_10.txt", "r");
    file10 = $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_11.txt", "r");
    file11 = $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_12.txt", "r");
    file12 = $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_13.txt", "r");
    file13 = $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_14.txt", "r");
    file14 = $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_15.txt", "r");
    file15 = $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/output_16.txt", "r");
    file1_winere =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/wiener_coefficient.txt", "r");
    if (file1_winere  == 0) $display("Failed to open file1_winere");
    file1_winere_data =  $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/X_q.txt", "r");
    if (file1_winere_data  == 0) $display("Failed to open file1_winere_data");
    // if (file0  == 0) $display("Failed to open file0");
    // if (file1  == 0) $display("Failed to open file0");
    // if (file2  == 0) $display("Failed to open file0");
    // if (file3  == 0) $display("Failed to open file0");
    // if (file4  == 0) $display("Failed to open file0");
    // if (file5  == 0) $display("Failed to open file0");
    // if (file6  == 0) $display("Failed to open file0");
    // if (file7  == 0) $display("Failed to open file0");
    // if (file8  == 0) $display("Failed to open file0");
    // if (file9  == 0) $display("Failed to open file0");
    // if (file10 == 0) $display("Failed to open file0");
    // if (file11 == 0) $display("Failed to open file0");
    // if (file12 == 0) $display("Failed to open file0");
    // if (file13 == 0) $display("Failed to open file0");
    // if (file14 == 0) $display("Failed to open file0");
    // if (file15 == 0) $display("Failed to open file0");


//     for (i = 0; i < 16; i = i + 1) begin
//         //从文件中读取一个整数，存入 matrix[i][j]
//         matrix[0][i] = 'd0;
//         matrix[1][i] = 'd0;
//         matrix[2][i] = 'd0;
//         matrix[3][i] = 'd0;
//         matrix[4][i] = 'd0;
//         matrix[5][i] = 'd0;
//         matrix[6][i] = 'd0;
//         matrix[7][i] = 'd0;
//         matrix[8][i] = 'd0;
//         matrix[9][i] = 'd0;
//         matrix[10][i]= 'd0;
//         matrix[11][i]= 'd0;
//         matrix[12][i]= 'd0;
//         matrix[13][i]= 'd0;
//         matrix[14][i]= 'd0;
//         matrix[15][i]= 'd0;
// end
for (i = 0; i < 168; i = i + 1) begin
    //从文件中读取一个整数，存入 matrix[i][j]
    matrix_w[i] <='d0;
end
for (i = 0; i < 38220; i = i + 1) begin
    //从文件中读取一个整数，存入 matrix[i][j]
    wiener_cal_data[i] <='d0;
end
      //  逐行读取文件内容到矩阵中
    for (i = 0; i < 16; i = i + 1) begin
          //从文件中读取一个整数，存入 matrix[i][j]
$fscanf(file0 , "%d", val0 );
$fscanf(file1 , "%d", val1 );
$fscanf(file2 , "%d", val2 );
$fscanf(file3 , "%d", val3 );
$fscanf(file4 , "%d", val4 );
$fscanf(file5 , "%d", val5 );
$fscanf(file6 , "%d", val6 );
$fscanf(file7 , "%d", val7 );
$fscanf(file8 , "%d", val8 );
$fscanf(file9 , "%d", val9 );
$fscanf(file10, "%d", val10);
$fscanf(file11, "%d", val11);
$fscanf(file12, "%d", val12);
$fscanf(file13, "%d", val13);
$fscanf(file14, "%d", val14);
$fscanf(file15, "%d", val15);
          matrix[0][i] = val0 ;
          matrix[1][i] = val1 ;
          matrix[2][i] = val2 ;
          matrix[3][i] = val3 ;
          matrix[4][i] = val4 ;
          matrix[5][i] = val5 ;
          matrix[6][i] = val6 ;
          matrix[7][i] = val7 ;
          matrix[8][i] = val8 ;
          matrix[9][i] = val9 ;
          matrix[10][i]= val10;
          matrix[11][i]= val11;
          matrix[12][i]= val12;
          matrix[13][i]= val13;
          matrix[14][i]= val14;
          matrix[15][i]= val15;
  end
#10
for (i = 0; i < 168; i = i + 1) begin
    //从文件中读取一个整数，存入 matrix[i][j]
    $fscanf(file1_winere , "%d", val0 );
    matrix_w[i] = val0 ;
end
for (i = 0; i < 10000; i = i + 1) begin
    //从文件中读取一个整数，存入 matrix[i][j]
    $fscanf(file1_winere_data , "%d", val1 );
    wiener_cal_data[i] = val1 ;
end
// $fclose(file1_winere);
  //关闭文件
//   $fclose(file0 );
//   $fclose(file1 );
//   $fclose(file2 );
//   $fclose(file3 );
//   $fclose(file4 );
//   $fclose(file5 );
//   $fclose(file6 );
//   $fclose(file7 );
//   $fclose(file8 );
//   $fclose(file9 );
//   $fclose(file10);
//   $fclose(file11);
//   $fclose(file12);
//   $fclose(file13);
//   $fclose(file14);
//   $fclose(file15);


  start = 0;
		rst_n = 1;
		#20;
		rst_n = 0;
		#40;
		rst_n = 1;
        #100000
        start = 1;
		//$stop;
	end

reg [31:0]cnt;
always@(posedge clk or negedge rst_n)
 begin 
  if(~rst_n) begin
    cnt <= 'd0;
   end
  else begin      
    cnt <= cnt + 'd1;
   end
 end

reg [16-1:0]data;
reg      data_v;
always@(*)
 begin 
if(~rst_n) begin
    data <= 'd0;
    data_v<= 'd0;
 end
else       begin
 if(cnt >= 'd1&&cnt <= 'd168) begin     
    data <= matrix_w[cnt - 1];
    data_v<= 'd1; end
 else   begin      
    data <= 'd0;
    data_v<= 'd0; end
 end
 end


reg [31:0]cnt_wr_t;
reg wr_d,wr_dd;
reg wr;
wire start_cl;
 always@(posedge clk or negedge rst_n)
 begin 
  if(~rst_n) begin
    cnt_wr_t <= 'd0;
    wr_d <= 'd0;
    wr_dd <= 'd0;
   end
  else begin      
    cnt_wr_t <= cnt_wr_t + 'd1;
    wr_d <= wr;
    wr_dd <= wr_d;
   end
 end
  wire start_cal;
  reg [31:0]add_w;
  assign start_cal = (&cnt_wr_t[12:0])?1:0;
  reg [2:0]state = 0 ;
  assign start_cl = ~wr_d&&wr_dd;
  
  always@(posedge clk) begin 
    case(state)
     'd0: begin 
        if(start_cal) begin state <= 'd1; end else begin state <= 'd0; end
        add_w <= 'd0;
        wr  <= 'd0;
    end
     'd1: begin
        wr  <= 'd1;
        if(add_w < 'd42 - 'd1) begin add_w <= add_w + 'd1; state <= 'd1; end else begin add_w <= 'd42; state <= 'd2; end
      end
     'd2: begin
        wr  <= 'd0;
        state <= 'd0;
      end 
    endcase
  end
  
reg [31:0]chose_data;
  always@(posedge clk or negedge rst_n)
  begin 
   if(~rst_n) begin
    chose_data <= 'd0;
    end
   else begin   
    if(start_cl)   begin chose_data <= chose_data + 'd1; end
    else begin chose_data <= chose_data; end
    end
  end
        wire wr_ram_en;
        reg wr_ram_en_d,wr_ram_en_dd;
        reg [16:0]addr11;
  always@(posedge clk or negedge rst_n)
  begin 
   if(~rst_n) begin
    addr11 <= 'd0;
    wr_ram_en_d <='d0;
    wr_ram_en_dd<='d0;
    end
   else begin   
        wr_ram_en_d <=wr_ram_en;
    wr_ram_en_dd<=wr_ram_en_d;
    if(wr_ram_en)   begin addr11 <= addr11 + 'd1; end
    else begin addr11 <= addr11; end
    end
  end

wire [15:0]data_in;
assign data_in = wiener_cal_data[addr11];//[chose_data*42+add_w-'d1];

wire [7:0]addr;
assign addr = cnt[7:0] - 'd1;
    // LU_cal#(
    //     .DATA_WIDTH   (16),
    //     .matrix_size  (16)
        
    // )LU_cal_inst(
    //    .rst_i    (~rst_n),
    //    .clk_i    (clk),
    //    .addr     (addr),
    //    .DATA_in  (data),
    //    .DATA_in_v(data_v),
    //    .start_LU (start) 
    
    // );
wire [31:0]cnt_wr_t0;
assign cnt_wr_t0 = cnt_wr_t - 'd1;
        assign wr_ram_en = (cnt_wr_t0[11:0]<='d95)?1:0;


wire start_c;
assign start_c = ~wr_ram_en_d&&wr_ram_en_dd;

Wienerfilter
#(
    .WIDTH   (16),
    .COL_NUM (96),
    .ROW_NUM (2)

)
Wienerfilter_inst
(
.clk         (clk),
.rst         (~rst_n),
.start       (start_c),
.finish_cal_o(),
.wr_addr     (0),
.ram_wr_en   (0),
.ram_data_in (0),

.wr_data_addr  ({10'd0,addr11[6:0]}),
.ram_wr_data_en(wr_ram_en),
.ram_data_wr_in(data_in)
) ;


endmodule