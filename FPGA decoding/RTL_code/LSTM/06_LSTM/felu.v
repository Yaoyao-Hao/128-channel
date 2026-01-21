module felu#(
    parameter QZ_R = 8,
    parameter QZ_D = 16,
    parameter QZ = QZ_R + QZ_D //数据量化位宽
)
(
input clk,
input rst_n,

input data_valid,
input [QZ-1:0]data_in,


output wire data_out_valid,
output wire [QZ-1:0]data_out_o
);
wire sign ;
assign sign = data_in[QZ-1];
wire [9:0]STATE;//根据数据大小选择查找表
wire [QZ-1:0]data_in0;
assign data_in0 = sign?~data_in+1:data_in;
assign STATE = data_in0[QZ_D-1+3:QZ_D-1-7];
reg [QZ-1:0]data_out;

reg data_valid_d,data_valid_dd;
always@(posedge clk or negedge rst_n) begin 
    if(~rst_n) begin
        data_valid_d <= 'd0;
        data_valid_dd <= 'd0;
     end
    else begin
        data_valid_d <=  data_valid;
        data_valid_dd <= data_valid_d;
     end
 end

reg [QZ-1:0]data_out_cal;
wire a ;
//assign a  = 
wire [QZ_D-1:0]romdata_out;
always@(posedge clk or negedge rst_n) begin 
   if(~rst_n) begin
    data_out_cal <= 'd0;
    end
   else begin
     if(~sign) begin 
        data_out_cal <= data_in0;
     end
        else begin 
if(|data_in0[QZ-1:QZ_D-2+3]) begin data_out_cal <= -'d1;  end
else begin 
    data_out_cal<= {{QZ_R{romdata_out[QZ_D-1]}},romdata_out};
end
        end
    end
end
/*
romexp ramexpu(
        .rd_clk_i(clk), 
        .rst_i(~rst_n), 
        .rd_en_i(1), 
        .rd_clk_en_i(1), 
        .rd_addr_i(STATE), 
        .rd_data_o(romdata_out)) ;*/
reg [2:0]data_o_v;
        always@(posedge clk or negedge rst_n) begin 
            if(~rst_n) begin
                data_o_v <= 'd0;
             end
            else begin
                data_o_v <=  {data_o_v[1:0],data_valid_dd};
             end
         end
         assign data_out_valid = data_o_v[2];
wire [39:0]multout;
/*
         elu24x16 elu24x16u(
        .clk_i(clk), 
        .clk_en_i(1), 
        .rst_i(~rst_n), 
        .data_a_i(data_out_cal), 
        .data_b_i('d32767), 
        .result_o(multout)) ;
*/
        ramexp ramexpu(
        .wr_clk_i(clk), 
        .rd_clk_i(clk), 
        .rst_i(~rst_n), 
        .wr_clk_en_i(1), 
        .rd_en_i(1), 
        .rd_clk_en_i(1), 
        .wr_en_i(0), 
        .wr_data_i(0), 
        .wr_addr_i(0), 
        .rd_addr_i(STATE), 
        .rd_data_o(romdata_out)) ;
        assign  data_out_o =data_out_cal;// multout[39:39-QZ];
endmodule