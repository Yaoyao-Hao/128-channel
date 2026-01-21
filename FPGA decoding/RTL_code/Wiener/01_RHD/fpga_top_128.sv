

//--------------------------------------------------------------------------------------------------------
// Module  : fpga_top_example_ft232h
// Type    : 
// Standard: 
// Function: 1.0 
//           1.1 1.指令插槽换到数据前面 2.修复了数据误码问题 3.单个stream改为32通道，一个stream数据量为70字节 4.修改部分时序问题
//           1.2 1 调整SPI发送数据，2 修改TrigIn 0x42: TrigInRamWrite命令模块
    //       1.3 修复一段时间之后数据有可能丢失问题
//--------------------------------------------------------------------------------------------------------

module fpga_top_128 #
( parameter CLK_CHOSE = 0,
  parameter RST_TIME = 15'hFFF0,
  parameter LENGTH = 1024,
  parameter CHOSE_MODULE = 0 //0为缓存满继续采样 1为缓存满停止采样
  )(
    input  wire         clk_in,   // main clock, connect to on-board crystal oscillator

    // USB2.0 HS (FT232H chip)
    //output wire         usb_resetn,  // to FT232H's pin34 (RESET#) , Comment out this line if this signal is not connected to FPGA.
    //output wire         usb_pwrsav,  // to FT232H's pin31 (PWRSAV#), Comment out this line if this signal is not connected to FPGA.
 //   output wire         usb_siwu,    // to FT232H's pin28 (SIWU#)  , Comment out this line if this signal is not connected to FPGA.
 //   input  wire         usb_clk,     // to FT232H's pin29 (CLKOUT)
 //   input  wire         usb_rxf,     // to FT232H's pin21 (RXF#)
 //   input  wire         usb_txe,     // to FT232H's pin25 (TXE#)
 //   output wire         usb_oe,      // to FT232H's pin30 (OE#)
 //   output wire         usb_rd,      // to FT232H's pin26 (RD#)
 //   output wire         usb_wr,      // to FT232H's pin27 (WR#)
 //   inout        [ 7:0] usb_data,     // to FT232H's pin20~13 (ADBUS7~ADBUS0)
	

	//output test0,
	/////RHDspi

	output CS,
	output reg SCLK,
	
	input rst_i,
	
	
	//output  SCLK,
	output MOSI1,
	output MOSI2,
	//output MISO1,
	input MISO1,
	input MISO2,

	// output  data_v,
    // output [7:0]ram_data_rd_o,
	// output [16*2-1:0]DSP_ADD_DATA_o,
    // output           finish_cal_o,
//output SCK_I0,
//output MOSI_I0,
//output CS_I0,
//output MISO_O0,
//
input  test0,
input  test1,
input SCK_I,
input MOSI_I,
input CS_I,
output MISO_O

///
//output      test_valid	,
//input [15:0]test_data
///	
);
wire closeRHD;
assign closeRHD = test0;

/*
wire CS;
reg SCLK;

wire MOSI2;
wire MISO2;
*/




assign MOSI1 = MOSI2;





reg a1;
//wire CS;
//reg SCLK;

wire wr_fifo_spike;
wire [15:0]wr_data_spike;


reg         rstn = '0;
wire clk;
wire usb_clk0;
wire data_entest;


/*
assign CS0 = CS_I;
assign SCLK0 = SCK_I;
assign MOSI10 = MOSI_I;
assign MOSI20 = rstn;
assign MISO10 = data_entest;
assign MISO20 = MISO_O;
*/
//assign usb_clk0 = usb_clk;

	//output CS,
	//output reg SCLK,
	//output MOSI1,
	//output MOSI2,
	//input MISO1,
	//input MISO2,

//wire CS;
// reg SCLK;
//wire  MOSI1;
//wire  MOSI2;

//assign MOSI1 = MOSI_I;

//assign SCLK = SCK_I;
//assign CS = CS_I;

wire clk_buf;


    // wire         test0;   // used to show whether the recv data meets expectations
    // wire         test1;
	// wire         test2;
	// wire         test3;
//////BCI
//assign clk = clk_in;

wire clk56M;

//clk_config uclk_config(
//                  .clk_out(clk),
//                  .clk_chose(ep03wirein[7:0]),
//                  .clk_ref(clk_in)
//
//);
wire clk_gen;
HSOSC
#(
  .CLKHF_DIV ("0b00")//0'b00 = 48 MHz0'b01 = 24 MHz0'b10 = 12 MHz0'b11 = 6 MHz
)HSOSCINST (
  .CLKHFPU (1),  // I
  .CLKHFEN (~rst_i),  // I
  .CLKHF   (clk_gen)   // O
);
// clkgen HSOSCINST(
// .hf_out_en_i (1), 
// .hf_clk_out_o(clk_gen), 
// .lf_clk_out_o()) ;
wire clk_lock;
// assign clk_lock = 1;
pll_gen pll_genu(
	    .ref_clk_i  (clk_gen), 
        .rst_n_i    (~rst_i), 
        .outcore_o  (), 
		.lock_o (clk_lock),
        .outglobal_o(clk56M)) ;
		// pllclk pll48_56u(
		// .clki_i (clk_gen), 
        // .rstn_i (1), 
        // .clkop_o(), 
        // .clkos_o(clk56M), 
        // .lock_o ()) ;
		//assign clk = clk_in;//clk56M;

generate
	if (CLK_CHOSE) begin: CLK_CHOSE0
		assign	clk = clk_in;
	end else begin: CLK_CHOSE1
		assign	clk = clk56M;
	end
endgenerate


reg [31:0]cnt;
reg                               CS_b;//6
//reg                               SCLK; //9
reg                          MOSI_A;
wire                               MISO_A1;
//

wire                               MISO_A2;
wire                              CS_b_A;
wire                              SCLK_A;
wire                               MISO_B1;
wire                               MISO_B2;
wire                              CS_b_B;
wire                              SCLK_B;
reg                          MOSI_B;
wire                               MISO_C1;
wire                               MISO_C2;
wire                              CS_b_C;
wire                              SCLK_C;
reg                              MOSI_C; 
wire                               MISO_D1;
wire                               MISO_D2;
wire                              CS_b_D;
wire                              SCLK_D;
reg                              MOSI_D;
	reg [15:0]		FIFO_data_in;
	reg				FIFO_write_to;
		reg [7:0] main_state;
assign CS = CS_b;
assign MOSI2 = MOSI_A;///////////////////////////////////////////////////////////////
assign MISO_A1 = MISO1  ;
assign MISO_A2 = MISO2;////////////////////////////////////////////////

wire onepacket_finish;//当spike写完时表示一包已写入fifo
wire reset;
// for power on reset
reg  [ 3:0] reset_shift = '0;


// USB send data stream
reg         usbtx_valid = 1'b0;
wire        usbtx_ready;
reg  [ 5:0] usbtx_datah = '0;
wire [31:0] usbtx_data;

// USB received data stream
wire        usbrx_valid;
reg         usbrx_ready = 1'b0;
wire [ 15:0] usbrx_data;

// other signals for USB received control
reg  [ 7:0] last_data = '0;
reg  [31:0] busy_cnt = 0;
reg  [15:0] error_cnt = '0;


assign led = error_cnt[0] ;
reg wireout_start;
//assign led = error_cnt[0];

reg rstn0 = 0;
reg [15:0]reset_cnt = 32'd0;
reg [15:0]reset_cnt0 = 32'd0;
always @ (posedge clk or negedge clk_lock) begin
	if(~clk_lock) begin reset_cnt <='d0; end
	else begin 
	
	if(reset_cnt>RST_TIME)
		begin rstn <= 'd1;
		reset_cnt<=reset_cnt;
		end 
	else begin
		rstn <= 'd0;
        reset_cnt <=reset_cnt+ 'd1;
	 end
		end
	end


			reg [2:0]cntx,cntx0;
// wire clk_1_4K;
// wire clk_9_3K;
// assign clk_9_3K  = reset_cnt[9];
// assign clk_1_4K = reset_cnt[15];
//assign MOSI2 = clk_9_3K;


          

wire [15:0]spike_data;
wire spike_data_valid;

wire [31:0]spike_data0;
wire spike_data_valid0;

wire [31:0]spike_data1;
wire spike_data_valid1;
wire [31:0]spike_data2;
wire spike_data_valid2;
wire [31:0]spike_data3;
wire spike_data_valid3;
wire data_valid;
wire [15:0]rx_data;
wire [7:0]spi_test;
wire fifo_ready;

reg [15:0]data_spi;
reg spi_valid;
wire [15:0]local_thre_0_31;
wire [15:0]local_thre_32_63;
//assign data_spi = spike_data_valid?data_spi:FIFO_data_in;
//assign spi_valid = spike_data_valid?spike_data_valid:FIFO_write_to;
wire valid_rd;
wire [15:0]thre_data_tra;



/////testdata
reg [15:0]data_test;
//always@(posedge clk or negedge rstn)
//begin 
// if(~rstn) begin data_test <= 'd0; end
// else begin 
//   if(data_in_valid) begin 
//   if(data_test < 'd196) begin data_test <= data_test + 'd1; end
//   else begin data_test <= 'd0; end 
// end
// 
//end
//end

//
reg spike_data_valid_d,spike_data_valid_dd;
always@(posedge clk)// or posedge reset)
 begin
  if(reset) begin 
	spike_data_valid_d <=  0;
	spike_data_valid_dd<=  0 ;
 end
 else begin
	spike_data_valid_d <=#1 spike_data_valid;
	spike_data_valid_dd<=#1 spike_data_valid_d ;
 end
end


always@(posedge clk)// or posedge reset)
 begin
//  if(reset)
//   begin
//    data_spi <= 'd0;
//	spi_valid <= 'd0;
//   end
//else begin 
  if(spike_data_valid) begin 
   data_spi <=  spike_data;
   spi_valid <= spike_data_valid;
 end
 else begin
	data_spi <= FIFO_data_in;
   spi_valid <= FIFO_write_to;
 end
end


wire start_Impedance_test;


//end

// end
wire cal_busy;
//assign cal_busy = 0;
wire fifo_empty;

//reg data_in_valid;
//reg [15:0]data_in;

wire data_in_valid;
wire [15:0]data_in;



//assign data_in_valid = spi_valid;
//assign data_in = data_spi;
reg wr_fifo_en;

assign data_in = valid_rd?thre_data_tra:data_spi;
wire [9:0]raw_length;

wire tx_fifo_reready;

reg MOSI_d,MOSI_dd,MOSI_ddd;
always@(posedge clk or posedge reset) begin 
	if(reset) begin
		MOSI_d <= 'd0;
		MOSI_dd<= 'd0;
		MOSI_ddd<='d0;
	 end
	else      begin 
		MOSI_d <= MOSI_I;
		MOSI_dd<= MOSI_d;
		MOSI_ddd<=MOSI_dd;
end
end
wire x0;
wire reset_tra_fifo;
//assign raw_length = cal_busy? 'd132:'d394;
SPI_TX_RX uSPI_TX_RX
(
.clk(clk),
.spi_clk(clk),
.rst(reset),
.rstn(rstn),//接收fifo复位 spi_phy复位
.reset_tra_fifo(reset_tra_fifo),
//.STATE(STATEaa),

.raw_length('d386),//('d394),//326+68 132
//.spike_length('d68),
//.spi_test0(spi_test),
//datawr
.raw_data(data_in),//data_in[7:0],data_in[15:8]}),//data_in),//~cal_busy),
.raw_data_valid(data_in_valid),//&&~cal_busy),
.spike_data(),
.spike_data_valid(),
.fifo_ready(),
.fifo_empty(fifo_empty),
.cal_busy(cal_busy),
//SPI
.SCK_I(SCK_I),
.MOSI_I(MOSI_I),
.CS_I(CS_I),
.MISO_O(MISO_O),

.data_valid(data_valid),
.rx_data(rx_data),
.t_data1(),
.data_entest(data_entest),


.wr_fifo_cho(0),///////
.tx_fifo_reready(tx_fifo_reready),//////////////



.tx_empty_raw0(tx_empty_raw0),
.tx_empty_raw1(tx_empty_raw1),
.x0(x0),
.x(x1)

);
reg [5:0]win_cnt0;
//assign tx_fifo_reready = 'd1;

assign fifo_ready = tx_fifo_reready;//1;

reg fifo_ready0;
always@(posedge clk or negedge rstn)
 begin 
  if(~rstn)
   begin 
    fifo_ready0 <= 'd0;
   end
   else 
    begin 
	 if(~fifo_ready)
	  begin 
	   if(win_cnt0== 'd0&&cntx == 'd0)
	    begin fifo_ready0<= 0; end
		else 
		 begin fifo_ready0<= 1; end
	  end	
	 else 
	  begin 
	  fifo_ready0<= 1;
	  end
	end
 end
 generate
	if (CHOSE_MODULE) begin: MODULE_CHOSE0
	//assign data_in_valid = valid_rd?valid_rd:(spi_valid&&(~cal_busy)&&wr_fifo_en); end
	assign data_in_valid = valid_rd?valid_rd:(spi_valid&&(~cal_busy)); end
	else begin: MODULE_CHOSE1
    assign data_in_valid = (cal_busy)?valid_rd:(spi_valid&&(~cal_busy)&&wr_fifo_en); end

endgenerate
generate
	if (CHOSE_MODULE) begin: MODULE_CHOSE2
	assign usbtx_ready = (fifo_ready0)||cal_busy;//(fifo_ready0)||cal_busy;//fifo_ready||cal_busy;//||cal_busy;//fifo_ready;//;////////////////////test
	end
	else begin: MODULE_CHOSE3
	assign usbtx_ready = 1 ;//fifo_ready||cal_busy;//||cal_busy;//fifo_ready;//;////////////////////test
	end
endgenerate
assign usbrx_data = rx_data;
		





// assign MISO_A2 = 'd0;
assign MISO_B1 = 'd0;
assign MISO_B2 = 'd0;
assign MISO_C1 = 'd0;
assign MISO_C2 = 'd0;

assign MISO_D1 = 'd0;
assign MISO_D2 = 'd0;
















//
reg										      sample_clk;
wire [15:0]								      TTL_in;
assign TTL_in = 16'd0;
wire [15:0]							          TTL_out;
wire										  DAC_SYNC;
wire										  DAC_SCLK;
wire										  DAC_DIN_1;
wire										  DAC_DIN_2;
wire										  DAC_DIN_3;
wire										  DAC_DIN_4;
wire										  DAC_DIN_5;
wire										  DAC_DIN_6;
wire										  DAC_DIN_7;
wire										  DAC_DIN_8;
wire										  ADC_CS;
wire										  ADC_SCLK;
wire										  ADC_DOUT_1;
wire										  ADC_DOUT_2;
wire										  ADC_DOUT_3;
wire										  ADC_DOUT_4;
wire										  ADC_DOUT_5;
wire										  ADC_DOUT_6;
wire										  ADC_DOUT_7;
wire										  ADC_DOUT_8;
wire [3:0]								      board_mode;


assign board_mode = 'd1;









//////////

wire [5:0]win_cnt; //窗统计
wire 				clk1;				// buffered 100 MHz clock
	wire				dataclk;			// programmable frequency clock (f = 2800 * per-channel amplifier sampling rate)
	wire				dataclk_locked, DCM_prog_done;
	assign dataclk_locked = 1;

	wire [15:0] 	FIFO_data_out;
	wire				FIFO_read_from;
	wire [31:0] 	num_words_in_FIFO;

	wire [9:0]		RAM_addr_wr;
	reg [9:0]		RAM_addr_rd;
	wire [3:0]		RAM_bank_sel_wr;
	reg [3:0]		RAM_bank_sel_rd;
	wire [15:0]		RAM_data_in;
	wire [15:0]		RAM_data_out_1_pre, RAM_data_out_2_pre, RAM_data_out_3_pre;
	reg [15:0]		RAM_data_out_1, RAM_data_out_2, RAM_data_out_3;
	wire				RAM_we_1, RAM_we_2, RAM_we_3;
		
	reg [6:0] 		channel/* synthesis loc = "SLICE_R15C19D" */;
	reg [6:0]   channel_MISO;
	reg [6:0]channel_chose;  // varies from 0-34 (amplfier channels 0-31, plus 3 auxiliary commands)
	reg [15:0] 		MOSI_cmd_A, MOSI_cmd_B, MOSI_cmd_C, MOSI_cmd_D;
	
	reg [73:0] 		in4x_A1, in4x_A2;
	reg [73:0] 		in4x_B1, in4x_B2;
	reg [73:0] 		in4x_C1, in4x_C2;
	reg [73:0] 		in4x_D1, in4x_D2;
	wire [15:0] 	in_A1, in_A2;
	wire [15:0] 	in_B1, in_B2;
	wire [15:0] 	in_C1, in_C2;
	wire [15:0] 	in_D1, in_D2;
	wire [31:0] 	in_DDR_A1, in_DDR_A2;
	wire [31:0] 	in_DDR_B1, in_DDR_B2;
	wire [31:0] 	in_DDR_C1, in_DDR_C2;
	wire [31:0] 	in_DDR_D1, in_DDR_D2;
	
	wire [3:0] 		delay_A, delay_B, delay_C, delay_D;
	
	reg [15:0] 		result_A1, result_A2;
	reg [15:0] 		result_B1, result_B2;
	reg [15:0] 		result_C1, result_C2;
	reg [15:0] 		result_D1, result_D2;
	reg [31:0] 		result_DDR_A1, result_DDR_A2;
	reg [31:0] 		result_DDR_B1, result_DDR_B2;
	reg [31:0] 		result_DDR_C1, result_DDR_C2;
	reg [31:0] 		result_DDR_D1, result_DDR_D2;

	reg [31:0] 		timestamp;			 
	//reg [31:0] 		timestamp;	
	reg [31:0]		max_timestep;
	wire [31:0]		max_timestep_in;
	wire [31:0] 	data_stream_timestamp;
	wire [63:0]		header_magic_number;
	wire [15:0]		data_stream_filler;
	assign data_stream_filler = 16'd0;
	reg [15:0]		data_stream_1, data_stream_2, data_stream_3, data_stream_4;
	reg [15:0]		data_stream_5, data_stream_6, data_stream_7, data_stream_8;
	reg [3:0]		data_stream_1_sel, data_stream_2_sel, data_stream_3_sel, data_stream_4_sel;
	reg [3:0]		data_stream_5_sel, data_stream_6_sel, data_stream_7_sel, data_stream_8_sel;
	wire [3:0]	 data_stream_2_sel_in, data_stream_3_sel_in, data_stream_4_sel_in;
	reg  [3:0]  data_stream_1_sel_in;
	wire [3:0]		data_stream_5_sel_in, data_stream_6_sel_in, data_stream_7_sel_in, data_stream_8_sel_in;
	reg				data_stream_1_en, data_stream_2_en, data_stream_3_en, data_stream_4_en;
	reg				data_stream_5_en, data_stream_6_en, data_stream_7_en, data_stream_8_en;
	wire				data_stream_1_en_in, data_stream_2_en_in, data_stream_3_en_in, data_stream_4_en_in;
	wire				data_stream_5_en_in, data_stream_6_en_in, data_stream_7_en_in, data_stream_8_en_in;
	
	reg [15:0]		data_stream_TTL_in, data_stream_TTL_out;
	wire [15:0]		data_stream_ADC_1, data_stream_ADC_2, data_stream_ADC_3, data_stream_ADC_4;
	wire [15:0]		data_stream_ADC_5, data_stream_ADC_6, data_stream_ADC_7, data_stream_ADC_8;
	
	wire				TTL_out_mode;
	reg [15:0]		TTL_out_user;
	
	
	reg				SPI_running;

	wire [8:0]		dataclk_M;


	wire		   DCM_prog_trigger;
	wire           DSP_settle;

	wire [15:0] 	MOSI_cmd_selected_A, MOSI_cmd_selected_B, MOSI_cmd_selected_C, MOSI_cmd_selected_D;

	reg [15:0] 		aux_cmd_A, aux_cmd_B, aux_cmd_C, aux_cmd_D;
	reg [9:0] 		aux_cmd_index_1, aux_cmd_index_2, aux_cmd_index_3;
	wire [9:0] 		max_aux_cmd_index_1_in, max_aux_cmd_index_2_in, max_aux_cmd_index_3_in;
	reg [9:0] 		max_aux_cmd_index_1, max_aux_cmd_index_2, max_aux_cmd_index_3;
	reg [9:0]		loop_aux_cmd_index_1, loop_aux_cmd_index_2, loop_aux_cmd_index_3;

	wire [3:0] 		aux_cmd_bank_1_A_in, aux_cmd_bank_1_B_in, aux_cmd_bank_1_C_in, aux_cmd_bank_1_D_in;
	wire [3:0] 		aux_cmd_bank_2_A_in, aux_cmd_bank_2_B_in, aux_cmd_bank_2_C_in, aux_cmd_bank_2_D_in;
	wire [3:0] 		aux_cmd_bank_3_A_in, aux_cmd_bank_3_B_in, aux_cmd_bank_3_C_in, aux_cmd_bank_3_D_in;
	reg [3:0] 		aux_cmd_bank_1_A, aux_cmd_bank_1_B, aux_cmd_bank_1_C, aux_cmd_bank_1_D;
	reg [3:0] 		aux_cmd_bank_2_A, aux_cmd_bank_2_B, aux_cmd_bank_2_C, aux_cmd_bank_2_D;
	reg [3:0] 		aux_cmd_bank_3_A, aux_cmd_bank_3_B, aux_cmd_bank_3_C, aux_cmd_bank_3_D;

	reg				external_fast_settle_enable;
	reg [3:0]		external_fast_settle_channel;
	reg				external_fast_settle, external_fast_settle_prev;

	reg				external_digout_enable_A, external_digout_enable_B, external_digout_enable_C, external_digout_enable_D;
	reg [3:0]		external_digout_channel_A, external_digout_channel_B, external_digout_channel_C, external_digout_channel_D;
	reg				external_digout_A, external_digout_B, external_digout_C, external_digout_D;
	
	wire [7:0]		led_in;

	// Opal Kelly USB Host Interface
	
	wire        ti_clk;		// 48 MHz clock from Opal Kelly USB interface


	wire [15:0] ep00wirein, ep01wirein, ep02wirein, ep03wirein, ep04wirein, ep05wirein, ep06wirein, ep07wirein;
	wire [15:0] ep08wirein, ep09wirein, ep0awirein, ep0bwirein, ep0cwirein, ep0dwirein, ep0ewirein, ep0fwirein;
	wire [15:0] ep10wirein, ep11wirein, ep12wirein, ep13wirein, ep14wirein, ep15wirein, ep16wirein, ep17wirein;
	wire [15:0] ep18wirein, ep19wirein, ep1awirein, ep1bwirein, ep1cwirein, ep1dwirein, ep1ewirein, ep1fwirein;

	wire [15:0] ep20wireout, ep21wireout, ep22wireout, ep23wireout, ep24wireout, ep25wireout, ep26wireout, ep27wireout;
	wire [15:0] ep28wireout, ep29wireout, ep2awireout, ep2bwireout, ep2cwireout, ep2dwireout, ep2ewireout, ep2fwireout;
	wire [15:0] ep30wireout, ep31wireout, ep32wireout, ep33wireout, ep34wireout, ep35wireout, ep36wireout, ep37wireout;
	wire [15:0] ep38wireout, ep39wireout, ep3awireout, ep3bwireout, ep3cwireout, ep3dwireout, ep3ewireout, ep3fwireout;

	wire [15:0] ep40trigin, ep41trigin, ep42trigin, ep43trigin, ep44trigin, ep45trigin, ep46trigin,ep47trigin,ep49trigin,ep50trigin,ep53trigin;
