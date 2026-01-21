`timescale 1ns / 1ps
module weight_read
#(
   parameter DEBUG = 1,   
parameter input_size = 1, //输入特征数
parameter hidden_size = 1, //隐藏层特征数
parameter num_layers = 1, //LSTM层数
parameter output_size = 1, //输出类别数
parameter batch_size = 1, //批大小
parameter sequence_length = 1, //序列长度


parameter ADDR_WIDTHAD = $clog2(hidden_size*hidden_size*4),
parameter ADDR_WIDTHBIAS = $clog2(hidden_size*4),
parameter QZ = 16, //数据量化位宽
parameter QZ_R = 8,
parameter QZ_D = 16,
parameter PARALL_NUM = 8 ,//并行计算规模 必须为2的幂次
parameter INPUTSIZE = input_size/PARALL_NUM,
parameter REMAINDER = input_size - INPUTSIZE * PARALL_NUM,// 计算余数

parameter INPUTSIZE_AD = hidden_size/PARALL_NUM,
parameter REMAINDER_AD = hidden_size - INPUTSIZE_AD * PARALL_NUM,// 计算余数


parameter DATA_PARALL = 1,
parameter LAST_ADR_AD = (hidden_size-1-1)*hidden_size+1,////权重地址的最终值
parameter LAST_ADR = (hidden_size-1-1)*input_size+1////权重地址的最终值




)
(
input clk ,
input rst_n ,

input cnt_input_size_valid,
input cnt_hidden_size_valid,




input [10:0]STATE,
input start_read,


input wire Gate_Cal,//指示权重读取模块从mem中读出相应权重值
input HID_CYCLE_FINISH,

input rd_busy,//读取ad权重参数
input rd_busy_ah,///读取ah权重
output fifo_ready,
input [ADDR_WIDTHAD-1:0]addr_ram_ad,
input [2:0]STATE_TYPE,
output reg cal_Chara_finish,//一组特征数计算完成指示
output wire last_eigenvalue,//最后一个特征值，当处于改状态时将进行C,H参数计算
output wire [2:0]STATE_HID,
output reg [DATA_PARALL*QZ*4-1:0]weight_out_o,
output reg weight_out_valid_o,

output reg [ADDR_WIDTHBIAS-1:0]cnt_hidden_size0,
output wire [QZ*4-1:0]bih,
output wire [QZ*4-1:0]bhh,
input data_save_reg
);
reg weight_out_valid;
reg[DATA_PARALL*QZ-1:0]weight_out;

reg [23:0]INPUTSIZE0;
always@(*)
begin 
   case(STATE_HID)
   'd2:begin   INPUTSIZE0 = INPUTSIZE;      end
   'd3:begin   INPUTSIZE0 = INPUTSIZE_AD;      end
   default:begin INPUTSIZE0 = INPUTSIZE;      end
   endcase
end 




reg [QZ-1:0]RAM_DATA;
////////////////////////////ah
reg [23:0]cnt_input_size;
reg [23:0]cnt_hidden_size;

always@(posedge clk or negedge rst_n)/////隐藏层地址累加
begin 
 if(~rst_n||HID_CYCLE_FINISH) begin 
    cnt_hidden_size <= 'd0;
    cnt_hidden_size0 <= 'd0;
 end
 else if(cnt_hidden_size_valid)
    begin 
      if(cnt_hidden_size <= LAST_ADR-1)
       begin    cnt_hidden_size <= cnt_hidden_size + input_size;    
         cnt_hidden_size0 <= cnt_hidden_size0 + 'd1;
      end
      else
        begin cnt_hidden_size <= 0; 
         cnt_hidden_size0 <= 0 ;end
    end
    else 
        begin 
         cnt_hidden_size <= cnt_hidden_size;
         cnt_hidden_size0 <= cnt_hidden_size0 ;
        end
end

always@(posedge clk or negedge rst_n)/////特征数地址累加
begin 
 if(~rst_n) begin 
    cnt_input_size <= 'd0;
    cal_Chara_finish <= 'd0;
 end
 else if(cnt_input_size_valid)begin 
    if(cnt_input_size < input_size-1) ////////完成一组特征数计算
    begin    cnt_input_size <= cnt_input_size + PARALL_NUM;    cal_Chara_finish <= 'd0;      end
   else
     begin cnt_input_size <= 0;
      cal_Chara_finish <= 'd1; end
 end
 else begin 
    cnt_input_size <= cnt_input_size;
    cal_Chara_finish <= 'd0;
 end
end


assign last_eigenvalue = (cnt_input_size == input_size-1);
/////////////////////////////////////////////////////////
/*
/////////////////////////ad
reg [23:0]cnt_input_size_ad;
reg [23:0]cnt_hidden_size_ad;
always@(posedge clk or negedge rst_n)/////隐藏层地址累加
begin 
 if(~rst_n||HID_CYCLE_FINISH) begin 
    cnt_hidden_size_ad <= 'd0;
 end
 else if(cnt_hidden_size_valid_ad)
    begin 
      if(cnt_hidden_size_ad <= LAST_ADR_AD-1)
       begin    cnt_hidden_size_ad <= cnt_hidden_size_ad + input_size;          end
      else
        begin cnt_hidden_size_ad <= 0; end
    end
    else 
        begin 
         cnt_hidden_size_ad <= cnt_hidden_size_ad;
        end
end

always@(posedge clk or negedge rst_n)/////特征数地址累加
begin 
 if(~rst_n) begin 
    cnt_input_size_ad <= 'd0;
 end
 else if(cnt_input_size_valid_ad)begin 
    if(cnt_input_size_ad <= hidden_size-1) ////////完成一组特征数计算
    begin    cnt_input_size_ad <= cnt_input_size_ad + PARALL_NUM;          end
   else
     begin cnt_input_size_ad <= 0; end
 end
 else begin 
    cnt_input_size_ad <= cnt_input_size_ad;
 end
end

*/
/////////////////////////////////////////////////////////



wire [31:0]rd_addr_start;
reg [23:0]ramread_cnt;
reg [4:0]STATE_R;//读取权重状态机
reg [7:0]read_num;//读取参数数量
reg weight_valid;
reg weight_read_valid;


wire [QZ-1:0]weight_out_wih;
wire [QZ*4-1:0]weight_out_whh;
wire [QZ*4-1:0]weight_out_bih;
wire [QZ*4-1:0]weight_out_bhh;






localparam INIT = 0,
           ADDR_CAL = 1,
           READ_W = 2,
           READ_FINISH = 3,
           READ_BI = 4,
           READ_BH = 5;
reg read_bi;
reg read_bh;

reg [23:0]rd_adr;///////从缓存中读取10个权值数据的起始地址
           always@(posedge clk or negedge rst_n)
            begin 
             if(~rst_n) begin 
                STATE_R <= INIT;
                weight_out <= 'd0;
                weight_out_valid <= 'd0;
                ramread_cnt <= 'd0;
                read_num <= 'd0;
                weight_valid <= 'd0;
                rd_adr <= 'd0;
                read_bi <= 'd0;
                read_bh <= 'd0;
               // bih <= 'd0;
               // bhh <= 'd0;

            end
             else begin 
               case(STATE_R)
               INIT :begin
                ramread_cnt <= 'd0;
                read_num <= 'd0;
                weight_valid <= 'd0;
                weight_out_valid <= 'd0;
                rd_adr <= rd_adr;
                read_bi <= 'd0;
                read_bh <= 'd0;
              //  bih <= bih;
              //  bhh <= bhh;
                 if(start_read||Gate_Cal) begin 
                    STATE_R <= ADDR_CAL;
                 end
                 else begin 
                    STATE_R <= INIT;
                 end
                end
               ADDR_CAL:begin
                    ramread_cnt <= 'd0;
                    read_num <= 'd0;
                    weight_valid <= 'd1;

                    rd_adr <= cnt_hidden_size + cnt_input_size;
                    STATE_R <= READ_W;

                    weight_out_valid <= 'd0;
                    
                    if(cnt_input_size == INPUTSIZE0 - 1)
                     begin read_num <= PARALL_NUM ; end
                    else begin read_num <=PARALL_NUM;  end
               end 
               READ_W:begin
                    weight_valid <= 'd1;
                    if(weight_read_valid) begin 
                        weight_out <=RAM_DATA;
                        if(ramread_cnt >= read_num-1)  begin 
                         // if(~last_eigenvalue)begin STATE_R <= READ_FINISH; ramread_cnt <= 0;end
                         //  else begin STATE_R <= READ_BI; ramread_cnt <= 0;  read_bi <= 'd1;end
                           if(~last_eigenvalue)begin STATE_R <= READ_FINISH; ramread_cnt <= 0;end
                           else begin STATE_R <= READ_FINISH; ramread_cnt <= 0;  end//read_bi <= 'd1;end
                          end
                        else begin STATE_R <=READ_W; ramread_cnt <= ramread_cnt + 1;end
                    end
                end

///////////////////////////////最后一个特征值时会进入该状态/////////////////

                READ_BI:begin 
                  
                  weight_valid <= 'd0;
                  if(weight_read_valid) begin 
                  //   bih <= weight_out_bih;
                  //   bhh <= weight_out_bhh;
                      if(ramread_cnt >= read_num-1)  begin STATE_R <= READ_BH; ramread_cnt <= 0;  read_bh <= 'd1;read_bi <= 'd0;end
                      else begin STATE_R <=STATE_R; ramread_cnt <= ramread_cnt + 1;read_bi <= 'd1;end
                  end
              end      
              
              READ_BH:begin 
               //read_bh <= 'd1;
               weight_valid <= 'd0;
               if(weight_read_valid) begin 
                 // bih <= weight_out_bih;
                 // bhh <= weight_out_bhh;
                   if(ramread_cnt >= read_num-1)  begin STATE_R <= READ_FINISH; ramread_cnt <= 0; read_bh <= 'd0; end
                   else begin STATE_R <=STATE_R; ramread_cnt <= ramread_cnt + 1;read_bh <= 'd1;end
               end
           end   

/////////////////////////////////////////////////////////////////////////
               READ_FINISH:begin
                   STATE_R <=INIT;
                   weight_out_valid <= 'd1;
                   rd_adr <= rd_adr;
                   weight_out <= weight_out;
                   read_bi <= 'd0;
                   read_bh <= 'd0;
                //   bih <= bih;
                //   bhh <= bhh;
                end          
               endcase
             end
            end


wire [23:0]adr_ram_rd;



reg [23:0]adr_ram_rd_gat;////gat权重储存地址
localparam INIT0 = 0,
           INGA = 1,
           FORGET = 2,
           CELL = 3,
           OUTGATE = 4,
           FINISH = 5;

           localparam length_wei = input_size *hidden_size;//每个权重数组的大小
      reg [ADDR_WIDTHBIAS-1:0]     gate_num;
always@(*) 
begin
case(STATE)
INGA:begin       adr_ram_rd_gat = length_wei*0; gate_num = hidden_size * 0; end
FORGET:begin     adr_ram_rd_gat = length_wei*1; gate_num = hidden_size * 1; end 
CELL:begin       adr_ram_rd_gat = length_wei*2; gate_num = hidden_size * 2; end
OUTGATE:begin    adr_ram_rd_gat = length_wei*3; gate_num = hidden_size * 3; end
   default:begin adr_ram_rd_gat = length_wei*0; gate_num = 'd0; end
endcase

end
/*
always@(posedge clk or negedge rst_n)
 begin 
 if(~rst_n)  begin adr_ram_rd<= 'd0; end
   else begin 
       if(HID_CYCLE_FINISH) begin adr_ram_rd <= 0; end
       else begin end
      end
end
*/
assign adr_ram_rd = rd_adr + ramread_cnt + adr_ram_rd_gat; 

///////////////////////选择读取权重参数///////////////////////////////////////////
localparam            CAL_AD = 1,
                      CAL_AH = 2;


wire read_valid_ah; 

always@(*)
begin 
  case(STATE_TYPE)
  CAL_AD:begin
   weight_out_valid_o = read_valid_ah;
   weight_out_o       = weight_out_whh;
    
   end
  CAL_AH:begin
   weight_out_valid_o =  read_valid_ah;
   weight_out_o       = weight_out_whh;

   end 
   default:begin    weight_out_valid_o = read_valid_ah;
                    weight_out_o       = weight_out_whh;  end
  endcase

end

////////////////////////////模拟spi读取延迟///////////////////
reg [10:0]cntrd_0;
reg [10:0]cntrd_1;
//assign  weight_read_valid = weight_valid;
/*
always@(posedge clk or negedge rst_n)
 begin 
  if(~rst_n) begin cntrd_0<= 'd0; read_valid_ah<= 'd0;end
   else  begin
      if(rd_busy)  begin if(cntrd_0>=4 ) begin   cntrd_0 <= 'd0;read_valid_ah<= 'd1;end
      else 
         begin cntrd_0 <= cntrd_0 + 'd1; read_valid_ah<= 'd0;end
       end
 end
 end
*/
 always@(posedge clk or negedge rst_n)
 begin 
  if(~rst_n) begin cntrd_1<= 'd0; weight_read_valid<= 'd0;end
   else  begin if(weight_valid||read_bh||read_bi) begin 
       if(cntrd_1>=4 ) begin   cntrd_1 <= 'd0;weight_read_valid<= 'd1;end
      else 
         begin cntrd_1 <= cntrd_1 + 'd1; weight_read_valid<= 'd0;end
    end
   else begin cntrd_1 <= 0; weight_read_valid<= 'd0; end 
   end
 end

////////////////////////////////////////////////////////////


wire [ADDR_WIDTHBIAS-1:0]adr_weight_b;
assign adr_weight_b = cnt_hidden_size0; //  +     gate_num;
/*
weight_rom
#(
   .DEBUG(DEBUG),
   .col(hidden_size),
   .cow(input_size),

   .QZ(QZ) //数据量化位宽

)weight_rom_u
(
 .addr_wih(adr_ram_rd),
 .addr_whh(addr_ram_ad),
 .addr_bih(adr_weight_b),
 .addr_bhh(adr_weight_b),

 .weight_out_wih(weight_out_wih),
 .weight_out_whh(),
 .bias_out_bih  (),
 .bias_out_bhh  ()

);
assign bih = 0;
assign bhh = 0;*/
/*
bias_ram bias_mem(
        .wr_clk_i   (clk), 
        .rd_clk_i   (clk), 
        .rst_i      (~rst_n), 
        .wr_clk_en_i(1), 
        .rd_en_i    (1), 
        .rd_clk_en_i(1), 
        .wr_en_i    (0), 
        .wr_data_i  (), 
        .wr_addr_i  (adr_weight_b), 
        .rd_addr_i  (adr_weight_b), 
        .rd_data_o  (weight_out_bih)) ;
*/
       
always@(*)
begin
   case(STATE_TYPE) 
   'd1:begin  RAM_DATA = weight_out_wih; end
   'd2:begin  RAM_DATA = weight_out_whh; end
  default:begin RAM_DATA = weight_out_whh; end
      endcase
end
wire rd_weight_fifo;
assign rd_weight_fifo = (STATE_TYPE==CAL_AD)?rd_busy_ah:rd_busy;
/*
read_contral#(
 .DEBUG         (DEBUG),
 .input_size    (input_size),
 .hidden_size   (hidden_size),


 
 

 .QZ(QZ) //数据量化位宽
 
 
 
 )read_contralu
 (
 .clk (clk),
 .rst_n(rst_n), 
 
 .weight_out(weight_out_whh),
 

 
.rd_data(rd_weight_fifo),
 

.data_valid(read_valid_ah),
.fifo_ready(fifo_ready)
 





 );

*/

endmodule