module spike_cal(
input clk,
input rst,
input [5:0]channel_cho,
input [15:0]RHD_data_in,
input RHD_data_valid,
input [15:0]threshold,
input [5:0]channel_in,
input [7:0]main_state,
output wire spike_data_valid,
output wire [31:0]spike_data_o,
input [5:0]win_depth,//窗大小
input usbtx_ready,
output reg [5:0]win_cnt,

output reg [31:0]data_spike ,

output test

);
reg  [31:0]spike_data;
reg [5:0]channel_now;///* synthesis loc = "R22C21C" */;
reg [5:0]channel_d;
always@(posedge clk or posedge rst)
begin
 if(rst)
  begin
   channel_now <= 'd0;
   channel_d   <= 'd0;
  end
 else 
  begin
    channel_now <= channel_in - 3;
    channel_d   <= channel_in;
  end
end


//reg [31:0]spike_data;
//reg spike_en;
////窗函数
//reg [5:0]win_cnt;
reg win_comp;
always@(posedge clk or posedge rst)
begin
 if(rst)
  begin
   win_cnt <='d0;
   win_comp <= 'd0;
  end
 //else if(channel_now=='d34&&main_state == 11&&usbtx_ready)
 else if((channel_in[5]&&channel_in[1])&&main_state == 11&&usbtx_ready)
  begin
   if(win_cnt < win_depth)
    begin
     win_cnt <= win_cnt  +'d1;
     win_comp <= 'd0;
    end
   else 
    begin
     win_cnt <= 'd0;
     win_comp <= 'd1;
    end
  end
 else 
  begin
   win_cnt <= win_cnt;
   win_comp <= 'd0;
  end
end


reg spike_en;
wire spike_data_valid_0;
assign spike_data_valid_0 = spike_en&&win_comp&&channel_d[5];


wire  spike_ht,spike_ht1;
//assign spike_ht =  (RHD_data_valid && (RHD_data_in < threshold));
//assign spike_ht =  (RHD_data_valid && (RHD_data_in < threshold)&&~channel_now[4]&&~channel_now[5]);
assign spike_ht =  (RHD_data_valid &&~channel_now[4]&&~channel_now[5]);
assign spike_ht1=  (RHD_data_valid && channel_now[4]&&~channel_now[5]);
wire spike_cal;
assign spike_cal =threshold[15]?(RHD_data_in > threshold) : (RHD_data_in < threshold);

// wire [15:0] channel_sel = (16'b1 << channel_now[3:0]);
reg spike_en_d,spike_en_dd;

// always @(posedge clk or posedge rst) begin
//     if (rst || spike_en_dd) begin
//         spike_data <= 16'd0;
//     end else if (~channel_now[4] && ~channel_now[5]) begin
//         if (spike_ht)
//             spike_data <= spike_data | channel_sel;  // 累加 OR
//     end
// end


// always @(posedge clk or posedge rst) begin
//     if (rst || spike_en_dd) begin
//         spike_data <= 32'd0;
//         spike_en   <= 1'b0;
//     end
//     else if (~channel_now[5]) begin
//         // 前 16 路
//         if (~channel_now[4] && spike_ht) begin
//             spike_data <= spike_data | channel_sel;
//             spike_en   <= 1'b1;
//         end
//         // 后 16 路
//         else if (channel_now[4] && spike_ht) begin
//             spike_data <= spike_data | channel_sel;
//             // 当最后一路 'd15+16 命中时可设置 spike_en=1
//             spike_en   <= (channel_now[3:0] == 4'd15) ? 1'b1 : 1'b0;
//         end
//         else begin
//             spike_en   <= 1'b0;
//         end
//     end
//     else begin
//         spike_en   <= 1'b0;
//     end
// end


wire spike_buf_reset;
assign spike_buf_reset = spike_en_dd&&~spike_en_d;
always@(posedge clk or posedge rst)
begin
 if(rst)
  begin
   spike_data[15:0]<='d0;
  end
 else 
  begin
   case(channel_now[3:0])
