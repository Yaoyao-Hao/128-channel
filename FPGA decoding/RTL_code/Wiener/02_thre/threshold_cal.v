`timescale 1ns / 1ps
/*
通过计算数组的RMS来获得通道阈值

*/
module threshold_cal
#(
 parameter LENGTH = 1024   ,
 parameter WIDTH = $clog2(LENGTH)
 //parameter WIDTH = $clog2(LENGTH)
)
(
input clk ,
input rst ,
input [15:0]raw_data_in,
input raw_data_valid,
input [5:0]channel,
//output [15:0]threshold
output reg [15:0]threshold_o,
output reg threshold_v,




output reg cal_finish





);
localparam Median = 16'h7fff;
wire sqrt_valid;
wire [15:0]sqrt_data_out;
//assign threshold_o = {sqrt_data_out[13:0],2'b0};
//assign threshold_v = sqrt_valid;






//always@(posedge clk or posedge rst)
// begin
//  if(rst)
//   begin
//     threshold_o <= 0;
//     threshold_v <= 0;
//   end
//  else 
//    if(sqrt_valid)
//    begin
//      threshold_v <= 1;
//      if(sqrt_data_out[16]||sqrt_data_out[15]) begin threshold_o <= {sqrt_data_out[13:0],2'b0};end//threshold_o <= 16'hffff; end 
//      else begin threshold_o <= {sqrt_data_out[13:0],2'b0}; end
//    end
// end


//reg start_0;//第一个数据开始
//reg stop_34;//最后一个数据
//always@(posedge clk or posedge rst)
// begin
//  if(rst)
//   begin
//     start_0 <= 0;
//   end
//  else 
//    begin
//      if(channel == 0) begin start_0 <= 1; end else begin start_0 <= 0; end
//    end
// end
// always@(posedge clk or posedge rst)
// begin
//  if(rst)
//   begin
//     stop_34 <= 0;
//   end
//  else 
//    begin
//      if(channel == 34) begin stop_34 <= 1; end else begin stop_34 <= 0; end
//    end
// end
wire start_0;//第一个数据开始
wire stop_34;//最后一个数据
assign stop_34 = channel[5]&&channel[1];
assign start_0 = ~(|channel);
/*
reg [15:0]threshold0  = 0;
reg [15:0]threshold1  = 0;
reg [15:0]threshold2  = 0;
reg [15:0]threshold3  = 0;
reg [15:0]threshold4  = 0;
reg [15:0]threshold5  = 0;
reg [15:0]threshold6  = 0;
reg [15:0]threshold7  = 0;
reg [15:0]threshold8  = 0;
reg [15:0]threshold9  = 0;
reg [15:0]threshold10 = 0;
reg [15:0]threshold11 = 0;
reg [15:0]threshold12 = 0;
reg [15:0]threshold13 = 0;
reg [15:0]threshold14 = 0;
reg [15:0]threshold15 = 0;
reg [15:0]threshold16 = 0;
reg [15:0]threshold17 = 0;
reg [15:0]threshold18 = 0;
reg [15:0]threshold19 = 0;
reg [15:0]threshold20 = 0;
reg [15:0]threshold21 = 0;
reg [15:0]threshold22 = 0;
reg [15:0]threshold23 = 0;
reg [15:0]threshold24 = 0;
reg [15:0]threshold25 = 0;
reg [15:0]threshold26 = 0;
reg [15:0]threshold27 = 0;
reg [15:0]threshold28 = 0;
reg [15:0]threshold29 = 0;
reg [15:0]threshold30 = 0;
reg [15:0]threshold31 = 0;
*/


localparam INIT = 0;
localparam SAVE0 = 1;
localparam SAVE1 = 2;
localparam READ_CAL = 3;
localparam FINISH = 4;

/*该部分用于统计累加窗数量，当各个通道累加到窗长度时进行平均开方计算*/
//reg [23:0]win_cnt;
wire [WIDTH-1:0]win_cnt;
reg [23:0]win_cnt0;///* synthesis loc = "R22C30B" */;
//always@(posedge clk or posedge rst)
// begin
//  if(rst) 
//   begin
//     win_cnt <='d0;
//   end
//  //else if(channel=='d34&&raw_data_valid)//35通道的数据为最后一个数据
//  else if(stop_34&&raw_data_valid)//35通道的数据为最后一个数据
//   begin
//    if(win_cnt < LENGTH-1)
//    begin
//     win_cnt <= win_cnt + 'd1;
//    end
//    else 
//     begin
//      win_cnt <= 0;
//     end
//   end
//   else 
//    begin
//      win_cnt <= win_cnt;
//    end
// end

wire [15:0]counter;
//pmi_counter
//#(
//  .pmi_data_width   (WIDTH+2 ), // integer
//  .pmi_updown       ("up" ), // "up"|"down"|"updown"
//  .pmi_family       ("common" )  // "iCE40UP" | "common"
//) win_cnt_counter (
//  .Clock    (clk ),  // I:
//  .Clk_En   (stop_34&&raw_data_valid ),  // I:
//  .Aclr    (rst),// (stop_34&&raw_data_valid ),  // I:
//  .UpDown   (1 ),  // I:
//  .Q        (win_cnt )   // O:
//);



count timestamp0
	 (  .clk_i(clk), 
        .clk_en_i(stop_34&&raw_data_valid), 
        .aclr_i(rst), 
        .q_o(counter[7:0])
		) ;
count timestamp1
	 (  .clk_i(clk), 
        .clk_en_i((stop_34&&raw_data_valid)&&(counter[7:0]==8'hff)), 
        .aclr_i(rst), 
        .q_o(counter[15:8])
		) ;
assign win_cnt = counter[WIDTH-1:0];
/////时序对齐

 always@(posedge clk or posedge rst)
 begin
  if(rst) 
   begin
     win_cnt0 <='d0;
   end
  // else if(channel==0)
  else if(start_0)
    begin
      win_cnt0 <= win_cnt;
    end
   else 
    begin
     win_cnt0 <= win_cnt0;
    end
 end
 wire win_cnt_v;
 assign win_cnt_v = ~|win_cnt0;//(win_cnt0==0)?1:0;
/////////////////////////////////////////////////////////////////
reg valid_wr;
reg valid_rd,valid_rd0,valid_rd1,valid_rd2,valid_rd3,valid_rd4,valid_rd5;
reg [3:0]STATE;
wire [31:0]sqare_data;
wire [31+WIDTH:0]ram_data_out;

wire rd_en;
assign rd_en = raw_data_valid;

always@(posedge clk or posedge rst)
 begin
  if(rst) begin
    STATE <= INIT;
    cal_finish <= 'd0;


  end else begin
    case(STATE)
     INIT: begin 
       cal_finish <= 'd0;
          if(win_cnt0 == LENGTH -1 ) begin STATE <= FINISH; end else begin STATE <= STATE; end
         end
     FINISH: begin  
        //  if((sqrt_valid&&(channel=='d34)) ) begin STATE <= INIT; cal_finish <= 'd1; end else begin STATE <= STATE;  cal_finish <= 'd0;end    
          if((sqrt_valid&&stop_34) ) begin STATE <= INIT; cal_finish <= 'd1; end else begin STATE <= STATE;  cal_finish <= 'd0;end    
      end
    endcase
  end
  end

/*写ram延迟，乘法器计算消耗三个时钟周期*/
reg [15:0]raw_data_in0,raw_data_in1;
always@(posedge clk or posedge rst)
 begin
  if(rst) begin
    valid_rd0 <= 'd0;
    valid_rd1 <= 'd0;
    valid_rd2 <= 'd0;
    valid_rd3 <= 'd0;
    valid_rd4 <= 'd0;
    valid_rd5 <= 'd0;
    raw_data_in0 <= 'd0;
    raw_data_in1 <= 'd0;
  end
  else 
   begin 
        valid_rd0 <= rd_en;
        valid_rd1 <= valid_rd0;
        valid_rd2 <= valid_rd1;
        valid_rd3 <= valid_rd2;
        valid_rd4 <= valid_rd3;  
        valid_rd5 <= valid_rd4;    
    raw_data_in0 <= raw_data_in;
    raw_data_in1 <= raw_data_in0;
   end
 end
/////////////////////////////////////////////////
/*累加器，累加长度为LENGTH，对乘法器结果位数进行展宽，在窗口的起始将ram中的累加值清0，窗口起始读出来的数据结果进行平方根运算*/
reg [31+WIDTH:0]threshold_add;

reg wr_en;
wire [31+WIDTH:0]threshold_add0;
//assign threshold_add = valid_rd2?threshold_add0:0;
//assign wr_en = valid_rd2;
always@(posedge clk)
 begin
 // if(rst) begin
 //   threshold_add <= 'd0;
 //   wr_en <= 'd0;
 // end
 //// else if(valid_rd2&&~win_cnt_v)
 ////  begin
 ////       threshold_add <= threshold_add0;//ram_data_out + {{WIDTH{1'b0}},sqare_data};//未到达窗口时数据进行累加
 ////       wr_en <= 'd1; 
 ////  end
 //// else if(valid_rd2&&win_cnt_v)
 ////    begin
 ////       threshold_add <=  {{WIDTH{1'b0}},sqare_data};//到达下一个窗口数据清除
 ////       wr_en <= 'd1;      
 ////    end

      if(valid_rd5)
       begin
        threshold_add <=  threshold_add0;
        wr_en <= 'd1;
       end
       else 
        begin
        threshold_add <=  threshold_add;
        wr_en <= 'd0;
        end
 end


///////////////////////////////////////////////////////////////////////////


RAM_THREDP RAM_THREDP(
        .wr_clk_i(clk), 
        .rd_clk_i(clk), 
        .rst_i(rst), 
        .wr_clk_en_i(1), 
        .rd_en_i(rd_en), 
        .rd_clk_en_i(1), 
        .wr_en_i(wr_en), 
        .wr_data_i({{WIDTH{1'b0}},{WIDTH{1'b0}},threshold_add}), 
        .wr_addr_i(channel), 
        .rd_addr_i(channel), 
        .rd_data_o(ram_data_out)) ;



mult16x16 mult16x16u(
        .clk_i   (clk)      , 
        .clk_en_i(1)      , 
        .rst_i   (rst)      , 
        .data_a_i(raw_data_in)      , 
        .data_b_i(raw_data_in)       , 
        .result_o(sqare_data)         ) ;
/*移位运算用于实现除法                                        */
reg sqrt_start;
reg [31:0]sqrt_data_in;

always@(posedge clk or posedge rst)
 begin
  if(rst)
   begin
     sqrt_data_in <= 'd0;
     sqrt_start <= 'd0;
   end
  else 
   begin
    sqrt_data_in <= ram_data_out[31+WIDTH:WIDTH];
    if(win_cnt0 == 0) begin sqrt_start <= valid_rd1; end
    else begin sqrt_start <= 0; end
   end
 end
 wire sqrt_busy ;
  reg sqrt_busy0,sqrt_busy1;
reg sqrt_valid_d,sqrt_valid_dd,sqrt_valid_ddd,sqrt_valid_dddd;
always@(posedge clk or posedge rst)
 begin
  if(rst) begin
    sqrt_busy0 <= 'd0;
    sqrt_busy1 <= 'd0;
    threshold_v <= 0;
    sqrt_valid_d <= 'd0;
    sqrt_valid_dd<= 'd0;
    sqrt_valid_ddd <= 'd0;
    sqrt_valid_dddd<= 'd0;
  end
  else 
   begin 
    sqrt_busy0 <= sqrt_busy;
    sqrt_busy1 <= sqrt_busy0;
    sqrt_valid_d <= sqrt_valid;
    sqrt_valid_dd<= sqrt_valid_d;    
   // threshold_v <= sqrt_valid_dd;
    sqrt_valid_ddd <= sqrt_valid_dd;
    sqrt_valid_dddd<= sqrt_valid_ddd;
    threshold_v <= sqrt_valid_dddd;
   end
 end
//wire sqrt_valid;
assign sqrt_valid = ~sqrt_busy0&&sqrt_busy1;
/*
cm_sqrt cm_sqrtu(
    .clk(clk),							//时钟
    .rst_n(~rst),						//低电平复位，异步复位同步释放

    .din_i(sqrt_data_in),				//开方数据输入
    .din_valid_i(sqrt_start),					//数据输入有效

    .busy_o(sqrt_busy),						//sqrt单元繁忙

    .sqrt_o(sqrt_data_out),	//开方结果输出
    .rem_o()				//开方余数输出
);
*/

cm_sqrt_q cm_sqrt_qu(
    .clk(clk),							//时钟
    .rst_n(~rst),						//低电平复位，异步复位同步释放

    .din_i(sqrt_data_in),				//开方数据输入
    .din_valid_i(sqrt_start),					//数据输入有效

    .busy_o(sqrt_busy),						//sqrt单元繁忙

    .sqrt_o(sqrt_data_out),	//开方结果输出
    .rem_o()				//开方余数输出
);

wire [31:0]data_out;
//add add_inst(
//        clk_en_i(1), 
//        clk_i(clk), 
//        rst_i(rst), 
//        data_a_re_i(32'd100), 
//        data_b_re_i(32'd100), 
//        result_re_o(data_out)) ;

wire [31+WIDTH:0]ram_data_out0;

assign ram_data_out0 = win_cnt_v?0:ram_data_out;

 pmi_add
#(
  .pmi_data_width   ( 32+WIDTH), // integer
  .pmi_sign         ("off" ), // "on"|"off"
  .pmi_family       ("common" )  // "iCE40UP" | "common"
) pmi_addinst (
  .DataA    (ram_data_out0 ),  // I:
  .DataB    ({{WIDTH{1'b0}},sqare_data} ),  // I:
  .Cin      (1 ),  // I:
  .Result   ( ),  // O:
  .Cout     ( ),  // O:
  .Overflow ( )   // O:
);
wire [31+WIDTH:0]test;
add_48 add_48inst(
 .clk_i(clk), 
 .rst_i(rst), 
 .add_sub_i(1), 
 .data_a_re_i({{WIDTH{1'b0}},{WIDTH{1'b0}},ram_data_out0}), 
 .data_b_re_i({{WIDTH{1'b0}},{WIDTH{1'b0}},sqare_data} ), 
 .result_re_o(threshold_add0)) ; 
//assign threshold_add0 = ram_data_out0 + {{WIDTH{1'b0}},{WIDTH{1'b0}},sqare_data};


wire [15:0]sqrt_data_out0,sqrt_data_out_abs;
reg  [15:0]sqrt_data_out1;

wire [15:0]sqrt_data_outd;
assign sqrt_data_out0  = sqrt_data_out -  Median;
assign  sqrt_data_out_abs =sqrt_data_out0[15]? ~sqrt_data_out0:sqrt_data_out0;
//assign sqrt_data_outd = (|sqrt_data_out_abs[15:13] )? 16'h1fff:sqrt_data_out_abs[15:0];

always@(posedge clk)
 begin 
   sqrt_data_out1 <= (|sqrt_data_out_abs[15:12] )? 16'h7fff:{1'b0,sqrt_data_out_abs[12:0],2'b0} + {1'b0,sqrt_data_out_abs[15:1]};
   threshold_o    <= sqrt_data_out0[15]? Median - sqrt_data_out1[15:0]:Median + sqrt_data_out1[15:0];
 end 


//assign sqrt_data_out1 =(|sqrt_data_out_abs[15:12] )? 16'h7fff:{1'b0,sqrt_data_out_abs[12:0],2'b0} + {1'b0,sqrt_data_out_abs[15:1]};

//assign threshold_o    =sqrt_data_out;//sqrt_data_out0[15]? Median - sqrt_data_out1[15:0]:Median + sqrt_data_out1[15:0];
// //wire [15:0]threshold_out;
// wire [15:0]add16_out;
// wire [15:0]add16_out0;
// add16 uadd16(
//  .clk_i(clk), 
//  .rst_i(rst), 
//  .add_sub_i(0), 
//  .data_a_re_i(Median), 
//  .data_b_re_i(sqrt_data_out), 
//  .result_re_o(add16_out)) ;
// assign add16_out0 = add16_out[15]? ~add16_out+1:add16_out;

// add16 uthre_cal(
//  .clk_i(clk), 
//  .rst_i(rst), 
//  .add_sub_i(0), 
//  .data_a_re_i(Median), 
//  .data_b_re_i({add16_out0[13:0],2'd0}), 
//  .result_re_o(threshold_o));//(threshold_o)) ;
// //assign threshold_o = {add16_out0[13:0],2'd0};

endmodule