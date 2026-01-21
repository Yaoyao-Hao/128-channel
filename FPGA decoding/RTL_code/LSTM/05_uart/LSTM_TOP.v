`timescale 1ns / 1ps
module LSTM_TOP
  #(parameter debug = 0,
    parameter input_size = 32, //输入特征数
    parameter hidden_size = 64, //隐藏层特征数)
    parameter output_size = 32,
    parameter OS_W = $clog2(output_size)+1,
    parameter QZ_R = 8,
    parameter QZ_D = 16,
    parameter QZ = QZ_R + QZ_D, //数据量化位宽
    parameter ADDR_WIDTHBIAS = $clog2(hidden_size*4))
   (

     input ref_clk , ///50M
     input w_clk_200m,
     //input rst_n,
     input i_uart_rx,
     output o_uart_tx,

     input r_reset,
     output reg                              o_led,
     output wire                              o_led2,


     output wire [7:0] rd_data_cnt_out ,
     input r_acess_wdata_tvalid,

     output reg[20:0]file_length,
     output reg length_valid,
     output data_save_out,
     output data_save_valid,
     output   wire [16-1:0]uart_re_data,
     output reg start_wr_hperram, //0写 1读
     output reg reset_hyram,//开始写入之前复位hyram

     input wire [QZ_R-1:0]weight_out_fc,
     output ram_wr_bias,
     output [15:0]ram_wr_data,

     output data_fifo_wr,
     output [15:0]data_fifo_in,
     input   wire              [15 : 0]           w_acess_rdata_tdata   ,
     input wire                                 w_acess_rdata_tvalid ,
     output fifo_ready,
     output reg reset_test,

     input                      wire fifo_ready_r,
     input wire fifo_ready_fc,
     output  wire [ADDR_WIDTHBIAS-1:0]cnt_hidden_size0,
     input  wire            [16*4-1:0]bias_gate,
     output                          rd_weight_en,
     output rd_weight_fc,
     input wire weight_out_valid,
     input wire [24*4-1:0]weight_out,
     output [OS_W-1:0]fc_bais_adr,
     input  [QZ-QZ_R-1:0]fc_bais_data,
     output tx_ready,
     output reg start_rd,
     input [7:0]uart_data,
     output [8:0]fc_w_adr,

     input [7:0]tdata,
     input t_valid,
     output   wire [ADDR_WIDTHBIAS-1:0]h_rd_adr_i
   );

  wire [47:0]data_debug;
  wire data_debug_valid;


  wire [7:0] rd_data_cnt_o;
  /*************************************************************/
  //part2: generate clocks for system
  //clkop:200MHz;  clkos_o: 200MHz phase offset 130 degree
  /*************************************************************/
  reg              [7 : 0]             r_sys_dcnt    = 8'd0 ;
  reg                                  r_ref_resetn  = 1'b0 ;
  reg              [7 : 0]             r_pll_locked  = 8'd0 ;
  //reg                                  r_reset       = 1'b1 ;
  reg              [15 : 0]            r_poweron_cnt = 16'd0;

  wire                                 w_clk_50m     ;
  wire                                 w_pll_locked  ;
  //wire                                 w_clk_200m    ;
  wire                                 w_clk_200m_135os ;
  wire                                 w_clk_200m_180os ;

  //  pll_2xq_5x_dynport u_pll_tb_inst(
  //    .clki_i              (ref_clk             )
  //   ,.rstn_i              (r_ref_resetn          )
  //
  //   ,.clkop_o             (w_clk_200m            )
  //   ,.clkos_o             (w_clk_200m_135os      )
  //   ,.clkos2_o            (                      )
  //   ,.clkos3_o            (                      )
  //   ,.clkos4_o            (                      )
  //  // ,.clkos5_o            (                      )
  //
  //   ,.lock_o              (w_pll_locked          )
  //   ,.done_pll_init_o     (w_done_pll_init_o     )
  //);
  //always @ (posedge w_clk_200m)
  //begin
  //	    r_pll_locked <= {r_pll_locked[6:0],(w_pll_locked & w_done_pll_init_o)} ;
  //end
  //always @ (posedge w_clk_200m)
  //begin
  //	   if(~r_pll_locked[7]) begin
  //	   	 r_reset       <= 1'b1 ;
  //	   	 r_poweron_cnt <= 16'd0;
  //	   end
  //	   else begin
  //	   	 r_poweron_cnt <= (&r_poweron_cnt) ? r_poweron_cnt : (r_poweron_cnt + 1'b1);
  //	   	 r_reset       <= (&r_poweron_cnt) ? 1'b0 : 1'b1;
  //	   end
  //end



  assign  o_led2 = i_uart_rx;
  wire clk;
  wire w_chip_clk_50m;
  assign clk = ref_clk;

  wire rst_n0;


  wire [24-1:0]ht_wr_fifo;


  reg             [9 : 0]          r_stable_cnt = 10'd0;

  // wire                             w_sys_clk    ;

  assign rst_n0 = ~r_reset;

  localparam UART_WIDTH = 8;
  wire w_rx_done;
  wire[UART_WIDTH-1 : 0] w_data;
  wire ht_valid;
  wire [QZ*2-1:0]output_data;
  wire         output_data_valid;
  uart_loop#(.DATA_WIDTH(8))
           uart_loopcell(
             .i_clk_sys(clk),
             .i_rst_n(rst_n0),
             .i_uart_rx(i_uart_rx),
             .o_uart_tx(o_uart_tx),
             .o_ld_parity(),
             .w_rx_done(w_rx_done),
             .w_data(w_data),
             .tx_ready(tx_ready),
             .t_data(uart_data),
             .t_data_valid(weight_out_valid),

             .ht_wr_fifo(output_data),//(output_data),
             .ht_valid(output_data_valid),//(output_data_valid),



             .data_debug(),
             .data_debug_valid()
           );

  assign rst_n = rst_n0;

  wire uart_re_empty_o;
  wire uart_re_full_o;
  wire uart_re_rd;
  wire [UART_WIDTH*2-1:0]uart_re_data_d;


  uart_re_fifo uart_re_fifou(
                 .wr_clk_i     (clk),
                 .rd_clk_i     (w_clk_200m),
                 .rst_i        (~rst_n),
                 .rp_rst_i     (~rst_n),
                 .wr_en_i     (w_rx_done),//~uart_re_full_o),
                 .rd_en_i      (uart_re_rd),
                 .wr_data_i    (w_data),
                 .full_o       (),
                 .empty_o      (uart_re_empty_o),
                 .almost_full_o(uart_re_full_o),
                 .rd_data_cnt_o(rd_data_cnt_o),
                 .rd_data_o    (uart_re_data_d) ) ;
  assign uart_re_data = {uart_re_data_d[7:0],uart_re_data_d[15:8]};

  reg [3:0]STATE_FILE_SAVE;
  reg uart_re_data_out;
  always@(posedge w_clk_200m or negedge rst_n)
  begin
    if(~rst_n)
    begin
      uart_re_data_out <= 'd0;
    end
    else
    begin
      uart_re_data_out <= uart_re_rd;
    end
  end


  localparam INIT = 0,
             START_SAVE_FILE = 1,
             SAVE_FILE = 2,
             FINISH = 3;
  reg [2:0]file_type;

  localparam HEAD = 8'hAC;
  localparam FILE_TYPE_WHH = 4'b001,
             FILE_TYPE_BIAS = 4'b010,
             FILE_TYPE_DATAH = 3'b100,
             FILE_TYPE_DATAL = 3'b101;
  // BIAS = 3'b010;

  assign rd_data_cnt_out = (file_type==FILE_TYPE_WHH)?rd_data_cnt_o:0;
  reg [20:0]LENGTH_FILE;
  reg [20:0]LENG_CNT;
  reg save_wr_valid;
  reg [UART_WIDTH*2-1:0]save_data;
  reg [3:0]BIAS_TYPE;

  always@(posedge w_clk_200m or negedge rst_n)
  begin
    if(~rst_n)
    begin
      length_valid <= 'd0;
      STATE_FILE_SAVE <= INIT;
      file_type <= 0;
      LENGTH_FILE     <= 0;
      save_wr_valid<= 'd0;
      save_data <= 'd0;
      LENG_CNT <= 'd0;
      BIAS_TYPE <= 'd0;
      o_led     <= 'd1;
      start_wr_hperram<= 'd1;
      reset_hyram <='d0;
    end
    else
    begin
      case(STATE_FILE_SAVE)
        INIT:
        begin
          LENG_CNT <= 'd0;
          o_led     <= 'd1;
          length_valid <= 'd0;
          reset_hyram <='d0;
          if((uart_re_data[15:8]== HEAD)&&uart_re_data_out)
          begin
            STATE_FILE_SAVE <= START_SAVE_FILE;
            file_type       <= uart_re_data[7:5];
            LENGTH_FILE[20:16]     <= uart_re_data[4:0];
            BIAS_TYPE <= uart_re_data[3:0];
            start_wr_hperram<= 'd1;
          end
          else
          begin
            STATE_FILE_SAVE <= STATE_FILE_SAVE;
            file_type       <= file_type;
            LENGTH_FILE     <= LENGTH_FILE;
            start_wr_hperram<= 'd1;
          end
        end
        START_SAVE_FILE:
        begin
          LENG_CNT <= 'd0;
          o_led     <= 'd0;

          if(uart_re_data_out)
          begin
            LENGTH_FILE[15:0]     <= uart_re_data;
            LENGTH_FILE[20:16]    <= (file_type == FILE_TYPE_WHH)? LENGTH_FILE[20:16]: 5'd0;
            length_valid <= 'd1;
            STATE_FILE_SAVE <= SAVE_FILE;
            start_wr_hperram <= (file_type == FILE_TYPE_WHH)? 0:1;
            reset_hyram <=(file_type == FILE_TYPE_WHH)?1:0;
          end
          else
          begin
            LENGTH_FILE     <= LENGTH_FILE;
            STATE_FILE_SAVE <= STATE_FILE_SAVE;
            length_valid <= 'd0;
            start_wr_hperram <= start_wr_hperram;
            reset_hyram<= reset_hyram;
          end
        end
        SAVE_FILE:
        begin
          length_valid <= 'd0;
          o_led     <= 'd0;
          reset_hyram <= 0;
          if(uart_re_data_out)
          begin
            LENG_CNT <= LENG_CNT + 'd2;
            if(LENG_CNT >= LENGTH_FILE-2)
            begin
              save_wr_valid<= 'd1;
              save_data <= uart_re_data;
              STATE_FILE_SAVE <= FINISH;
            end
            else
            begin
              save_wr_valid<= 'd1;
              save_data <= uart_re_data;
              STATE_FILE_SAVE <= STATE_FILE_SAVE;
            end
          end

          else
          begin
            LENG_CNT <= LENG_CNT ;
            save_wr_valid<= 'd0;
            save_data <= uart_re_data;
            STATE_FILE_SAVE <= STATE_FILE_SAVE;
          end
          //  if(LENG_CNT >= LENGTH_FILE-1) begin STATE_FILE_SAVE <= FINISH; end
          //    else begin STATE_FILE_SAVE <= STATE_FILE_SAVE; end
        end
        FINISH:
        begin
          o_led     <= 'd0;
          reset_hyram <= 0;
          LENG_CNT <= 'd0;
          save_wr_valid<= 'd0;
          save_data <= 0;
          file_type       <= 0;
          LENGTH_FILE     <= 0;
          STATE_FILE_SAVE <= INIT;
          start_wr_hperram<= 1;
        end
      endcase
    end
  end
  always@(posedge w_clk_200m or negedge rst_n)
  begin
    if(~rst_n)
    begin
      file_length <= 'd0;
    end
    else
    begin
      if(~start_wr_hperram)
      begin
        file_length <= LENGTH_FILE;
      end
      else
      begin
        file_length <= file_length;
      end
    end
  end
  assign data_save_out = uart_re_data;
  assign data_save_valid = save_wr_valid;
  assign uart_re_rd = (STATE_FILE_SAVE == SAVE_FILE)&&(file_type==FILE_TYPE_WHH)? r_acess_wdata_tvalid:~uart_re_empty_o;

  assign ram_wr_bias =  (STATE_FILE_SAVE == SAVE_FILE)&&(file_type==FILE_TYPE_BIAS)? save_wr_valid:0;
  assign ram_wr_data =  save_data;




  wire data_fifo_wrl,data_fifo_wrh;
  assign data_fifo_wrh = (STATE_FILE_SAVE == SAVE_FILE||STATE_FILE_SAVE == FINISH)&&(file_type==FILE_TYPE_DATAH)? save_wr_valid:0;
  assign data_fifo_wrl = (STATE_FILE_SAVE == SAVE_FILE||STATE_FILE_SAVE == FINISH)&&(file_type==FILE_TYPE_DATAL)? save_wr_valid:0;
  assign data_fifo_in = save_data;
  wire cal_Chara_finish;
  reg cal_Chara_finish_d;

  ////*测试指令////
  wire rst_test;
  wire rd_start;
  reg rd_start_d,rd_start_dd;
  reg rst_test_d ,rst_test_dd;
  reg start;
  assign rst_test = (STATE_FILE_SAVE!= SAVE_FILE)&&(uart_re_data[15:8]==16'haa)&&(uart_re_data_out)?uart_re_data[0]:0;
  assign rd_start = (STATE_FILE_SAVE!= SAVE_FILE)&&(uart_re_data[15:8]==16'haa)&&(uart_re_data_out)?uart_re_data[1]:0;

  always@(posedge w_clk_200m or negedge rst_n)
  begin
    if(~rst_n||rst_test)
    begin
      rd_start_d <= 'd0;
      rd_start_dd <= 'd0;
      cal_Chara_finish_d<= 'd0;
      start <= 'd0;
    end
    else
    begin
      rd_start_d <= rd_start;
      rd_start_dd <= rd_start_d;
      cal_Chara_finish_d<= cal_Chara_finish;
      if(rd_start_d&&~rd_start_dd)
      begin
        start <= 'd1;
      end
      else if(cal_Chara_finish&&~cal_Chara_finish_d)
      begin
        start <= 'd0;
      end
      else
      begin
        start <=start;
      end
    end
  end

  reg [31:0]cal_time;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      cal_time <= 'd0;

    end
    else
    begin
      if(start)
      begin
        cal_time <= cal_time + 'd1;
      end
      else
      begin
        cal_time <= 0 ;
      end

    end
  end

  //reg reset_test;
  reg [10:0]rst_cnt;
  always@(posedge w_clk_200m or negedge rst_n)
  begin
    if(~rst_n||rst_test)
    begin
      rst_test_d <= 'd0;
      rst_test_dd <= 'd0;
      rst_cnt<= 'd0;
    end
    else
    begin

      rst_cnt <= (&rst_cnt) ? rst_cnt : (rst_cnt + 1'b1);
      reset_test       <= (&rst_cnt) ? 1'b0 : 1'b1;

    end
  end


  /////////


  wire data_read;
  reg data_valid;
  always@(posedge clk)
  begin
    if(~rst_n)
    begin
      // cnt <= 'd0;
      data_valid <= 'd0;
    end
    else
    begin
      //cnt <= cnt + 1;
      data_valid <= data_read;
    end
  end


  reg [8:0]wr_addr;

  always@(posedge w_clk_200m or negedge rst_n)
  begin
    if(~rst_n)
    begin
      wr_addr<= 'd0;
    end
    else
    begin
      if(data_fifo_wrh||data_fifo_wrl)
      begin
        if(wr_addr>= 'd95)
        begin
          wr_addr<=  'd0;
        end
        else
        begin
          wr_addr<= wr_addr + 'd1; //96*2
        end

      end
      else
      begin
        wr_addr<= wr_addr;
      end
    end

  end
  wire[10:0]cal_cnt;
  reg [8:0]addr_rd;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      addr_rd<= 'd0;
    end
    else
    begin
      if(addr_rd>=95 )
      begin
        addr_rd<=0;
      end
      else
      begin
        addr_rd<= addr_rd + 'd1;
      end

    end


  end

  wire [15:0]datah,datal;
  wire [31:0]datacal;
  assign datacal = {datah,datal};
  cal_data_ram96x16 cal_data_ram96x16h(
                      .wr_clk_i   (w_clk_200m),
                      .rd_clk_i   (clk),
                      .rst_i      (~rst_n),
                      .wr_clk_en_i(1),
                      .rd_en_i    (1) ,
                      .rd_clk_en_i(1),
                      .wr_en_i    (data_fifo_wrh),
                      .wr_data_i  (data_fifo_in),
                      .wr_addr_i  (wr_addr),
                      .rd_addr_i  (cal_cnt[8:0]),
                      .rd_data_o  (datah)) ;
  cal_data_ram96x16 cal_data_ram96x16l(
                      .wr_clk_i   (w_clk_200m),
                      .rd_clk_i   (clk),
                      .rst_i      (~rst_n),
                      .wr_clk_en_i(1),
                      .rd_en_i    (1) ,
                      .rd_clk_en_i(1),
                      .wr_en_i    (data_fifo_wrl),
                      .wr_data_i  (data_fifo_in),
                      .wr_addr_i  (wr_addr),
                      .rd_addr_i  (cal_cnt[8:0]),
                      .rd_data_o  (datal)) ;
  wire [23:0]data_in ;
  assign data_in = datacal[23:0];
  LSTM #(
         .input_size     (input_size), //输入特征数
         .hidden_size    (hidden_size), //隐藏层特征数
         .num_layers     (1), //LSTM层数
         .output_size    (output_size), //输出类别数
         .batch_size     (1), //批大小
         .sequence_length(1),//序列长度
         .QZ_R(8),
         .QZ_D(16)
       )LSTM_INST(
         .clk  (clk),
         .clk_200m(w_clk_200m),
         .rst_n(rst_n),
         //.start(1), //开始计算
         .start(start),
         .data_in(data_in),//(24'd32768),
         .data_in_valid(data_valid),


         .ht_wr_fifo(ht_wr_fifo),
         .ht_valid(ht_valid),

         .ht_out(),
         // .ht_valid(),
         .data_read(data_read),
         .fifo_ready_w(fifo_ready),
         .cal_cnt(cal_cnt),
         // .wr_fifo_data_valid(w_acess_rdata_tvalid),
         // .wr_fifo_data(w_acess_rdata_tdata)
         .fifo_ready_r(fifo_ready_r),
         .fifo_ready_fc(fifo_ready_fc),
         .cnt_hidden_size0(cnt_hidden_size0),
         .bias_gate(bias_gate),
         .rd_weight_en(rd_weight_en),
         .rd_weight_fc(rd_weight_fc),
         .weight_out_fc(weight_out_fc),
         .weight_out_valid(weight_out_valid),
         .weight_out(weight_out),
         .fc_bais_adr(fc_bais_adr),
         .fc_bais_data(fc_bais_data),
         .cal_Chara_finish(cal_Chara_finish),
         .data_debug(data_debug),
         .data_debug_valid(data_debug_valid),
         .fc_w_adr(fc_w_adr),
         .h_rd_adr_i(h_rd_adr_i),
         .output_data(output_data),
         .output_data_valid(output_data_valid)

       );


endmodule