'd0 :begin      if(spike_ht) begin spike_data[0] <= spike_cal; end  else begin spike_data[0] <= spike_data[0] ;end  end
'd1 :begin      if(spike_ht) begin spike_data[1] <= spike_cal; end  else begin spike_data[1] <= spike_data[1] ;end  end
'd2 :begin      if(spike_ht) begin spike_data[2] <= spike_cal; end  else begin spike_data[2] <= spike_data[2] ;end  end
'd3 :begin      if(spike_ht) begin spike_data[3] <= spike_cal; end  else begin spike_data[3] <= spike_data[3] ;end  end
'd4 :begin      if(spike_ht) begin spike_data[4] <= spike_cal; end  else begin spike_data[4] <= spike_data[4] ;end  end
'd5 :begin      if(spike_ht) begin spike_data[5] <= spike_cal; end  else begin spike_data[5] <= spike_data[5] ;end  end
'd6 :begin      if(spike_ht) begin spike_data[6] <= spike_cal; end  else begin spike_data[6] <= spike_data[6] ;end  end
'd7 :begin      if(spike_ht) begin spike_data[7] <= spike_cal; end  else begin spike_data[7] <= spike_data[7] ;end  end
'd8 :begin      if(spike_ht) begin spike_data[8] <= spike_cal; end  else begin spike_data[8] <= spike_data[8] ;end  end
'd9 :begin      if(spike_ht) begin spike_data[9] <= spike_cal; end  else begin spike_data[9] <= spike_data[9] ;end  end
'd10:begin      if(spike_ht) begin spike_data[10]<= spike_cal; end  else begin spike_data[10]<= spike_data[10]; end  end
'd11:begin      if(spike_ht) begin spike_data[11]<= spike_cal; end  else begin spike_data[11]<= spike_data[11]; end  end
'd12:begin      if(spike_ht) begin spike_data[12]<= spike_cal; end  else begin spike_data[12]<= spike_data[12]; end  end
'd13:begin      if(spike_ht) begin spike_data[13]<= spike_cal; end  else begin spike_data[13]<= spike_data[13]; end  end
'd14:begin      if(spike_ht) begin spike_data[14]<= spike_cal; end  else begin spike_data[14]<= spike_data[14]; end  end
'd15:begin      if(spike_ht) begin spike_data[15]<= spike_cal; end  else begin spike_data[15]<= spike_data[15]; end  end
default:begin  spike_data[15:0]<= spike_data[15:0]; end
   endcase
  end
end

always@(posedge clk or posedge rst)
begin
 if(rst)
  begin
   spike_data[31:16]<='d0;
   //spike_data_valid <='d0;
   spike_en <='d0;
  end
 //else if(~spike_data_valid&&channel_now[4])
 else 
  begin
   case(channel_now[3:0])
'd0 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[0 +16]<= spike_cal; end  else begin spike_data[0 +16]<= spike_data[0 +16]; end  end
'd1 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[1 +16]<= spike_cal; end  else begin spike_data[1 +16]<= spike_data[1 +16]; end  end
'd2 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[2 +16]<= spike_cal; end  else begin spike_data[2 +16]<= spike_data[2 +16]; end  end
'd3 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[3 +16]<= spike_cal; end  else begin spike_data[3 +16]<= spike_data[3 +16]; end  end
'd4 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[4 +16]<= spike_cal; end  else begin spike_data[4 +16]<= spike_data[4 +16]; end  end
'd5 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[5 +16]<= spike_cal; end  else begin spike_data[5 +16]<= spike_data[5 +16]; end  end
'd6 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[6 +16]<= spike_cal; end  else begin spike_data[6 +16]<= spike_data[6 +16]; end  end
'd7 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[7 +16]<= spike_cal; end  else begin spike_data[7 +16]<= spike_data[7 +16]; end  end
'd8 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[8 +16]<= spike_cal; end  else begin spike_data[8 +16]<= spike_data[8 +16]; end  end
'd9 :begin  spike_en <='d0;   if(spike_ht1) begin spike_data[9 +16]<= spike_cal; end  else begin spike_data[9 +16]<= spike_data[9 +16]; end  end
'd10:begin  spike_en <='d0;   if(spike_ht1) begin spike_data[10+16]<= spike_cal; end  else begin spike_data[10+16]<= spike_data[10+16]; end  end
'd11:begin  spike_en <='d0;   if(spike_ht1) begin spike_data[11+16]<= spike_cal; end  else begin spike_data[11+16]<= spike_data[11+16]; end  end
'd12:begin  spike_en <='d0;   if(spike_ht1) begin spike_data[12+16]<= spike_cal; end  else begin spike_data[12+16]<= spike_data[12+16]; end  end
'd13:begin  spike_en <='d0;   if(spike_ht1) begin spike_data[13+16]<= spike_cal; end  else begin spike_data[13+16]<= spike_data[13+16]; end  end
'd14:begin  spike_en <='d0;   if(spike_ht1) begin spike_data[14+16]<= spike_cal; end  else begin spike_data[14+16]<= spike_data[14+16]; end  end
'd15:begin  spike_en <= channel_now[4];   if(spike_ht1) begin spike_data[15+16]<= spike_cal; end  else begin spike_data[15+16]<= spike_data[15+16]; end  end
default:begin spike_en <='d0;spike_data[31:16]<= spike_data[31:16]; end
   endcase
  end
