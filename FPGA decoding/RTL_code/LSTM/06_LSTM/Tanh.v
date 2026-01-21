module Tanh#(
    parameter QZ_R = 8,
    parameter QZ_D = 16,
    parameter QZ = QZ_R + QZ_D //数据量化位宽
)
(
input clk,
input rst_n,

input data_valid,
input [QZ*2-1:0]data_in,


output reg data_out_valid,
output reg [QZ-1:0]data_out_o
);
//localparam SYM = 1<< QZ_D;
wire [QZ_R-1:0]STATE;//判断数据所处分段
 reg [QZ-1:0]data_out;
/////////////////////////////数据正负判断
reg [QZ*2-1:0]data_in_d;
wire [QZ-1:0]data_in_dd;//除量化位
reg sign ; //用于记录输入数据符号 1表示负数 0表示正数
//assign data_in_d  = data_in[QZ*2-1]? (!data_in_d+'d1):data_in_d;

always@(posedge clk or negedge rst_n)
begin 
 if(~rst_n)
  begin sign <= 'd0; end
 else begin
     if(data_valid) begin sign <= data_in[QZ*2-1]; end
        else begin sign <=sign; end
 end
end

always@(posedge clk or negedge rst_n)
begin 
 if(~rst_n)
  begin data_in_d <= 'd0; end
 else if(data_valid) begin
  if(data_in[QZ*2-1])    begin data_in_d <= (~data_in)-'d1; end
        else begin data_in_d <=data_in; end
 end
 else 
    begin data_in_d <=data_in_d; end
end
assign data_in_dd = data_in_d[QZ+QZ_D-1:QZ_D];

assign  STATE = data_in_dd[QZ_R+QZ_D-1-2:QZ_D-2];
////////////////////////
reg [QZ-1:0]a,b,c;
wire  [QZ-1:0]data_out_x;
always@(*)
 begin 
  case(STATE)


   8'b00000000:    begin a <= -'d3967; b <='d33117; c<=  -'d3;        data_out_o = data_out;end
   8'b00000001:    begin a <= -'d10140; b <='d36087; c<= -'d365;        data_out_o = data_out;end
   8'b00000010:    begin a <= -'d12506; b <='d38312; c<= -'d888;        data_out_o = data_out;end
   8'b00000011:    begin a <= -'d11603; b <='d36871; c<= -'d314;        data_out_o = data_out;end
   8'b00000100:    begin a <= -'d9148; b <='d31936; c<= 'd2167;        data_out_o = data_out;end
   8'b00000101:    begin a <= -'d6525; b <='d25389; c<= 'd6256;        data_out_o = data_out;end
   8'b00000110:    begin a <= -'d4373; b <='d18953; c<= 'd11068;        data_out_o = data_out;end
   8'b00000111:    begin a <= -'d2820; b <='d13536; c<= 'd15791;        data_out_o = data_out;end
   8'b00001000:    begin a <= -'d1775; b <='d9375; c<= 'd19938;        data_out_o = data_out;end
   8'b00001001:    begin a <= -'d1102; b <='d6354; c<= 'd23324;        data_out_o = data_out;end
   8'b00001010:    begin a <= -'d678; b <='d4241; c<= 'd25957;        data_out_o = data_out;end
   8'b00001011:    begin a <= -'d415; b <='d2799; c<= 'd27934;        data_out_o = data_out;end
   8'b00001100:    begin a <= -'d253; b <='d1832; c<= 'd29381;        data_out_o = data_out;end
   8'b00001101:    begin a <= -'d154; b <='d1191; c<= 'd30420;        data_out_o = data_out;end
   
   default    : begin a <= 0; b <=0; c<= 0; data_out_o = data_out_x;end         
  endcase
 end
 assign data_out_x = sign? (~(1<<QZ_D)+'d1):1<<QZ_D;

reg [QZ-1:0]multa_dataa;
reg [QZ-1:0]multa_datab;

wire [QZ*2-1:0]resulta_o;
wire [QZ*2-1:0]resultb_o;
 mult_sigmoid mult_sigmoidua(
        .clk_i(clk), 
        .clk_en_i(1), 
        .rst_i(~rst_n), 
        .data_a_i(multa_dataa), 
        .data_b_i(multa_datab), 
        .result_o(resulta_o)) ;
 mult_sigmoid mult_sigmoidub(
     .clk_i(clk), 
     .clk_en_i(1), 
     .rst_i(~rst_n), 
     .data_a_i(data_in_dd), 
     .data_b_i(b), 
     .result_o(resultb_o)) ;




        reg [13:0]valid_d;
always@(posedge clk or negedge rst_n)
 begin 
     if(~rst_n) begin valid_d <= 0; end
        else begin valid_d <= {valid_d[13:0],data_valid}; end
 end


reg [3:0]STATE_CAL ;//计算状态机 三元二次方程
localparam INIT   = 0,
           CAL0   = 1,
           CAL1   = 2,
           CAL2   = 3,
           FINISH = 4;


wire [QZ-1:0]data_mult0;
wire [QZ-1:0]data_mult1;

reg [QZ-1:0]add_reg_c_b;
assign data_mult0 = resulta_o[QZ_D+QZ-1:QZ_D];
assign data_mult1 = resultb_o[QZ_D+QZ-1:QZ_D];
always@(posedge clk or negedge rst_n) begin 
 if(~rst_n) begin
    STATE_CAL <= INIT;
    multa_dataa <= 'd0;
    multa_datab <= 'd0; 
    add_reg_c_b <= 'd0;
    data_out <= 'd0;
    data_out_valid <= 'd0;
 end else begin 
  case(STATE_CAL)
  INIT  :begin      
    add_reg_c_b <= 'd0;
    data_out <= 'd0;
    data_out_valid <= 'd0;
     if(valid_d[1]) begin 
        STATE_CAL <= CAL0;
        multa_dataa <= a;
        multa_datab <= data_in_dd; 
     end
     else begin 
        STATE_CAL <= INIT;
        multa_dataa <= 0;
        multa_datab <= 0; 
     end
   end 
  CAL0  :begin      
    if(valid_d[7]) begin 
        STATE_CAL <= CAL1;
        multa_dataa <= data_mult0;
        multa_datab <= data_in_dd; 
        add_reg_c_b <= data_mult1 + c;
     end
     else begin 
        STATE_CAL <= STATE_CAL;
        multa_dataa <= multa_dataa;
        multa_datab <= multa_datab; 
        add_reg_c_b <= add_reg_c_b;
     end
   end 
  CAL1  :begin      
    if(valid_d[13]) begin 
        STATE_CAL <= FINISH;
        multa_dataa <= multa_dataa;
        multa_datab <= multa_datab; 
        add_reg_c_b <= add_reg_c_b + data_mult0;
     end
     else begin 
        STATE_CAL <= STATE_CAL;
        multa_dataa <= multa_dataa;
        multa_datab <= multa_datab; 
        add_reg_c_b <= add_reg_c_b;
     end
   end 
  FINISH:begin      
      if(sign) begin data_out <=  (~add_reg_c_b) + 'd1; end
        else begin data_out <= add_reg_c_b; end
         STATE_CAL <= INIT;
    data_out_valid <= 'd1;
   end 


  endcase
 end
end



endmodule