wire clk_100M;
assign start_Impedance_test = ep50trigin[0];
	// USB WireIn inputs
	reg rst_com,rst_com_d;
	reg SPI_run_continuousd;

wire SPI_run_continuous;
assign SPI_run_continuous = 1;//cal_busy?'d1:ep00wirein[1];
assign SPI_start = 			1;//cal_busy?'d1:ep41trigin[0];
wire [15:0]thre_64_95; 
wire [15:0]thre_96_127; 
	wire rst_thre_c;
	assign reset_tra_fifo = (SPI_run_continuousd&&~SPI_run_continuous)||rst_thre_c;
always@(posedge clk or negedge rstn)
 begin
  if(~rstn) begin
	 rst_com <= 'd0;
	 rst_com_d <= 'd0;
	 SPI_run_continuousd <=0; 
  end
  else 
  begin
	rst_com <= ep00wirein[0];
	rst_com_d<=rst_com;
	SPI_run_continuousd <=SPI_run_continuous; 
  end
 end
wire start_cal;
wire reset_fifo;
	//assign reset = 					    cal_busy?'d0:(reset_tra_fifo||ep00wirein[0]||(~rstn)||start_cal||reset_fifo);////////���ָ�λ����Ч��
assign reset = 					    cal_busy?'d0:(reset_tra_fifo||ep00wirein[0]||(~rstn)||start_cal||reset_fifo);
	assign DSP_settle =     			cal_busy?'d1:ep00wirein[2];
	//assign TTL_out_mode = 				ep00wirein[3];
	//assign DAC_noise_suppress = 		ep00wirein[12:6];
	//assign DAC_gain = 					ep00wirein[15:13];

	assign max_timestep_in[15:0] = 	ep01wirein;
	assign max_timestep_in[31:16] =	ep02wirein;

	always @(posedge dataclk) begin
		max_timestep <= 0;//max_timestep_in;
	end

	//assign dataclk_M = 					{ 1'b0, ep03wirein[15:8] };
	assign dataclk_D = 					{ 1'b0, ep03wirein[7:0] };

	assign delay_A = 						cal_busy?'d0:ep04wirein[3:0];
	assign delay_B = 						ep04wirein[7:4];
	assign delay_C = 						ep04wirein[11:8];
	assign delay_D = 						ep04wirein[15:12];
	
	assign RAM_addr_wr = 				{1'd0,ep05wirein[7:1]} + 8'd1;
	assign RAM_bank_sel_wr = 			{3'd0,ep05wirein[0]};	
	assign RAM_data_in = 				{1'd1,ep05wirein[6:0],ep07wirein[7:0]};

	assign aux_cmd_bank_1_A_in = 		0;//ep08wirein[3:0];
	assign aux_cmd_bank_1_B_in = 		0;//ep08wirein[7:4];
	assign aux_cmd_bank_1_C_in = 		0;//ep08wirein[11:8];
	assign aux_cmd_bank_1_D_in = 		0;//ep08wirein[15:12];

	assign aux_cmd_bank_2_A_in = 		0;//ep09wirein[3:0];
	assign aux_cmd_bank_2_B_in = 		0;//ep09wirein[7:4];
	assign aux_cmd_bank_2_C_in = 		0;//ep09wirein[11:8];
	assign aux_cmd_bank_2_D_in = 		0;//ep09wirein[15:12];

	assign aux_cmd_bank_3_A_in = 		0;//ep0awirein[3:0];
	assign aux_cmd_bank_3_B_in = 		0;//ep0awirein[7:4];
	assign aux_cmd_bank_3_C_in = 		0;//ep0awirein[11:8];
	assign aux_cmd_bank_3_D_in = 		0;//ep0awirein[15:12];
		
	assign max_aux_cmd_index_1_in = 	'd15;//ep0bwirein[9:0];
	assign max_aux_cmd_index_2_in = 	'd15;//ep0cwirein[9:0];
	assign max_aux_cmd_index_3_in = 	'd15;//ep0dwirein[9:0];

	always @(posedge dataclk) begin
		loop_aux_cmd_index_1 <=	'd15;//		start_Impedance_test?'d0:'d15;//ep0ewirein[9:0];
		loop_aux_cmd_index_2 <=	'd15;//		start_Impedance_test?'d0:'d15;//ep0fwirein[9:0];
		loop_aux_cmd_index_3 <=	'd15;//		start_Impedance_test?'d0:'d15;//ep10wirein[9:0];
	end
    wire thre_cho;
	assign thre_cho = ep11wirein[7:0];
	//assign led_in =  		   			ep11wirein[7:0];
	reg channel_A_B;
	reg channel_en;


always@(*) begin
	case(ep47trigin[6:5])
	 'd0:begin data_stream_1_sel_in = 'd0; end
	 'd1:begin data_stream_1_sel_in = 'd1; end
	 'd2:begin data_stream_1_sel_in = 'd2; end
	 'd3:begin data_stream_1_sel_in = 'd3; end
	endcase
 end


	//assign data_stream_1_sel_in = channel_en?	2:0;//ep12wirein[3:0];
	assign data_stream_2_sel_in = channel_en?	3:1;//ep12wirein[7:4];
	assign data_stream_3_sel_in = 	0;//[11:8];
	assign data_stream_4_sel_in = 	0;//[15:12];
	//assign data_stream_5_sel_in = 	ep13wirein[3:0];
	//assign data_stream_6_sel_in = 	ep13wirein[7:4];
	//assign data_stream_7_sel_in = 	ep13wirein[11:8];
	//assign data_stream_8_sel_in = 	ep13wirein[15:12];

   assign data_stream_1_en_in = 		1;//ep14wirein[0];
   assign data_stream_2_en_in = 		0;//ep14wirein[1];
   assign data_stream_3_en_in = 		0;//ep14wirein[2];
   assign data_stream_4_en_in = 		0;//ep14wirein[3];
   assign data_stream_5_en_in = 		0;//ep14wirein[4];
   assign data_stream_6_en_in = 		0;//ep14wirein[5];
   assign data_stream_7_en_in = 		0;//ep14wirein[6];
   assign data_stream_8_en_in = 		0;//ep14wirein[7];

	
	// USB TriggerIn inputs

	assign DCM_prog_trigger = 			ep40trigin[0];
	


	assign RAM_we_1 = 					ep08wirein[0];//ep42trigin[0];
	// assign RAM_we_2 = 					ep08wirein[0];//ep42trigin[1];
	// assign RAM_we_3 = 					ep08wirein[0];//ep42trigin[2];

assign data_stream_filler = 16'd0;
reg [15:0]wr_reg;
// RAM_bank_two RAM_bank_1(
// 		.clk_A(dataclk),
// 		.clk_B(dataclk),
// 		.RAM_bank_sel_A(RAM_bank_sel_wr),
// 		.RAM_bank_sel_B(RAM_bank_sel_rd),
// 		.RAM_addr_A(RAM_addr_wr),
// 		.RAM_addr_B(RAM_addr_rd),
// 		.RAM_data_in(RAM_data_in),
// 		.RAM_data_out_A(),
// 		.RAM_data_out_B(RAM_data_out_1_pre),
// 		.RAM_we(RAM_we_1),//ep42trigin[0]),
// 		.reset(~rstn)
// 	);

	RAM_bank RAM_bank_3(
		.clk_A(dataclk),
		.clk_B(dataclk),
		.RAM_bank_sel_A(RAM_bank_sel_wr),
		.RAM_bank_sel_B(RAM_bank_sel_rd),
		.RAM_addr_A(RAM_addr_wr),
		.RAM_addr_B(RAM_addr_rd),
		.RAM_data_in(RAM_data_in),
		.RAM_data_out_A(),
        .RAM_data_out_B0(RAM_data_out_1_pre),
        .RAM_data_out_B1(RAM_data_out_2_pre),
        .RAM_data_out_B2(RAM_data_out_3_pre),
		.RAM_we(RAM_we_1),//RAM_we_3),//ep42trigin[0]),
		.reset('d0)
	);


	wire external_fast_settle_rising_edge, external_fast_settle_falling_edge;
	assign external_fast_settle_rising_edge = external_fast_settle_prev == 1'b0 && external_fast_settle == 1'b1;
	assign external_fast_settle_falling_edge = external_fast_settle_prev == 1'b1 && external_fast_settle == 1'b0;
	
	// If the user has enabled external fast settling of amplifiers, inject commands to set fast settle
	// (bit D[5] in RAM Register 0) on a rising edge and reset fast settle on a falling edge of the control
	// signal.  We only inject commands in the auxcmd1 slot, since this is typically used only for setting
	// impedance test waveforms.
	/*
	always @(*) begin
		if(cal_busy) begin RAM_data_out_1 <= 16'h8490; end
		else begin RAM_data_out_1 <= RAM_data_out_1_pre;end//RAM_data_out_1_pre; end
		//RAM_data_out_1 <= RAM_data_out_1_pre;//RAM_data_out_1_pre; 
		//if (external_fast_settle_enable == 1'b0)
		//	RAM_data_out_1 <= RAM_data_out_1_pre; // If external fast settle is disabled, pass command from RAM
		//else if (external_fast_settle_rising_edge)
		//	RAM_data_out_1 <= 16'h80fe; // Send WRITE(0, 254) command to set fast settle when rising edge detected.
		//else if (external_fast_settle_falling_edge)
		//	RAM_data_out_1 <= 16'h80de; // Send WRITE(0, 222) command to reset fast settle when falling edge detected.
		//else if (RAM_data_out_1_pre[15:8] == 8'h80)
		//	// If the user tries to write to Register 0, override it with the external fast settle value.
		//	RAM_data_out_1 <= { RAM_data_out_1_pre[15:6], external_fast_settle, RAM_data_out_1_pre[4:0] };
		//else RAM_data_out_1 <= RAM_data_out_1_pre; // Otherwise pass command from RAM.
	end
	always @(*) begin
		if (external_fast_settle_enable == 1'b1 && RAM_data_out_3_pre[15:8] == 8'h80)
			// If the user tries to write to Register 0 when external fast settle is enabled, override it
			// with the external fast settle value.
			RAM_data_out_3 <= { RAM_data_out_3_pre[15:6], external_fast_settle, RAM_data_out_3_pre[4:0] };
		else RAM_data_out_3 <= RAM_data_out_3_pre;
	end
*/




reg [13:0]ADC_DATA;
reg [7:0]sin_data;
pmi_rom 
#(
  .pmi_addr_depth       (32 ), // integer       
  .pmi_addr_width       (5 ), // integer       
  .pmi_data_width       (8 ), // integer       
  .pmi_regmode          ("reg" ), // "reg"|"noreg"
  .pmi_resetmode        ("sync" ), // "async"|"sync"	
  .pmi_init_file        ( "D:/YCB/YCB/PROJECT/BCI2024/sin_lut.hex"), // string		
  .pmi_init_file_format ("hex"  ), // "binary"|"hex"    
  .pmi_family           ("common" )  // "common"
) pmi_rom_sin (
  .Address    ({ADC_DATA[3:0],1'd0} ),  // I:
  .OutClock   ( dataclk),  // I:
  .OutClockEn ( 1),  // I:
  .Reset      (~rstn ),  // I:
  .Q          (sin_data )   // O:
);










always @(*) begin
	 RAM_data_out_1 <= (start_Impedance_test)?16'h8559: (closeRHD? 16'h80ce:RAM_data_out_1_pre);
end
always @(*) begin
	 RAM_data_out_2 <= (start_Impedance_test)?{8'h87,{2'd0,ep47trigin[5:0]}}:RAM_data_out_2_pre;
end
always @(*) begin
     RAM_data_out_3 <=start_Impedance_test? {8'h86,sin_data}:0;
end
	command_selector command_selector_A (
		.channel(channel[5:0]), .DSP_settle(0), .aux_cmd(aux_cmd_A), .digout_override(0), .MOSI_cmd(MOSI_cmd_selected_A));
//assign  MOSI_cmd_selected_A = {2'b11,6'd59,8'd0};
	command_selector command_selector_B (
		.channel(channel[5:0]), .DSP_settle(0), .aux_cmd(aux_cmd_B), .digout_override(0),  .MOSI_cmd(MOSI_cmd_selected_B));

reg [15:0]datacnt;

	assign header_magic_number = 64'hC691199927021942;  // Fixed 64-bit "magic number" that begins each data frame
																		 // to aid in synchronization.
	assign data_stream_filler = 16'd0;


	// USB WireOut outputs

	//assign ep20wireout = 				num_words_in_FIFO[15:0];
	//assign ep21wireout = 				num_words_in_FIFO[31:16];
	//
	//assign ep22wireout = 				{ 15'b0, SPI_running };
	//	
	//assign ep23wireout = 				'd0;
	//
	//assign ep24wireout = 				{ 14'b0, DCM_prog_done, dataclk_locked };
	//
	//assign ep25wireout = 				{ 12'b0, board_mode };
	//
//
	//// Unused; future expansion
	//assign ep26wireout = 				16'h0000;
	//assign ep27wireout = 				16'h0000;
	//assign ep28wireout = 				16'h0000;
	//assign ep29wireout = 				16'h0000;
	//assign ep2awireout = 				16'h0000;
	//assign ep2bwireout = 				16'h0000;
	//assign ep2cwireout = 				16'h0000;
	//assign ep2dwireout = 				16'h0000;
	//assign ep2ewireout = 				16'h0000;
	//assign ep2fwireout = 				16'h0000;
	//assign ep30wireout = 				16'h0000;
	//assign ep31wireout = 				16'h0000;
	//assign ep32wireout = 				16'h0000;
	//assign ep33wireout = 				16'h0000;
	//assign ep34wireout = 				16'h0000;
	//assign ep35wireout = 				16'h0000;
	//assign ep36wireout = 				16'h0000;
	//assign ep37wireout = 				16'h0000;
	//assign ep38wireout = 				16'h0000;
	//assign ep39wireout = 				16'h0000;
	//assign ep3awireout = 				16'h0000;
	//assign ep3bwireout = 				16'h0000;
	//assign ep3cwireout = 				16'h0000;
	//assign ep3dwireout = 				16'h0000;
	//	localparam BOARD_ID = 16'd500;
	//localparam BOARD_VERSION = 16'h135;
	//assign ep3ewireout = 				BOARD_ID;
	//assign ep3fwireout = 				BOARD_VERSION;
	
	reg [15:0]threshold_h,threshold_l;
	// 8-LED Display on Opal Kelly board
	
	// assign led = ~{ led_in };
	
	
	// // Variable frequency data clock generator
	
	// variable_freq_clk_generator #(
	// 	.M_DEFAULT     (42),		// default sample frequency = 30 kS/s/channel
	// 	.D_DEFAULT		(25)
	// 	)
	// variable_freq_clk_generator_inst
	// 	(
	// 	.clk1					(clk1),
	// 	.ti_clk				(ti_clk),
	// 	.reset				(reset),
	// 	.M						(dataclk_M),
	// 	.D						(dataclk_D),
	// 	.DCM_prog_trigger	(DCM_prog_trigger),
	// 	.clkout				(dataclk),
	// 	.DCM_prog_done		(DCM_prog_done),
	// 	.locked				(dataclk_locked)
	// 	);




reg [15:0]spike_in;
reg spike_in_valid;



wire one_packet;//指示完整一包数据
reg one_packet_d;
//assign ep47trigin = 0;
//assign channel_en = ep47trigin[6];
//	assign channel_chose =  {1'b0,ep47trigin[5:0]} + 7'd3	;	
always@(posedge clk or negedge rstn)
begin
 if(~rstn)
  begin
   one_packet_d <= 0;//ep47trigin[6];
  end
   else 
    begin 
	  one_packet_d <=one_packet;
      // channel_chose <=  channel_chose	;
	end
end
wire one_pack_v;
assign one_pack_v = one_packet&&~one_packet_d;
always@(posedge clk or posedge rst_com_d)
begin
 if(rst_com_d)
  begin
   channel_en <= 0;//ep47trigin[6];
   channel_A_B<= 0;
   channel_chose <= 3;// {1'b0,ep47trigin[5:0]} + 7'd3	;
   
  end
  else if((one_packet&&~one_packet_d)||(main_state[7]&&main_state[5]))
   begin 
   channel_en <= ep47trigin[5];
   channel_A_B<= ep47trigin[6];
   channel_chose <=  {1'b0,ep47trigin[4:0]} + 7'd3	;
   end
   else 
    begin 
	   channel_en <= channel_en;
	   channel_A_B<= channel_A_B;
       channel_chose <=  channel_chose	;
	end
end
wire [6:0]channel_tra;
assign channel_tra = channel_chose - 'd3;
	//assign header_magic_number = 64'hC691199927021942;  // Fixed 64-bit "magic number" that begins each data frame

	//assign channel_chose0 = ep47trigin[5:0]+ 'd3;															 // to aid in synchronization.

reg [31:0]ila_data;////1写入Wiener_data 0写入0
reg updata_reg_v;
wire[16*4-1:0]Wiener_data;
    wire [15:0]RAWHEADER;
	wire [15:0]SPIKEHEADER;
    assign RAWHEADER = 16'hC691;
    assign SPIKEHEADER = 16'h1999;
   localparam
			                      ms_wait    = 80,//  ms_wait    = 99,
	            	              ms_clk1_a  = 00,//  ms_clk1_a  = 100,
			    			      ms_clk1_b  = 01,//  ms_clk1_b  = 101,
                                  ms_clk1_c  = 02,//  ms_clk1_c  = 102,
                                  ms_clk1_d  = 03,//  ms_clk1_d  = 103,
			    			      ms_clk2_a  = 04,//  ms_clk2_a  = 104,
			    			      ms_clk2_b  = 05,//  ms_clk2_b  = 105,
                                  ms_clk2_c  = 06,//  ms_clk2_c  = 106,
                                  ms_clk2_d  = 07,//  ms_clk2_d  = 107,
			    			      ms_clk3_a  = 08,//  ms_clk3_a  = 108,
			    			      ms_clk3_b  = 09,//  ms_clk3_b  = 109,
                                  ms_clk3_c  = 10,//  ms_clk3_c  = 110,
                                  ms_clk3_d  = 11,//  ms_clk3_d  = 111,
			    			      ms_clk4_a  = 12,//  ms_clk4_a  = 112,
			    			      ms_clk4_b  = 13,//  ms_clk4_b  = 113,
                                  ms_clk4_c  = 14,//  ms_clk4_c  = 114,
                                  ms_clk4_d  = 15,//  ms_clk4_d  = 115,
			    			      ms_clk5_a  = 16,//  ms_clk5_a  = 116,
			    			      ms_clk5_b  = 17,//  ms_clk5_b  = 117,
                                  ms_clk5_c  = 18,//  ms_clk5_c  = 118,
                                  ms_clk5_d  = 19,//  ms_clk5_d  = 119,
			    			      ms_clk6_a  = 20,//  ms_clk6_a  = 120,
			    			      ms_clk6_b  = 21,//  ms_clk6_b  = 121,
                                  ms_clk6_c  = 22,//  ms_clk6_c  = 122,
                                  ms_clk6_d  = 23,//  ms_clk6_d  = 123,
			    			      ms_clk7_a  = 24,//  ms_clk7_a  = 124,
			    			      ms_clk7_b  = 25,//  ms_clk7_b  = 125,
                                  ms_clk7_c  = 26,//  ms_clk7_c  = 126,
                                  ms_clk7_d  = 27,//  ms_clk7_d  = 127,
			    			      ms_clk8_a  = 28,//  ms_clk8_a  = 128,
			    			      ms_clk8_b  = 29,//  ms_clk8_b  = 129,
                                  ms_clk8_c  = 30,//  ms_clk8_c  = 130,
                                  ms_clk8_d  = 31,//  ms_clk8_d  = 131,
			    			      ms_clk9_a  = 32,//  ms_clk9_a  = 132,
			    			      ms_clk9_b  = 33,//  ms_clk9_b  = 133,
                                  ms_clk9_c  = 34,//  ms_clk9_c  = 134,
                                  ms_clk9_d  = 35,//  ms_clk9_d  = 135,
			    			      ms_clk10_a = 36,//  ms_clk10_a = 136,
			    			      ms_clk10_b = 37,//  ms_clk10_b = 137,
                                  ms_clk10_c = 38,//  ms_clk10_c = 138,
                                  ms_clk10_d = 39,//  ms_clk10_d = 139,
			    			      ms_clk11_a = 40,//  ms_clk11_a = 140,
			    			      ms_clk11_b = 41,//  ms_clk11_b = 141,
                                  ms_clk11_c = 42,//  ms_clk11_c = 142,
                                  ms_clk11_d = 43,//  ms_clk11_d = 143,
			    			      ms_clk12_a = 44,//  ms_clk12_a = 144,
			    			      ms_clk12_b = 45,//  ms_clk12_b = 145,
                                  ms_clk12_c = 46,//  ms_clk12_c = 146,
                                  ms_clk12_d = 47,//  ms_clk12_d = 147,
			    			      ms_clk13_a = 48,//  ms_clk13_a = 148,
			    			      ms_clk13_b = 49,//  ms_clk13_b = 149,
                                  ms_clk13_c = 50,//  ms_clk13_c = 150,
                                  ms_clk13_d = 51,//  ms_clk13_d = 151,
			    			      ms_clk14_a = 52,//  ms_clk14_a = 152,
			    			      ms_clk14_b = 53,//  ms_clk14_b = 153,
                                  ms_clk14_c = 54,//  ms_clk14_c = 154,
                                  ms_clk14_d = 55,//  ms_clk14_d = 155,
			    			      ms_clk15_a = 56,//  ms_clk15_a = 156,
			    			      ms_clk15_b = 57,//  ms_clk15_b = 157,
                                  ms_clk15_c = 58,//  ms_clk15_c = 158,
                                  ms_clk15_d = 59,//  ms_clk15_d = 159,
			    			      ms_clk16_a = 60,//  ms_clk16_a = 160,
			    			      ms_clk16_b = 61,//  ms_clk16_b = 161,
                                  ms_clk16_c = 62,//  ms_clk16_c = 162,
                                  ms_clk16_d = 63,//  ms_clk16_d = 163,
                                  ms_clk17_a = 64,//  ms_clk17_a = 164,
                                  ms_clk17_b = 65,//  ms_clk17_b = 165,
								  ms_cs_a    = 66,//  ms_cs_a    = 166,
								  ms_cs_b    = 67,//  ms_cs_b    = 167,
								  ms_cs_c    = 68,//  ms_cs_c    = 168,
								  ms_cs_d    = 69,//  ms_cs_d    = 169,
								  ms_cs_e    = 70,//  ms_cs_e    = 170,
								  ms_cs_f    = 71,//  ms_cs_f    = 171,
								  ms_cs_g    = 72,//  ms_cs_g    = 172,
								  ms_cs_h    = 73,//  ms_cs_h    = 173,
								  ms_cs_i    = 74,//  ms_cs_i    = 174,
								  ms_cs_j    = 75,//  ms_cs_j    = 175,
								  ms_cs_k    = 76,//  ms_cs_k    = 176,
								  ms_cs_l    = 77,//  ms_cs_l    = 177,
								  ms_cs_m    = 78,//  ms_cs_m    = 178,
								  ms_cs_n    = 79,//  ms_cs_n    = 179;
								  ms_cs_o    = 81,//  ms_cs_l    = 177,
								  ms_cs_p    = 82,//  ms_cs_m    = 178,
								  ms_cs_q    = 83,//  ms_cs_n    = 179;
								  ms_cs_r    = 84;//  ms_cs_n    = 179;



wire chochannel_arr0,chochannel_arr1;//指示当前选择通道
assign chochannel_arr = (channel == channel_chose);//&&~channel_en;
assign chochannel_arr1 = (channel == channel_chose)&&channel_en;
reg wiener_data_wr;////1写入Wiener_data 0写入0
				 	
	always @(posedge clk) begin
		if (reset) begin
			main_state <= ms_wait;
			//timestamp <= 32'd0;
			sample_clk <= 0;
			//channel <= 0;
			CS_b <= 1'b1;
			SCLK <= 1'b0;
			MOSI_A <= 1'b0;
			MOSI_B <= 1'b0;
			MOSI_C <= 1'b0;
			MOSI_D <= 1'b0;
			FIFO_data_in <= 16'b0;
			FIFO_write_to <= 1'b0;	
			spike_in <= 16'd0;
			spike_in_valid <= 1'd0;
			wireout_start <= 'd0;

RAM_bank_sel_rd <='d0;
RAM_addr_rd <='d0;
					max_aux_cmd_index_1 <= max_aux_cmd_index_1_in;
					max_aux_cmd_index_2 <= max_aux_cmd_index_2_in;
					max_aux_cmd_index_3 <= max_aux_cmd_index_3_in;
					aux_cmd_bank_1_A <= aux_cmd_bank_1_A_in;
					aux_cmd_bank_1_B <= aux_cmd_bank_1_B_in;
					aux_cmd_bank_1_C <= aux_cmd_bank_1_C_in;
					aux_cmd_bank_1_D <= aux_cmd_bank_1_D_in;
					aux_cmd_bank_2_A <= aux_cmd_bank_2_A_in;
					aux_cmd_bank_2_B <= aux_cmd_bank_2_B_in;
					aux_cmd_bank_2_C <= aux_cmd_bank_2_C_in;
					aux_cmd_bank_2_D <= aux_cmd_bank_2_D_in;
					aux_cmd_bank_3_A <= aux_cmd_bank_3_A_in;
					aux_cmd_bank_3_B <= aux_cmd_bank_3_B_in;
					aux_cmd_bank_3_C <= aux_cmd_bank_3_C_in;
					aux_cmd_bank_3_D <= aux_cmd_bank_3_D_in;
					
					data_stream_1_en <= data_stream_1_en_in;		// can only change USB streams after stopping SPI
					data_stream_2_en <= data_stream_2_en_in;
					data_stream_3_en <= data_stream_3_en_in;
					data_stream_4_en <= data_stream_4_en_in;
					data_stream_5_en <= data_stream_5_en_in;
					data_stream_6_en <= data_stream_6_en_in;
					data_stream_7_en <= data_stream_7_en_in;
					data_stream_8_en <= data_stream_8_en_in;
					data_stream_1_sel <= data_stream_1_sel_in;
					data_stream_2_sel <= data_stream_2_sel_in;
					data_stream_3_sel <= data_stream_3_sel_in;
					data_stream_4_sel <= data_stream_4_sel_in;
					data_stream_5_sel <= data_stream_5_sel_in;
					data_stream_6_sel <= data_stream_6_sel_in;
					data_stream_7_sel <= data_stream_7_sel_in;
					data_stream_8_sel <= data_stream_8_sel_in;


		end else begin
			CS_b <= 1'b0;
			SCLK <= 1'b0;
			FIFO_data_in <= 16'b0;
			FIFO_write_to <= 1'b0;
			spike_in <= 16'd0;
			spike_in_valid <= 1'd0;
			case (main_state)
			
				ms_wait: begin
			//		timestamp <= 32'd0;
					sample_clk <= 0;
					//channel <= 0;
					channel_MISO <= 33;	// channel of MISO output, accounting for 2-cycle pipeline in RHD2000 SPI interface (Bug fix: changed 2 to 33, 1/26/13)
					CS_b <= 1'b1;
					SCLK <= 1'b0;
					MOSI_A <= 1'b0;
					MOSI_B <= 1'b0;
					MOSI_C <= 1'b0;
					MOSI_D <= 1'b0;
					FIFO_data_in <= 16'b0;
					FIFO_write_to <= 1'b0;
					aux_cmd_index_1 <= 0;
					aux_cmd_index_2 <= 0;
					aux_cmd_index_3 <= 0;
					max_aux_cmd_index_1 <= max_aux_cmd_index_1_in;
					max_aux_cmd_index_2 <= max_aux_cmd_index_2_in;
					max_aux_cmd_index_3 <= max_aux_cmd_index_3_in;
					aux_cmd_bank_1_A <= aux_cmd_bank_1_A_in;
					aux_cmd_bank_1_B <= aux_cmd_bank_1_B_in;
					aux_cmd_bank_1_C <= aux_cmd_bank_1_C_in;
					aux_cmd_bank_1_D <= aux_cmd_bank_1_D_in;
					aux_cmd_bank_2_A <= aux_cmd_bank_2_A_in;
					aux_cmd_bank_2_B <= aux_cmd_bank_2_B_in;
					aux_cmd_bank_2_C <= aux_cmd_bank_2_C_in;
					aux_cmd_bank_2_D <= aux_cmd_bank_2_D_in;
					aux_cmd_bank_3_A <= aux_cmd_bank_3_A_in;
					aux_cmd_bank_3_B <= aux_cmd_bank_3_B_in;
					aux_cmd_bank_3_C <= aux_cmd_bank_3_C_in;
					aux_cmd_bank_3_D <= aux_cmd_bank_3_D_in;
					
					data_stream_1_en <= data_stream_1_en_in;		// can only change USB streams after stopping SPI
					data_stream_2_en <= data_stream_2_en_in;
					data_stream_3_en <= data_stream_3_en_in;
					data_stream_4_en <= data_stream_4_en_in;
					data_stream_5_en <= data_stream_5_en_in;
					data_stream_6_en <= data_stream_6_en_in;
					data_stream_7_en <= data_stream_7_en_in;
					data_stream_8_en <= data_stream_8_en_in;
					data_stream_1_sel <= data_stream_1_sel_in;
					data_stream_2_sel <= data_stream_2_sel_in;
					data_stream_3_sel <= data_stream_3_sel_in;
					data_stream_4_sel <= data_stream_4_sel_in;
					data_stream_5_sel <= data_stream_5_sel_in;
					data_stream_6_sel <= data_stream_6_sel_in;
					data_stream_7_sel <= data_stream_7_sel_in;
					data_stream_8_sel <= data_stream_8_sel_in;
					//FIFO_data_in <= header_magic_number[15:0];
					// DAC_pre_register_1 <= 16'h8000;		// set DACs to midrange, initially, to avoid loud 'pop' in audio at start
					// DAC_pre_register_2 <= 16'h8000;
					// DAC_pre_register_3 <= 16'h8000;
					// DAC_pre_register_4 <= 16'h8000;
					// DAC_pre_register_5 <= 16'h8000;
					// DAC_pre_register_6 <= 16'h8000;
					// DAC_pre_register_7 <= 16'h8000;
					// DAC_pre_register_8 <= 16'h8000;
					
					SPI_running <= 1'b0;

					if (SPI_start) begin
						main_state <= ms_cs_n;
					end
				end

				ms_cs_n: begin
					SPI_running <= 1'b1;
					MOSI_cmd_A <= MOSI_cmd_selected_A;
					MOSI_cmd_B <= MOSI_cmd_selected_B;
					//MOSI_cmd_C <= MOSI_cmd_selected_C;
					//MOSI_cmd_D <= MOSI_cmd_selected_D;
					MOSI_cmd_C <= 0;
					MOSI_cmd_D <= 0;
					CS_b <= 1'b1;
					main_state <= ms_clk1_a;
				end

				ms_clk1_a: begin
					if (channel == 0) begin				// sample clock goes high during channel 0 SPI command
						sample_clk <= 1'b1;
					end else begin
						sample_clk <= 1'b0;
					end

					if (channel == 0) begin				// grab TTL inputs, and grab current state of TTL outputs and manual DAC outputs
						data_stream_TTL_in <= TTL_in;
						data_stream_TTL_out <= TTL_out;
						
						// Route selected TTL input to external fast settle signal
						external_fast_settle_prev <= external_fast_settle;	// save previous value so we can detecting rising/falling edges
						external_fast_settle <= TTL_in[external_fast_settle_channel];
						
						// Route selected TLL inputs to external digout signal
						// external_digout_A <= external_digout_enable_A ? TTL_in[external_digout_channel_A] : 0;
						// external_digout_B <= external_digout_enable_B ? TTL_in[external_digout_channel_B] : 0;
						// external_digout_C <= external_digout_enable_C ? TTL_in[external_digout_channel_C] : 0;
						// external_digout_D <= external_digout_enable_D ? TTL_in[external_digout_channel_D] : 0;
 external_digout_A <=  0;////ycb
 external_digout_B <=  0;
 external_digout_C <=  0;
 external_digout_D <=  0;						
					end

					// if (channel == 0) begin				// update all DAC registers simultaneously
					// 	DAC_register_1 <= DAC_pre_register_1;
					// 	DAC_register_2 <= DAC_pre_register_2;
					// 	DAC_register_3 <= DAC_pre_register_3;
					// 	DAC_register_4 <= DAC_pre_register_4;
					// 	DAC_register_5 <= DAC_pre_register_5;
					// 	DAC_register_6 <= DAC_pre_register_6;
					// 	DAC_register_7 <= DAC_pre_register_7;
					// 	DAC_register_8 <= DAC_pre_register_8;
					// end

					MOSI_A <= MOSI_cmd_A[15];
					MOSI_B <= MOSI_cmd_B[15];
					MOSI_C <= MOSI_cmd_C[15];
					MOSI_D <= MOSI_cmd_D[15];
					main_state <= ms_clk1_b;
				end

				ms_clk1_b: begin
					// Note: After selecting a new RAM_addr_rd, we must wait two clock cycles before reading from the RAM
					if (channel == 31) begin
						RAM_addr_rd <= aux_cmd_index_1;
					end 
					else if (channel == 32) begin
						RAM_addr_rd <= aux_cmd_index_2;
					end 
					else if (channel == 33) begin
						RAM_addr_rd <= aux_cmd_index_3;
					end
//
//					if (channel == 0&&one_packet) begin
//						FIFO_data_in <= RAWHEADER;//header_magic_number[15:0];
//						//FIFO_data_in <= 'd11;
//						FIFO_write_to <= 1'b1;
//			         //   spike_data <=SPIKEHEADER;
//                     //   spike_data_valid <= 1;



//					end

					main_state <= ms_clk1_c;
				end

				ms_clk1_c: begin
					// Note: We only need to wait one clock cycle after selecting a new RAM_bank_sel_rd
					if (channel == 31) begin
						RAM_bank_sel_rd <= aux_cmd_bank_1_A;
					end 
					else if(channel == 33) begin 
						RAM_bank_sel_rd <= aux_cmd_bank_3_A;
					end 
					SCLK <= 1'b1;
					in4x_A1[0] <= MISO_A1; in4x_A2[0] <= MISO_A2;
					//in4x_B1[0] <= MISO_B1; in4x_B2[0] <= MISO_B2;
					//in4x_C1[0] <= MISO_C1; in4x_C2[0] <= MISO_C2;
					//in4x_D1[0] <= MISO_D1; in4x_D2[0] <= MISO_D2;					
					main_state <= ms_clk1_d;
				end
				
				ms_clk1_d: begin
					if (channel == 31) begin
						aux_cmd_A <= RAM_data_out_1;
					end else if (channel == 32) begin
						aux_cmd_A <= RAM_data_out_2;
					end else if (channel == 33) begin
						aux_cmd_A <= RAM_data_out_3;
					end

					if (channel == 0&&win_cnt==0&&cntx == 0) begin
						//FIFO_data_in <= header_magic_number[47:32];
						//FIFO_data_in <= 'd33;
						//FIFO_write_to <= 1'b0;
					end

					SCLK <= 1'b1;
					in4x_A1[1] <= MISO_A1; in4x_A2[1] <= MISO_A2;
					//in4x_B1[1] <= MISO_B1; in4x_B2[1] <= MISO_B2;
					//in4x_C1[1] <= MISO_C1; in4x_C2[1] <= MISO_C2;
					//in4x_D1[1] <= MISO_D1; in4x_D2[1] <= MISO_D2;				
					main_state <= ms_clk2_a;
				end

				ms_clk2_a: begin
					if (channel == 31) begin
						RAM_bank_sel_rd <= aux_cmd_bank_1_B;
					end else if (channel == 32) begin
						RAM_bank_sel_rd <= aux_cmd_bank_2_B;
					end else if (channel == 33) begin
						RAM_bank_sel_rd <= aux_cmd_bank_3_B;
					end
					if (channel == 0&&one_packet) begin
					//	FIFO_data_in <= header_magic_number[63:48];
						//FIFO_data_in <= 'd44;
					//	FIFO_write_to <= 1'b0;
					end

					MOSI_A <= MOSI_cmd_A[14];
					MOSI_B <= MOSI_cmd_B[14];
					MOSI_C <= MOSI_cmd_C[14];
					MOSI_D <= MOSI_cmd_D[14];
					in4x_A1[2] <= MISO_A1; in4x_A2[2] <= MISO_A2;
					//in4x_B1[2] <= MISO_B1; in4x_B2[2] <= MISO_B2;
					//in4x_C1[2] <= MISO_C1; in4x_C2[2] <= MISO_C2;
					//in4x_D1[2] <= MISO_D1; in4x_D2[2] <= MISO_D2;				
					main_state <= ms_clk2_b;
				end

				ms_clk2_b: begin
					if (channel == 31) begin
						aux_cmd_B <= RAM_data_out_1;
					end else if (channel == 32) begin
						aux_cmd_B <= RAM_data_out_1;
					end else if (channel == 33) begin
						aux_cmd_B <= RAM_data_out_3;
					end

	//				if (channel == 0&&one_packet) begin
	//					FIFO_data_in <= timestamp[15:0];
	//					FIFO_write_to <= 1'b1;
	//				end

					in4x_A1[3] <= MISO_A1; in4x_A2[3] <= MISO_A2;
					//in4x_B1[3] <= MISO_B1; in4x_B2[3] <= MISO_B2;
					//in4x_C1[3] <= MISO_C1; in4x_C2[3] <= MISO_C2;
					//in4x_D1[3] <= MISO_D1; in4x_D2[3] <= MISO_D2;				
					main_state <= ms_clk2_c;
				end

				ms_clk2_c: begin
					if (channel == 31) begin
						RAM_bank_sel_rd <= aux_cmd_bank_1_C;
					end else if (channel == 32) begin
						RAM_bank_sel_rd <= aux_cmd_bank_2_C;
					end else if (channel == 33) begin
						RAM_bank_sel_rd <= aux_cmd_bank_3_C;
					end

					SCLK <= 1'b1;
					in4x_A1[4] <= MISO_A1; in4x_A2[4] <= MISO_A2;
					//in4x_B1[4] <= MISO_B1; in4x_B2[4] <= MISO_B2;
					//in4x_C1[4] <= MISO_C1; in4x_C2[4] <= MISO_C2;
					//in4x_D1[4] <= MISO_D1; in4x_D2[4] <= MISO_D2;					
					main_state <= ms_clk2_d;
				end
				
                ms_clk2_d: begin
					if (channel == 31) begin
						aux_cmd_C <= RAM_data_out_1;
					end else if (channel == 32) begin
						aux_cmd_C <= RAM_data_out_2;
					end else if (channel == 33) begin
						aux_cmd_C <= RAM_data_out_3;
					end

					//if (data_stream_1_en == 1'b1&&channel != 0) begin
					if (data_stream_1_en == 1'b1&&chochannel_arr) begin //channel == channel_chose&&~channel_en) begin
						FIFO_data_in <=data_stream_1; //{data_stream_1[7:0],data_stream_1[15:8]};//data_stream_1;//双通道32bit
						//FIFO_data_in <= 16'h1122;//双通道32bit
						FIFO_write_to <= 1'b1;
					end


					SCLK <= 1'b1;
					in4x_A1[5] <= MISO_A1; in4x_A2[5] <= MISO_A2;
					//in4x_B1[5] <= MISO_B1; in4x_B2[5] <= MISO_B2;
					//in4x_C1[5] <= MISO_C1; in4x_C2[5] <= MISO_C2;
					//in4x_D1[5] <= MISO_D1; in4x_D2[5] <= MISO_D2;				
					main_state <= ms_clk3_a;
				end
				
				ms_clk3_a: begin
					if (data_stream_1_en == 1'b1) begin
						//spike_in <= data_stream_2;//双通道32bit
						spike_in_valid <= 1'b1;
					end


					MOSI_A <= MOSI_cmd_A[13];
					MOSI_B <= MOSI_cmd_B[13];
					MOSI_C <= MOSI_cmd_C[13];
					MOSI_D <= MOSI_cmd_D[13];
					in4x_A1[6] <= MISO_A1; in4x_A2[6] <= MISO_A2;
					//in4x_B1[6] <= MISO_B1; in4x_B2[6] <= MISO_B2;
					//in4x_C1[6] <= MISO_C1; in4x_C2[6] <= MISO_C2;
					//in4x_D1[6] <= MISO_D1; in4x_D2[6] <= MISO_D2;				
					main_state <= ms_clk3_b;
				end

				ms_clk3_b: begin

			//		if (data_stream_3_en == 1'b1&&channel == channel_chose) begin
			//			FIFO_data_in <= data_stream_3;
			//			FIFO_write_to <= 1'b1;
			//		end
// if (data_stream_2_en == 1'b1&&chochannel_arr1) begin //&&channel == channel_chose&&channel_en) begin
// 	FIFO_data_in <= data_stream_2;//{data_stream_2[7:0],data_stream_2[15:8]};//双通道32bit
// 	FIFO_write_to <= 1'b1;
// end
					in4x_A1[7] <= MISO_A1; in4x_A2[7] <= MISO_A2;
					//in4x_B1[7] <= MISO_B1; in4x_B2[7] <= MISO_B2;
					//in4x_C1[7] <= MISO_C1; in4x_C2[7] <= MISO_C2;
					//in4x_D1[7] <= MISO_D1; in4x_D2[7] <= MISO_D2;				
					main_state <= ms_clk3_c;
				end

				ms_clk3_c: begin
					SCLK <= 1'b1;
					in4x_A1[8] <= MISO_A1; in4x_A2[8] <= MISO_A2;
					//in4x_B1[8] <= MISO_B1; in4x_B2[8] <= MISO_B2;
					//in4x_C1[8] <= MISO_C1; in4x_C2[8] <= MISO_C2;
					//in4x_D1[8] <= MISO_D1; in4x_D2[8] <= MISO_D2;					
					main_state <= ms_clk3_d;
				end
				
				ms_clk3_d: begin

					SCLK <= 1'b1;
					in4x_A1[9] <= MISO_A1; in4x_A2[9] <= MISO_A2;
					//in4x_B1[9] <= MISO_B1; in4x_B2[9] <= MISO_B2;
					//in4x_C1[9] <= MISO_C1; in4x_C2[9] <= MISO_C2;
					//in4x_D1[9] <= MISO_D1; in4x_D2[9] <= MISO_D2;				
					main_state <= ms_clk4_a;
				end

				ms_clk4_a: begin


					MOSI_A <= MOSI_cmd_A[12];
					MOSI_B <= MOSI_cmd_B[12];
					MOSI_C <= MOSI_cmd_C[12];
					MOSI_D <= MOSI_cmd_D[12];
					in4x_A1[10] <= MISO_A1; in4x_A2[10] <= MISO_A2;
					//in4x_B1[10] <= MISO_B1; in4x_B2[10] <= MISO_B2;
					//in4x_C1[10] <= MISO_C1; in4x_C2[10] <= MISO_C2;
					//in4x_D1[10] <= MISO_D1; in4x_D2[10] <= MISO_D2;				
					main_state <= ms_clk4_b;
				end

				ms_clk4_b: begin

					in4x_A1[11] <= MISO_A1; in4x_A2[11] <= MISO_A2;
					//in4x_B1[11] <= MISO_B1; in4x_B2[11] <= MISO_B2;
					//in4x_C1[11] <= MISO_C1; in4x_C2[11] <= MISO_C2;
					//in4x_D1[11] <= MISO_D1; in4x_D2[11] <= MISO_D2;				
					main_state <= ms_clk4_c;
				end

				ms_clk4_c: begin

					SCLK <= 1'b1;
					in4x_A1[12] <= MISO_A1; in4x_A2[12] <= MISO_A2;
					//in4x_B1[12] <= MISO_B1; in4x_B2[12] <= MISO_B2;
					//in4x_C1[12] <= MISO_C1; in4x_C2[12] <= MISO_C2;
					//in4x_D1[12] <= MISO_D1; in4x_D2[12] <= MISO_D2;					
					main_state <= ms_clk4_d;
				end
				
				ms_clk4_d: begin
					SCLK <= 1'b1;
					in4x_A1[13] <= MISO_A1; in4x_A2[13] <= MISO_A2;
					//in4x_B1[13] <= MISO_B1; in4x_B2[13] <= MISO_B2;
					//in4x_C1[13] <= MISO_C1; in4x_C2[13] <= MISO_C2;
					//in4x_D1[13] <= MISO_D1; in4x_D2[13] <= MISO_D2;				
					main_state <= ms_clk5_a;
					
					
					//	FIFO_data_in <= {6'd0,channel};///////////////testЭ����û�и�ֵ����ʹ��
					//	FIFO_write_to <= 1'b1;//////test
				end
				
				ms_clk5_a: begin
					MOSI_A <= MOSI_cmd_A[11];
					MOSI_B <= MOSI_cmd_B[11];
					MOSI_C <= MOSI_cmd_C[11];
					MOSI_D <= MOSI_cmd_D[11];
					in4x_A1[14] <= MISO_A1; in4x_A2[14] <= MISO_A2;
					//in4x_B1[14] <= MISO_B1; in4x_B2[14] <= MISO_B2;
					//in4x_C1[14] <= MISO_C1; in4x_C2[14] <= MISO_C2;
					//in4x_D1[14] <= MISO_D1; in4x_D2[14] <= MISO_D2;				
					main_state <= ms_clk5_b;
				end

				ms_clk5_b: begin
					in4x_A1[15] <= MISO_A1; in4x_A2[15] <= MISO_A2;
					//in4x_B1[15] <= MISO_B1; in4x_B2[15] <= MISO_B2;
					//in4x_C1[15] <= MISO_C1; in4x_C2[15] <= MISO_C2;
					//in4x_D1[15] <= MISO_D1; in4x_D2[15] <= MISO_D2;				
					main_state <= ms_clk5_c;
				end

				ms_clk5_c: begin
					SCLK <= 1'b1;
					in4x_A1[16] <= MISO_A1; in4x_A2[16] <= MISO_A2;
					//in4x_B1[16] <= MISO_B1; in4x_B2[16] <= MISO_B2;
					//in4x_C1[16] <= MISO_C1; in4x_C2[16] <= MISO_C2;
					//in4x_D1[16] <= MISO_D1; in4x_D2[16] <= MISO_D2;					
					main_state <= ms_clk5_d;
				end
				
				ms_clk5_d: begin
					SCLK <= 1'b1;
					in4x_A1[17] <= MISO_A1; in4x_A2[17] <= MISO_A2;
					//in4x_B1[17] <= MISO_B1; in4x_B2[17] <= MISO_B2;
					//in4x_C1[17] <= MISO_C1; in4x_C2[17] <= MISO_C2;
					//in4x_D1[17] <= MISO_D1; in4x_D2[17] <= MISO_D2;				
					main_state <= ms_clk6_a;
				end
				
				ms_clk6_a: begin
					MOSI_A <= MOSI_cmd_A[10];
					MOSI_B <= MOSI_cmd_B[10];
					MOSI_C <= MOSI_cmd_C[10];
					MOSI_D <= MOSI_cmd_D[10];
					in4x_A1[18] <= MISO_A1; in4x_A2[18] <= MISO_A2;
					//in4x_B1[18] <= MISO_B1; in4x_B2[18] <= MISO_B2;
					//in4x_C1[18] <= MISO_C1; in4x_C2[18] <= MISO_C2;
					//in4x_D1[18] <= MISO_D1; in4x_D2[18] <= MISO_D2;				
					main_state <= ms_clk6_b;
				end

				ms_clk6_b: begin
					in4x_A1[19] <= MISO_A1; in4x_A2[19] <= MISO_A2;
					//in4x_B1[19] <= MISO_B1; in4x_B2[19] <= MISO_B2;
					//in4x_C1[19] <= MISO_C1; in4x_C2[19] <= MISO_C2;
					//in4x_D1[19] <= MISO_D1; in4x_D2[19] <= MISO_D2;				
					main_state <= ms_clk6_c;
				end

				ms_clk6_c: begin
					SCLK <= 1'b1;
					in4x_A1[20] <= MISO_A1; in4x_A2[20] <= MISO_A2;
					//in4x_B1[20] <= MISO_B1; in4x_B2[20] <= MISO_B2;
					//in4x_C1[20] <= MISO_C1; in4x_C2[20] <= MISO_C2;
					//in4x_D1[20] <= MISO_D1; in4x_D2[20] <= MISO_D2;					
					main_state <= ms_clk6_d;
				end
				
				ms_clk6_d: begin
					SCLK <= 1'b1;
					in4x_A1[21] <= MISO_A1; in4x_A2[21] <= MISO_A2;
					//in4x_B1[21] <= MISO_B1; in4x_B2[21] <= MISO_B2;
					//in4x_C1[21] <= MISO_C1; in4x_C2[21] <= MISO_C2;
					//in4x_D1[21] <= MISO_D1; in4x_D2[21] <= MISO_D2;				
					main_state <= ms_clk7_a;
				end
				
				ms_clk7_a: begin
					MOSI_A <= MOSI_cmd_A[9];
					MOSI_B <= MOSI_cmd_B[9];
					MOSI_C <= MOSI_cmd_C[9];
					MOSI_D <= MOSI_cmd_D[9];
					in4x_A1[22] <= MISO_A1; in4x_A2[22] <= MISO_A2;
					//in4x_B1[22] <= MISO_B1; in4x_B2[22] <= MISO_B2;
					//in4x_C1[22] <= MISO_C1; in4x_C2[22] <= MISO_C2;
					//in4x_D1[22] <= MISO_D1; in4x_D2[22] <= MISO_D2;				
					main_state <= ms_clk7_b;
				end

				ms_clk7_b: begin
					in4x_A1[23] <= MISO_A1; in4x_A2[23] <= MISO_A2;
					//in4x_B1[23] <= MISO_B1; in4x_B2[23] <= MISO_B2;
					//in4x_C1[23] <= MISO_C1; in4x_C2[23] <= MISO_C2;
					//in4x_D1[23] <= MISO_D1; in4x_D2[23] <= MISO_D2;				
					main_state <= ms_clk7_c;
				end

				ms_clk7_c: begin
					SCLK <= 1'b1;
					in4x_A1[24] <= MISO_A1; in4x_A2[24] <= MISO_A2;
					//in4x_B1[24] <= MISO_B1; in4x_B2[24] <= MISO_B2;
					//in4x_C1[24] <= MISO_C1; in4x_C2[24] <= MISO_C2;
					//in4x_D1[24] <= MISO_D1; in4x_D2[24] <= MISO_D2;					
					main_state <= ms_clk7_d;
				end
				
				ms_clk7_d: begin
					SCLK <= 1'b1;
					in4x_A1[25] <= MISO_A1; in4x_A2[25] <= MISO_A2;
					//in4x_B1[25] <= MISO_B1; in4x_B2[25] <= MISO_B2;
					//in4x_C1[25] <= MISO_C1; in4x_C2[25] <= MISO_C2;
					//in4x_D1[25] <= MISO_D1; in4x_D2[25] <= MISO_D2;				
					main_state <= ms_clk8_a;
				end

				ms_clk8_a: begin
					MOSI_A <= MOSI_cmd_A[8];
					MOSI_B <= MOSI_cmd_B[8];
					MOSI_C <= MOSI_cmd_C[8];
					MOSI_D <= MOSI_cmd_D[8];
					in4x_A1[26] <= MISO_A1; in4x_A2[26] <= MISO_A2;
					//in4x_B1[26] <= MISO_B1; in4x_B2[26] <= MISO_B2;
					//in4x_C1[26] <= MISO_C1; in4x_C2[26] <= MISO_C2;
					//in4x_D1[26] <= MISO_D1; in4x_D2[26] <= MISO_D2;				
					main_state <= ms_clk8_b;
				end

				ms_clk8_b: begin
					in4x_A1[27] <= MISO_A1; in4x_A2[27] <= MISO_A2;
					//in4x_B1[27] <= MISO_B1; in4x_B2[27] <= MISO_B2;
					//in4x_C1[27] <= MISO_C1; in4x_C2[27] <= MISO_C2;
					//in4x_D1[27] <= MISO_D1; in4x_D2[27] <= MISO_D2;				
					main_state <= ms_clk8_c;
				end

				ms_clk8_c: begin
					SCLK <= 1'b1;
					in4x_A1[28] <= MISO_A1; in4x_A2[28] <= MISO_A2;
					//in4x_B1[28] <= MISO_B1; in4x_B2[28] <= MISO_B2;
					//in4x_C1[28] <= MISO_C1; in4x_C2[28] <= MISO_C2;
					//in4x_D1[28] <= MISO_D1; in4x_D2[28] <= MISO_D2;					
					main_state <= ms_clk8_d;
				end
				
				ms_clk8_d: begin
					SCLK <= 1'b1;
					in4x_A1[29] <= MISO_A1; in4x_A2[29] <= MISO_A2;
					//in4x_B1[29] <= MISO_B1; in4x_B2[29] <= MISO_B2;
					//in4x_C1[29] <= MISO_C1; in4x_C2[29] <= MISO_C2;
					//in4x_D1[29] <= MISO_D1; in4x_D2[29] <= MISO_D2;				
					main_state <= ms_clk9_a;
				end

				ms_clk9_a: begin
					MOSI_A <= MOSI_cmd_A[7];
					MOSI_B <= MOSI_cmd_B[7];
					MOSI_C <= MOSI_cmd_C[7];
					MOSI_D <= MOSI_cmd_D[7];
					in4x_A1[30] <= MISO_A1; in4x_A2[30] <= MISO_A2;
					//in4x_B1[30] <= MISO_B1; in4x_B2[30] <= MISO_B2;
					//in4x_C1[30] <= MISO_C1; in4x_C2[30] <= MISO_C2;
					//in4x_D1[30] <= MISO_D1; in4x_D2[30] <= MISO_D2;				
					main_state <= ms_clk9_b;
				end

				ms_clk9_b: begin
					in4x_A1[31] <= MISO_A1; in4x_A2[31] <= MISO_A2;
					//in4x_B1[31] <= MISO_B1; in4x_B2[31] <= MISO_B2;
					//in4x_C1[31] <= MISO_C1; in4x_C2[31] <= MISO_C2;
					//in4x_D1[31] <= MISO_D1; in4x_D2[31] <= MISO_D2;				
					main_state <= ms_clk9_c;
				end

				ms_clk9_c: begin
					SCLK <= 1'b1;
					in4x_A1[32] <= MISO_A1; in4x_A2[32] <= MISO_A2;
					//in4x_B1[32] <= MISO_B1; in4x_B2[32] <= MISO_B2;
					//in4x_C1[32] <= MISO_C1; in4x_C2[32] <= MISO_C2;
					//in4x_D1[32] <= MISO_D1; in4x_D2[32] <= MISO_D2;					
					main_state <= ms_clk9_d;
				end
				
				ms_clk9_d: begin
					SCLK <= 1'b1;
					in4x_A1[33] <= MISO_A1; in4x_A2[33] <= MISO_A2;
					//in4x_B1[33] <= MISO_B1; in4x_B2[33] <= MISO_B2;
					//in4x_C1[33] <= MISO_C1; in4x_C2[33] <= MISO_C2;
					//in4x_D1[33] <= MISO_D1; in4x_D2[33] <= MISO_D2;				
					main_state <= ms_clk10_a;
				end

				ms_clk10_a: begin
					MOSI_A <= MOSI_cmd_A[6];
					MOSI_B <= MOSI_cmd_B[6];
					MOSI_C <= MOSI_cmd_C[6];
					MOSI_D <= MOSI_cmd_D[6];
					in4x_A1[34] <= MISO_A1; in4x_A2[34] <= MISO_A2;
					//in4x_B1[34] <= MISO_B1; in4x_B2[34] <= MISO_B2;
					//in4x_C1[34] <= MISO_C1; in4x_C2[34] <= MISO_C2;
					//in4x_D1[34] <= MISO_D1; in4x_D2[34] <= MISO_D2;				
					main_state <= ms_clk10_b;
				end

				ms_clk10_b: begin
					in4x_A1[35] <= MISO_A1; in4x_A2[35] <= MISO_A2;
					//in4x_B1[35] <= MISO_B1; in4x_B2[35] <= MISO_B2;
					//in4x_C1[35] <= MISO_C1; in4x_C2[35] <= MISO_C2;
					//in4x_D1[35] <= MISO_D1; in4x_D2[35] <= MISO_D2;				
					main_state <= ms_clk10_c;
				end

				ms_clk10_c: begin
					SCLK <= 1'b1;
					in4x_A1[36] <= MISO_A1; in4x_A2[36] <= MISO_A2;
					//in4x_B1[36] <= MISO_B1; in4x_B2[36] <= MISO_B2;
					//in4x_C1[36] <= MISO_C1; in4x_C2[36] <= MISO_C2;
					//in4x_D1[36] <= MISO_D1; in4x_D2[36] <= MISO_D2;					
					main_state <= ms_clk10_d;
				end
				
				ms_clk10_d: begin
					SCLK <= 1'b1;
					in4x_A1[37] <= MISO_A1; in4x_A2[37] <= MISO_A2;
					//in4x_B1[37] <= MISO_B1; in4x_B2[37] <= MISO_B2;
					//in4x_C1[37] <= MISO_C1; in4x_C2[37] <= MISO_C2;
					//in4x_D1[37] <= MISO_D1; in4x_D2[37] <= MISO_D2;				
					main_state <= ms_clk11_a;
				end

				ms_clk11_a: begin
					MOSI_A <= MOSI_cmd_A[5];
					MOSI_B <= MOSI_cmd_B[5];
					MOSI_C <= MOSI_cmd_C[5];
					MOSI_D <= MOSI_cmd_D[5];
					in4x_A1[38] <= MISO_A1; in4x_A2[38] <= MISO_A2;
					//in4x_B1[38] <= MISO_B1; in4x_B2[38] <= MISO_B2;
					//in4x_C1[38] <= MISO_C1; in4x_C2[38] <= MISO_C2;
					//in4x_D1[38] <= MISO_D1; in4x_D2[38] <= MISO_D2;				
					main_state <= ms_clk11_b;
				end

				ms_clk11_b: begin
					in4x_A1[39] <= MISO_A1; in4x_A2[39] <= MISO_A2;
					//in4x_B1[39] <= MISO_B1; in4x_B2[39] <= MISO_B2;
					//in4x_C1[39] <= MISO_C1; in4x_C2[39] <= MISO_C2;
					//in4x_D1[39] <= MISO_D1; in4x_D2[39] <= MISO_D2;				
					main_state <= ms_clk11_c;
				end

				ms_clk11_c: begin
					SCLK <= 1'b1;
					in4x_A1[40] <= MISO_A1; in4x_A2[40] <= MISO_A2;
					//in4x_B1[40] <= MISO_B1; in4x_B2[40] <= MISO_B2;
					//in4x_C1[40] <= MISO_C1; in4x_C2[40] <= MISO_C2;
					//in4x_D1[40] <= MISO_D1; in4x_D2[40] <= MISO_D2;					
					main_state <= ms_clk11_d;
				end
				
				ms_clk11_d: begin
					if (channel == 0&&one_packet) begin
						FIFO_data_in <= RAWHEADER;//header_magic_number[15:0];
						//FIFO_data_in <= 'd11;
						FIFO_write_to <= 1'b1;
			         //   spike_data <=SPIKEHEADER;
                     //   spike_data_valid <= 1;
					end




					SCLK <= 1'b1;
					in4x_A1[41] <= MISO_A1; in4x_A2[41] <= MISO_A2;
					//in4x_B1[41] <= MISO_B1; in4x_B2[41] <= MISO_B2;
					//in4x_C1[41] <= MISO_C1; in4x_C2[41] <= MISO_C2;
					//in4x_D1[41] <= MISO_D1; in4x_D2[41] <= MISO_D2;				
					main_state <= ms_clk12_a;
				end

				ms_clk12_a: begin
					MOSI_A <= MOSI_cmd_A[4];
					MOSI_B <= MOSI_cmd_B[4];
					MOSI_C <= MOSI_cmd_C[4];
					MOSI_D <= MOSI_cmd_D[4];
					in4x_A1[42] <= MISO_A1; in4x_A2[42] <= MISO_A2;
					//in4x_B1[42] <= MISO_B1; in4x_B2[42] <= MISO_B2;
					//in4x_C1[42] <= MISO_C1; in4x_C2[42] <= MISO_C2;
					//in4x_D1[42] <= MISO_D1; in4x_D2[42] <= MISO_D2;				
					main_state <= ms_clk12_b;
	if (channel == 0&&one_packet) begin
		FIFO_data_in <=timestamp[15:0];//{timestamp[7:0],timestamp[15:8]};
		FIFO_write_to <= 1'b0;
	//	spike_data <=timestamp[31:16];
      //    spike_data_valid <= 1;
	end


				end

				ms_clk12_b: begin
					in4x_A1[43] <= MISO_A1; in4x_A2[43] <= MISO_A2;
					//in4x_B1[43] <= MISO_B1; in4x_B2[43] <= MISO_B2;
					//in4x_C1[43] <= MISO_C1; in4x_C2[43] <= MISO_C2;
					//in4x_D1[43] <= MISO_D1; in4x_D2[43] <= MISO_D2;				
					main_state <= ms_clk12_c;

//	if (channel == 0&&one_packet) begin
//		FIFO_data_in <= {timestamp[23:16],timestamp[31:24]};
//		FIFO_write_to <= 1'b1;
//	//	spike_data <=timestamp[31:16];
//      //    spike_data_valid <= 1;
//	end
	//if (channel == 0&&one_packet) begin
		FIFO_data_in <=(channel == 0&&one_packet)?timestamp[15:0]:0;//timestamp[15:0]; //{timestamp[7:0],timestamp[15:8]};
		FIFO_write_to <= (channel == 0&&one_packet)?1:0;
	//	spike_data <=timestamp[31:16];
      //    spike_data_valid <= 1;
	//end

				end

				ms_clk12_c: begin

	//	spike_data <=timestamp[31:16];
      //    spike_data_valid <= 1;





					SCLK <= 1'b1;
					in4x_A1[44] <= MISO_A1; in4x_A2[44] <= MISO_A2;
					//in4x_B1[44] <= MISO_B1; in4x_B2[44] <= MISO_B2;
					//in4x_C1[44] <= MISO_C1; in4x_C2[44] <= MISO_C2;
					//in4x_D1[44] <= MISO_D1; in4x_D2[44] <= MISO_D2;					
					main_state <= ms_clk12_d;
				end
				
				ms_clk12_d: begin

	//	spike_data <=timestamp[31:16];
      //    spike_data_valid <= 1;
	if (channel == 0&&one_packet) begin
		FIFO_data_in <= timestamp[31:16];//{timestamp[23:16],timestamp[31:24]};
		FIFO_write_to <= 1'b1;
	//	spike_data <=timestamp[31:16];
      //    spike_data_valid <= 1;
	end						
	

	
					SCLK <= 1'b1;
					in4x_A1[45] <= MISO_A1; in4x_A2[45] <= MISO_A2;
					//in4x_B1[45] <= MISO_B1; in4x_B2[45] <= MISO_B2;
					//in4x_C1[45] <= MISO_C1; in4x_C2[45] <= MISO_C2;
					//in4x_D1[45] <= MISO_D1; in4x_D2[45] <= MISO_D2;				
					main_state <= ms_clk13_a;
				end

				ms_clk13_a: begin
		if (channel == 0&&one_packet) begin
		FIFO_data_in <={8'd0,1'b0,channel_A_B,channel_en,channel_tra[4:0]};
		FIFO_write_to <= 1'b1;
		end

					MOSI_A <= MOSI_cmd_A[3];
					MOSI_B <= MOSI_cmd_B[3];
					MOSI_C <= MOSI_cmd_C[3];
					MOSI_D <= MOSI_cmd_D[3];
					in4x_A1[46] <= MISO_A1; in4x_A2[46] <= MISO_A2;
					//in4x_B1[46] <= MISO_B1; in4x_B2[46] <= MISO_B2;
					//in4x_C1[46] <= MISO_C1; in4x_C2[46] <= MISO_C2;
					//in4x_D1[46] <= MISO_D1; in4x_D2[46] <= MISO_D2;				
					main_state <= ms_clk13_b;
				end

				ms_clk13_b: begin
		if (channel == 0&&one_packet) begin
		FIFO_data_in <=0;
		FIFO_write_to <= 1'b0;
		end
					in4x_A1[47] <= MISO_A1; in4x_A2[47] <= MISO_A2;
					//in4x_B1[47] <= MISO_B1; in4x_B2[47] <= MISO_B2;
					//in4x_C1[47] <= MISO_C1; in4x_C2[47] <= MISO_C2;
					//in4x_D1[47] <= MISO_D1; in4x_D2[47] <= MISO_D2;				
					main_state <= ms_clk13_c;
				end

				ms_clk13_c: begin
				if (channel == 0&&one_packet) begin
					FIFO_data_in <={8'hbc,7'd0,wiener_data_wr};//16'haabb;
					FIFO_write_to <= 1'b1;
					end
					SCLK <= 1'b1;
					in4x_A1[48] <= MISO_A1; in4x_A2[48] <= MISO_A2;
					//in4x_B1[48] <= MISO_B1; in4x_B2[48] <= MISO_B2;
					//in4x_C1[48] <= MISO_C1; in4x_C2[48] <= MISO_C2;
					//in4x_D1[48] <= MISO_D1; in4x_D2[48] <= MISO_D2;					
					main_state <= ms_clk13_d;
				end
				
				ms_clk13_d: begin
				if (channel == 0&&one_packet) begin
					FIFO_data_in <=Wiener_data[15:0];
					FIFO_write_to <= 1'b1;
					end	
					SCLK <= 1'b1;
					in4x_A1[49] <= MISO_A1; in4x_A2[49] <= MISO_A2;
					//in4x_B1[49] <= MISO_B1; in4x_B2[49] <= MISO_B2;
					//in4x_C1[49] <= MISO_C1; in4x_C2[49] <= MISO_C2;
					//in4x_D1[49] <= MISO_D1; in4x_D2[49] <= MISO_D2;				
					main_state <= ms_clk14_a;
				end

				ms_clk14_a: begin
				if (channel == 0&&one_packet) begin
					FIFO_data_in <=Wiener_data[31:16];
					FIFO_write_to <= 1'b1;
					end	
					MOSI_A <= MOSI_cmd_A[2];
					MOSI_B <= MOSI_cmd_B[2];
					MOSI_C <= MOSI_cmd_C[2];
					MOSI_D <= MOSI_cmd_D[2];
					in4x_A1[50] <= MISO_A1; in4x_A2[50] <= MISO_A2;
					//in4x_B1[50] <= MISO_B1; in4x_B2[50] <= MISO_B2;
					//in4x_C1[50] <= MISO_C1; in4x_C2[50] <= MISO_C2;
					//in4x_D1[50] <= MISO_D1; in4x_D2[50] <= MISO_D2;				
					main_state <= ms_clk14_b;
				end

				ms_clk14_b: begin
				if (channel == 0&&one_packet) begin
					FIFO_data_in <=Wiener_data[47:32];
					FIFO_write_to <= 1'b1;
					end
					in4x_A1[51] <= MISO_A1; in4x_A2[51] <= MISO_A2;
					//in4x_B1[51] <= MISO_B1; in4x_B2[51] <= MISO_B2;
					//in4x_C1[51] <= MISO_C1; in4x_C2[51] <= MISO_C2;
					//in4x_D1[51] <= MISO_D1; in4x_D2[51] <= MISO_D2;				
					main_state <= ms_clk14_c;
				end

				ms_clk14_c: begin
				if (channel == 0&&one_packet) begin
					FIFO_data_in <=Wiener_data[63:48];
					FIFO_write_to <= 1'b1;
					end	
					SCLK <= 1'b1;
					in4x_A1[52] <= MISO_A1; in4x_A2[52] <= MISO_A2;
					//in4x_B1[52] <= MISO_B1; in4x_B2[52] <= MISO_B2;
					//in4x_C1[52] <= MISO_C1; in4x_C2[52] <= MISO_C2;
					//in4x_D1[52] <= MISO_D1; in4x_D2[52] <= MISO_D2;					
					main_state <= ms_clk14_d;
				end
				
				ms_clk14_d: begin
					SCLK <= 1'b1;
					in4x_A1[53] <= MISO_A1; in4x_A2[53] <= MISO_A2;
					//in4x_B1[53] <= MISO_B1; in4x_B2[53] <= MISO_B2;
					//in4x_C1[53] <= MISO_C1; in4x_C2[53] <= MISO_C2;
					//in4x_D1[53] <= MISO_D1; in4x_D2[53] <= MISO_D2;				
					main_state <= ms_clk15_a;
				end

				ms_clk15_a: begin
					MOSI_A <= MOSI_cmd_A[1];
					MOSI_B <= MOSI_cmd_B[1];
					MOSI_C <= MOSI_cmd_C[1];
					MOSI_D <= MOSI_cmd_D[1];
					in4x_A1[54] <= MISO_A1; in4x_A2[54] <= MISO_A2;
					//in4x_B1[54] <= MISO_B1; in4x_B2[54] <= MISO_B2;
					//in4x_C1[54] <= MISO_C1; in4x_C2[54] <= MISO_C2;
					//in4x_D1[54] <= MISO_D1; in4x_D2[54] <= MISO_D2;				
					main_state <= ms_clk15_b;
				end

				ms_clk15_b: begin
					in4x_A1[55] <= MISO_A1; in4x_A2[55] <= MISO_A2;
					//in4x_B1[55] <= MISO_B1; in4x_B2[55] <= MISO_B2;
					//in4x_C1[55] <= MISO_C1; in4x_C2[55] <= MISO_C2;
					//in4x_D1[55] <= MISO_D1; in4x_D2[55] <= MISO_D2;				
					main_state <= ms_clk15_c;
				end

				ms_clk15_c: begin
					SCLK <= 1'b1;
					in4x_A1[56] <= MISO_A1; in4x_A2[56] <= MISO_A2;
					//in4x_B1[56] <= MISO_B1; in4x_B2[56] <= MISO_B2;
					//in4x_C1[56] <= MISO_C1; in4x_C2[56] <= MISO_C2;
					//in4x_D1[56] <= MISO_D1; in4x_D2[56] <= MISO_D2;					
					main_state <= ms_clk15_d;
				end
				
				ms_clk15_d: begin


					SCLK <= 1'b1;
					in4x_A1[57] <= MISO_A1; in4x_A2[57] <= MISO_A2;
					//in4x_B1[57] <= MISO_B1; in4x_B2[57] <= MISO_B2;
					//in4x_C1[57] <= MISO_C1; in4x_C2[57] <= MISO_C2;
					//in4x_D1[57] <= MISO_D1; in4x_D2[57] <= MISO_D2;				
					main_state <= ms_clk16_a;
				end

				ms_clk16_a: begin


					MOSI_A <= MOSI_cmd_A[0];
					MOSI_B <= MOSI_cmd_B[0];
					MOSI_C <= MOSI_cmd_C[0];
					MOSI_D <= MOSI_cmd_D[0];
					in4x_A1[58] <= MISO_A1; in4x_A2[58] <= MISO_A2;
					//in4x_B1[58] <= MISO_B1; in4x_B2[58] <= MISO_B2;
					//in4x_C1[58] <= MISO_C1; in4x_C2[58] <= MISO_C2;
					//in4x_D1[58] <= MISO_D1; in4x_D2[58] <= MISO_D2;				
					main_state <= ms_clk16_b;
				end

				ms_clk16_b: begin


					in4x_A1[59] <= MISO_A1; in4x_A2[59] <= MISO_A2;
					//in4x_B1[59] <= MISO_B1; in4x_B2[59] <= MISO_B2;
					//in4x_C1[59] <= MISO_C1; in4x_C2[59] <= MISO_C2;
					//in4x_D1[59] <= MISO_D1; in4x_D2[59] <= MISO_D2;				
					main_state <= ms_clk16_c;
				end

				ms_clk16_c: begin


					SCLK <= 1'b1;
					in4x_A1[60] <= MISO_A1; in4x_A2[60] <= MISO_A2;
					//in4x_B1[60] <= MISO_B1; in4x_B2[60] <= MISO_B2;
					//in4x_C1[60] <= MISO_C1; in4x_C2[60] <= MISO_C2;
					//in4x_D1[60] <= MISO_D1; in4x_D2[60] <= MISO_D2;					
					main_state <= ms_clk16_d;
				end
				
				ms_clk16_d: begin


					SCLK <= 1'b1;
					in4x_A1[61] <= MISO_A1; in4x_A2[61] <= MISO_A2;
					//in4x_B1[61] <= MISO_B1; in4x_B2[61] <= MISO_B2;
					//in4x_C1[61] <= MISO_C1; in4x_C2[61] <= MISO_C2;
					//in4x_D1[61] <= MISO_D1; in4x_D2[61] <= MISO_D2;				
					main_state <= ms_clk17_a;
				end

				ms_clk17_a: begin

					MOSI_A <= 1'b0;
					MOSI_B <= 1'b0;
					MOSI_C <= 1'b0;
					MOSI_D <= 1'b0;
					in4x_A1[62] <= MISO_A1; in4x_A2[62] <= MISO_A2;
					//in4x_B1[62] <= MISO_B1; in4x_B2[62] <= MISO_B2;
					//in4x_C1[62] <= MISO_C1; in4x_C2[62] <= MISO_C2;
			//		in4x_D1[62] <= MISO_D1; in4x_D2[62] <= MISO_D2;				
					main_state <= ms_clk17_b;
				end

				ms_clk17_b: begin


					in4x_A1[63] <= MISO_A1; in4x_A2[63] <= MISO_A2;
					//in4x_B1[63] <= MISO_B1; in4x_B2[63] <= MISO_B2;
					//in4x_C1[63] <= MISO_C1; in4x_C2[63] <= MISO_C2;
					//in4x_D1[63] <= MISO_D1; in4x_D2[63] <= MISO_D2;				
					main_state <= ms_cs_a;
					//main_state <= ms_cs_l;//ms_cs_k;
				end

				ms_cs_a: begin
					//if (data_stream_4_en == 1'b1 && channel == 34) begin


					CS_b <= 1'b1;
					in4x_A1[64] <= MISO_A1; in4x_A2[64] <= MISO_A2;
					//in4x_B1[64] <= MISO_B1; in4x_B2[64] <= MISO_B2;
					//in4x_C1[64] <= MISO_C1; in4x_C2[64] <= MISO_C2;
					//in4x_D1[64] <= MISO_D1; in4x_D2[64] <= MISO_D2;				
					main_state <= ms_cs_b;//ms_cs_b;
				end

				ms_cs_b: begin
					//if (channel == 34) begin
						// FIFO_data_in <= data_stream_ADC_1;	// Write evaluation-board ADC samples
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					in4x_A1[65] <= MISO_A1; in4x_A2[65] <= MISO_A2;
					//in4x_B1[65] <= MISO_B1; in4x_B2[65] <= MISO_B2;
					//in4x_C1[65] <= MISO_C1; in4x_C2[65] <= MISO_C2;
					//in4x_D1[65] <= MISO_D1; in4x_D2[65] <= MISO_D2;				
					main_state <= ms_cs_c;
				end

				ms_cs_c: begin
					//if (channel == 34) begin
						// FIFO_data_in <= data_stream_ADC_2;	// Write evaluation-board ADC samples
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					in4x_A1[66] <= MISO_A1; in4x_A2[66] <= MISO_A2;
					//in4x_B1[66] <= MISO_B1; in4x_B2[66] <= MISO_B2;
					//in4x_C1[66] <= MISO_C1; in4x_C2[66] <= MISO_C2;
					//in4x_D1[66] <= MISO_D1; in4x_D2[66] <= MISO_D2;				
					main_state <= ms_cs_d;
				end
				
				ms_cs_d: begin
					//if (channel == 34) begin
						// FIFO_data_in <= data_stream_ADC_3;	// Write evaluation-board ADC samples
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					in4x_A1[67] <= MISO_A1; in4x_A2[67] <= MISO_A2;
					//in4x_B1[67] <= MISO_B1; in4x_B2[67] <= MISO_B2;
					//in4x_C1[67] <= MISO_C1; in4x_C2[67] <= MISO_C2;
					//in4x_D1[67] <= MISO_D1; in4x_D2[67] <= MISO_D2;				
					main_state <= ms_cs_e;
				end
				
				ms_cs_e: begin
					//if (channel == 34) begin
						// FIFO_data_in <= data_stream_ADC_4;	// Write evaluation-board ADC samples
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					in4x_A1[68] <= MISO_A1; in4x_A2[68] <= MISO_A2;
					//in4x_B1[68] <= MISO_B1; in4x_B2[68] <= MISO_B2;
					//in4x_C1[68] <= MISO_C1; in4x_C2[68] <= MISO_C2;
					//in4x_D1[68] <= MISO_D1; in4x_D2[68] <= MISO_D2;				
					main_state <= ms_cs_f;
				end
				
				ms_cs_f: begin
					//if (channel == 34) begin
						// FIFO_data_in <= data_stream_ADC_5;	// Write evaluation-board ADC samples
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					in4x_A1[69] <= MISO_A1; in4x_A2[69] <= MISO_A2;
					//in4x_B1[69] <= MISO_B1; in4x_B2[69] <= MISO_B2;
					//in4x_C1[69] <= MISO_C1; in4x_C2[69] <= MISO_C2;
					//in4x_D1[69] <= MISO_D1; in4x_D2[69] <= MISO_D2;				
					main_state <= ms_cs_g;
				end
				
				ms_cs_g: begin
					//if (channel == 34) begin
						// FIFO_data_in <= data_stream_ADC_6;	// Write evaluation-board ADC samples
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					in4x_A1[70] <= MISO_A1; in4x_A2[70] <= MISO_A2;
					//in4x_B1[70] <= MISO_B1; in4x_B2[70] <= MISO_B2;
					//in4x_C1[70] <= MISO_C1; in4x_C2[70] <= MISO_C2;
					//in4x_D1[70] <= MISO_D1; in4x_D2[70] <= MISO_D2;				
					main_state <= ms_cs_h;
				end
				
				ms_cs_h: begin
					//if (channel == 10'd34) begin
						// FIFO_data_in <= data_stream_ADC_7;	// Write evaluation-board ADC samples
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					in4x_A1[71] <= MISO_A1; in4x_A2[71] <= MISO_A2;
					//in4x_B1[71] <= MISO_B1; in4x_B2[71] <= MISO_B2;
					//in4x_C1[71] <= MISO_C1; in4x_C2[71] <= MISO_C2;
					//in4x_D1[71] <= MISO_D1; in4x_D2[71] <= MISO_D2;				
					main_state <= ms_cs_i;
				end
				
				ms_cs_i: begin
					//if (channel == 10'd34) begin
						// FIFO_data_in <= data_stream_ADC_8;	// Write evaluation-board ADC samples
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					in4x_A1[72] <= MISO_A1; in4x_A2[72] <= MISO_A2;
					//in4x_B1[72] <= MISO_B1; in4x_B2[72] <= MISO_B2;
					//in4x_C1[72] <= MISO_C1; in4x_C2[72] <= MISO_C2;
					//in4x_D1[72] <= MISO_D1; in4x_D2[72] <= MISO_D2;				
					main_state <= ms_cs_j;
				end
				
				ms_cs_j: begin
					//if (channel == 34) begin
						// FIFO_data_in <= data_stream_TTL_in;	// Write TTL inputs
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					in4x_A1[73] <= MISO_A1; in4x_A2[73] <= MISO_A2;
					//in4x_B1[73] <= MISO_B1; in4x_B2[73] <= MISO_B2;
					//in4x_C1[73] <= MISO_C1; in4x_C2[73] <= MISO_C2;
					//in4x_D1[73] <= MISO_D1; in4x_D2[73] <= MISO_D2;				
					main_state <= ms_cs_k;
				end
				
				ms_cs_k: begin
					//if (channel == 34) begin
						// FIFO_data_in <= data_stream_TTL_out;	// Write current value of TTL outputs so users can reconstruct exact timings
						// FIFO_write_to <= 1'b1;
					//end					

					CS_b <= 1'b1;
					result_A1 <= in_A1; result_A2 <= in_A2;
					result_B1 <= in_B1; result_B2 <= in_B2;
					result_C1 <= in_C1; result_C2 <= in_C2;
					result_D1 <= in_D1; result_D2 <= in_D2;
					result_DDR_A1 <= in_DDR_A1; result_DDR_A2 <= in_DDR_A2;
					result_DDR_B1 <= in_DDR_B1; result_DDR_B2 <= in_DDR_B2;
					result_DDR_C1 <= in_DDR_C1; result_DDR_C2 <= in_DDR_C2;
					result_DDR_D1 <= in_DDR_D1; result_DDR_D2 <= in_DDR_D2;
					main_state <= ms_cs_o;
				end
				ms_cs_o:begin 
					CS_b <= 1'b1;
					result_A1 <= in_A1; result_A2 <= in_A2;
					result_B1 <= in_B1; result_B2 <= in_B2;
					result_C1 <= in_C1; result_C2 <= in_C2;
					result_D1 <= in_D1; result_D2 <= in_D2;
					result_DDR_A1 <= in_DDR_A1; result_DDR_A2 <= in_DDR_A2;
					result_DDR_B1 <= in_DDR_B1; result_DDR_B2 <= in_DDR_B2;
					result_DDR_C1 <= in_DDR_C1; result_DDR_C2 <= in_DDR_C2;
					result_DDR_D1 <= in_DDR_D1; result_DDR_D2 <= in_DDR_D2;
					main_state <= ms_cs_p;
				end
                ms_cs_p:begin 
					CS_b <= 1'b1;
					result_A1 <= in_A1; result_A2 <= in_A2;
					result_B1 <= in_B1; result_B2 <= in_B2;
					result_C1 <= in_C1; result_C2 <= in_C2;
					result_D1 <= in_D1; result_D2 <= in_D2;
					result_DDR_A1 <= in_DDR_A1; result_DDR_A2 <= in_DDR_A2;
					result_DDR_B1 <= in_DDR_B1; result_DDR_B2 <= in_DDR_B2;
					result_DDR_C1 <= in_DDR_C1; result_DDR_C2 <= in_DDR_C2;
					result_DDR_D1 <= in_DDR_D1; result_DDR_D2 <= in_DDR_D2;
					main_state <= ms_cs_l;
				end
                ms_cs_q:begin 
					CS_b <= 1'b1;
					result_A1 <= in_A1; result_A2 <= in_A2;
					result_B1 <= in_B1; result_B2 <= in_B2;
					result_C1 <= in_C1; result_C2 <= in_C2;
					result_D1 <= in_D1; result_D2 <= in_D2;
					result_DDR_A1 <= in_DDR_A1; result_DDR_A2 <= in_DDR_A2;
					result_DDR_B1 <= in_DDR_B1; result_DDR_B2 <= in_DDR_B2;
					result_DDR_C1 <= in_DDR_C1; result_DDR_C2 <= in_DDR_C2;
					result_DDR_D1 <= in_DDR_D1; result_DDR_D2 <= in_DDR_D2;
					main_state <= ms_cs_r;
				end
				ms_cs_r:begin 
					CS_b <= 1'b1;
					result_A1 <= in_A1; result_A2 <= in_A2;
					result_B1 <= in_B1; result_B2 <= in_B2;
					result_C1 <= in_C1; result_C2 <= in_C2;
					result_D1 <= in_D1; result_D2 <= in_D2;
					result_DDR_A1 <= in_DDR_A1; result_DDR_A2 <= in_DDR_A2;
					result_DDR_B1 <= in_DDR_B1; result_DDR_B2 <= in_DDR_B2;
					result_DDR_C1 <= in_DDR_C1; result_DDR_C2 <= in_DDR_C2;
					result_DDR_D1 <= in_DDR_D1; result_DDR_D2 <= in_DDR_D2;
					main_state <= ms_cs_l;
				end
				ms_cs_l: begin
					//if (channel == 34) begin
					if (channel == 34) begin	
						if (aux_cmd_index_1 == max_aux_cmd_index_1) begin
							aux_cmd_index_1 <=updata_reg_v? 0:loop_aux_cmd_index_1;
							max_aux_cmd_index_1 <= max_aux_cmd_index_1_in;
							aux_cmd_bank_1_A <= aux_cmd_bank_1_A_in;
							aux_cmd_bank_1_B <= aux_cmd_bank_1_B_in;
							aux_cmd_bank_1_C <= aux_cmd_bank_1_C_in;
							aux_cmd_bank_1_D <= aux_cmd_bank_1_D_in;
						end else begin
							aux_cmd_index_1 <=updata_reg_v? 0: aux_cmd_index_1 + 10'd1;
						end
						if (aux_cmd_index_2 == max_aux_cmd_index_2) begin
							aux_cmd_index_2 <=updata_reg_v? 0: loop_aux_cmd_index_2;
							max_aux_cmd_index_2 <= max_aux_cmd_index_2_in;
							aux_cmd_bank_2_A <= aux_cmd_bank_2_A_in;
							aux_cmd_bank_2_B <= aux_cmd_bank_2_B_in;
							aux_cmd_bank_2_C <= aux_cmd_bank_2_C_in;
							aux_cmd_bank_2_D <= aux_cmd_bank_2_D_in;
						end else begin
							aux_cmd_index_2 <=updata_reg_v? 0: aux_cmd_index_2 + 10'd1;
						end
						if (aux_cmd_index_3 == max_aux_cmd_index_3) begin
							aux_cmd_index_3 <= loop_aux_cmd_index_3;
							max_aux_cmd_index_3 <= max_aux_cmd_index_3_in;
							aux_cmd_bank_3_A <= aux_cmd_bank_3_A_in;
							aux_cmd_bank_3_B <= aux_cmd_bank_3_B_in;
							aux_cmd_bank_3_C <= aux_cmd_bank_3_C_in;
							aux_cmd_bank_3_D <= aux_cmd_bank_3_D_in;
						end else begin
							aux_cmd_index_3 <= aux_cmd_index_3 + 10'd1;
						end
					end
					else begin 
						aux_cmd_index_1 <=updata_reg_v? 0:aux_cmd_index_1;
                        aux_cmd_index_2 <=updata_reg_v? 0:aux_cmd_index_2;
					end
					// Route selected samples to DAC outputs
					// if (channel_MISO == DAC_channel_sel_1) begin
					// 	case (DAC_stream_sel_1)
					// 		0: DAC_pre_register_1 <= data_stream_1;
					// 		1: DAC_pre_register_1 <= data_stream_2;
					// 		2: DAC_pre_register_1 <= data_stream_3;
					// 		3: DAC_pre_register_1 <= data_stream_4;
					// 		4: DAC_pre_register_1 <= data_stream_5;
					// 		5: DAC_pre_register_1 <= data_stream_6;
					// 		6: DAC_pre_register_1 <= data_stream_7;
					// 		7: DAC_pre_register_1 <= data_stream_8;
					// 		8: DAC_pre_register_1 <= DAC_manual;
					// 		default: DAC_pre_register_1 <= 16'b0;
					// 	endcase
					// end
					// if (channel_MISO == DAC_channel_sel_2) begin
					// 	case (DAC_stream_sel_2)
					// 		0: DAC_pre_register_2 <= data_stream_1;
					// 		1: DAC_pre_register_2 <= data_stream_2;
					// 		2: DAC_pre_register_2 <= data_stream_3;
					// 		3: DAC_pre_register_2 <= data_stream_4;
					// 		4: DAC_pre_register_2 <= data_stream_5;
					// 		5: DAC_pre_register_2 <= data_stream_6;
					// 		6: DAC_pre_register_2 <= data_stream_7;
					// 		7: DAC_pre_register_2 <= data_stream_8;
					// 		8: DAC_pre_register_2 <= DAC_manual;
					// 		default: DAC_pre_register_2 <= 16'b0;
					// 	endcase
					// end
					// if (channel_MISO == DAC_channel_sel_3) begin
					// 	case (DAC_stream_sel_3)
					// 		0: DAC_pre_register_3 <= data_stream_1;
					// 		1: DAC_pre_register_3 <= data_stream_2;
					// 		2: DAC_pre_register_3 <= data_stream_3;
					// 		3: DAC_pre_register_3 <= data_stream_4;
					// 		4: DAC_pre_register_3 <= data_stream_5;
					// 		5: DAC_pre_register_3 <= data_stream_6;
					// 		6: DAC_pre_register_3 <= data_stream_7;
					// 		7: DAC_pre_register_3 <= data_stream_8;
					// 		8: DAC_pre_register_3 <= DAC_manual;
					// 		default: DAC_pre_register_3 <= 16'b0;
					// 	endcase
					// end
					// if (channel_MISO == DAC_channel_sel_4) begin
					// 	case (DAC_stream_sel_4)
					// 		0: DAC_pre_register_4 <= data_stream_1;
					// 		1: DAC_pre_register_4 <= data_stream_2;
					// 		2: DAC_pre_register_4 <= data_stream_3;
					// 		3: DAC_pre_register_4 <= data_stream_4;
					// 		4: DAC_pre_register_4 <= data_stream_5;
					// 		5: DAC_pre_register_4 <= data_stream_6;
					// 		6: DAC_pre_register_4 <= data_stream_7;
					// 		7: DAC_pre_register_4 <= data_stream_8;
					// 		8: DAC_pre_register_4 <= DAC_manual;
					// 		default: DAC_pre_register_4 <= 16'b0;
					// 	endcase
					// end
					// if (channel_MISO == DAC_channel_sel_5) begin
					// 	case (DAC_stream_sel_5)
					// 		0: DAC_pre_register_5 <= data_stream_1;
					// 		1: DAC_pre_register_5 <= data_stream_2;
					// 		2: DAC_pre_register_5 <= data_stream_3;
					// 		3: DAC_pre_register_5 <= data_stream_4;
					// 		4: DAC_pre_register_5 <= data_stream_5;
					// 		5: DAC_pre_register_5 <= data_stream_6;
					// 		6: DAC_pre_register_5 <= data_stream_7;
					// 		7: DAC_pre_register_5 <= data_stream_8;
					// 		8: DAC_pre_register_5 <= DAC_manual;
					// 		default: DAC_pre_register_5 <= 16'b0;
					// 	endcase
					// end
					// if (channel_MISO == DAC_channel_sel_6) begin
					// 	case (DAC_stream_sel_6)
					// 		0: DAC_pre_register_6 <= data_stream_1;
					// 		1: DAC_pre_register_6 <= data_stream_2;
					// 		2: DAC_pre_register_6 <= data_stream_3;
					// 		3: DAC_pre_register_6 <= data_stream_4;
					// 		4: DAC_pre_register_6 <= data_stream_5;
					// 		5: DAC_pre_register_6 <= data_stream_6;
					// 		6: DAC_pre_register_6 <= data_stream_7;
					// 		7: DAC_pre_register_6 <= data_stream_8;
					// 		8: DAC_pre_register_6 <= DAC_manual;
					// 		default: DAC_pre_register_6 <= 16'b0;
					// 	endcase
					// end
					// if (channel_MISO == DAC_channel_sel_7) begin
					// 	case (DAC_stream_sel_7)
					// 		0: DAC_pre_register_7 <= data_stream_1;
					// 		1: DAC_pre_register_7 <= data_stream_2;
					// 		2: DAC_pre_register_7 <= data_stream_3;
					// 		3: DAC_pre_register_7 <= data_stream_4;
					// 		4: DAC_pre_register_7 <= data_stream_5;
					// 		5: DAC_pre_register_7 <= data_stream_6;
					// 		6: DAC_pre_register_7 <= data_stream_7;
					// 		7: DAC_pre_register_7 <= data_stream_8;
					// 		8: DAC_pre_register_7 <= DAC_manual;
					// 		default: DAC_pre_register_7 <= 16'b0;
					// 	endcase
					// end
					// if (channel_MISO == DAC_channel_sel_8) begin
					// 	case (DAC_stream_sel_8)
					// 		0: DAC_pre_register_8 <= data_stream_1;
					// 		1: DAC_pre_register_8 <= data_stream_2;
					// 		2: DAC_pre_register_8 <= data_stream_3;
					// 		3: DAC_pre_register_8 <= data_stream_4;
					// 		4: DAC_pre_register_8 <= data_stream_5;
					// 		5: DAC_pre_register_8 <= data_stream_6;
					// 		6: DAC_pre_register_8 <= data_stream_7;
					// 		7: DAC_pre_register_8 <= data_stream_8;
					// 		8: DAC_pre_register_8 <= DAC_manual;
					// 		default: DAC_pre_register_8 <= 16'b0;
					// 	endcase
					// end					
					// if (channel == 0) begin
					// 	timestamp <= timestamp + 32'd1;
					// end
					CS_b <= 1'b1;			
					main_state <= ms_cs_m;
				end
				
				ms_cs_m: begin
					//if (channel == 34) begin
					
					// if (channel == 34) begin 
                    //  if(usbtx_ready&&STATE != 3) begin 						
					// 	channel <= 0; end 
					//   else begin 
					// 	 channel <= channel;
					// 	  end 
						  
					// end else begin
					// 	channel <= channel + 6'd1;
					// end
					CS_b <= 1'b1;	

					//if (channel == 34) begin
					  if (channel == 34) begin  

							if (SPI_run_continuous) begin		// run continuously if SPI_run_continuous == 1
								if(usbtx_ready) begin main_state <= ms_cs_n; wireout_start <= 'd0;end else  begin main_state <= main_state; wireout_start <= 'd1;end
							end else begin
								if ((timestamp == max_timestep || max_timestep == 32'b0)) begin  // stop if max_timestep reached, or if max_timestep == 0
									if(cntx==3'h0&&win_cnt0=='h0) begin main_state <= ms_wait; wireout_start <= 'd0;end else  begin main_state <= ms_cs_n;wireout_start <= 'd1; end
								end 
								else begin 
									main_state <= ms_cs_n;
									wireout_start <= 'd0;
									end
								end


					end else begin
						main_state <= ms_cs_n;
					end
				end
								
				default: begin
					main_state <= ms_wait;
				end
				
			endcase  
		end
	end



assign one_packet = ~(|{cntx,win_cnt0});//(cntx=='d0)&&(win_cnt0=='d0);//&&(main_state == ms_cs_m);
	always @(posedge clk) begin
		if (reset) begin
		  channel <= 0;
			end
		else 
		 begin
		  if(main_state == ms_cs_m) 
		   begin
		    if (channel == 34) begin 
                     if(usbtx_ready) begin 						
						channel <= 0; end 
					  else begin 
						 channel <= channel;
						  end 
						  
					end else begin
						channel <= channel + 6'd1;
					end
		   end
		  else 
		   begin
		   channel <= channel;
		 end
	end
	end

	always @(posedge clk) begin
		if (reset) begin
		  win_cnt0 <= 0;
			end
		else 
		 begin
		  win_cnt0 <= win_cnt;
		 end
	end
wire data_start_cal_valid;
assign data_start_cal_valid = spike_in_valid&&(main_state == ms_clk3_b);
wire ADC_add_v;
assign ADC_add_v = spike_in_valid&&(channel==0);

always@(posedge clk or posedge reset)
begin
 if(reset)
  begin
	ADC_DATA <='d0;

  end
 //else if(channel_now=='d34&&main_state == 11&&usbtx_ready)
 else begin
	if(ADC_add_v)
  begin
		ADC_DATA <= ADC_DATA  +13'd1;

    end
	else 
		begin
	  ADC_DATA <= ADC_DATA; 
		end	
  end
end
// reg [9:0]adr_ram;
// always@(posedge clk or posedge reset)
// begin
//  if(reset)
//   begin
// 	adr_ram <='d0;

//   end
//  //else if(channel_now=='d34&&main_state == 11&&usbtx_ready)
//  else if((channel[5]&&channel[1])&&main_state == 11&&usbtx_ready)
//   begin
//    if(adr_ram < 'd32)
//     begin
// 		adr_ram <= adr_ram  +'d1;

//     end
//    else 
//     begin
// 		adr_ram <= 'd0;

//     end
//   end
//  else 
//   begin
// 	adr_ram <= adr_ram;

//   end
// end

// always@(*) begin
//  case(adr_ram)
//   'd1:     begin  wr_reg= {2'b10,6'd8 ,2'd0,6'd11}; end
//   'd2:     begin  wr_reg= {2'b10,6'd9 ,3'd0,5'd0}; end
//   'd3:     begin  wr_reg= {2'b10,6'd10,2'd0,6'd8}; end
//   'd4:     begin  wr_reg= {2'b10,6'd11,3'd0,5'd0}; end
//   'd5:     begin  wr_reg= {2'b00,6'd0,8'd0}; end
//   default: begin  wr_reg= {2'b00,6'd0,8'd0}; end
//  endcase

//  end


wire [15:0]RHD_DATA_IN0,RHD_DATA_IN1,RHD_DATA_IN2,RHD_DATA_IN3;
wire [15:0]RHD_DATA_IN00,RHD_DATA_IN11,RHD_DATA_IN22,RHD_DATA_IN33;
wire [15:0]THRE0,THRE1,THRE2,THRE3;
reg  [15:0]THRE00 = 0,THRE11 = 0,THRE22 = 0,THRE33 = 0;
//assign RHD_DATA_IN0 =result_DDR_A1[15] ?  ~result_DDR_A1[15:0] :result_DDR_A1[15:0] ;
// assign RHD_DATA_IN0 = {~result_DDR_A1[15],result_DDR_A1[14:0 ] };//  result_DDR_A1[15:0];
// assign RHD_DATA_IN1 = {~result_DDR_A1[31],result_DDR_A1[30:16 ]};//  result_DDR_A1[31:16];
// assign RHD_DATA_IN2 = {~result_DDR_A2[15],result_DDR_A2[14:0 ] };//  result_DDR_A2[15:0] ;
// assign RHD_DATA_IN3 = {~result_DDR_A2[31],result_DDR_A2[30:16 ]};//  result_DDR_A2[31:16];
assign RHD_DATA_IN00 =result_DDR_A1[15:0 ] ;// RHD_DATA_IN0[15]? -RHD_DATA_IN0:RHD_DATA_IN0;
assign RHD_DATA_IN11 =result_DDR_A1[31:16 ];// RHD_DATA_IN1[15]? -RHD_DATA_IN1:RHD_DATA_IN1;
assign RHD_DATA_IN22 =result_DDR_A2[15:0 ] ;// RHD_DATA_IN2[15]? -RHD_DATA_IN2:RHD_DATA_IN2;
assign RHD_DATA_IN33 =result_DDR_A2[31:16 ];// RHD_DATA_IN3[15]? -RHD_DATA_IN3:RHD_DATA_IN3;




assign THRE0  = {~threshold_l[15],threshold_l[14:0]};
assign THRE1  = {~threshold_h[15],threshold_h[14:0]};
assign THRE2  = {~thre_64_95 [15],thre_64_95 [14:0]};
assign THRE3  = {~thre_96_127[15],thre_96_127[14:0]};

always@(posedge clk)
begin
THRE00<= THRE0[15]?  -THRE0:THRE0;
THRE11<= THRE1[15]?  -THRE1:THRE1;
THRE22<= THRE2[15]?  -THRE2:THRE2;
THRE33<= THRE3[15]?  -THRE3:THRE3;

end





wire spike_t;
	spike_cal spike_cal_INST0(
.clk(clk),
.rst(reset),
.channel_cho(),
//.RHD_data_in(result_DDR_A1[15:0]),
.RHD_data_in(RHD_DATA_IN00),
.RHD_data_valid(data_start_cal_valid),//spike_in_valid&&(main_state == ms_clk3_a)),
.threshold(threshold_l),
.channel_in(channel),
.main_state(main_state),
.spike_data_valid(spike_data0_valid),
.spike_data_o(spike_data0),
.win_depth('d14),//窗大小
.usbtx_ready(1),
.data_spike(),
.win_cnt(win_cnt),
.test(spike_t)

);

	spike_cal spike_cal_INST1(
.clk(clk),
.rst(reset),
.channel_cho(),
//.RHD_data_in(result_DDR_A1[31:16]),
.RHD_data_in(RHD_DATA_IN11),
.RHD_data_valid(data_start_cal_valid),//spike_in_valid&&(main_state == ms_clk3_a)),//ms_clk3_b)),
.threshold(threshold_h),
.channel_in(channel),
.main_state(main_state),
.spike_data_valid(spike_data_valid1),
.spike_data_o(spike_data1),
.win_depth('d14),//窗大小
.usbtx_ready(1),
.data_spike(),
.win_cnt()

);
spike_cal spike_cal_INST11(
	.clk(clk),
	.rst(reset),
	.channel_cho(),
	//.RHD_data_in(result_DDR_A2[15:0]),
	.RHD_data_in(RHD_DATA_IN22),
	.RHD_data_valid(data_start_cal_valid),//spike_in_valid&&(main_state == ms_clk3_a)),//ms_clk3_b)),
	.threshold(thre_64_95),
	.channel_in(channel),
	.main_state(main_state),
	.spike_data_valid(spike_data_valid2),
	.spike_data_o(spike_data2),
	.win_depth('d14),//窗大小
	.usbtx_ready(1),
	.data_spike(),
	.win_cnt()
	
	);
spike_cal spike_cal_INST12(
.clk(clk),
.rst(reset),
.channel_cho(),
//.RHD_data_in(result_DDR_A2[31:16]),
.RHD_data_in(RHD_DATA_IN33),
.RHD_data_valid(data_start_cal_valid),//spike_in_valid&&(main_state == ms_clk3_a)),//ms_clk3_b)),
.threshold(thre_96_127),
.channel_in(channel),
.main_state(main_state),
.spike_data_valid(spike_data_valid3),
.spike_data_o(spike_data3),
.win_depth('d14),//窗大小
.usbtx_ready(1),
.data_spike(),
.win_cnt()

);

reg [31:0]spike_data_a;
reg [31:0]spike_data_b;
reg [31:0]spike_data_c;
reg [31:0]spike_data_d;
reg [31:0]spike_data_e;
reg [31:0]spike_data_f;
reg [31:0]spike_data_g;
reg [31:0]spike_data_h;
reg [31:0]spike_data_i;
reg [31:0]spike_data_j;
reg [31:0]spike_data_k;
reg [31:0]spike_data_l;
reg [31:0]spike_data_m;
reg [31:0]spike_data_n;
reg [31:0]spike_data_o;
reg [31:0]spike_data_p;


reg [31:0]spike_data_a0;
reg [31:0]spike_data_b0;
reg [31:0]spike_data_c0;
reg [31:0]spike_data_d0;
reg [31:0]spike_data_e0;
reg [31:0]spike_data_f0;
reg [31:0]spike_data_g0;
reg [31:0]spike_data_h0;
reg [31:0]spike_data_i0;
reg [31:0]spike_data_j0;
reg [31:0]spike_data_k0;
reg [31:0]spike_data_l0;
reg [31:0]spike_data_m0;
reg [31:0]spike_data_n0;
reg [31:0]spike_data_o0;
reg [31:0]spike_data_p0;


reg wr_fifo;
reg [10:0]rest_data;
reg cal_busy_d;
always@(posedge clk or posedge reset)
 begin
  if(reset)
   begin
	 cntx <='d0;
     rest_data <= 'd0;
   end
  else if(spike_data0_valid)
   begin
    cntx <=cntx+ 'd1;
    rest_data <= cntx + win_cnt; 
   end
  else
   begin
    cntx <=cntx;
	rest_data <= cntx + win_cnt;

   end 
 end

always@(posedge clk or posedge reset)
 begin
  if(reset)
   begin

	 cntx0<='d0;

	 cal_busy_d<= 0;
   end
  else
   begin

	cntx0<=cntx;

	cal_busy_d<= cal_busy;
   end 
 end
wire [7:0]wr_cnt0_o;
wire [63:0]spike_data_0,spike_data_1;
 pmi_ram_dp
#(
  .pmi_wr_addr_depth    (8 ), // integer
  .pmi_wr_addr_width    (3 ), // integer
  .pmi_wr_data_width    (64 ), // integer
  .pmi_rd_addr_depth    (8 ), // integer
  .pmi_rd_addr_width    (3 ), // integer
  .pmi_rd_data_width    (64 ), // integer
  .pmi_regmode          ("reg"), // "reg"|"noreg"
  .pmi_resetmode        ("async" ), // "async"|"sync"
  .pmi_init_file        ( ), // string
  .pmi_init_file_format ( ), // "binary"|"hex"
  .pmi_family           ("common" )  // "iCE40UP"|"common"
) pmi_ram_dp_spike0 (
  .Data      ({spike_data1,spike_data0} ),  // I:
  .WrAddress (cntx0 ),  // I:
  .RdAddress (wr_cnt0_o[5:2] ),  // I:
  .WrClock   (clk   ),  // I:
  .RdClock   (clk   ),  // I:
  .WrClockEn (1 ),  // I:
  .RdClockEn (1 ),  // I:
  .WE        (spike_data0_valid),//||ram_wr[i] ),  // I:
  .Reset     (reset),  // I:
  .Q         (spike_data_0 )   // O:
);
pmi_ram_dp
#(
  .pmi_wr_addr_depth    (8 ), // integer
  .pmi_wr_addr_width    (3 ), // integer
  .pmi_wr_data_width    (64 ), // integer
  .pmi_rd_addr_depth    (8 ), // integer
  .pmi_rd_addr_width    (3 ), // integer
  .pmi_rd_data_width    (64 ), // integer
  .pmi_regmode          ("reg" ), // "reg"|"noreg"
  .pmi_resetmode        ("async" ), // "async"|"sync"
  .pmi_init_file        ( ), // string
  .pmi_init_file_format ( ), // "binary"|"hex"
  .pmi_family           ("common" )  // "iCE40UP"|"common"
) pmi_ram_dp_spike1 (
  .Data      ({spike_data3,spike_data2} ),  // I:
  .WrAddress (cntx0 ),  // I:
  .RdAddress (wr_cnt0_o[5:2] ),  // I:
  .WrClock   (clk   ),  // I:
  .RdClock   (clk   ),  // I:
  .WrClockEn (1 ),  // I:
  .RdClockEn (1 ),  // I:
  .WE        (spike_data0_valid),//||ram_wr[i] ),  // I:
  .Reset     (reset),  // I:
  .Q         (spike_data_1 )   // O:
);







assign timestamp0en = (main_state == ms_cs_l)&&(channel == 0);
always@(posedge clk or posedge reset) begin 
 if(reset) begin timestamp <= 'd0; end
else begin timestamp<= timestamp0en?timestamp+'d1:timestamp;  end

end 


// count timestamp0
// 	 (  .clk_i(clk), 
//         .clk_en_i(timestamp0en), 
//         .aclr_i(reset||(main_state[6]&&main_state[4])), 
//         .q_o(timestamp[7:0])
// 		) ;
// count timestamp1
// 	 (  .clk_i(clk), 
//         .clk_en_i(timestamp0en&&(&timestamp[7:0])),//timestamp[7:0]==8'hff)), 
//         .aclr_i(reset||(main_state[6]&&main_state[4])), 
//         .q_o(timestamp[15:8])
// 		) ;
// count timestamp2
// 	 (  .clk_i(clk), 
//         .clk_en_i(timestamp0en&&(&timestamp[15:0])),//(timestamp[15:0]==16'hffff)), 
//         .aclr_i(reset||(main_state[6]&&main_state[4])), 
//         .q_o(timestamp[23:16])
// 		) ;		
// count timestamp3
// 	 (  .clk_i(clk), 
//         .clk_en_i(timestamp0en&&(&timestamp[23:0])),//timestamp[23:0]==24'hffffff)), 
//         .aclr_i(reset||(main_state[6]&&main_state[4])), 
//         .q_o(timestamp[31:24])
// 		) ;	



//assign in_DDR_A2 = {16'd0,test_data};
		reg [31:0]cnt_spike;

	always @(*) begin
		case (data_stream_1_sel_in)
			0:		data_stream_1 <= result_DDR_A1[15:0];
			1:		data_stream_1 <= result_DDR_A1[31:16];
			2:		data_stream_1 <= result_DDR_A2[15:0];
			3:		data_stream_1 <= result_DDR_A2[31:16];
			4:		data_stream_1 <= result_C1;
			5:		data_stream_1 <= result_C2;
			6:		data_stream_1 <= result_D1;
			7:		data_stream_1 <= result_D2;
			//8:	data_stream_1 <= result_DDR_A1;
			//9: 	data_stream_1 <= result_DDR_A2;
			//10:	data_stream_1 <= result_DDR_B1;
			//11:	data_stream_1 <= result_DDR_B2;
			//12:	data_stream_1 <= result_DDR_C1;
			//13:	data_stream_1 <= result_DDR_C2;
			//14:	data_stream_1 <= result_DDR_D1;
			//15:	data_stream_1 <= result_DDR_D2;
		endcase
	end
	
	always @(*) begin
		case (data_stream_2_sel_in)
			0:		data_stream_2 <= result_DDR_A1[15:0];
			1:		data_stream_2 <= result_DDR_A1[31:16];
			2:		data_stream_2 <= result_DDR_A2[15:0];
			3:		data_stream_2 <= result_DDR_A2[31:16];
			4:		data_stream_2 <= result_C1;
			5:		data_stream_2 <= result_C2;
			6:		data_stream_2 <= result_D1;
			7:		data_stream_2 <= result_D2;
			//8:		data_stream_2 <= result_DDR_A1;
			//9: 	data_stream_2 <= result_DDR_A2;
			//10:	data_stream_2 <= result_DDR_B1;
			//11:	data_stream_2 <= result_DDR_B2;
			//12:	data_stream_2 <= result_DDR_C1;
			//13:	data_stream_2 <= result_DDR_C2;
			//14:	data_stream_2 <= result_DDR_D1;
			//15:	data_stream_2 <= result_DDR_D2;
		endcase
	end

	always @(*) begin
		case (data_stream_3_sel)
			0:		data_stream_3 <= result_DDR_A1[15:0];
			1:		data_stream_3 <= result_DDR_A1[31:16];
			2:		data_stream_3 <= result_DDR_A2[15:0];
			3:		data_stream_3 <= result_DDR_A2[31:16];
			4:		data_stream_3 <= result_C1;
			5:		data_stream_3 <= result_C2;
			6:		data_stream_3 <= result_D1;
			7:		data_stream_3 <= result_D2;
			//8:		data_stream_3 <= result_DDR_A1;
			//9: 	data_stream_3 <= result_DDR_A2;
			//10:	data_stream_3 <= result_DDR_B1;
			//11:	data_stream_3 <= result_DDR_B2;
			//12:	data_stream_3 <= result_DDR_C1;
			//13:	data_stream_3 <= result_DDR_C2;
			//14:	data_stream_3 <= result_DDR_D1;
			//15:	data_stream_3 <= result_DDR_D2;
		endcase
	end

	 wire [15:0]thre_0_31;
 wire [15:0]thre_32_63; 

	wire thre_rec_busy_o;
	//assign thre_rec_busy_o = 0;
	wire [15:0] ok1;
	assign ok1 ={rx_data[7:0],rx_data[15:8]};//测试程序顺序
    wire wireoutfinish;
	assign wireoutfinish  = 1;
    WireIn     wi00 (.ok1(rx_data),  .STATE(STATE), .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(~rstn),     .data_valid(data_valid),                      .data_cnt_num(5'h11),             .ep_addr(8'h00), .ep_dataout(ep00wirein));
	// WireIn     wi01 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h01), .ep_dataout(ep01wirein));
	// WireIn     wi02 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h02), .ep_dataout(ep02wirein));
	// WireIn     wi03 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h03), .ep_dataout(ep03wirein));
	// WireIn     wi04 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h04), .ep_dataout(ep04wirein));
	// WireIn     wi05 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h05), .ep_dataout(ep05wirein));
	// WireIn     wi06 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h06), .ep_dataout(ep06wirein));
	// WireIn     wi07 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h07), .ep_dataout(ep07wirein));
	// WireIn     wi08 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h08), .ep_dataout(ep08wirein));
	// WireIn     wi09 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h09), .ep_dataout(ep09wirein));
	// WireIn     wi0a (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h0a), .ep_dataout(ep0awirein));
	// WireIn     wi0b (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h0b), .ep_dataout(ep0bwirein));
	// WireIn     wi0c (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h0c), .ep_dataout(ep0cwirein));
	// WireIn     wi0d (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h0d), .ep_dataout(ep0dwirein));
	// WireIn     wi0e (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h0e), .ep_dataout(ep0ewirein));
	// WireIn     wi0f (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h0f), .ep_dataout(ep0fwirein));
	// WireIn     wi10 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h10), .ep_dataout(ep10wirein));
	// WireIn     wi11 (.ok1(rx_data),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),    .data_cnt_num(5'h11),             .ep_addr(8'h11), .ep_dataout(ep11wirein));

/*
Wireinnew uWireinnew (
.clk_in(clk),
.rst(reset),
.data_valid(data_valid&&~thre_rec_busy_o),
.ok1(rx_data),

.wireoutfinish(wireoutfinish),

//output reg[15:0]ep_dataout,

.ep01wirein(ep01wirein),
.ep02wirein(ep02wirein),
.ep03wirein(ep03wirein),
.ep04wirein(ep04wirein),
.ep05wirein(ep05wirein),
.ep06wirein(ep06wirein),
.ep07wirein(ep07wirein),
.ep08wirein(ep08wirein),
.ep09wirein(ep09wirein),
.ep0awirein(ep0awirein),
.ep0bwirein(ep0bwirein),
.ep0cwirein(ep0cwirein),
.ep0dwirein(ep0dwirein),
.ep0ewirein(ep0ewirein),
.ep0fwirein(ep0fwirein),
.ep10wirein(ep10wirein),
.ep11wirein(ep11wirein)
);*/

//	WireIn     wi12 (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h12), .ep_dataout(ep12wirein));
//	WireIn     wi13 (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h13), .ep_dataout(ep13wirein));
//	WireIn     wi14 (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h14), .ep_dataout(ep14wirein));
//	WireIn     wi15 (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h15), .ep_dataout(ep15wirein));
//	WireIn     wi16 (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h16), .ep_dataout(ep16wirein));
//	WireIn     wi17 (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h17), .ep_dataout(ep17wirein));
//	WireIn     wi18 (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h18), .ep_dataout(ep18wirein));
//	WireIn     wi19 (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h19), .ep_dataout(ep19wirein));
//	WireIn     wi1a (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h1a), .ep_dataout(ep1awirein));
//	WireIn     wi1b (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h1b), .ep_dataout(ep1bwirein));
//	WireIn     wi1c (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h1c), .ep_dataout(ep1cwirein));
//	WireIn     wi1d (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h1d), .ep_dataout(ep1dwirein));
//	WireIn     wi1e (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h1e), .ep_dataout(ep1ewirein));
//	WireIn     wi1f (.ok1(ok1),  .STATE(),      .wireoutfinish(wireoutfinish),   .clk_in(clk), .rst(reset),     .data_valid(data_valid),                 .ep_addr(8'h1f), .ep_dataout(ep1fwirein));


//ram config
triggerchannel ramaddr(.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h05), .ep_dataout(ep05wirein));
triggerchannel ramdata(.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h07), .ep_dataout(ep07wirein));
okTriggerln0   ram_wr (.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h08), .ep_dataout(ep08wirein));
okTriggerln0   reg_updata (.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),             .ep_addr(8'h09), .ep_dataout(ep09wirein));

always@(posedge clk or negedge rstn)
begin 
	if(~rstn) begin updata_reg_v <='d0; end
	else if(ep09wirein[0]) begin updata_reg_v <='d1; end
	else if(main_state == ms_cs_m) begin updata_reg_v <='d0;          end
	else                           begin updata_reg_v <=updata_reg_v; end
end
wire wiener_cal;
assign wiener_cal = ep53trigin[0];
wire [1:0]rd_wiener_para;
okTriggerln   tri00 (.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h40), .ep_dataout(ep40trigin));
okTriggerln0  tri01 (.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h41), .ep_dataout(ep41trigin));
okTriggerln1  tri02 (.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h42), .ep_dataout(ep42trigin));
triggerchannel tri03(.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst('d0 ),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h47), .ep_dataout(ep47trigin));
okTriggerln0  tri04 (.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h49), .ep_dataout(ep49trigin));
okTriggerln2  tri05 (.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h50), .ep_dataout(ep50trigin));

okTriggerln2  tri06 (.ok2(rx_data),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h53), .ep_dataout(ep53trigin));


wire thre_tra;
//assign thre_tra = ep50trigin[0];
//okTriggerln0  tri05 (.ok2(ok1),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),        .data_valid(data_valid&&~thre_rec_busy_o),                 .ep_addr(8'h50), .ep_dataout(ep50trigin));
//assign ep47trigin = 'd127;
reg [15:0] test_cnt;
reg [15:0]rest_thre;


wire[7:0]addr_ram;
wire [7:0]channel_in;

reg [1:0]rd_bank = 0;
reg      rd_para = 0;

wire [1:0]sqrt_valid;
wire [15:0]sqrt_data_out;
wire channel_chose_cal_thre;//选择计算0-31或者32-63
reg  rd_rec_thre = 0;
wire [1:0]thre_save_ram_v0,thre_save_ram_v1;
// rd_thre = 0;
reg caL_channel_chose = 0;//0为0~63  1为64~127
assign thre_save_ram_v0[0] = ~caL_channel_chose&&sqrt_valid[0]&&~rd_rec_thre;
assign thre_save_ram_v0[1] = ~caL_channel_chose&&sqrt_valid[1]&&~rd_rec_thre;
assign thre_save_ram_v1[0] =  caL_channel_chose&&sqrt_valid[0]&&~rd_rec_thre;
assign thre_save_ram_v1[1] =  caL_channel_chose&&sqrt_valid[1]&&~rd_rec_thre;
		always@(posedge clk)
		 begin
      //    rd_rec_thre <= ep49trigin[0]&&ep49trigin[2];
             if(ep49trigin[0])
			  begin 
			   rd_rec_thre <= ep49trigin[2];
			   rd_bank     <= ep49trigin[5:4];
               rd_para     <= ep49trigin[3];
			  // rd_thre     <= ep49trigin[2];
			  end
			 else 
			  begin 
			  rd_rec_thre <= rd_rec_thre;
			  rd_bank     <=   rd_bank ;
              rd_para     <=   rd_para ;
			 // rd_thre     <= rd_thre    ;
			  end
		   end
assign channel_in = cal_busy? addr_ram:{1'b0,channel};// - 'd3:{1'b0,channel};
//wire flag;
//wire [2:0]REC_STATE;
wire [15:0]wiener_ram_data;
wire       wiener_ram_en;
wire [7:0] wiener_ram_addr;
wire thre_rec_busy_0,thre_rec_busy_1;
assign thre_rec_busy_o = thre_rec_busy_0||thre_rec_busy_1;
thre_rec  thre_rec_inst    (.ok2(rx_data),  .wireoutfinish(),   .clk_in(clk), .rst(~rstn), .reset(~rstn),   .data_valid(data_valid),   /* .channel(rest_thre),.flag(flag), .REC_STATE(REC_STATE),*/.channel(channel_in[6:0]),    .thre_rec_busy_o(thre_rec_busy_0),   
                            .thre_0_31(thre_0_31), .thre_32_63(thre_32_63),   .test_cnt(test_cnt),   .ep_addr(8'h48) ,
							.thre_save_ram_v(thre_save_ram_v0), .channel_chose_cal_thre(channel_chose_cal_thre), .sqrt_data_out(sqrt_data_out)
							);
thre_rec  thre_rec_inst_49 (.ok2(rx_data),  .wireoutfinish(),   .clk_in(clk), .rst(~rstn), .reset(~rstn),   .data_valid(data_valid),   /* .channel(rest_thre),.flag(flag), .REC_STATE(REC_STATE),*/.channel(channel_in[6:0]),    .thre_rec_busy_o(thre_rec_busy_1),   
                            .thre_0_31(thre_64_95), .thre_32_63(thre_96_127), .test_cnt(),           .ep_addr(8'h51) ,
							.thre_save_ram_v(thre_save_ram_v1), .channel_chose_cal_thre(channel_chose_cal_thre), .sqrt_data_out(sqrt_data_out)
							);
rec_wiener_para  rec_wiener_para_inst (
   .ok2(rx_data),
   .clk_in(clk),
   .rst(~rstn),
   .reset(reset),
   .data_valid(data_valid),         
   .wr_ram_addr (wiener_ram_addr),
   .wr_ram_en   (wiener_ram_en  ),
   .wr_ram_data (wiener_ram_data),
   .ep_addr(8'h52)  );





//okTriggerln1   tri03 (.ok2(ok1),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),     .data_valid(data_valid),                 .ep_addr(8'h43), .ep_dataout(ep43trigin));
//okTriggerln1   tri04 (.ok2(ok1),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),     .data_valid(data_valid),                 .ep_addr(8'h44), .ep_dataout(ep44trigin));
//okTriggerln1   tri05 (.ok2(ok1),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),     .data_valid(data_valid),                 .ep_addr(8'h45), .ep_dataout(ep45trigin));
//okTriggerln1   tri06 (.ok2(ok1),  .STATE(), .wireoutfinish(),   .clk_in(clk), .rst(~rstn),     .data_valid(data_valid),                 .ep_addr(8'h46), .ep_dataout(ep46trigin));

assign ti_clk = clk;
assign dataclk = clk;

////用于spike接收测试

// reg a ;
// 		always@(posedge clk or posedge reset)
// 		 begin
// 		  if(reset) begin 
// 			cnt_spike <= 'd0;
// 			a <= 0;
// 		  end
// 		  else if(SPI_running&&one_pack_v)
// 		   begin
// 			if(cnt_spike<= 32'd32767)
// 			 begin  cnt_spike <= cnt_spike + 'd1;
// 			 a <= 0; end
// 			 else begin
// 			 cnt_spike <= 0; 
// 			 a <= 1; end
// 		   end
// 		   else begin 
// 		    cnt_spike <= cnt_spike;
// 			a <= a;
// 		   end
// 		 end


save_spike_new save_spikeinst(
.clk(clk) ,
.rst(reset) , 
.cntx(cntx0),
.wr_start(spike_data0_valid),

.channel(channel_chose),
.timestamp(timestamp),
.fifo_ready(1),
.wr_fifo_o(spike_data_valid),
.wr_data0(spike_data),
.wr_cnt0_o(wr_cnt0_o),
.spike_data_0(spike_data_0),
.spike_data_1(spike_data_1),
.onepacket_finish(onepacket_finish)
);





//assign threshold_h = threshold_l;
wire raw_data_valid0,raw_data_valid1;
wire [15:0]raw_data0,raw_data1;
assign raw_data_valid0 = data_start_cal_valid;//spike_in_valid&&(main_state == ms_clk3_a);
assign raw_data_valid1 = data_start_cal_valid;//spike_in_valid&&(main_state == ms_clk3_a);//ms_clk3_b);


assign raw_data0 =caL_channel_chose? result_DDR_A2[15:0]  : result_DDR_A1[15:0];
assign raw_data1 =caL_channel_chose? result_DDR_A2[31:16] : result_DDR_A1[31:16];


assign start_cal = ep49trigin[0];
reg [31:0]rst_cal;

always@(posedge clk or negedge rstn)
 begin 
  if(~rstn) begin rst_cal <='d0; end
  else begin rst_cal<= {rst_cal[30:0],~cal_busy_d&&cal_busy}; end
 end
assign rst_thre_c = |rst_cal;
always@(posedge clk) begin 

 if      (start_cal) begin caL_channel_chose <= ep49trigin[1]                ; end
 else                                begin caL_channel_chose <= caL_channel_chose; end
// caL_channel_chose =start_cal? ep49trigin[1]:caL_channel_chose; 
end
// reg start_cal_d = 0,start_cal_dd = 0;
// always@(posedge clk) begin  
// start_cal_d<= start_cal;
// start_cal_dd<= start_cal_d;
// end

//wire[4:0]STATEaa;
wire[7:0]rd_wiener;
 reg [15:0] thre_0_31_r = 0 ;
 reg [15:0]thre_32_63_r = 0;
 wire [7:0]ram_data_rd_o;
  wire [8-1:0]ram_data_out_o;
//rd_para
wire [1:0]state_data_chose;
assign state_data_chose = {caL_channel_chose,rd_para};
always@(*) begin 
	case(state_data_chose) 
	  'd0:begin thre_0_31_r = thre_0_31;  thre_32_63_r = thre_32_63; end
      'd1:begin thre_0_31_r = {{8{ram_data_out_o[7]}},ram_data_out_o};  thre_32_63_r = {{8{ram_data_out_o[7]}},ram_data_out_o}; end
	  'd2:begin thre_0_31_r = thre_64_95;  thre_32_63_r = thre_96_127; end
	  'd3:begin thre_0_31_r = {{8{ram_data_out_o[7]}},ram_data_out_o};  thre_32_63_r = {{8{ram_data_out_o[7]}},ram_data_out_o}; end
	endcase
end

// assign  thre_0_31_r =caL_channel_chose? thre_64_95 :thre_0_31 ;
// assign thre_32_63_r =caL_channel_chose? thre_96_127:thre_32_63;
thre_cal_con 
#(.LENGTH(LENGTH))
thre_cal_con_inst(
.clk(clk) ,
.rst(~rstn) ,
.start_cal(start_cal),
.rd_thre(rd_rec_thre),
.one_packet(one_packet),
.raw_data_valid0(raw_data_valid0),
.raw_data_valid1(raw_data_valid1),
.raw_data0(raw_data0),
.raw_data1(raw_data1),
.threshold_0_31_i(thre_0_31_r),
.threshold_32_63_i(thre_32_63_r),
.channel(channel),
.cal_busy(cal_busy),
.thre_tra(thre_tra),
.valid_rd(valid_rd),
.thre_data_tra(thre_data_tra),
.fifo_empty(fifo_empty),//fifo中的阈值数据已被上位机读空
.fifo_tra_rst(reset_tra_fifo),
.reset_fifo(reset_fifo),

.rd_wiener(rd_wiener),
.addr_ram_o(addr_ram),
.sqrt_valid_o   (sqrt_valid),
.sqrt_data_out(sqrt_data_out),
.channel_chose_o(channel_chose_cal_thre)//选择计算0-31或者32-63


);

//assign threshold_l =thre_cho? thre_0_31:local_thre_0_31;
//assign threshold_h =thre_cho? thre_32_63:local_thre_32_63;

assign threshold_l = thre_0_31;
assign threshold_h = thre_32_63;
assign test_valid = spike_in_valid&&(main_state == ms_clk3_a);



	MISO_DDR_phase_selector MISO_DDR_phase_selector_1 (
		.phase_select(0), .MISO4x(in4x_A1), .MISOout(in_DDR_A1));	
//		.phase_select(delay_A), .MISO4x(in4x_A1), .MISOout());	

	MISO_DDR_phase_selector MISO_DDR_phase_selector_2 (
		.phase_select(0), .MISO4x(in4x_A2), .MISOout(in_DDR_A2));	
	//	.phase_select(delay_A), .MISO4x(in4x_A2), .MISOout());	


wire [15:0]t_ila;
//assign t_ila = ila_data[20]? 16'd8000 +  16'd32768:     16'd32768 - 16'd8000;
//assign in_DDR_A1 ={t_ila,t_ila};//test_cnt[7:0],thre_0_31[7:0]} ;




/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////
////////////数据 写入状态机///////////////////////////////////////////////////////////////
//当fifo可以写入时写入一整包，否则不写入数据,写完之后切换另一个fifo 7.28ycb
reg [1:0]STATE_WR;
localparam INIT_WR = 0;
localparam WR_FIFO = 1;
localparam WR_FINISH = 2;

reg [9:0]onepacket_finish0;//最后一包指示延迟10个时钟
always@(posedge clk or negedge rstn)
begin
 if(~rstn)
  begin
	 onepacket_finish0 <= 0;
  end
  else 
    onepacket_finish0<= {onepacket_finish0[8:0],onepacket_finish};
    
end




always@(posedge clk or posedge reset)
 begin
  if(reset) begin
	STATE_WR <= 'd0;
	wr_fifo_en <= 0;
	//wr_fifo_cho <=0;
  end
  else begin
	case(STATE_WR)
	 INIT_WR:  begin
		//wr_fifo_cho <= wr_fifo_cho;
		if(onepacket_finish0[8]&&tx_fifo_reready)
		 begin 
           STATE_WR <= WR_FIFO;
		   wr_fifo_en <= 1;
		 end
		 else 
		  begin 
           STATE_WR <= STATE_WR;
		   wr_fifo_en <= 0;
		  end
	  end
	 WR_FIFO:  begin 
	//   wr_fifo_cho <= wr_fifo_cho;
       wr_fifo_en <= 1; 
	   if(onepacket_finish0[1])
	    begin 
		 STATE_WR <= WR_FINISH;
		end
	   else 
		begin
		 STATE_WR <= STATE_WR;
		end
	 end
	 WR_FINISH:begin 
	   
	   //if(tx_fifo_reready) begin 
	   STATE_WR <= INIT_WR;
       wr_fifo_en <= 0;  end
	   //else begin
	   //STATE_WR <= STATE_WR;
       //wr_fifo_en <= 0; 
	   //end 

	// end
	endcase
  end
 end

//  wire rd_wiener;
//  wire [32*4-1:0]wiener_cal_data_in;
//  wire rd_en_wiener;
//  wire empty_wiener;
 wire clk_wiener;
 assign clk_wiener = clk;

 wire start_cal_wiener;
 wire [15:0]cnt_s_o;
 wire[16*4-1:0]Wiener_data_o;
 wire data_v;
 
 wiener_data_ready wiener_data_ready_inst
 (
	 .data_num('d525),//单通道1ms数据量 
 
	 .clk          (clk_wiener),
	 .rst          (reset),//||~wiener_cal),
	 .data_in      ({result_DDR_A2,result_DDR_A1}),
	 .data_valid   (data_start_cal_valid),
	 .data_v       (data_v),
	 .finish       (start_cal_wiener),
	 .cnt_s_o      (cnt_s_o),
	 .ram_data_rd_o(ram_data_rd_o)
 );



 Wienerfilter Wienerfilter_inst
(
.clk           (clk_wiener),
.rst           (reset),
.rd_wiener     (rd_wiener),
.rd_bank       (rd_bank),
.rd_para       (rd_para&&valid_rd),
.ram_data_out_o(ram_data_out_o),

.start         (start_cal_wiener&&wiener_cal),
.wr_addr       ({1'd0,wiener_ram_addr}),
.ram_wr_en     (wiener_ram_en),
.ram_data_in   (wiener_ram_data),
.wr_data_addr  (ram_data_rd_o),
.ram_wr_data_en(data_v),
.ram_data_wr_in(cnt_s_o),
.DSP_ADD_DATA_o(DSP_ADD_DATA_o),
.finish_cal_o  (finish_cal_o) ,

.data_wr_v_o   (data_wiener_v),
.Wiener_data   (Wiener_data_o)
) ;



always@(posedge clk or posedge reset) begin 
	if(reset) begin
		wiener_data_wr <= 'd0;
	 end
	else      begin 
      if(finish_cal_o) begin 
		wiener_data_wr <='d1;
	  end
	  else if(main_state == ms_clk15_a&&one_packet&&~(|channel)) begin 
		wiener_data_wr <='d0;
	  end
	  else begin 
		wiener_data_wr <=wiener_data_wr;
	  end
	end
end


assign Wiener_data = Wiener_data_o;//wiener_data_wr? Wiener_data_o:0;




always@(posedge clk or posedge reset) begin 
	if(reset) begin
		ila_data <= 'd0;
	 end
	else      begin 
		ila_data <=ila_data + 'd1;
	  end
	end


// reg [15:0]cnt_as;////1写入Wiener_data 0写入0
// always@(posedge clk or posedge reset) begin 
// 	if(reset) begin
// 		cnt_as <= 'd0;
// 	 end
// 	else      begin 
//       if(~CS) begin 
// 		cnt_as <=cnt_as + 'd1;
// 	  end
// 	  else begin 
// 		cnt_as <=0;
// 	  end
// 	end
// end

//  reg test = 0;
// always@(posedge clk) begin 
// test <= (rx_data==16'he5c7&&data_valid) ? 1:0;
// end

//  assign test0 = test;
   assign test1 = clk_lock;
endmodule
