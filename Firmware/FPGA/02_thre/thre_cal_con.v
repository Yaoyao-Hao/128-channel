module thre_cal_con#
(
  parameter LENGTH = 32768
  )(
input clk ,
input rst ,
input start_cal,
input rd_thre,
input one_packet,
input raw_data_valid0,
input raw_data_valid1,
input [15:0]raw_data0,
input [15:0]raw_data1,
input [15:0]threshold_0_31_i,
input [15:0]threshold_32_63_i,
input [6:0]channel,
output reg cal_busy,
input fifo_empty,
input fifo_tra_rst,
output wire [1:0]sqrt_valid_o,
output wire [15:0]sqrt_data_out,
output wire channel_chose_o,//选择计算0-31或者32-63
//阈值数据上传

output wire[7:0]addr_ram_o,
output wire[7:0]rd_wiener,
input rd_rec_thre,

//阈值数据输出
input thre_tra,
output reg valid_rd,
output reg [15:0]thre_data_tra,
output reg reset_fifo ///阈值计算结束后将系统复位状态清0保证数据传输
);
wire[7:0]addr_ram;
reg [7:0]addr_ram_d,addr_ram_dd;
reg start_tra_thre;
localparam INIT = 0;
localparam CAL0_31 = 1;
localparam SKIP = 2;
localparam CAL32_63 = 3;
localparam FINISH = 4;
localparam WAIT = 5;
localparam WAIT_TRA = 6;
localparam WAIT_CNT = 7;
localparam WAIT_STATE0 = 9;
localparam WAIT_STATE1 = 10;
localparam RST_SYS = 8;
localparam WAIT_RD = 11;
wire [15:0]threshold_0_31_o;
wire [15:0]threshold_32_63_o;

reg channel_chose;
reg fifo_empty_d;
reg [3:0]STATE;
//reg channel_chose; //选择计算0-31或者32-63
reg cal_ctrl; //控制计算模块工作
wire cal_finish;
reg [7:0]cnt;

reg [3:0]empty_fifo;
always@(posedge clk or posedge rst)
 begin
  if(rst)
   begin
    STATE <=INIT;
    channel_chose <='d0;
    cal_ctrl <='d0;
    reset_fifo <= 'd0;
    cal_busy <= 'd0;
    cnt <= 'd0;
    start_tra_thre <= 'd0;
   end
  else 
   begin
    case(STATE)
    INIT:begin
      
     if(start_cal)
      begin
        reset_fifo <= 'd1;
        STATE <=WAIT;
        channel_chose <='d0;
        cal_ctrl <='d0;
        cal_busy <= 'd0;
      end
      else 
       begin
        reset_fifo <= 'd0;
        STATE <=INIT;
        channel_chose <='d0;
        cal_ctrl <='d0;
        cal_busy <= 'd0;
       end
     end



     WAIT:
      begin
        
       if(channel == 0&&one_packet)
        begin
          reset_fifo <= 'd0;
         STATE <=rd_thre? WAIT_RD:CAL0_31;
         cal_busy <= 'd1;
        end
       else 
        begin
          reset_fifo <= 'd0;
         STATE <=WAIT;
         cal_busy <= 'd1;
        end
      end
     CAL0_31:begin
        cal_ctrl <='d1;
        channel_chose <='d0;
        if(cal_finish)
          begin
          STATE <=SKIP;
          end
         else 
          begin
          STATE <=CAL0_31;      
          end end
      SKIP:begin 
           
           STATE <=CAL32_63;
           channel_chose <='d0;
           cal_ctrl <='d0;   
       if(channel == 0)
        begin
         STATE <=CAL32_63;
        end
       else 
        begin
         STATE <=SKIP;
        end
      end
      CAL32_63:begin
        cal_ctrl <='d1;
        channel_chose <='d1;
        if(cal_finish)
          begin
          STATE <=WAIT_STATE0;
          start_tra_thre<= 'd0;
          end
         else 
          begin
          STATE <=CAL32_63;  
          start_tra_thre<= 'd0;     
          end end
      WAIT_RD:begin 
        STATE <=WAIT_STATE0;
        start_tra_thre<= 'd0;
      end    

      WAIT_STATE0:begin 
        STATE <=fifo_tra_rst?WAIT_STATE0:WAIT_STATE1;
        start_tra_thre<= 'd0;
      end
      WAIT_STATE1:begin 
        STATE <=WAIT_CNT;
        start_tra_thre<= 'd1;
      end
      WAIT_CNT:begin 
       if(cnt[7])
        begin
         STATE <=WAIT_TRA;
         cnt <= 0;
         start_tra_thre<= 'd0;
        end
        else 
         begin
         STATE <=STATE;
         cnt <= cnt + 'd1;
         start_tra_thre<= 'd0;
         end
      end

      WAIT_TRA:begin
       if(fifo_empty&&~fifo_empty_d) begin
         STATE <=RST_SYS;
       end
       else 
      begin 
        STATE <=STATE;
      end      end
      RST_SYS:begin 
        if(empty_fifo == 4'b0111)
         begin  STATE <=FINISH;end
        else 
          begin  STATE <=STATE;end
         cal_busy <= 'd0; 
         reset_fifo <= 'd1;
      end 
      

        FINISH:begin
         cal_ctrl <='d0;
         reset_fifo <= 'd0;
         channel_chose <='d0;   
         cal_busy <= 'd0;     
         STATE <=INIT; 
         //reset_fifo <= 'd0;
        // if(one_packet) begin 
        // STATE <=INIT; 
        // end
        // else begin 
        // STATE <=STATE; 
         
        // end
        end
    endcase
   end
 end

//reg  reset_fifo_d; 



// wire sqrt_valid;
// wire [15:0]sqrt_data_out;


// wire raw_data_cal_valid;
// wire [15:0]raw_data_cal;

// assign raw_data_cal_valid = channel_chose? raw_data_valid1:raw_data_valid0;
// assign raw_data_cal = channel_chose? raw_data1:raw_data0;

localparam Median = 16'h8000;

reg raw_data_cal_valid;
reg [15:0]raw_data_cal;
always@(posedge clk)
begin 
raw_data_cal_valid <= channel_chose? raw_data_valid1:raw_data_valid0;
raw_data_cal       <= channel_chose? raw_data1:raw_data0; 
end



threshold_cal
#(
 .LENGTH(LENGTH))
