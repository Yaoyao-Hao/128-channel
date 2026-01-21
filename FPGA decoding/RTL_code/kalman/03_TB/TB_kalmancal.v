`timescale 1ns / 1ps
module TB_kalmancal();



reg clk;
reg rst_n;

parameter N = 16;
reg start;

integer file_output;
integer file_handle;      // 文件句柄数组
integer j;//i, j;
integer val;                    
integer i;
integer temp;
initial clk = 0;
always #50 clk = ~clk;


//reg [31:0] matrix[0:N-1][0:N-1];  // 假设我们要读取 8 位的 96x96 矩阵
	initial begin
    file_output = $fopen("xxxxxxx/fpgaoutput.txt", "w"); // 打开文件以写入，w表示覆盖
/*
    
        file_handle = $fopen("D:/YCB/YCB/PROJECT/BCI2024/NeuralDecoding-master/A_Q_tb.txt", "r");
        if (file_handle == 0) begin
            $display("Failed to open A_Q_tb.txt");
            $finish;
        end
    // 初始化矩阵为 0
        // 按列填充 matrix[i][j]
        for (j = 0; j < N; j = j + 1) begin
            for (i = 0; i < N; i = i + 1) begin
                if (!$feof(file_handle)) begin
                    $fscanf(file_handle, "%d\n", temp);
                    matrix[i][j] = temp;
                end
                else begin
                    $display("File ended prematurely!");
                end
            end
        end

if (file_output  == 0) $display("Failed to open file0");


 $fclose(file_handle);
*/


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

reg [32*N-1:0]data;
wire      data_v;
    integer a;
// 如果你想发送成一个连续的向量，可组合：
reg [32*N-1:0] data_out;





 wire signed[32*2-1:0]data_o;
 wire           data_o_v;
assign data_v = (cnt>='d0&&cnt<=(N))?'d1:'d0;

wire [7:0]addr;
assign addr = cnt[7:0] - 'd1;
/*
always @(*) begin
    for (a = 0; a< N; a = a + 1)
        data_out[32*a +: 32] = matrix[a][cnt-1][31:0];
end

    LU_CAL_CON#(
          .DATA_Q (16),
          .Q_num  (16),
        .matrix_size  (N)
        
    )LU_cal_inst(
       .rst_i    (~rst_n),
       .clk_i    (clk),
       .addr     (addr),
       .DATA_in  (data_out),
       .DATA_in_v(data_v),
       .start_LU (start) ,
       .data_o     (data_o),
       .data_o_v     (data_o_v)
    
    );

 wire signed[32-1:0]data_wrfile_o;
 assign data_wrfile_o = data_o[47:16];


    always @(posedge clk) begin
    if (data_o_v) begin
       // $fwrite(file, "%h\n", data_o); // 写入16进制数据到文件
        // $fwrite(file, "%b\n", data_o); // 如果你希望写入二进制
         $fwrite(file_output, "%d\n", data_wrfile_o); // 写入十进制
    end
end
    */
parameter COL   = 96;
parameter ROW   = 96;
parameter DATA_W= 32;
reg signed[DATA_W*2-1:0]data_in;
reg [31:0]cnt_data;
reg [31:0]cnt_dataa;
wire [31:0]cnt_datab;
assign cnt_datab = cnt_dataa * 'd9216;
wire             cal_data_o_v;
wire [DATA_W-1:0]cal_data_o   ;
reg start_d,start_dd;
wire finsh_o;
reg cnt_data_d,cnt_data_dd,cnt_data_ddd;
always@(posedge clk or negedge rst_n)
begin 
    if(~rst_n) begin cnt_data <='d0; 
                data_in[31:0] <=  'd200587;
               data_in[63:32] <=  -'d676877;
               start_d <='d0;
               start_dd<='d0;
               cnt_data_d  <= 'd0; 
               cnt_data_dd <= 'd0; 
               cnt_data_ddd<= 'd0;
               cnt_dataa<='d0;
    end
    else       begin 
               start_d <=rst_n;
               start_dd<=start_d;

               cnt_data_d  <= finsh_o; 
               cnt_data_dd <= cnt_data_d; 
               cnt_data_ddd<= cnt_data_dd;
        
        if(finsh_o) begin cnt_dataa <=cnt_dataa + 'd1; end
        else begin cnt_dataa <=cnt_dataa; end

        if(cal_data_o_v) begin 
        cnt_data <=cnt_data + 'd1; 
        if(cnt_data[0]=='d0) begin  data_in[31:0]  <=  cal_data_o; end
        if(cnt_data[0]=='d1) begin  data_in[63:32] <= cal_data_o; end
    end
end
end
// assign data_in[31:0] =  'd200587;
// assign data_in[63:32] =  -'d676877;
wire [$clog2(COL) :0]cnt_b;
wire [DATA_W-1:0]Z_data;
wire [$clog2(COL*'d140) :0]cnt_b_adr;
assign cnt_b_adr = {{($clog2(COL*'d140)-$clog2(COL)){1'b0}},cnt_b + 'd96*cnt_dataa};
pmi_rom 
#(
  .pmi_addr_depth       (COL*'d140 ), // integer       
  .pmi_addr_width       ($clog2(COL*'d140) ), // integer       
  .pmi_data_width       (DATA_W ), // integer       
  .pmi_regmode          ("noreg" ), // "reg"|"noreg"     
  .pmi_resetmode        ("async"  ), // "async"|"sync"	
  .pmi_init_file        ("xxxxxxx/Z_test_Q.hex" ), // string		
  .pmi_init_file_format ("hex" ), // "binary"|"hex"    
  .pmi_family           ("common" )  // "common"
) pmi_rom_tt(
  .Address    (cnt_b_adr ),  // I:
  .OutClock   (clk ),  // I:
  .OutClockEn (1   ),  // I:
  .Reset      (~rst_n ),  // I:
  .Q          (Z_data )   // O:
);


wire  [$clog2(COL*COL)  :0]Address_rd_o;
wire start_in;
assign start_in = (start_d&&~start_dd) | (cnt_data_ddd);

wire  [$clog2(COL*COL*140)  :0]Address_rd;
assign  Address_rd = Address_rd_o + cnt_dataa*96*'d96;
wire [DATA_W-1:0]INV_TEST_DATA;

pmi_rom 
#(
  .pmi_addr_depth       (COL*COL*140 ), // integer       
  .pmi_addr_width       ($clog2(COL*COL*140) ), // integer       
  .pmi_data_width       (DATA_W ), // integer       
  .pmi_regmode          ("noreg" ), // "reg"|"noreg"     
  .pmi_resetmode        ("async"  ), // "async"|"sync"	
  .pmi_init_file        ("xxxxxxx/K_Q00_vector_wr_file.hex" ), // string		
  .pmi_init_file_format ("hex" ), // "binary"|"hex"    
  .pmi_family           ("common" )  // "common"
) pmi_rom_TEST_INV(
  .Address    (Address_rd ),  // I:
  .OutClock   (clk ),  // I:
  .OutClockEn (1   ),  // I:
  .Reset      (rst ),  // I:
  .Q          (INV_TEST_DATA )   // O:
);
  


kalman_Iteration_ldl
  #(
  .MAX_COL(COL),
  .MAX_ROW(ROW),  
  .DATA_W (DATA_W),
      .Q       (16))
   kalman_Iteration_inst
   (
     .clk  (clk),
     .rst  (~rst_n),
     .start( start_in),
     .cnt_b_o(cnt_b),
     .Z_in   (Z_data),
     .data_in(data_in),
     .finsh_o(finsh_o),
     .Address_rd(Address_rd_o),
     //.INV_TEST_DATA(INV_TEST_DATA),
     .cal_data_o_v(cal_data_o_v),
     .cal_data_o  (cal_data_o)  


   );
    always @(posedge clk) begin
    if (cal_data_o_v&&cnt_data[0]=='d0) begin
       // $fwrite(file, "%h\n", data_o); // 写入16进制数据到文件
        // $fwrite(file, "%b\n", data_o); // 如果你希望写入二进制
         $fwrite(file_output, "%d\n", $signed(cal_data_o)); // 写入十进制
         end
     else if (cal_data_o_v&&cnt_data[0]=='d1) begin
       // $fwrite(file, "%h\n", data_o); // 写入16进制数据到文件
        // $fwrite(file, "%b\n", data_o); // 如果你希望写入二进制
         $fwrite(file_output, "%d\n", $signed(cal_data_o)); // 写入十进制
         end
    else if(cnt_dataa=='d140) begin 
      $display("Stop sim!");
      $fclose(file_handle);
      $stop;
    end
    end


endmodule