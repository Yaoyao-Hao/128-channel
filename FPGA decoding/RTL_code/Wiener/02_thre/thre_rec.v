`timescale 1ns / 1ps
module thre_rec(
input clk_in,
input rst,
input reset,
input data_valid,
input [15:0]ok2,
input [7:0]ep_addr,
input wireoutfinish,
input [5:0]channel,

//test
output reg [15:0] test_cnt,
output wire flag,




input [1:0]thre_save_ram_v        ,
input channel_chose_cal_thre ,
input [15:0]sqrt_data_out    ,
//output reg [2:0]REC_STATE,

output wire thre_rec_busy_o,
output  wire [15:0]thre_0_31,
output  wire [15:0]thre_32_63,
output  wire [15:0]thre_64_95,
output  wire [15:0]thre_96_127
    );

reg[2:0]STATE/* synthesis loc = "R14C23A" */;
    reg[15:0]ep_dataout;    
    wire [15:0]ok1;
    assign ok1 = {ok2[7:0],ok2[15:8]};
// reg [2:0]STATE;
reg xa;assign flag = xa;
reg [1:0]rec_ad;
localparam HEADER = 16'hC7E5,

           START_THRE_REC = 8'hA5,
           UPDATAHEADER = 16'hB79E,
           IDLE = 0,
           SAVE = 1,
           FINISH = 2,
           WireOUT = 3;
 reg [9:0]data_cnt;          
always@(posedge clk_in)
 begin
  if(reset)
   begin
   // flag <='d0;
    ep_dataout <= 16'd0;
    data_cnt  <= 10'd0;
    STATE <= IDLE; 
    rec_ad<='d0;
   end
 else 
  begin
   case(STATE)
    IDLE: begin 
     //ep_dataout <= ep_dataout;
     ep_dataout <= 0;
	   data_cnt  <= 10'd0;
     rec_ad<='d0;
     
     if(ok1[15:0] == HEADER&&data_valid)
      begin
       STATE <= SAVE;
       data_cnt  <= 10'd1;
      end

     else 
      begin
       STATE <= IDLE;
       data_cnt <= data_cnt;
      end
    end
    
    SAVE:begin
      if(data_valid)
       begin
        data_cnt  <= data_cnt + 'd1;
		    //rec_ad<={1'b1,ok1[15]};
        if(ok1[14:8] == ep_addr[7:0])
          begin
            ep_dataout <= 'd1; 
			      STATE      <= FINISH; 
          end
        else 
             begin
               ep_dataout <= ep_dataout;
               STATE      <= IDLE; 
             end
           end
      else 
       begin
        data_cnt  <= data_cnt;
        STATE     <= STATE;
       end
       end

     FINISH: begin
      ep_dataout <= 'd0;
      STATE      <= IDLE;
      rec_ad<=0;
     end
   endcase
  end
 end
////////////////////////////当接收到阈值头储存时，进行阈值储存////////////////
reg add_cho;
always@(posedge clk_in or posedge reset) begin 
  if(reset) begin add_cho <= 'd0; end
  else if(rec_ad[1])begin add_cho <= rec_ad[0]; end
  else if(xa       )begin add_cho <= 0;         end
  else begin add_cho<= add_cho; end
end

reg [2:0]REC_STATE;
reg [7:0]thre_channel;
reg [15:0]thre_data_out;
reg thre_data_valid_out;
localparam INIT_REC = 0;
localparam HEAD_REC = 1;
localparam THRE_REC = 2;
localparam FINISH_REC = 3;
always@(posedge clk_in)
 begin
  if(reset)
   begin
    REC_STATE <= INIT_REC;
    thre_channel <= 'd0;
    thre_data_out <= 'd0;
    thre_data_valid_out <= 'd0;
    test_cnt <= 'd0;
   end
  else 
   begin
    case(REC_STATE)
     INIT_REC:begin //初始化状态
        thre_channel <= 'd0;
        thre_data_out <= 'd0;
        thre_data_valid_out <= 'd0;
        xa <= 'd0;
      if(ep_dataout) 
      begin REC_STATE <= HEAD_REC; end
      else begin REC_STATE <= REC_STATE; end end
     HEAD_REC:begin //接收头
        thre_channel <= thre_channel ;
        thre_data_out <= thre_data_out;
        thre_data_valid_out <= 'd0;
       // if(ok1[15:0] == HEADER&&data_valid) begin 
        if(data_valid) begin 
         REC_STATE <= THRE_REC; 
        end
        else begin
         REC_STATE <= REC_STATE; 
        end
     end
     THRE_REC:begin //储存接下来到来的阈值数据 
        if(data_valid) begin
         if(thre_channel<63) begin 
            thre_channel <= thre_channel + 'd1;
            thre_data_valid_out <= 'd1;
            thre_data_out <= ok1;
            REC_STATE <= HEAD_REC; 
            test_cnt <= test_cnt + 'd1;
        end
        else //接收完64通道阈值数据之后进入结束状态
         begin
            thre_channel <= thre_channel + 'd1;
            thre_data_valid_out <= 'd1;
            thre_data_out <= ok1;
            REC_STATE <= FINISH_REC; 
         end
        end 
        else 
         begin
            thre_channel <= thre_channel;
            thre_data_valid_out <= 'd0;
            thre_data_out <= thre_data_out;
            REC_STATE <= REC_STATE;         
         end
        end
     FINISH_REC:begin //结束状态对状态清0并进入初始状态
        REC_STATE <= INIT_REC; 
        thre_channel <= 0;
        thre_data_valid_out <= 'd0;
        thre_data_out <= ok1;
        xa <= 'd1;
     end
    endcase
   end
 end




 wire [6:0]ram_addr;
 wire [6:0]rd_addr;
 wire [5:0]wr_channel;
 assign wr_channel = thre_channel[5:0] -'d1;
 assign rd_addr = channel-'d3;
 assign ram_addr[5:0] =|thre_save_ram_v? {channel_chose_cal_thre,channel[4:0]} :wr_channel;//thre_channel[5:0] -'d1;//循环时地址从1开始，-1使地址从1开始

 assign ram_addr[6] = 0;//add_cho;//循环时地址从1开始，-1使地址从1开始
 wire [15:0]thre_data_out0;
assign thre_data_out0 =(|thre_save_ram_v)? sqrt_data_out:{thre_data_out[7:0],thre_data_out[15:8]};


// thre_rec_ram thre_rec0_31(
//        . wr_clk_i        (clk_in)         , 
//        . rd_clk_i        (clk_in)         , 
//        . rst_i           (rst)      , 
//        . wr_clk_en_i     (1)            , 
//        . rd_en_i         (1)        , 
//        . rd_clk_en_i     (1)            , 
//        . wr_en_i         (thre_data_valid_out&&~ram_addr[5]&&~ram_addr[6])        , 
//        . wr_data_i       (thre_data_out0)          , 
//        . wr_addr_i       (ram_addr[4:0])          , 
//        . rd_addr_i       (rd_addr[4:0])          , 
//        . rd_data_o       (thre_0_31)          ) ;
// thre_rec_ram thre_rec32_63(
//        . wr_clk_i        (clk_in)         , 
//        . rd_clk_i        (clk_in)         , 
//        . rst_i           (rst)      , 
//        . wr_clk_en_i     (1)            , 
//        . rd_en_i         (1)        , 
//        . rd_clk_en_i     (1)            , 
//        . wr_en_i         (thre_data_valid_out&&ram_addr[5]&&~ram_addr[6])        , 
//        . wr_data_i       (thre_data_out0)          , 
//        . wr_addr_i       (ram_addr[4:0])          , 
//        . rd_addr_i       (rd_addr[4:0])          , 
//        . rd_data_o       (thre_32_63)          ) ;
// thre_rec_ram thre_rec64_95(
//        . wr_clk_i        (clk_in)         , 
//        . rd_clk_i        (clk_in)         , 
//        . rst_i           (rst)      , 
//        . wr_clk_en_i     (1)            , 
//        . rd_en_i         (1)        , 
//        . rd_clk_en_i     (1)            , 
//        . wr_en_i         (thre_data_valid_out&&~ram_addr[5]&&ram_addr[6])        , 
//        . wr_data_i       (thre_data_out0)          , 
//        . wr_addr_i       (ram_addr[4:0])          , 
//        . rd_addr_i       (rd_addr[4:0])          , 
//        . rd_data_o       (thre_64_95)          ) ;
// thre_rec_ram thre_rec96_127(
//        . wr_clk_i        (clk_in)         , 
//        . rd_clk_i        (clk_in)         , 
//        . rst_i           (rst)      , 
//        . wr_clk_en_i     (1)            , 
//        . rd_en_i         (1)        , 
//        . rd_clk_en_i     (1)            , 
//        . wr_en_i         (thre_data_valid_out&&ram_addr[5]&&ram_addr[6])        , 
//        . wr_data_i       (thre_data_out0)          , 
//        . wr_addr_i       (ram_addr[4:0])          , 
//        . rd_addr_i       (rd_addr[4:0])          , 
//        . rd_data_o       (thre_96_127)          ) ;

       pmi_ram_dp
       #(
         .pmi_wr_addr_depth    (32 ), // integer
         .pmi_wr_addr_width    (5 ), // integer
         .pmi_wr_data_width    (16 ), // integer
         .pmi_rd_addr_depth    (32 ), // integer
         .pmi_rd_addr_width    (5 ), // integer
         .pmi_rd_data_width    (16 ), // integer
         .pmi_regmode          ( "reg" ), // "reg"|"noreg"
         .pmi_resetmode        ("async" ), // "async"|"sync"
         .pmi_init_file        ( "D:/YCB/YCB/PROJECT/BCI2024/ram_init.hex"), // string
         .pmi_init_file_format ( "hex"), // "binary"|"hex"
         .pmi_family           ("common" )  // "iCE40UP"|"common"
       ) thre_rec0_31 (
         .Data      (thre_data_out0 ),  // I:
         .WrAddress (ram_addr[4:0] ),  // I:
         .RdAddress (rd_addr[4:0] ),  // I:
         .WrClock   (clk_in   ),  // I:
         .RdClock   (clk_in   ),  // I:
         .WrClockEn (1 ),  // I:
         .RdClockEn (1 ),  // I:
         .WE        ((thre_save_ram_v[0]||thre_data_valid_out)&&~ram_addr[5]),//||ram_wr[i] ),  // I:
         .Reset     ('d0),  // I:
         .Q         (thre_0_31 )   // O:
       );
       
       pmi_ram_dp
       #(
         .pmi_wr_addr_depth    (32 ), // integer
         .pmi_wr_addr_width    (5 ), // integer
         .pmi_wr_data_width    (16 ), // integer
         .pmi_rd_addr_depth    (32 ), // integer
         .pmi_rd_addr_width    (5 ), // integer
         .pmi_rd_data_width    (16 ), // integer
         .pmi_regmode          ( "reg" ), // "reg"|"noreg"
         .pmi_resetmode        ("async" ), // "async"|"sync"
         .pmi_init_file        ("D:/YCB/YCB/PROJECT/BCI2024/ram_init.hex" ), // string
         .pmi_init_file_format ( "hex"), // "binary"|"hex"
         .pmi_family           ("common" )  // "iCE40UP"|"common"
       ) thre_rec32_63 (
         .Data      (thre_data_out0 ),  // I:
         .WrAddress (ram_addr[4:0] ),  // I:
         .RdAddress (rd_addr[4:0] ),  // I:
         .WrClock   (clk_in   ),  // I:
         .RdClock   (clk_in   ),  // I:
         .WrClockEn (1 ),  // I:
         .RdClockEn (1 ),  // I:
         .WE        ((thre_save_ram_v[1]||thre_data_valid_out)&&ram_addr[5]),//||ram_wr[i] ),  // I:
         .Reset     ('d0),  // I:
         .Q         (thre_32_63 )   // O:
       );
      //  pmi_ram_dp
      //  #(
      //    .pmi_wr_addr_depth    (32 ), // integer
      //    .pmi_wr_addr_width    (5 ), // integer
      //    .pmi_wr_data_width    (16 ), // integer
      //    .pmi_rd_addr_depth    (32 ), // integer
      //    .pmi_rd_addr_width    (5 ), // integer
      //    .pmi_rd_data_width    (16 ), // integer
      //    .pmi_regmode          ( "reg" ), // "reg"|"noreg"
      //    .pmi_resetmode        ("async" ), // "async"|"sync"
      //    .pmi_init_file        ( ), // string
      //    .pmi_init_file_format ( ), // "binary"|"hex"
      //    .pmi_family           ("common" )  // "iCE40UP"|"common"
      //  ) thre_rec64_95 (
      //    .Data      (thre_data_out0 ),  // I:
      //    .WrAddress (ram_addr[4:0] ),  // I:
      //    .RdAddress (rd_addr[4:0] ),  // I:
      //    .WrClock   (clk_in   ),  // I:
      //    .RdClock   (clk_in   ),  // I:
      //    .WrClockEn (1 ),  // I:
      //    .RdClockEn (1 ),  // I:
      //    .WE        (thre_data_valid_out&&~ram_addr[5]&&ram_addr[6]),//||ram_wr[i] ),  // I:
      //    .Reset     (reset),  // I:
      //    .Q         (thre_64_95 )   // O:
      //  );
      //  pmi_ram_dp
      //  #(
      //    .pmi_wr_addr_depth    (32 ), // integer
      //    .pmi_wr_addr_width    (5 ), // integer
      //    .pmi_wr_data_width    (16 ), // integer
      //    .pmi_rd_addr_depth    (32 ), // integer
      //    .pmi_rd_addr_width    (5 ), // integer
      //    .pmi_rd_data_width    (16 ), // integer
      //    .pmi_regmode          ( "reg" ), // "reg"|"noreg"
      //    .pmi_resetmode        ("async" ), // "async"|"sync"
      //    .pmi_init_file        ( ), // string
      //    .pmi_init_file_format ( ), // "binary"|"hex"
      //    .pmi_family           ("common" )  // "iCE40UP"|"common"
      //  ) thre_rec96_127 (
      //    .Data      (thre_data_out0 ),  // I:
      //    .WrAddress (ram_addr[4:0] ),  // I:
      //    .RdAddress (rd_addr[4:0] ),  // I:
      //    .WrClock   (clk_in   ),  // I:
      //    .RdClock   (clk_in   ),  // I:
      //    .WrClockEn (1 ),  // I:
      //    .RdClockEn (1 ),  // I:
      //    .WE        (thre_data_valid_out&&ram_addr[5]&&ram_addr[6]),//||ram_wr[i] ),  // I:
      //    .Reset     (reset),  // I:
      //    .Q         (thre_96_127 )   // O:
      //  );      



       assign thre_rec_busy_o = (REC_STATE==INIT_REC)?0:1;
endmodule