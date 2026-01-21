`timescale 1ns / 1ps
module uart_loop_tb(
  );
  GSR GSR_INST( .GSR_N(1'b1), .CLK(1'b0));
  reg clk_sys;
  reg rst_n;
  reg uart_in;
  wire uart_out;
  wire parity;

  localparam BAUD_RATE = 115200;
  localparam PARITY_ON = 0;
  localparam PARITY_TYPE = 1;
  /*
  uart_loop u_uart_loop(
      .i_clk_sys(clk_sys),
      .i_rst_n(rst_n),
      .i_uart_rx(o_uart_tx),
      .o_uart_tx(uart_out),
      .o_ld_parity(parity)
      );*/
  integer file0,file1,file2,file3;
  integer temp0,temp1,temp2,temp3;
  integer i;
  genvar j;
  localparam length_wih = 64*64*4+32*64;
  reg [8-1:0]mem_wih[0:64*64*4+32*64-1];
  initial
  begin
    clk_sys = 1'b0;
    rst_n = 1'b0;
    uart_in = 1'b1;
    file0 = $fopen("XXXXXXX/tz_test.txt","r");
    for(i=0 ; i <= length_wih ; i=i+1)
    begin
      temp0 = $fscanf(file0,"%d",mem_wih[i+1]); //每次读取一个数据，以空格或回车以及tab为区分。
    end
  end

  always #1 clk_sys = ~clk_sys;
  wire tx_byte_over;

  localparam ELEMENT_TIME = 104160/12;
  reg [7:0] DATA = 8'hAC;

  initial
  begin
    #100 rst_n = 1'b0;
    #200 rst_n = 1'b1;

    uart_in = 1'b0;
    #ELEMENT_TIME
     uart_in = DATA[0];
    #ELEMENT_TIME
     uart_in = DATA[1];
    #ELEMENT_TIME
     uart_in = DATA[2];
    #ELEMENT_TIME
     uart_in = DATA[3];
    #ELEMENT_TIME
     uart_in = DATA[4];
    #ELEMENT_TIME
     uart_in = DATA[5];
    #ELEMENT_TIME
     uart_in = DATA[6];
    #ELEMENT_TIME
     uart_in = DATA[7];
    #ELEMENT_TIME
     uart_in = 1'b1;
    #ELEMENT_TIME
     uart_in = 1'b1;

  end
  /*
  hyperRam_top_v2 uhyperRam_top_v2(
                    . i_ref_50m    (clk_sys),
                    . o_hram_clk   (),
                    . o_hram_csn   () ,
                    . o_hram_resetn(),
                    . io_hram_rwds (),
                    . io_hram_dq   (),
                    . file_length  ('d32768));
*/
  wire tx_ready;
  wire [7:0]w_data;
wire rs232;
reg tx_valid_d,tx_valid_dd;
  /*
  LSTM_TOP uLSTM_TOP(
   
      .clk       (clk_sys),
      .rst_n     (rst_n),
      .i_uart_rx (rs232),
      . o_uart_tx()
   
    );
 */
 localparam DATA_WIDTH = 8;

 uart_rx_a
 #(
   .CLK_FRE(50),         //时钟频率，默认时钟频率为50MHz
   .DATA_WIDTH(DATA_WIDTH),       //有效数据位，缺省为8位
   .PARITY_ON(PARITY_ON),        //校验位，1为有校验位，0为无校验位，缺省为0
   .PARITY_TYPE(PARITY_TYPE),      //校验类型，1为奇校验，0为偶校验，缺省为偶校验
   .BAUD_RATE(BAUD_RATE)      //波特率，缺省为9600
 ) u_uart_rx
 (
   .i_clk_sys(clk_sys),      //系统时钟
   .i_rst_n(rst_n),        //全局异步复位,低电平有效
   .i_uart_rx(o_uart_tx),      //UART输入
   .o_uart_data(),    //UART接收数据
   .o_ld_parity(o_ld_parity),    //校验位检验LED，高电平位为校验正确
   .o_rx_done()       //UART数据接收完成标志
 );
wire rden;
reg [31:0]cnt;
reg [31:0]data_v;
wire t;
reg t_d;
assign t =~data_v[31]&&data_v[30];
reg [7:0]data_out;

reg w_rx_done;
uart_tx_a
 #(
   .CLK_FRE(50),         //时钟频率，默认时钟频率为50MHz
   .DATA_WIDTH(),       //有效数据位，缺省为8位
   .PARITY_ON(),        //校验位，1为有校验位，0为无校验位，缺省为0
   .PARITY_TYPE(),      //校验类型，1为奇校验，0为偶校验，缺省为偶校验
   .BAUD_RATE()      //波特率，缺省为9600
 ) u_uart_tx
 (   .i_clk_sys(clk_sys),      //系统时钟
     .i_rst_n(rst_n),        //全局异步复位
     .i_data_tx(data_out),//(w_data),      //传输数据输入
     .i_data_valid(w_rx_done),//(data_out_valid_d),//(w_rx_done),   //传输数据有效
     .o_uart_tx(o_uart_tx)  ,     //UART输出
     .tx_ready(tx_ready)
 );
         wire Trans_Done_d;
reg tx_ready_d;
         assign Trans_Done_d = tx_ready&&~tx_ready_d;

  assign tx_valid = tx_ready&&rst_n;


  always@(posedge clk_sys or negedge rst_n)
  begin
    if(~rst_n)
    begin
      cnt<= 'd0;
      tx_valid_d <= 'd0;
      tx_valid_dd <= 'd0;
      data_v<='d0;
      tx_ready_d <='d0;
      t_d <='d0;
    end
    else
    begin
      tx_valid_d <= tx_valid;
      tx_valid_dd <= tx_valid_d;
      tx_ready_d <=tx_ready;
      data_v<={data_v[30:0],tx_valid_dd};
      t_d <=t;
      if(~data_v[31]&&data_v[30])
      begin
        if(cnt <= length_wih-1)
        begin
          cnt <= cnt + 1;
        end
        else
        begin
          cnt <= 0;
        end
      end
    end
  end
  assign w_data = mem_wih[cnt];

/*
  weight_save uweight_save
 
   (
    .clk_200m(clk_sys),
    .user_clk(clk_sys),
    .rst(~rst_n),

    .wr_fifo_data_valid(1),
    .wr_fifo_data(),


    .wr_ram_valid(),
    .wr_ram_data()

   );
*/

LSTM_TOP u
   (

     .ref_clk(clk_sys) , ///50M
     .w_clk_200m(clk_sys),


     .r_reset(~rst_n),

.tdata(w_data),
.t_valid(t_d)

   );

   felu ua
(
.clk(clk_sys),
.rst_n(rst_n),

.data_valid(1),
.data_in(-'d32768),

.data_out_valid(),
.data_out_o()
);



reg [3:0]STATE_0;
always@(posedge clk_sys or negedge rst_n )
begin 
 if(~rst_n) begin STATE_0<= 'd0; 
  w_rx_done<='d0;
  data_out <= 'd0;
end
 else begin 
  case(STATE_0)
   'd0:begin
    
              //if(wr_start) begin STATE_0 <= 'd1;w_rx_done <= 1;  end
       if(uart_in) begin STATE_0 <= 'd2; w_rx_done <= 1;data_out <= 8'h79; end
       else begin STATE_0<= STATE_0; w_rx_done <= 0;data_out <= 8'h79; end
    end 
    'd1:begin end
   'd2:begin //器件地址
            //data_out <= 16'h79;
    
            if(Trans_Done_d) begin STATE_0<= 'd3; w_rx_done <= 1;data_out <= 8'h91; end
    else begin STATE_0<= STATE_0; w_rx_done <= 0;data_out <= data_out; end
    end
    'd3: begin//寄存器地址 
    //cmd <=  WR;
    //Go <= 1;
    //TX_DATA <= addr;//8'hB1;//写方向
            if(Trans_Done_d) begin STATE_0<= 'd4; w_rx_done <= 1;data_out <= 8'h1e; end
    else begin STATE_0<= STATE_0;w_rx_done <= 0;data_out <= data_out;  end
    end
    'd4:begin //器件地址
           // cmd <= STA | WR;
    //Go <= 1;
    //TX_DATA <= 8'h90 | 8'd1;//写方向
            if(Trans_Done_d) begin STATE_0<= 'd5; w_rx_done <= 1;data_out <= 8'h01; end
    else begin STATE_0<= STATE_0; w_rx_done <= 0;data_out <= data_out; end
    end
    'd5:begin //器件地址
           // cmd <=  RD | STO;
    //Go <= 1;
    //TX_DATA <= 0;//写方向
            if(Trans_Done_d) begin STATE_0<= 0;  end
    else begin STATE_0<= STATE_0;  end
    end

  endcase
 end
 end 


endmodule
