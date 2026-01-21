module TOP(
    input  wire                       i_ref_50m
    ,output wire                       o_hram_clk
    ,output wire                       o_hram_csn
    ,output wire                       o_hram_resetn
    ,inout  wire                       io_hram_rwds
    ,inout  wire          [7 : 0]      io_hram_dq
    //,input ref_clk  ///50M
    //input rst_n,
    ,input  i_uart_rx
    ,output o_uart_tx

  );

  //////////////复位初始化时钟
  //reg              [7 : 0]             r_sys_dcnt    = 8'd0 ;
  //reg                                  r_ref_resetn  = 1'b0 ;
  //reg              [7 : 0]             r_pll_locked  = 8'd0 ;
  ////reg                                  r_reset       = 1'b1 ;
  //reg              [15 : 0]            r_poweron_cnt = 16'd0;
  //wire w_clk_200m;
  //wire                                 w_clk_50m     ;
  //wire                                 w_pll_locked  ;
  //reg r_reset = 1'b1;
  //wire                                 w_clk_200m_135os ;
  //wire                                 w_clk_200m_180os ;
  ///************************************************************/
  ////part1: onchip soc clock generate
  ////freq : 50MHz
  ///************************************************************/
  //osc_v1 u_osc_inst(
  //    .hf_out_en_i                     (1'b1                   )
  //   ,.hf_clk_out_o                    (w_clk_50m              )
  //);
  //
  ////wire [31:0]length_file;
  ////assign length_file = {24'd3,7'd0};
  //
  //
  //
  //always @ (posedge w_clk_50m)
  //begin
  //	   r_sys_dcnt     <= (&r_sys_dcnt) ? r_sys_dcnt : (r_sys_dcnt + 1'b1);
  //	   r_ref_resetn   <= (&r_sys_dcnt) ? 1'b1 : 1'b0;
  //end
  //
  ///*************************************************************/
  ////part2: generate clocks for system
  ////clkop:200MHz;  clkos_o: 200MHz phase offset 130 degree
  ///*************************************************************/
  //pll_2xq_5x_dynport u_pll_tb_inst(
  //    .clki_i              (i_ref_50m             )
  //   ,.rstn_i              (r_ref_resetn          )
  //
  //   ,.clkop_o             (w_clk_200m            )
  //   ,.clkos_o             (w_clk_200m_135os      )
  //
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

  localparam hidden_size = 512; //隐藏层特征数)
  localparam ADDR_WIDTHBIAS = $clog2(hidden_size*4);

  localparam LENGTH_DATA = $clog2(hidden_size);
  localparam output_size = 2;
  localparam input_size = 96; //输入特征数


  localparam OS_W = $clog2(output_size)+1;
  wire [OS_W-1:0]fc_bais_adr;
  wire  [16-1:0]fc_bais_data;
  wire fifo_ready_r;
  wire [ADDR_WIDTHBIAS-1:0]cnt_hidden_size0;
  wire [16*4-1:0]bias_gate;
  wire rd_weight_en;
  wire weight_out_valid;
  wire [24*4-1:0]weight_out;
  ///////////////
  wire [20:0]length_file;
  //wire r_reset;
  wire [7:0]rd_data_cnt_o;
  wire r_acess_wdata_tvalid;
  wire [15:0]wr_data;
  wire rw_con;
  wire fifo_ready;

  wire              [15 : 0]           w_acess_rdata_tdata   ;
  wire                                 w_acess_rdata_tvalid ;
  wire reset_test;
  wire user_clk_50;
  wire uart_read;
  wire [7:0]uart_data;
  wire rd_en_fc;
  wire [8-1:0]weight_out_fc;
  wire [ADDR_WIDTHBIAS-1:0]h_rd_adr_i;
  wire [LENGTH_DATA:0]fc_w_adr;
  LSTM_TOP #(      .input_size( input_size), //输入特征数
                   .output_size      (output_size) , //输出类别数
                   .hidden_size (hidden_size))
           LSTM_top_inst
           (

             .ref_clk         (i_ref_50m), ///50M
             .w_clk_200m      (w_clk_200m),
             .i_uart_rx       (i_uart_rx),
             .o_uart_tx       (o_uart_tx),

             .r_reset         (r_reset),
             .reset_hyram(reset_hyram),
             .o_led           (),
             .o_led2          (),

             .fc_w_adr(fc_w_adr),
             .rd_data_cnt_out   (rd_data_cnt_o),
             .start_wr_hperram(rw_con),
             .r_acess_wdata_tvalid(r_acess_wdata_tvalid),
             .uart_re_data(wr_data),
             .file_length     (length_file),
             .length_valid    (),
             .data_save_out   (),
             .data_save_valid(),
             .rd_weight_fc(rd_en_fc),
             .w_acess_rdata_tdata(w_acess_rdata_tdata),
             .w_acess_rdata_tvalid(w_acess_rdata_tvalid),
             .fifo_ready(),
             .reset_test(reset_test),
             .fifo_ready_r(fifo_ready_r),//(fifo_ready_r),
             .cnt_hidden_size0(cnt_hidden_size0),
             .bias_gate(bias_gate),
             .rd_weight_en(rd_weight_en),
             .weight_out_valid(weight_out_valid),
             .weight_out(weight_out),
             .tx_ready(tx_ready),
             .fc_bais_adr(fc_bais_adr),
             .fc_bais_data(fc_bais_data),
             .fifo_ready_fc(1),//(fifo_ready_fc),
             .weight_out_fc(weight_out_fc),
             .h_rd_adr_i(h_rd_adr_i),
             .uart_data(uart_data)



           );
  wire w_r;
  wire [20:0]length_file_in;
  assign length_file_in = w_r?21'd1245184:length_file;
  hyperRam_top_v2 hyperRam_top_v2_inst(
                    .i_ref_50m    (i_ref_50m),
                    .o_hram_clk   (o_hram_clk),
                    .w_clk_200m   (w_clk_200m),
                    .o_hram_csn   (o_hram_csn),
                    .o_hram_resetn(o_hram_resetn),
                    .io_hram_rwds (io_hram_rwds),
                    .io_hram_dq   (io_hram_dq),
                    .wr_data(wr_data),
                    .rw_con(rw_con),
                    .user_clk_50(user_clk_50),
                    .reset_test(reset_test),
                    .reset_hyram(0),
                    .fifo_ready(fifo_ready),
                    .r_reset      (r_reset),//||reset_hyram),
                    .fifo_count   (rd_data_cnt_o),
                    .r_acess_wdata_tvalid_out0(r_acess_wdata_tvalid),
                    .length_file({11'd0,length_file_in}),//28672
                    .w_r(w_r),
                    //.length_file(32'd28672),
                    .w_acess_rdata_tdata (w_acess_rdata_tdata),
                    .w_acess_rdata_tvalid (w_acess_rdata_tvalid)
                  );


  assign uart_read =tx_ready&&fifo_ready_r;


  weight_save
    #(.QZ(16),
      .input_size( input_size), //输入特征数
      .output_size      (output_size) , //输出类别数
      .hidden_size (hidden_size)

     )weight_save_inst//隐藏层特征数)
    (
      .clk_200m(w_clk_200m),
      .user_clk(user_clk_50),//user_clk_50),
      .rst(r_reset),

      .wr_fifo_data_valid(w_acess_rdata_tvalid),
      .wr_fifo_data({w_acess_rdata_tdata[7:0],w_acess_rdata_tdata[15:8]}),

      .addr_rd_h(fc_w_adr[8:0]),
      .wr_ram_valid(),
      .wr_ram_data(),
      .fifo_ready_r(fifo_ready_r),
      .fifo_ready(fifo_ready),
      .cnt_hidden_size0(cnt_hidden_size0),
      .bias_gate(bias_gate),
      .weight_out(weight_out),
      .weight_out_valid_o(weight_out_valid),

      .uart_data(uart_data),
      .fc_bais_adr(fc_bais_adr),
      .fc_bais_data(fc_bais_data),
      .fifo_ready_fc(fifo_ready_fc),
      .rd_en(rd_weight_en),
      .weight_out_fc(weight_out_fc),
      .rd_en_fc(rd_en_fc)
    );
  // localparam lengthf = (512*512*4+96*512*4);


  /*
   weight_save  #( .QZ(16)) weight_save_inst
    (
      . clk_200m(w_clk_200m),
      . user_clk(i_ref_50m),
      . rst(r_reset),
   
      . wr_fifo_data_valid(w_acess_rdata_tvalid),
      . wr_fifo_data(w_acess_rdata_tdata),
   
      . fifo_ready(fifo_ready),
      . wr_ram_valid(),
      . wr_ram_data()
   
    );
   
  */
endmodule