end







// always@(posedge clk or posedge rst)
// begin
//  if(rst)
//   begin
//    spike_data<='d0;
//    spike_en <='d0;
//   end
//  else 
//   begin
//    case(channel_now[4:0])
// 'd0 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[0] <= spike_cal; end  else begin spike_data[0] <= spike_data[0] ;/*spike_data[0]; */end  end
// 'd1 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[1] <= spike_cal; end  else begin spike_data[1] <= spike_data[1] ;/*spike_data[1]; */end  end
// 'd2 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[2] <= spike_cal; end  else begin spike_data[2] <= spike_data[2] ;/*spike_data[2]; */end  end
// 'd3 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[3] <= spike_cal; end  else begin spike_data[3] <= spike_data[3] ;/*spike_data[3]; */end  end
// 'd4 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[4] <= spike_cal; end  else begin spike_data[4] <= spike_data[4] ;/*spike_data[4]; */end  end
// 'd5 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[5] <= spike_cal; end  else begin spike_data[5] <= spike_data[5] ;/*spike_data[5]; */end  end
// 'd6 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[6] <= spike_cal; end  else begin spike_data[6] <= spike_data[6] ;/*spike_data[6]; */end  end
// 'd7 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[7] <= spike_cal; end  else begin spike_data[7] <= spike_data[7] ;/*spike_data[7]; */end  end
// 'd8 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[8] <= spike_cal; end  else begin spike_data[8] <= spike_data[8] ;/*spike_data[8]; */end  end
// 'd9 :begin     spike_en <='d0;  if(spike_ht) begin spike_data[9] <= spike_cal; end  else begin spike_data[9] <= spike_data[9] ;/*spike_data[9]; */end  end
// 'd10:begin     spike_en <='d0;  if(spike_ht) begin spike_data[10]<= spike_cal; end  else begin spike_data[10]<= spike_data[10];/*spike_data[10];*/ end  end
// 'd11:begin     spike_en <='d0;  if(spike_ht) begin spike_data[11]<= spike_cal; end  else begin spike_data[11]<= spike_data[11];/*spike_data[11];*/ end  end
// 'd12:begin     spike_en <='d0;  if(spike_ht) begin spike_data[12]<= spike_cal; end  else begin spike_data[12]<= spike_data[12];/*spike_data[12];*/ end  end
// 'd13:begin     spike_en <='d0;  if(spike_ht) begin spike_data[13]<= spike_cal; end  else begin spike_data[13]<= spike_data[13];/*spike_data[13];*/ end  end
// 'd14:begin     spike_en <='d0;  if(spike_ht) begin spike_data[14]<= spike_cal; end  else begin spike_data[14]<= spike_data[14];/*spike_data[14];*/ end  end
// 'd15:begin     spike_en <='d0;  if(spike_ht) begin spike_data[15]<= spike_cal; end  else begin spike_data[15]<= spike_data[15];/*spike_data[15];*/ end  end

// 'd16 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[0 +16]<= spike_cal; end  else begin spike_data[0 +16]<= spike_data[0 +16]; end  end
// 'd17 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[1 +16]<= spike_cal; end  else begin spike_data[1 +16]<= spike_data[1 +16]; end  end
// 'd18 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[2 +16]<= spike_cal; end  else begin spike_data[2 +16]<= spike_data[2 +16]; end  end
// 'd19 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[3 +16]<= spike_cal; end  else begin spike_data[3 +16]<= spike_data[3 +16]; end  end
// 'd20 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[4 +16]<= spike_cal; end  else begin spike_data[4 +16]<= spike_data[4 +16]; end  end
// 'd21 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[5 +16]<= spike_cal; end  else begin spike_data[5 +16]<= spike_data[5 +16]; end  end
// 'd22 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[6 +16]<= spike_cal; end  else begin spike_data[6 +16]<= spike_data[6 +16]; end  end
// 'd23 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[7 +16]<= spike_cal; end  else begin spike_data[7 +16]<= spike_data[7 +16]; end  end
// 'd24 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[8 +16]<= spike_cal; end  else begin spike_data[8 +16]<= spike_data[8 +16]; end  end
// 'd25 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[9 +16]<= spike_cal; end  else begin spike_data[9 +16]<= spike_data[9 +16]; end  end
// 'd26:begin   spike_en <='d0;   if(spike_ht) begin spike_data[10+16]<= spike_cal; end  else begin spike_data[10+16]<= spike_data[10+16]; end  end
// 'd27:begin   spike_en <='d0;   if(spike_ht) begin spike_data[11+16]<= spike_cal; end  else begin spike_data[11+16]<= spike_data[11+16]; end  end
// 'd28:begin   spike_en <='d0;   if(spike_ht) begin spike_data[12+16]<= spike_cal; end  else begin spike_data[12+16]<= spike_data[12+16]; end  end
// 'd29:begin   spike_en <='d0;   if(spike_ht) begin spike_data[13+16]<= spike_cal; end  else begin spike_data[13+16]<= spike_data[13+16]; end  end
// 'd30:begin   spike_en <='d0;   if(spike_ht) begin spike_data[14+16]<= spike_cal; end  else begin spike_data[14+16]<= spike_data[14+16]; end  end
// 'd31:begin   spike_en <='d1;   if(spike_ht) begin spike_data[15+16]<= spike_cal; end  else begin spike_data[15+16]<= spike_data[15+16]; end  end
// default:begin spike_en <='d0;spike_data<= spike_data; end
//    endcase
//   end
// end






