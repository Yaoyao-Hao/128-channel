
`timescale 1ns / 1ps
module fc_cal#(parameter hidden_size = 512,
                 parameter WIDTH = $clog2(hidden_size),
                 parameter ADDR_WIDTH = $clog2(hidden_size*4),
                 parameter ALL_ADR_WIDTH = $clog2(hidden_size*hidden_size*4),
                 parameter QZ = 16 //数据量化位宽

                ) //隐藏层特征数)
  (
    input clk,
    input rst_n,
    input ahcal_busy, //ah计算忙
    input start, //开始计算LSTM
    input [QZ-1:0]whh,
    input whh_valid,
    input [QZ-1:0]data_in,

    input fifo_ready,
    input new_cal,//开始新的求和计算
    output reg rd_busy, //当ad计算读取参数时占用spi总线

    output reg cal_finish_o,


    output [ALL_ADR_WIDTH-1:0]addr_ram_whho,


    output [QZ*2-1:0]ram_data_in,
    input [QZ*2-1:0]ram_data_out,
    output ram_wr_valid,
    output [ADDR_WIDTH-1:0]h_rd_adr,
    output wire [ADDR_WIDTH-1:0]ht_rdaddr,


    output [ADDR_WIDTH-1:0]cnt_row0

  );

  wire [ALL_ADR_WIDTH-1:0]addr_ram;

  reg[3:0]CAL_STATE;//计算状态机

  wire ram_wr;
  localparam INIT = 0,
             READ_w = 1,
             CAL = 2,
             FINISH = 3;

  reg [4:0]whh_valid_d;
  wire [QZ*2-1:0]mult_out;
  wire mult_out_valid;
  reg start_cal_ad;
  reg cal_finish;
  reg [ADDR_WIDTH-1:0]cnt_row;
  reg [ADDR_WIDTH-1:0]cnt_col;//矩阵行列计数器用于从ram中索引数据

  wire cal_finish_a;
  reg [2:0]cnt_gate;
  assign cal_finish_a = (cnt_row ==hidden_size-1&&cnt_col ==hidden_size-1);//&&cnt_gate == 'd0);
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      CAL_STATE <= INIT;
      rd_busy<= 0;
      start_cal_ad<= 'd0;
      cal_finish_o <= 'd0;
    end
    else
    begin
      case(CAL_STATE)
        INIT:
        begin
          cal_finish_o <= 'd0;

          if(start&&~ahcal_busy)
          begin
            CAL_STATE <= READ_w;
            start_cal_ad <= 'd1;
            rd_busy<= 1;
          end
          else
          begin
            CAL_STATE <= INIT;
            start_cal_ad<= 'd0;
            rd_busy<= 0;
          end
        end
        READ_w:
        begin
          
          if(fifo_ready)
          begin
            CAL_STATE <= CAL;
            rd_busy<= 0;
          end
          else
          begin
            CAL_STATE <= CAL_STATE;
            rd_busy<= 1;
          end
        end
        CAL:
        begin

          if(ram_wr)
          begin
            if(cal_finish_a)
            begin
              CAL_STATE <= FINISH ;
              rd_busy<= 0;
            end
            else
            begin
              CAL_STATE <= READ_w ;
              rd_busy<= 1;
            end
          end
          else
          begin
            CAL_STATE<= CAL_STATE;
            rd_busy<= 0;
          end
        end

        FINISH :
        begin
          rd_busy<= 0;
          cal_finish_o <= 'd1;
          start_cal_ad <= 'd0;
          if(new_cal)
          begin
            CAL_STATE <= INIT;
          end
          else
          begin
            CAL_STATE <= CAL_STATE;
          end

        end
      endcase
    end
  end

  reg add_col_valid;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      cnt_col <= 'd0;
      add_col_valid <= 'd0;
    end
    else
    begin
      if(mult_out_valid&&start_cal_ad)
      begin
        if(cnt_col >=hidden_size-1)
        begin
          cnt_col <= 0;
          add_col_valid <= 'd1;
        end
        else
        begin
          cnt_col <= cnt_col + 'd1;
          add_col_valid <= 'd0;
        end
      end
      else
      begin
        cnt_col <= cnt_col;
        add_col_valid <= 'd0;
      end
    end
  end


  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      cnt_row <= 'd0;
      cal_finish <= 'd0;
    end
    else
    begin
      if(add_col_valid)
      begin
        if(cnt_row >=hidden_size-1)
        begin
          cnt_row <= 0;
          cal_finish <= 'd1;
        end
        else
        begin
          cnt_row <= cnt_row + 'd1;
          cal_finish <= 'd0;
        end
      end
      else
      begin
        cnt_row <= cnt_row;
        cal_finish <= 'd0;
      end
    end
  end
  assign ht_rdaddr = cnt_row ;
  ///////四个门计数器

  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      cnt_gate <= 'd0;
    end
    else
    begin
      if(cal_finish)
      begin
        if(cnt_gate >= 1)
        begin
          cnt_gate <= 0;
        end
        else
        begin
          cnt_gate <= cnt_gate + 'd1;
        end
      end
      else
      begin
        cnt_gate <= cnt_gate;
      end
    end
  end

  localparam GATE0 = hidden_size*hidden_size * 0;
  localparam GATE1 = hidden_size*hidden_size * 1;
  localparam GATE2 = hidden_size*hidden_size * 2;
  localparam GATE3 = hidden_size*hidden_size * 3;

  localparam HGATE0 = hidden_size * 0;
  localparam HGATE1 = hidden_size * 1;
  localparam HGATE2 = hidden_size * 2;
  localparam HGATE3 = hidden_size * 3;



  reg [ALL_ADR_WIDTH-1:0]GATE;
  reg [ADDR_WIDTH-1:0]HGATE;
  always@(*)
  begin
    case(cnt_gate)
      'd0:
      begin
        GATE = GATE0;
        HGATE = HGATE0;
      end
      'd1:
      begin
        GATE = GATE1;
        HGATE = HGATE1;
      end
      'd2:
      begin
        GATE = GATE2;
        HGATE = HGATE2;
      end
      'd3:
      begin
        GATE = GATE3;
        HGATE = HGATE3;
      end
      default:
      begin
        GATE = GATE0;
        HGATE = HGATE0;
      end
    endcase
  end

  wire [ALL_ADR_WIDTH-1:0]aaa;
  assign aaa = {cnt_row[ADDR_WIDTH-1:0],{WIDTH{1'd0}}};
  assign addr_ram = {cnt_row[ADDR_WIDTH-1:0],{WIDTH{1'd0}}} + {{WIDTH{1'b0}},cnt_col} ;
  assign addr_ram_whho = addr_ram;// + GATE;


  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      whh_valid_d<= 'd0;
    end

    else
    begin
      whh_valid_d <= {whh_valid_d[3:0],whh_valid};
    end
  end

  assign mult_out_valid = whh_valid_d[4];
  assign ram_wr = whh_valid_d[4];

wire [(QZ+8)*4-1:0]mult248_out;
  genvar i ;
  generate for (i=0;i<4;i=i+1)
    begin: mult
/*
      mult24x24 datamult1
                 (
                   .clk_i    (clk)     ,
                   .clk_en_i (1'b1)   ,
                   .rst_i    (~rst_n) ,
                   .data_a_i (data_in)  ,
                   .data_b_i (whh[QZ*(i+1)-1:QZ*(i)]),//[QZ*i-1:QZ*(i-1)])   ,
                   .result_o ()//(mult_out[QZ*2*(i+1)-1:QZ*2*(i)])//[QZ*2*i-1:QZ*2*(i-1)] )
                 );*/
                 mult24x8t datamult24X8(
                 .clk_i(clk), 
                 .clk_en_i(1'b1), 
                 .rst_i(~rst_n), 
                 .data_a_i(data_in), 
                 .data_b_i(whh[QZ*(i+1)-1-8:QZ*(i)+8]),//[QZ*i-1:QZ*(i-1)]), 
                 .result_o(mult248_out[(QZ+8)*(i+1)-1:(QZ+8)*(i)])) ;

/*
                 MULT24X8 datamult24X8(
                .data_a_i(data_in), 
                .data_b_i(whh[QZ*(i+1)-1-8:QZ*(i)+8]), 
                .result_o(mult248_out[(QZ+8)*(i+1)-1:(QZ+8)*(i)])) ;
*/
assign mult_out[QZ*2*(i+1)-1:QZ*2*(i)] = {{8{mult248_out[(QZ+8)*(i+1)-1]}},mult248_out[(QZ+8)*(i+1)-1:(QZ+8)*(i)],8'd0};
      assign ram_data_in[QZ*2*(i+1)-1:QZ*2*(i)] =(|cnt_row)? mult_out[QZ*2*(i+1)-1:QZ*2*(i)] + ram_data_out[QZ*2*(i+1)-1:QZ*2*(i)]:mult_out[QZ*2*(i+1)-1:QZ*2*(i)] ;
    end
  endgenerate

  assign h_rd_adr =  cnt_col;
  assign ram_wr_valid = ram_wr;

  /*
  wire [QZ*2-1:0]ram_data_in_debug[0:3];
  wire [QZ*2-1:0]ram_data_out_debug[0:3];
  generate for (i=0;i<4;i=i+1)
    begin: test
      assign ram_data_in_debug[i] = ram_data_in[QZ*2*(i+1)-1:QZ*2*(i)];
      assign ram_data_out_debug[i] = ram_data_out[QZ*2*(i+1)-1:QZ*2*(i)];
    end
  endgenerate
*/
reg [15:0]rd_whh;
always@(posedge clk or negedge rst_n)
 begin 
  if(~rst_n) begin rd_whh<= 'd0; end
    else begin rd_whh<= 16'haaaa; end
 end


assign cnt_row0 = cnt_row;
endmodule
