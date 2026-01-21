`timescale 1ns / 1ps
module read_contral#(
    parameter DEBUG = 1,   
 parameter input_size = 1, //输入特征数
 parameter hidden_size = 1, //隐藏层特征数
 parameter num_layers = 1, //LSTM层数
 parameter output_size = 1, //输出类别数
 parameter batch_size = 1, //批大小
 parameter sequence_length = 1, //序列长度
 
 
 parameter ADDR_WIDTHAD = $clog2(hidden_size*hidden_size*4),
 parameter ADDR_WIDTHAH = $clog2(hidden_size*input_size*4),
 parameter ADDR_WIDTHBIAS = $clog2(hidden_size*4),
 parameter QZ = 16, //数据量化位宽
 parameter QZ_R = 8,
 parameter QZ_D = 16
 
 
 
 )
 (
 input clk ,
 input rst_n, 
 
 output [QZ*4-1:0]weight_out,
 
 input rd_data,
 

output data_valid,
output fifo_ready


 );


wire rd_en;



 localparam WEIGTH_LENGTH = hidden_size*hidden_size*4 + hidden_size*input_size*4;// + input_size*2;

 localparam FC_PA =  input_size*hidden_size;
reg STATE_cho ;







localparam RAMADDR_W  = ADDR_WIDTHAD + ADDR_WIDTHAH + ADDR_WIDTHAH;
reg[RAMADDR_W -1 :0]rd_weight_addr;
reg[RAMADDR_W -1 :0]rd_weight_addr_fc;
wire[RAMADDR_W -1 :0]rd_addr;






wire [3:0]fifo_full;
wire data_out_valid;
wire [QZ-1:0]data_out;
wire [3:0]fifo_empty;
reg [3:0]wr_en;
reg addr_rd;

//////////////////////////////////////////////控制状态机
wire wr_en_fc;
wire fifo_full_fc;
wire fifo_empty_fc;
always@(posedge clk or negedge rst_n) begin 
  if(~rst_n) begin STATE_cho <= 0; end
    else begin 
  case(STATE_cho)
   'd0:begin 
      if(wr_en[3]||(&fifo_full)) begin STATE_cho<= 1; end
        else begin STATE_cho<= STATE_cho; end    
   end
   'd1:begin 
     if(wr_en_fc||fifo_full_fc) begin STATE_cho<= 0; end
      else begin STATE_cho<= STATE_cho; end
   end 
  endcase
  end
end


////////////////////////////////////////////



always@(posedge clk or negedge rst_n)
 begin 
 if(~rst_n) begin  addr_rd <= 0; end
    else begin addr_rd <= ~fifo_full[0]; end 
end
reg addr_rd_fc;
always@(posedge clk or negedge rst_n)
 begin 
 if(~rst_n) begin  addr_rd_fc <= 0; end
    else begin addr_rd_fc <= ~fifo_full_fc; end 
end



assign data_out_valid =    addr_rd&&~STATE_cho;

assign data_out_valid_fc = addr_rd_fc;

assign wr_en_fc = data_out_valid_fc&&STATE_cho;
always@(posedge clk or negedge rst_n)
 begin 
   if(~rst_n)
     begin 
        rd_weight_addr <= 'd0;
     end
    else begin if(data_out_valid&&~STATE_cho) begin 
         if(rd_weight_addr >= WEIGTH_LENGTH-1) begin rd_weight_addr <= 0; end
         else begin rd_weight_addr <= rd_weight_addr+ 'd1; end
    end
    else begin 
        rd_weight_addr <= rd_weight_addr;
    end
 end
 end
 always@(posedge clk or negedge rst_n)
 begin 
   if(~rst_n)
     begin 
        rd_weight_addr_fc <= 'd0;
     end
    else begin if(data_out_valid_fc&&STATE_cho) begin 
         if(rd_weight_addr_fc >= FC_PA-1) begin rd_weight_addr_fc <= 0; end
         else begin rd_weight_addr_fc <= rd_weight_addr_fc+ 'd1; end
    end
    else begin 
      rd_weight_addr_fc <= rd_weight_addr_fc;
    end
 end
 end



always@(*)
 begin 
     case(rd_weight_addr[1:0]) 
      2'b00: begin wr_en = {3'b000,data_out_valid}; end
      2'b01: begin wr_en = {2'b00,data_out_valid,1'b0}; end
      2'b10: begin wr_en = {1'b0,data_out_valid,2'b00};end
      2'b11: begin wr_en = {data_out_valid,3'b000};end
     endcase
 end


genvar i ;
generate for (i=0;i<4;i=i+1) begin: fifo_gate
    /* pmi_fifo 
    #(
      .pmi_data_width        (24 ), // integer       
      .pmi_data_depth        (96 ), // integer       
      .pmi_almost_full_flag  (80 ), // integer (pmi_almost_full_flag MUST be LESS than pmi_data_depth)       
      .pmi_almost_empty_flag (1  ), // integer		
      .pmi_regmode           ("reg" ), // "reg"|"noreg"    	
      .pmi_family            ("LIFCL" ), // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
      .pmi_implementation    ("EBR" )  // "LUT"|"EBR"|"HARD_IP"
    ) WEIGHT_FIFO_24x96a (         
      .Data        (data_out ), // I:      
      .Clock       (clk ), // I:
      .WrEn        (wr_en[i] ), // I:
      .RdEn        (rd_en ), // I:
      .Reset       (~rst_n ), // I:
      .Q           (weight_out[QZ*(i+1)-1:QZ*(i)] ), // O:
      .Empty       (fifo_empty[i] ), // O:
      .Full        ( ), // O:
      .AlmostEmpty ( ), // O:
      .AlmostFull  (fifo_full[i] )  // O:
    );
    */

    fifo3 WEIGHT_FIFO_24x96a(
    .clk_i       (clk) ,  
    .rst_i          (~rst_n) , 
    .wr_en_i        (wr_en[i]) , 
    .rd_en_i        (rd_en) , 
    .wr_data_i      (data_out) , 
    .full_o         (), 
    .empty_o        (fifo_empty[i]), 
    .almost_full_o  (fifo_full[i]), 
    .rd_data_o      (weight_out[QZ*(i+1)-1:QZ*(i)]) );
 
end
endgenerate

fifo3 WEIGHT_FIFO_24x96fc(
  .clk_i       (clk) ,  
  .rst_i          (~rst_n) , 
  .wr_en_i        (wr_en_fc) , 
  .rd_en_i        (0) , 
  .wr_data_i      (data_out) , 
  .full_o         (), 
  .empty_o        (fifo_empty_fc), 
  .almost_full_o  (fifo_full_fc), 
  .rd_data_o      ());





wire[QZ-1:0]weight_out_whh;

weight_rom
#(
   .DEBUG(DEBUG),
   .col(hidden_size),
   .cow(input_size),
   .RAMADDR_W(RAMADDR_W),
   .QZ(QZ) //数据量化位宽

)weight_rom_u
(
 .addr_wih(adr_ram_rd),
 .addr_whh(rd_weight_addr),
 .addr_bih(),
 .addr_bhh(),

 .weight_out_wih(weight_out_wih),
 .weight_out_whh(weight_out_whh),
 .bias_out_bih  (),
 .bias_out_bhh  ()

);
reg [2:0]data_valid_d;
assign fifo_ready = ~(|fifo_empty);
assign data_out = weight_out_whh;
assign rd_en = &(~fifo_empty)&&rd_data;

always@(posedge clk or negedge rst_n)
 begin 
   if(~rst_n)
     begin 
        data_valid_d <= 'd0;
     end
    else begin 
        data_valid_d <= {data_valid_d[1:0],rd_en};
    end
 end
 assign data_valid = data_valid_d[1];
localparam FCWEI_START = hidden_size*hidden_size*4+hidden_size*input_size*4;



assign rd_addr =STATE_cho? rd_weight_addr_fc + FCWEI_START:rd_weight_addr;

 //assign weight_out = weight_out;






endmodule