threshold_calinst
(
.clk(clk) ,
.rst(~cal_ctrl) ,
.raw_data_in(raw_data_cal),
.raw_data_valid(raw_data_cal_valid),
.channel(channel),
.threshold_o  (sqrt_data_out ),
.threshold_v(sqrt_valid),
//.sqrt_valid(sqrt_valid),
//.sqrt_data_out(sqrt_data_out),
.cal_finish(cal_finish)
);




assign sqrt_valid_o = {sqrt_valid&&channel_chose,sqrt_valid&&~channel_chose};

// RMSSAVE RMSSAVEINST0_31(
//         .clk_i(clk), 
//         .rst_i(rst), 
//         .clk_en_i(1), 
//         .wr_en_i(sqrt_valid&&~channel_chose), 
//         .wr_data_i(sqrt_data_out), 
//         .addr_i(addr_ram_d), 
//         .rd_data_o(threshold_0_31_o)) ;

// RMSSAVE RMSSAVEINST32_63(
//         .clk_i(clk), 
//         .rst_i(rst), 
//         .clk_en_i(1), 
//         .wr_en_i(sqrt_valid&&channel_chose), 
//         .wr_data_i(sqrt_data_out), 
//         .addr_i(addr_ram_d), 
//         .rd_data_o(threshold_32_63_o)) ;
//

reg [2:0]TRA_TH_STATE,TRA_TH_STATE_d,TRA_TH_STATE_dd;
reg [7:0]rd_addr;
//reg valid_rd;
//reg [15:0]thre_tra_out;
//reg [15:0]thre_data_tra;
always@(posedge clk or posedge rst)
 begin
  if(rst)
   begin
    TRA_TH_STATE <= 'd0;
    rd_addr <='d3;
    valid_rd <= 'd0;
  //  thre_tra_out <= 'd0;
   end
  else 
   begin
    case(TRA_TH_STATE)
     'd0:begin 
      
       if(start_tra_thre) begin
       TRA_TH_STATE <= 'd1;
       valid_rd <= 'd1;
       end
       else begin
       TRA_TH_STATE <= TRA_TH_STATE;
       valid_rd <= 'd0;
       end
     end
     'd1:begin 
       valid_rd <= 'd1;
      // thre_data_tra<=threshold_0_31_o;
       if(rd_addr =='d34)
        begin
         rd_addr <= 'd3;
         TRA_TH_STATE <= 'd2;
        end
       else 
        begin
         rd_addr <= rd_addr + 'd1;
         TRA_TH_STATE <= TRA_TH_STATE;
        end
     end
    
     'd2:begin 
       valid_rd <= 'd1;
       if(rd_addr =='d35)
        begin
         rd_addr <= 'd3;
         TRA_TH_STATE <= 'd3;
        end
       else 
        begin
         rd_addr <= rd_addr + 'd1;
         TRA_TH_STATE <= TRA_TH_STATE;
        end
     end
     'd3:begin 
       TRA_TH_STATE <= 'd4;
       rd_addr <= rd_addr;
       valid_rd <= 'd1;
     end
      'd4:begin 
       TRA_TH_STATE <= 'd0;
       rd_addr <= rd_addr;
       valid_rd <= 'd0;
     end
    endcase
   end
 end

reg [7:0]rd_addr_d;

always@(posedge clk or posedge rst)
 begin
  if(rst)
   begin
    rd_addr_d <= 'd0;
    TRA_TH_STATE_d <= 'd0;
    TRA_TH_STATE_dd<= 'd0;
    fifo_empty_d <='d0;
    empty_fifo <= 'd0;
    addr_ram_d <='d0;
    addr_ram_dd<='d0;
   end
  else 
   begin
    rd_addr_d <= rd_addr;
    TRA_TH_STATE_d <= TRA_TH_STATE;
    TRA_TH_STATE_dd<= TRA_TH_STATE_d;
    fifo_empty_d <=fifo_empty;
    empty_fifo <= {empty_fifo[2:0],fifo_empty_d};
    addr_ram_d <=addr_ram  ;
    addr_ram_dd<=addr_ram_d;
   end
 end

assign addr_ram_o = addr_ram;
assign addr_ram = valid_rd?rd_addr:channel;
always@(*)
 begin
  case(TRA_TH_STATE_dd)
   'd0:begin thre_data_tra= 'haa55; end
   'd1:begin thre_data_tra= threshold_0_31_i;end//rd_rec_thre?threshold_0_31_i:threshold_0_31_i ; end
   'd2:begin thre_data_tra= threshold_32_63_i;end//rd_rec_thre?threshold_0_31_i:threshold_0_31_i; end
    // 'd1:begin thre_data_tra= rd_rec_thre?threshold_0_31_i:'d100 ; end
    // 'd2:begin thre_data_tra= rd_rec_thre?threshold_32_63_i:'d200; end
   default: begin thre_data_tra= 'haa55; end
  endcase
 end
assign channel_chose_o = TRA_TH_STATE_dd[1] ||(STATE==CAL32_63);
assign rd_wiener =TRA_TH_STATE_d[1]?addr_ram_o + 'd29:addr_ram_o-'d3;
endmodule