/*
always@(posedge clk or posedge rst)
begin
 if(rst||spike_en_dd)
  begin
   spike_data[15:0]<='d0;
   //spike_data_valid <='d0;
 //  spike_en <='d0;
  end
 //else if(~spike_data_valid&&~channel_now[4])
 else if(~channel_now[4]&&~channel_now[5])
  begin
   case(channel_now[3:0])
'd0 :begin      if(spike_ht) begin spike_data[0] <= 1; end  else begin spike_data[0] <= spike_data[0]; end  end
'd1 :begin      if(spike_ht) begin spike_data[1] <= 1; end  else begin spike_data[1] <= spike_data[1]; end  end
'd2 :begin      if(spike_ht) begin spike_data[2] <= 1; end  else begin spike_data[2] <= spike_data[2]; end  end
'd3 :begin      if(spike_ht) begin spike_data[3] <= 1; end  else begin spike_data[3] <= spike_data[3]; end  end
'd4 :begin      if(spike_ht) begin spike_data[4] <= 1; end  else begin spike_data[4] <= spike_data[4]; end  end
'd5 :begin      if(spike_ht) begin spike_data[5] <= 1; end  else begin spike_data[5] <= spike_data[5]; end  end
'd6 :begin      if(spike_ht) begin spike_data[6] <= 1; end  else begin spike_data[6] <= spike_data[6]; end  end
'd7 :begin      if(spike_ht) begin spike_data[7] <= 1; end  else begin spike_data[7] <= spike_data[7]; end  end
'd8 :begin      if(spike_ht) begin spike_data[8] <= 1; end  else begin spike_data[8] <= spike_data[8]; end  end
'd9 :begin      if(spike_ht) begin spike_data[9] <= 1; end  else begin spike_data[9] <= spike_data[9]; end  end
'd10:begin      if(spike_ht) begin spike_data[10]<= 1; end  else begin spike_data[10]<= spike_data[10]; end  end
'd11:begin      if(spike_ht) begin spike_data[11]<= 1; end  else begin spike_data[11]<= spike_data[11]; end  end
'd12:begin      if(spike_ht) begin spike_data[12]<= 1; end  else begin spike_data[12]<= spike_data[12]; end  end
'd13:begin      if(spike_ht) begin spike_data[13]<= 1; end  else begin spike_data[13]<= spike_data[13]; end  end
'd14:begin      if(spike_ht) begin spike_data[14]<= 1; end  else begin spike_data[14]<= spike_data[14]; end  end
'd15:begin      if(spike_ht) begin spike_data[15]<= 1; end  else begin spike_data[15]<= spike_data[15]; end  end
default:begin  spike_data[15:0]<= spike_data[15:0]; end
   endcase
  end
else begin 
    spike_data[15:0]<= spike_data[15:0];
 //   spike_en <='d0;
end
end

always@(posedge clk or posedge rst)
begin
 if(rst||spike_en_dd)
  begin
   spike_data[31:16]<='d0;
   //spike_data_valid <='d0;
   spike_en <='d0;
  end
 //else if(~spike_data_valid&&channel_now[4])
 else if(channel_now[4]&&~channel_now[5])
  begin
   case(channel_now[3:0])
'd0 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[0 +16]<= 1; end  else begin  spike_data[0 +16]<= spike_data[0 +16]; end  end
'd1 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[1 +16]<= 1; end  else begin  spike_data[1 +16]<= spike_data[1 +16]; end  end
'd2 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[2 +16]<= 1; end  else begin  spike_data[2 +16]<= spike_data[2 +16]; end  end
'd3 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[3 +16]<= 1; end  else begin  spike_data[3 +16]<= spike_data[3 +16]; end  end
'd4 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[4 +16]<= 1; end  else begin  spike_data[4 +16]<= spike_data[4 +16]; end  end
'd5 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[5 +16]<= 1; end  else begin  spike_data[5 +16]<= spike_data[5 +16]; end  end
'd6 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[6 +16]<= 1; end  else begin  spike_data[6 +16]<= spike_data[6 +16]; end  end
'd7 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[7 +16]<= 1; end  else begin  spike_data[7 +16]<= spike_data[7 +16]; end  end
'd8 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[8 +16]<= 1; end  else begin  spike_data[8 +16]<= spike_data[8 +16]; end  end
'd9 :begin  spike_en <='d0;   if(spike_ht) begin spike_data[9 +16]<= 1; end  else begin  spike_data[9 +16]<= spike_data[9 +16]; end  end
'd10:begin  spike_en <='d0;   if(spike_ht) begin spike_data[10+16]<= 1; end  else begin  spike_data[10+16]<= spike_data[10+16]; end  end
'd11:begin  spike_en <='d0;   if(spike_ht) begin spike_data[11+16]<= 1; end  else begin  spike_data[11+16]<= spike_data[11+16]; end  end
'd12:begin  spike_en <='d0;   if(spike_ht) begin spike_data[12+16]<= 1; end  else begin  spike_data[12+16]<= spike_data[12+16]; end  end
'd13:begin  spike_en <='d0;   if(spike_ht) begin spike_data[13+16]<= 1; end  else begin  spike_data[13+16]<= spike_data[13+16]; end  end
'd14:begin  spike_en <='d0;   if(spike_ht) begin spike_data[14+16]<= 1; end  else begin  spike_data[14+16]<= spike_data[14+16]; end  end
'd15:begin  spike_en <='d1;   if(spike_ht) begin spike_data[15+16]<= 1; end  else begin  spike_data[15+16]<= spike_data[15+16]; end  end
default:begin spike_en <='d0;spike_data[31:16]<= spike_data[31:16]; end
   endcase
  end
else begin 
    spike_data[31:16]<= spike_data[31:16];
    spike_en <='d0;
end
end
*/
reg [31:0]spike_data_d;
reg RHD_data_valid_d;
reg [31:0]data_spike_d;
always@(posedge clk or posedge rst)
begin
 if(rst)
  begin
   spike_data_d<='d0;
   spike_en_d  <='d0;
   spike_en_dd <='d0;
   RHD_data_valid_d<='d0;
  end
  else begin
      spike_en_d  <=    #1 spike_en;
      spike_en_dd <=    #1 spike_en_d;
      RHD_data_valid_d<=#1 RHD_data_valid;
    if(RHD_data_valid_d) begin
      spike_data_d<=spike_data;
    end
   end
  end
