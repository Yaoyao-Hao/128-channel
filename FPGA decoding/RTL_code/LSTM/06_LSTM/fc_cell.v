module fc_cell#(
    parameter QZ = 24,
    parameter QZ_D = 8,
    parameter output_size = 96, //输入特征数
    parameter hidden_size = 512, //隐藏层特征数
    parameter OS_W = $clog2(output_size)+1,
    parameter HS_W = $clog2(hidden_size)+1


  )(
    input clk ,
    input rst_n,

    input [QZ-1:0]ht_in,
    input ht_valid,
    input start_cal,
    input fifo_ready,
    input [QZ_D-1:0]weight_in,
    //input [QZ_D-1:0]weight_out_fc,
    output wire rd_weight_en,



output [OS_W-1:0]fc_bais_adr,
input  [QZ-QZ_D-1:0]fc_bais_data,

output reg [QZ-1:0]output_data,
output reg output_data_valid


  );
  reg [HS_W-1:0]OS_CNT;
  reg [HS_W-1:0]HS_CNT;
  reg cntadd;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      HS_CNT <= 'd0;
    end
    else if(cntadd)
    begin
      if(HS_CNT < output_size-1)
      begin
        HS_CNT <= HS_CNT + 'd1;
      end
      else
      begin
        HS_CNT <= 0;
      end
    end
    else
    begin
      HS_CNT <= HS_CNT;
    end
  end


  reg rd_weight;
  assign rd_weight_en = rd_weight;
