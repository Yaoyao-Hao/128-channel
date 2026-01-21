module FC_C#(
    parameter QZ = 24,
    parameter QZ_D = 8,
    parameter output_size = 2, //输入特征数
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



output reg[OS_W-1:0]fc_bais_adr,
output wire [HS_W-1:0]fc_w_adr,
input  [QZ-QZ_D-1:0]fc_bais_data,

output wire [QZ*2-1:0]output_data,
output reg output_data_valid


  );
  reg [2:0]STATE;
  reg [HS_W-1:0]HS;
  reg [10:0]valid_d;
  wire mult_out_v;
  assign fc_w_adr = HS;
  assign mult_out_v = valid_d[4]||valid_d[9];

  always@(posedge clk or negedge rst_n)
  begin
    if(~rst_n)
    begin
      valid_d <= 'd0;
    end
    else
    begin
      valid_d <= {valid_d[9:0],ht_valid};
    end
  end

reg [31:0]ram_data0,ram_data1;//矩阵计算缓存
wire [31:0]mult_out;

  localparam INIT = 0,
             CAL_HS = 1,
             CAL    = 2,
             cal_finish = 3;
             always@(posedge clk or negedge rst_n)
             begin
               if(~rst_n)
               begin
                 STATE <= 'd0;
                 HS<= 'd0;
                 ram_data0<='d0;
                 ram_data1<='d0;
                 fc_bais_adr <= 'd0;
                 output_data_valid <= 'd0;
               end
               else
               begin
                 case(STATE)
                   INIT:
                   begin
                    output_data_valid <= 'd0;
                    if(~(|HS)) begin 
                        ram_data0<=0;
                        ram_data1<=0;
                    end
                    else begin 
                    ram_data0<=ram_data0;
                    ram_data1<=ram_data1;end
                    fc_bais_adr <= 'd0;
                     HS<= HS;
                     if(ht_valid)
                     begin
                        STATE <= CAL_HS;
                     end
                     else 
                     begin 
                        STATE <= STATE;
                     end
                   end
                   CAL_HS:
                   begin
                    if(mult_out_v)
                    begin
                        ram_data0<=ram_data0 + mult_out;
                        ram_data1<=ram_data1;
                        fc_bais_adr <= 'd1;
                       STATE <= CAL;
                    end
                    else 
                    begin 
                       STATE <= STATE;
                       ram_data0<=ram_data0;
                       ram_data1<=ram_data1;
                       fc_bais_adr <= 'd0;
                    end
                   end
                   CAL   :
                   begin
                    if(mult_out_v)
                    begin
                       STATE <= cal_finish;
                       fc_bais_adr <= 'd0;
                       ram_data0<=ram_data0;
                       ram_data1<=ram_data1 + mult_out;
                    end
                    else 
                    begin 
                       STATE <= STATE;
                       ram_data0<=ram_data0;
                       ram_data1<=ram_data1;
                       fc_bais_adr <= 'd1;
                    end
                   end
                   cal_finish:
                   begin
                     STATE  <= INIT;
                     fc_bais_adr <= 'd0;
                     if(HS<hidden_size-1) begin 
                     HS<= HS +'d1;
                     ram_data0<=ram_data0;
                     ram_data1<=ram_data1;
                     output_data_valid <= 'd0;
                     end
                     else begin 
                        HS<= 0;
                        ram_data0<=ram_data0;
                        ram_data1<=ram_data1 ;
                        output_data_valid <= 'd1;
                     end
                   end
                 endcase
               end
             end

ADD24T24 ADD0(
        .data_a_re_i(ram_data0[29:6]), 
        .data_b_re_i(24'd2366), 
        .result_re_o(output_data[QZ-1:0])) ;
        ADD24T24 ADD1(
        .data_a_re_i(ram_data1[29:6]), 
        .data_b_re_i(-24'd3145), 
        .result_re_o(output_data[QZ*2-1:QZ])) ;
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














endmodule