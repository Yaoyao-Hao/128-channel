`timescale 1ns / 1ps
module uart_loop#(parameter DATA_WIDTH = 8)(
    input i_clk_sys,
    input i_rst_n,
    input i_uart_rx,
    output o_uart_tx,
    output o_ld_parity,
    output  wire w_rx_done,
    output wire[DATA_WIDTH-1 : 0] w_data,

    input wire [DATA_WIDTH-1 : 0]t_data,
    input t_data_valid,
    output tx_ready,

    input [24*2-1:0]ht_wr_fifo,
    input ht_valid,


    input   wire [23:0]data_debug,
    input   wire data_debug_valid




  );


  localparam BAUD_RATE = 115200;
  localparam PARITY_ON = 0;
  localparam PARITY_TYPE = 1;


  reg [7:0]rx_data;
  reg[7:0]tx_data;
  wire [7:0]fifo_data_out;
  reg tx_valid;

  //wire tx_ready;


  reg w_rx_done_d,w_rx_done_dd;
  reg rdend;
  reg [31:0]data_out_valid_d;
  reg data_out_valid;
  wire [7:0]data_out;
  uart_rx_a
    #(
      .CLK_FRE(50),         //时钟频率，默认时钟频率为50MHz
      .DATA_WIDTH(DATA_WIDTH),       //有效数据位，缺省为8位
      .PARITY_ON(PARITY_ON),        //校验位，1为有校验位，0为无校验位，缺省为0
      .PARITY_TYPE(PARITY_TYPE),      //校验类型，1为奇校验，0为偶校验，缺省为偶校验
      .BAUD_RATE(BAUD_RATE)      //波特率，缺省为9600
    ) u_uart_rx
    (
      .i_clk_sys(i_clk_sys),      //系统时钟
      .i_rst_n(i_rst_n),        //全局异步复位,低电平有效
      .i_uart_rx(i_uart_rx),      //UART输入
      .o_uart_data(w_data),    //UART接收数据
      .o_ld_parity(o_ld_parity),    //校验位检验LED，高电平位为校验正确
      .o_rx_done(w_rx_done)       //UART数据接收完成标志
    );
  wire rden;
  uart_tx_a
    #(
      .CLK_FRE(50),         //时钟频率，默认时钟频率为50MHz
      .DATA_WIDTH(DATA_WIDTH),       //有效数据位，缺省为8位
      .PARITY_ON(PARITY_ON),        //校验位，1为有校验位，0为无校验位，缺省为0
      .PARITY_TYPE(PARITY_TYPE),      //校验类型，1为奇校验，0为偶校验，缺省为偶校验
      .BAUD_RATE(BAUD_RATE)      //波特率，缺省为9600
    ) u_uart_tx
    (   .i_clk_sys(i_clk_sys),      //系统时钟
        .i_rst_n(i_rst_n),        //全局异步复位
        .i_data_tx(data_out),//(w_data),      //传输数据输入
        .i_data_valid(w_rx_done_dd),//(data_out_valid_d),//(w_rx_done),   //传输数据有效
        .o_uart_tx(o_uart_tx)  ,     //UART输出
        .tx_ready(tx_ready)
    );



  wire empty ;
  assign  rden = tx_ready &&~empty;
  reg rd_fifo;
  reg mnirst_n;
  always@(posedge i_clk_sys)
  begin
    if(~i_rst_n)
    begin
      rd_fifo<= 'd0;
    end
    else
    begin
      rd_fifo <= ~rdend&&rden;
    end
  end


  /*
   uart_rx u_uart_rx
   (
     .clk(i_clk_sys),
     .rst_n(i_rst_n),
     .rs232_rx(i_uart_rx),
     .valid_out(w_rx_done),
     .recv_data(w_data)
   );

  reg rd_en_d;
  uart_tx u_uart_tx(
     .clk(i_clk_sys),
     .rst_n(i_rst_n),
     .start(tx_valid),
     .send_data(tx_data),
     .rs232_tx(o_uart_tx),
     .tx_ready(tx_ready)
   );
  */

  //assign o_uart_tx = i_uart_rx;

  reg tx_ready_d;


  always@(posedge i_clk_sys or negedge i_rst_n)
  begin
    if(~i_rst_n)
    begin
      rx_data<= 'd0;
    end
    else
    begin
      if(data_out_valid)
      begin
        rx_data<= data_out;
      end
      else
      begin
        rx_data<= rx_data;
      end
    end
  end


  always@(posedge i_clk_sys or negedge i_rst_n)
  begin
    if(~i_rst_n)
    begin
      tx_data<= 'd0;
      tx_valid<='d0;
      rdend<= 'd0;
      data_out_valid <= 'd0;
      data_out_valid_d<='d0;
      w_rx_done_d <= 'd0;
      w_rx_done_dd<='d0;

      tx_ready_d <= 'd0;
    end
    else
    begin
      rdend<= rden;
      tx_ready_d <= tx_ready;
      data_out_valid <= data_out_valid_d[31];
      w_rx_done_d <= w_rx_done;
      w_rx_done_dd<=w_rx_done_d;



      data_out_valid_d[31:0] <= {data_out_valid_d[31:1],rd_fifo};
      if(w_rx_done)
      begin
        tx_data<= w_data;
        tx_valid<='d1;
      end
      else
      begin
        tx_data<= tx_data;
        tx_valid<='d0;
      end
    end
  end
  wire full;


  wire [7:0]fifo_data_in;
  assign  fifo_data_in = data_debug[15:8];


  reg [16:0]wr_data;
  reg test_wr_en;
  reg [31:0]r_wait_stable_cnt;
wire [63:0]rd_fifo_in;
assign rd_fifo_in[31:0] =  {{8{ht_wr_fifo[23]}},ht_wr_fifo};
assign rd_fifo_in[63:32] = {{8{ht_wr_fifo[47]}},ht_wr_fifo[47:24]};
  test_fifo tets_debug(
              .wr_clk_i     (i_clk_sys),
              .rd_clk_i     (i_clk_sys),
              .rst_i        (0),
              .rp_rst_i     (0),
              .wr_en_i      (ht_valid),//(data_debug_valid&&~full),
              .rd_en_i      (w_rx_done),
              .wr_data_i    (rd_fifo_in),//{wr_data[7:0],wr_data[7:0]}),//(fifo_data_in),
              .full_o       (),
              .empty_o      (empty),
              .almost_full_o(full),
              .rd_data_o(data_out)) ;


//assign data_out = 0;
  /*testwr*/
  always@(posedge i_clk_sys )
  begin
    if(~i_rst_n)
    begin
      wr_data <= 'd0;
      test_wr_en <= 'd0;
    end
    else
    begin
      if(~full)
      begin
        wr_data<= wr_data + 'd1;
        test_wr_en <= 'd1;
      end
      else
      begin
        wr_data<= wr_data;
        test_wr_en <= 'd0;
      end
    end
  end
  ///////模拟rst

  always @ (posedge i_clk_sys)
  begin
    if(~i_rst_n)
    begin
      r_wait_stable_cnt  <= 16'd0;
      mnirst_n     <= 1'b0 ;
    end
    else
    begin
      r_wait_stable_cnt   <= (&r_wait_stable_cnt) ? r_wait_stable_cnt : (r_wait_stable_cnt + 1'b1);
      //wait 160us,after stable,then start hyperRAM intial
      mnirst_n  <= (&r_wait_stable_cnt)  ? 1'b1 : 1'b0;
    end
  end
endmodule