genvar i;
generate for (i=0;i<32;i=i+1)
  begin 
    always@(posedge clk or posedge rst) begin 
      if(rst||spike_data_valid_0) begin data_spike[i] <= 1'b0;end
      else    begin data_spike[i] <= (spike_data[i]&&~spike_data_d[i]&&RHD_data_valid_d)? 1'b1:data_spike[i];  end
    end
    //assign data_spike[i] = (spike_data[i]&&~spike_data_d[i]&&spike_data_valid_0)? 1'b1:data_spike[i]; 
  end
  endgenerate
// always@(posedge clk)
// begin
//     if(spike_data_valid_0) begin
//       for (i=0;i<=32;i=i+1)
//        data_spike[i] <= (spike_data[i]&&~spike_data_d[i])? 1'b1:1'b0; 
//     end 
//     else 
//       begin
//         data_spike <= data_spike;
//        end
//   end

assign spike_data_valid = spike_data_valid_0;

wire [31:0]test_spike_data;
reg [15:0]test_cnt;
always@(posedge clk or posedge rst)
begin
 if(rst)
  begin
   test_cnt<='d0;

  end
  else begin
    if(spike_en_d) begin
      test_cnt<=test_cnt + 'd1;
    end
    else begin 
      test_cnt<= test_cnt;
    end
   end
  end
assign test_spike_data ={ 32{test_cnt[3]}};
assign spike_data_o = data_spike;
assign  test = spike_data[0];
endmodule 