//assign rd_weight_en 


  localparam INIT = 0,
             CAL_HS = 1,
             CAL    = 2,
             cal_finish = 3;
  reg [6:0]valid_d;
  reg [2:0]STATE;
  wire mult_out_valid;
  wire [QZ+QZ_D-1:0]mult_out;
  reg [QZ+QZ_D-1:0]fc_data_out;
  reg fc_data_out_valid;

  wire [QZ+QZ_D-1:0]ram_data_out,ram_data_in;

  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      STATE <= 'd0;
      rd_weight <= 'd0;
      OS_CNT    <= 'd0;
      fc_data_out_valid <='d0;
      fc_data_out<='d0;
      cntadd <= 'd0;
    end
    else
    begin
      case(STATE)
        INIT:
        begin
          if(start_cal)
          begin
            STATE <= CAL_HS;
            rd_weight <= 'd1;
          end
          else
          begin
            STATE <= INIT  ;
            rd_weight <= 'd0;
          end
          OS_CNT    <= 'd0;
          fc_data_out_valid <='d0;
          fc_data_out<='d0;
          cntadd <= 'd0;
        end
        CAL_HS:
        begin
          cntadd <= 'd0;
          if(fifo_ready)
          begin
            rd_weight <= 'd0;
            STATE <= CAL  ;
          end
          else
          begin
            rd_weight <= 'd1;
            STATE <= CAL_HS  ;
          end
          fc_data_out_valid <='d0;
        end
        CAL   :
        begin
          if(mult_out_valid)
          begin
            if(OS_CNT < (hidden_size - 'd1))
            begin
              OS_CNT <= OS_CNT + 'd1;
              STATE <=CAL_HS;
              rd_weight <= 'd1;
              cntadd <= 'd0;
            end
            else 
            begin 
             // HS_CNT <= 'd0;
             // rd_weight <= 'd0;
             // STATE <=cal_finish;
              STATE  <= (HS_CNT>=output_size-1)?INIT:CAL_HS;//INIT;
              rd_weight <= (HS_CNT>=output_size-1)?'d0:'d1;
              OS_CNT    <= 'd0;
              fc_data_out_valid <='d1;
              fc_data_out<=mult_out  ;
              cntadd <= 'd1;

            end
          end
          else
          begin
            cntadd <= 'd0;
            OS_CNT <= OS_CNT;
            rd_weight <= 'd0;
            STATE  <= STATE;
            fc_data_out_valid <='d0;
            fc_data_out<=mult_out  ;
          end
        end
        cal_finish:
        begin
          STATE  <= INIT;
          rd_weight <= 'd0;
          OS_CNT    <= 'd0;
          fc_data_out_valid <='d1;
          fc_data_out<=mult_out  ;
        end
      endcase
    end
  end

  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      valid_d <= 'd0;
    end
    else
    begin
      valid_d <= {valid_d[5:0],rd_weight};
    end
  end
  assign mult_out_valid = valid_d[5];


  reg [QZ+QZ_D-1:0]data_add;
  reg wr_ram;
  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      data_add<= 'd0;
      wr_ram <='d0;
    end
    else if(mult_out_valid)
    begin
      data_add<=(OS_CNT == 0)?mult_out:mult_out + ram_data_out;
      wr_ram <='d1;

    end
else begin 
  data_add<=data_add;
  wr_ram <='d0;
end
  end
  wire [QZ_D-1:0]weight_in0;
  assign weight_in0 = weight_in;//{weight_in[QZ_D-2:0],1'b0};
  mult24x8tt fc_mult
             (
               .clk_i    (clk)     ,
               .clk_en_i (1'b1)   ,
               .rst_i    (~rst_n) ,
               .data_a_i (ht_in)  ,
               .data_b_i (weight_in0),//[QZ*i-1:QZ*(i-1)])   ,
               .result_o (mult_out)//[QZ*2*i-1:QZ*2*(i-1)] )
             );

  /*
     ramdata
     #(
         .addr_width($clog2(hidden_size)),
         .data_width(QZ*2),
         .data_deepth(hidden_size),
         .INITdata('d0)
     )ramdatau_fccal
     (
        .clka(clk),
        .clkb(clk),
        .rst_n(rst_n),
        .cs(1),
         //wr
         .wr_addr(OS_CNT),
         .wr_data(data_add),
         .wr_en(mult_out_valid),
         //rd
         .rd_addr(OS_CNT),
         .rd_en(1),
         .rd_data(ram_data_out)
         );*/
  ram96x32 ramdatau_fccal(
               .wr_clk_i   (clk)  ,
               .rd_clk_i   (clk) ,
               .rst_i      (~rst_n) ,
               .wr_clk_en_i(1),
               .rd_en_i    (1),
               .rd_clk_en_i(1),
               .wr_en_i    (wr_ram),
               .wr_data_i  (data_add),
               .wr_addr_i  ({3'b0,{HS_CNT-1}}),
               .rd_addr_i  ({3'b0,{HS_CNT-1}}),
               .rd_data_o  (ram_data_out)) ;

  wire [15:0]wb_out;
assign fc_bais_adr = HS_CNT  ;



wire [23:0]data_test_0,data_test_1;
assign data_test_0 = {data_add[29:6]};
assign data_test_1 = {{QZ_D{fc_bais_data[QZ-QZ_D-1]}},fc_bais_data};


always@(posedge clk or negedge rst_n) begin 

if(~rst_n) begin 
  output_data<= 'd0;
  output_data_valid<= 'd0;
end
else begin 
  output_data<= (wr_ram&&~(|OS_CNT))? data_test_0 + {{QZ_D{fc_bais_data[QZ-QZ_D-1]}},fc_bais_data}: output_data;
  output_data_valid<= (wr_ram&&~(|OS_CNT))? 1: 0;

end

end
  /*
  rom
  #(
      .addr_width(OS_W+1),
      .data_width(16),
      .data_deepth(output_size),
      .INITdata('d0)
  )uwb
  (
     .clka(clk),
     .clkb(clk),
     .rst_n(rst_n),
     .cs(1),
      //wr
      .wr_addr(),
      .wr_data(),
      .wr_en(),
      //rd
      .rd_addr(OS_CNT),
      .rd_en(1),
      .rd_data(wb_out)
      );
*/

endmodule
