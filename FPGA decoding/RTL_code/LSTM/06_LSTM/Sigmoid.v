module Sigmoid#(
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
localparam SYM = 1<< QZ_D;
wire [QZ_R-1:0]STATE;//判断数据所处分段

/////////////////////////////数据正负判断
reg [QZ*2-1:0]data_in_d;
wire [QZ-1:0]data_in_dd;//除量化位
reg [QZ-1:0]data_out;
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

assign  STATE = data_in_dd[QZ-2:QZ_D-1];
////////////////////////
wire  [QZ-1:0]data_out_x;
reg [QZ-1:0]a,b,c;
always@(*)
 begin 
  case(STATE)
   8'b00000000: begin a <= -'d496; b <='d8279; c<= 'd16383;     data_out_o = data_out; end
   8'b00000001: begin a <= -'d1267; b <='d9022; c<= 'd16202;     data_out_o = data_out; end
   8'b00000010: begin a <= -'d1563; b <='d9578; c<= 'd15940;     data_out_o = data_out; end
   8'b00000011: begin a <= -'d1450; b <='d9218; c<= 'd16227;     data_out_o = data_out; end
   8'b00000100: begin a <= -'d1143; b <='d7984; c<= 'd17468;     data_out_o = data_out; end
   8'b00000101: begin a <= -'d816; b <='d6347; c<= 'd19512;     data_out_o = data_out; end
   8'b00000110: begin a <= -'d547; b <='d4738; c<= 'd21918;     data_out_o = data_out; end
   8'b00000111: begin a <= -'d352; b <='d3384; c<= 'd24280;     data_out_o = data_out; end
   8'b00001000: begin a <= -'d222; b <='d2344; c<= 'd26353;     data_out_o = data_out; end
   8'b00001001: begin a <= -'d138; b <='d1589; c<= 'd28046;     data_out_o = data_out; end
   8'b00001010: begin a <= -'d85; b <='d1060; c<= 'd29363;     data_out_o = data_out; end
   8'b00001011: begin a <= -'d52; b <='d700; c<= 'd30351;     data_out_o = data_out; end
   8'b00001100: begin a <= -'d32; b <='d458; c<= 'd31075;     data_out_o = data_out; end
   8'b00001101: begin a <= -'d19; b <='d298; c<= 'd31594;     data_out_o = data_out; end
   8'b00001110: begin a <= -'d12; b <='d193; c<= 'd31961;     data_out_o = data_out; end
   default    : begin a <= 0; b <=0; c<= 0;                     data_out_o = data_out_x;  end         
  endcase
 end


 ///当x>7.5 x<-7.5取1 0

assign data_out_x = sign? 0:1<<QZ_D;

 /////////////////////

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
      if(sign) begin data_out <= SYM - add_reg_c_b; end
        else begin data_out <= add_reg_c_b; end
            STATE_CAL <= INIT;
    data_out_valid <= 'd1;
   end 


  endcase
 end
end



endmodule