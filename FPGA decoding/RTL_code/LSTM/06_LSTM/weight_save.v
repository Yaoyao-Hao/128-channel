module weight_save
  #(parameter QZ = 16,
    parameter input_size = 96, //输入特征数
    parameter hidden_size = 512 ,
    parameter output_size = 96, //输出类别数
    parameter OS_W = $clog2(output_size)+1,
    parameter ADDR_WIDTHBIAS = $clog2(hidden_size*4)

   )//隐藏层特征数)
   (
     input clk_200m,
     input user_clk,
     input rst,

     input wr_fifo_data_valid,
     input [15:0]wr_fifo_data,


     input wr_ram_valid,
     input [15:0]wr_ram_data,
     output fifo_ready,
     output fifo_ready_r,
     output fifo_ready_fc,
     input   wire [ADDR_WIDTHBIAS-1:0]cnt_hidden_size0,
     output wire [(QZ+8)*4-1:0]weight_out,
     output wire weight_out_valid_o,
     output wire [4*QZ-1:0]bias_gate,
     output wire [QZ-1:0]bias_gate_fc,
     input rd_en,
     input rd_en_fc,
     output   wire [8-1:0]weight_out_fc,
     output [7:0]uart_data,
     input [9-1:0]addr_rd_h,
     input [OS_W-1:0]fc_bais_adr,
     output reg [QZ-1:0]fc_bais_data

   );
  //wire test_read;
  //  wire [4*QZ-1:0]bias_gate;

  //localparam ADDR_WIDTHBIAS = $clog2(hidden_size*4);
  localparam FILE_W_LENGTH = hidden_size*hidden_size*5/2;
  localparam FILE_FC_LENGTH = input_size*hidden_size*4/2+FILE_W_LENGTH;
  localparam FULL_W_LENGTH = FILE_FC_LENGTH;
  /*************************************/
  //计数器用于控制5个fifo的写入
  /*************************************/
  //reg wr_fifo_data_valid;
  wire [7:0]data_outa;

  reg [15:0]fifo_data_in;
  reg [31:0]wr_cnt;


  reg wr_fifo_en;
  always@(posedge clk_200m or posedge rst)
  begin
    if(rst)
    begin
      wr_cnt <= 'd0;
      fifo_data_in <= 'd0;
      wr_fifo_en <= 'd0;
    end
    else
    begin
      if(wr_fifo_data_valid)
      begin
        if(wr_cnt <= FULL_W_LENGTH-2)
        begin
          wr_cnt <= wr_cnt + 'd1;
          fifo_data_in <= wr_fifo_data;
          wr_fifo_en <= 'd1;
        end
        else
        begin
          wr_cnt <= 0;
          fifo_data_in <= wr_fifo_data;
          wr_fifo_en <= 'd1;
        end
      end
      else
      begin
        wr_cnt <= wr_cnt;
        fifo_data_in <= wr_fifo_data;
        wr_fifo_en <= 'd0;
      end
    end
  end


  wire [7:0]ila_data0,ila_data1;
  assign ila_data0 = fifo_data_in[7:0];
  assign ila_data1 = fifo_data_in[15:8];
  //////////写fifo计数，当进行wih运算时为4个fifo缓存，进行whh时为5个fifo，其中多全连接层fifo
  reg [3:0]num_cnt;
  wire [3:0]NUM;

  reg  [3:0]num_cnt_d;
  always@(posedge clk_200m or posedge rst)
  begin
    if(rst)
    begin
      num_cnt_d<= 'd0;
    end
    else
    begin
      num_cnt_d<= num_cnt;
    end

  end
  always@(posedge clk_200m or posedge rst)
  begin
    if(rst)
    begin
      num_cnt <= 'd0;

    end
    else
    begin
      if(wr_fifo_data_valid)
      begin
        if(num_cnt < NUM-1)
        begin
          num_cnt <= num_cnt + 'd1;

        end
        else
        begin
          num_cnt <= 0;

        end
      end
      else
      begin
        num_cnt <= num_cnt;

      end
    end
  end
  ////////////////bias ram写入状态机////////////////////////
  wire STATE_BIAS;
  localparam  GATE = 0,
              FC = 1;

  localparam  bias_file_length = hidden_size + input_size;
  localparam  bias_file_length_fc = input_size;
  reg [31:0]bias_cnt;
  assign STATE_BIAS = (bias_cnt<(bias_file_length-bias_file_length_fc-1))? 1:0;
  always@(posedge user_clk or posedge rst)
  begin
    if(rst)
    begin
      bias_cnt <= 'd0;

    end
    else
    begin
      if(wr_ram_valid)
      begin
        if(num_cnt < bias_file_length-1)
        begin
          bias_cnt <= bias_cnt + 'd1;

        end
        else
        begin
          bias_cnt <= 0;

        end
      end
      else
      begin
        bias_cnt <= bias_cnt;

      end
    end
  end

  wire [20:0]RAM_wr_addr;
  wire [1:0]CHOSE_RAM;

  assign CHOSE_RAM = bias_cnt[1:0];
  assign RAM_wr_addr = bias_cnt[22:2];








  ///////////////////////////////////////////////////////////


  ////////////////控制文件写入缓存fifo类型
  wire STATE;
  assign NUM = 'd4;//STATE?'d5:'d4;
  localparam //INIT = 0,
             WHH  = 1,
             WIH   = 0;
  assign STATE = (wr_cnt<FILE_W_LENGTH-1);
  /*
  always@(posedge user_clk or  posedge rst)
  begin
  if(rst)
  begin
  STATE <= WHH;
  end
  else
  begin
  case(STATE)
  WIH:
  begin
  if(wr_cnt >= FILE_FC_LENGTH - 1)
  begin
  STATE <= WHH;
  end
  else
  begin
  STATE <= STATE;
  end
  end
  WHH:
  begin
  if(wr_cnt >= FILE_W_LENGTH)
  begin
  STATE <= WIH;
  end
  else
  begin
  STATE <= STATE;
  end
  end
  endcase
  end
  end
  */




  reg [3:0]wr_en;
  wire [3:0]fifo_empty;
  wire [3:0]almost_full_o;
  reg wr_en_fc ;
  always@(*)
  begin
    case(num_cnt_d[2:0])
      3'b000:
      begin
        wr_en = {3'b000,wr_fifo_en};
        wr_en_fc = 0;
      end
      3'b001:
      begin
        wr_en = {2'b00,wr_fifo_en,1'b0};
        wr_en_fc = 0;
      end
      3'b010:
      begin
        wr_en = {1'b0,wr_fifo_en,2'b00};
        wr_en_fc = 0;
      end
      3'b011:
      begin
        wr_en = {wr_fifo_en,3'b000};
        wr_en_fc = 0;
      end
      3'b100:
      begin
        wr_en = {4'b0000};
        wr_en_fc = wr_fifo_en;
      end
      default:
      begin
        wr_en = {4'b0000};
        wr_en_fc = 0;
      end
    endcase
  end


  reg [3:0]wr_ram;
  wire wr_ram_fc;
  always@(*)
  begin
    if(rst)
    begin
      wr_ram = 'd0;
    end
    else
    begin
      case(CHOSE_RAM)
        'd0:
        begin
          wr_ram = STATE_BIAS?   0:{3'b000,wr_ram_valid};
        end
        'd1:
        begin
          wr_ram = STATE_BIAS?   0:{2'b00,wr_ram_valid,1'b0};
        end
        'd2:
        begin
          wr_ram = STATE_BIAS?   0:{1'b0,wr_ram_valid,2'b00};
        end
        'd3:
        begin
          wr_ram = STATE_BIAS?   0:{wr_ram_valid,3'b000};
        end
      endcase
    end
  end



  wire [(QZ-8)*4-1:0]wfifo_data_out /* synthesis syn_preserve = 1 */ ;


  reg rd_en_d,rd_en_dd;
  always@(posedge user_clk or posedge rst)
  begin
    if(rst)
    begin
      rd_en_d <= 'd0;
      rd_en_dd<= 'd0;
    end
    else
    begin
      rd_en_d <= rd_en&&fifo_ready_r;
      rd_en_dd<= rd_en_d;
    end
  end
  assign weight_out_valid_o = rd_en_d;
  wire [4*QZ-1:0]bias_gate0;
  wire [7:0]data_out;
  assign uart_data = data_outa;
  genvar i ;
  generate for (i=0;i<4;i=i+1)
    begin: fifo_gate
      /* pmi_fifo
      #(
        .pmi_data_width        (24 ), // integer       
        .pmi_data_depth        (96 ), // integer       
        .pmi_almost_full_flag  (80 ), // integer (pmi_almost_full_flag MUST be LESS than pmi_data_depth)       
        .pmi_almost_empty_flag (1  ), // integer		
        .pmi_regmode           ("reg" ), // "reg"|"noreg"    	
        .pmi_family            ("LIFCL" ), // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
        .pmi_implementation    ("EBR" )  // "LUT"|"EBR"|"HARD_IP"
      ) WEIGHT_FIFO_24x96a (         
        .Data        (data_out ), // I:      
        .Clock       (clk ), // I:
        .WrEn        (wr_en[i] ), // I:
        .RdEn        (rd_en ), // I:
        .Reset       (~rst_n ), // I:
        .Q           (weight_out[QZ*(i+1)-1:QZ*(i)] ), // O:
        .Empty       (fifo_empty[i] ), // O:
        .Full        ( ), // O:
        .AlmostEmpty ( ), // O:
        .AlmostFull  (fifo_full[i] )  // O:
      );
      */

      fifo16x96 fifo_16_96_weight(
                  .wr_clk_i(clk_200m),
                  .rd_clk_i(user_clk),
                  .rst_i(rst),
                  .rp_rst_i(0),
                  .wr_en_i(wr_en[i]),
                  .rd_en_i(rd_en),
                  .wr_data_i(fifo_data_in),
                  .full_o(),
                  .empty_o(fifo_empty[i]),
                  .almost_full_o(almost_full_o[i]),
                  .rd_data_o(wfifo_data_out[(QZ-8)*(i+1)-1:(QZ-8)*(i)]))
                ;

      assign weight_out[(QZ+8)*(i+1)-1:(QZ+8)*(i)]  = {{7{wfifo_data_out[(QZ-8)*(i+1)-1]}},wfifo_data_out[(QZ-8)*(i+1)-1:(QZ-8)*(i)],9'd0};
      assign bias_gate[QZ*(i+1)-1:QZ*i] = {bias_gate0[QZ*(i+1)-1:QZ*i]};
    end
  endgenerate
  assign fifo_ready_r = (&(~fifo_empty));
  reg [20:0]data_cnt;
  always@(posedge user_clk or posedge rst)
  begin
    if(rst)
    begin
      data_cnt<= 'd0;
    end
    else
    begin
      if(rd_en&&fifo_ready)
      begin
        if(data_cnt<(21'd312046-1))
        begin
          data_cnt <= data_cnt+ 'd1;
        end
        else
        begin
          data_cnt <= 0;
        end
      end
      else
      begin
        data_cnt <= data_cnt;
      end

    end


  end


  //////////////////////////////bias mem//////////////////////////////////
  bias_ram0 bias_ram_inst0(
              .wr_clk_i    (user_clk),
              .rd_clk_i    (user_clk),
              .rst_i       (rst),
              .wr_clk_en_i (1'b1),
              .rd_en_i     (1'b1),
              .rd_clk_en_i (1'b1),
              .wr_en_i     (wr_ram[0]),
              .wr_data_i   (wr_ram_data),
              .wr_addr_i   (RAM_wr_addr),
              .rd_addr_i   ({1'b0,cnt_hidden_size0}),
              .rd_data_o   (bias_gate0[QZ*1-1:QZ*0]) ) ;

  bias_ram1 bias_ram_inst1(
              .wr_clk_i    (user_clk),
              .rd_clk_i    (user_clk),
              .rst_i       (rst),
              .wr_clk_en_i (1'b1),
              .rd_en_i     (1'b1),
              .rd_clk_en_i (1'b1),
              .wr_en_i     (wr_ram[1]),
              .wr_data_i   (wr_ram_data),
              .wr_addr_i   (RAM_wr_addr),
              .rd_addr_i   ({1'b0,cnt_hidden_size0}),
              .rd_data_o   (bias_gate0[QZ*2-1:QZ*1]) ) ;

  bias_ram2 bias_ram_inst2(
              .wr_clk_i    (user_clk),
              .rd_clk_i    (user_clk),
              .rst_i       (rst),
              .wr_clk_en_i (1'b1),
              .rd_en_i     (1'b1),
              .rd_clk_en_i (1'b1),
              .wr_en_i     (wr_ram[2]),
              .wr_data_i   (wr_ram_data),
              .wr_addr_i   (RAM_wr_addr),
              .rd_addr_i   ({1'b0,cnt_hidden_size0}),
              .rd_data_o   (bias_gate0[QZ*3-1:QZ*2]) ) ;

  bias_ram3 bias_ram_inst3(
              .wr_clk_i    (user_clk),
              .rd_clk_i    (user_clk),
              .rst_i       (rst),
              .wr_clk_en_i (1'b1),
              .rd_en_i     (1'b1),
              .rd_clk_en_i (1'b1),
              .wr_en_i     (wr_ram[3]),
              .wr_data_i   (wr_ram_data),
              .wr_addr_i   (RAM_wr_addr),
              .rd_addr_i   ({1'b0,cnt_hidden_size0}),
              .rd_data_o   (bias_gate0[QZ*4-1:QZ*3]) ) ;

  /////////////////////////////////////////////////////////////////////////



  localparam WR_FC_threshold = input_size*hidden_size/2,

             WR_FC_threshold0 = hidden_size*hidden_size/2,
             WIDTH_FC= $clog2(WR_FC_threshold0);

  reg [WIDTH_FC-1:0]fcdata_in_cnt;
  always@(posedge clk_200m or posedge rst)
  begin
    if(rst)
    begin
      fcdata_in_cnt<= 'd0;
    end
    else
    begin
      if(wr_en_fc)
      begin
        if(fcdata_in_cnt>=WR_FC_threshold0-1)
        begin
          fcdata_in_cnt <='d0;
        end
        else
        begin
          fcdata_in_cnt <= fcdata_in_cnt + 'd1;
        end
      end
      else
      begin
        fcdata_in_cnt <= fcdata_in_cnt;
      end

    end


  end


  wire wr_fc_fifo_en ;
  assign wr_fc_fifo_en = (fcdata_in_cnt > WR_FC_threshold-1)?0:1;

  wire fc_fifo_empty;

  assign fifo_ready_fc = 1;//~fc_fifo_empty;
  /*
  bias_ram4 bias_ram_inst(
  .wr_clk_i    (user_clk),
  .rd_clk_i    (user_clk),
  .rst_i       (rst),
  .wr_clk_en_i (1'd1),
  .rd_en_i     (1'd1),
  .rd_clk_en_i (1'd1),
  .wr_en_i     (wr_ram_fc),
  .wr_data_i   (wr_ram_data),
  .wr_addr_i   (RAM_wr_addr),
  .rd_addr_i   ({1'd0,fc_bais_adr}),
  .rd_data_o   () ) ;*/
  assign fifo_ready =~(|almost_full_o);//~( fifo_full_fc||(|almost_full_o));

  always@(*)
  begin
    case(fc_bais_adr)
      'd0:
      begin
        fc_bais_data<='d2366;
      end
      'd1:
      begin
        fc_bais_data<=-'d3145;
      end
      default:
      begin
        fc_bais_data<='d2366;
      end
    endcase

  end





  assign data_outa = wfifo_data_out[7:0];
  wire [ADDR_WIDTHBIAS-1:0]addr_rd_h_in;
  assign addr_rd_h_in = {fc_bais_adr[0],addr_rd_h[8:0]};

  ram_512_8_fc uram_512_8_fc0
               (
                 .wr_clk_i   (user_clk),
                 .rd_clk_i   (user_clk),
                 .rst_i      (rst),
                 .wr_clk_en_i(1'd1),
                 .rd_en_i    (1'd1),
                 .rd_clk_en_i(1'd1),
                 .wr_en_i    (0),
                 .wr_data_i  (0),
                 .wr_addr_i  (0),
                 .rd_addr_i  (addr_rd_h_in),
                 .rd_data_o  (weight_out_fc) ) ;





endmodule
