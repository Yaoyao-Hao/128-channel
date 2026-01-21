`timescale 1ns / 1ps
module TB_TOP();
// GSR GSR_INST( .GSR_N(1'b1), .CLK(1'b0));
reg sys_clk;
reg rst_n;
wire rx_ready_in;

reg [15:0] bl_test_data[0:35*1024-1];//定义寄存器数组用来缓存需要读取文件中的数据
// initial
// begin
//   // $readmemh("C:/Users/69594/Desktop/BCI/test_ram.dat",bl_test_data);  //初始化时把数据读出并缓存到寄存器数组当中；
// end

reg ipload_i;
  reg [3104-1:0] recv_data;
reg spi_cs, spi_clk, spi_mosi;
wire spi_miso;
        initial
        begin
        	sys_clk = 1'b0;
        	rst_n = 1'b0;
        ipload_i = 1;


        
        	#1000 rst_n = 1'b1;

          
        // 调用 SPI 主机读任务
         	#24000000 spi_master_read_388(recv_data);
          #2000 ipload_i = 0; 
        	end
        	always #10 sys_clk = ~sys_clk;   //50Mhz
        reg[15:0]data_in = 'd0;
        reg [31:0]cnt;
        reg data_valid;
        wire clk;
        assign clk = sys_clk;
        always@(posedge sys_clk)
         begin
          if(~rst_n)
           begin
           cnt <= 'd0;
           data_valid <= 'd0;
           end
          else if(rx_ready_in)
           begin
            cnt <= cnt + 'd1;
            data_valid <= 'd1;
           end
           else 
            begin
                 cnt <= cnt;
            data_valid <= 'd0;
            end
         end
        wire [7:0]WrData_I;
        reg [31:0]cnt0;
        reg start_wr;
        wire WrRdFinish_O;
        always@(posedge clk or negedge rst_n)
         begin
          if(~rst_n) begin 
            cnt0 <= 'd0;
          end
          else
          begin
            cnt0 <= cnt0 + 16'd1;
          end
         end
        always@(posedge clk or negedge rst_n)
         begin
          if(~rst_n) begin 
            cnt <= 'd0;
        
            start_wr <='d0;
          end
          else
          begin
           if(cnt0[9:0]=='d1023)
            begin
             start_wr <='d1;
        
            end
            else begin
             start_wr <='d0;
        
            end
        
           if(WrRdFinish_O) begin 
             cnt <= cnt + 1;
           end
           else begin
            cnt <= cnt;
           end
          end
         end
        wire full;
        reg a;
        reg start_wr_d;
        assign rx_ready_in = ~full;
        wire [15:0]wr_data;
          reg [15:0]rd_data_in;
        assign wr_data = a?{rd_data_in[7:0],rd_data_in[15:8]}:{data_in};
      
        fifo_tbtest fifo(
                .wr_clk_i(clk), 
                .rd_clk_i(clk), 
                .rst_i(~rst_n), 
                .rp_rst_i(~rst_n), 
                .wr_en_i(data_valid), 
                .rd_en_i(start_wr), 
                .wr_data_i({wr_data}), 
                .full_o(), 
                .empty_o(), 
                .almost_full_o(full), 
                .rd_data_o(WrData_I)) ;
        
        always@(posedge clk or negedge rst_n)
         begin
          if(~rst_n) begin 
            start_wr_d <='d0;
          end
          else
          begin
            start_wr_d<=#1 start_wr;
          end
        end
        
         wire SCK_O;
        wire MOSI_O;
        wire CS_O;
        SPI_Master#
        (
        	.CLK_FREQ(41),			/* 模块时钟输入，单位为MHz */
        	.SPI_CLK (8000),		    /* SPI时钟频率，单位为KHz */
        	.CPOL (0),				/* SPI时钟极性控制 */
        	.CPHA (0)				/* SPI时钟相位控制 */
        ) spitest				
        (				
        	.Clk_I(clk),			/* 模块时钟输入，应和CLK_FREQ一样 */
        	.RstP_I(~rst_n),			
        					
        	.WrRdReq_I(start_wr_d),		/* 读/写数据请求 */	
        	.WrRdReqAck_O(WrRdReqAck_O),
        	.WrRdFinish_O(WrRdFinish_O),
        	.WrRdDataBits_I(8),
        	.WrData_I(WrData_I),		    /* 要写入的数据 */
        	.RdData_O(),		    /* 读取到的数据 */
        					
        	.SCK_O(SCK_O),			/* SPI模块时钟输出 */
        	.MOSI_O(MOSI_O),			/* MOSI_O */
        	.MISO_I(MOSI_O),			/* MISO_I  */
        	.CS_O(CS_O)
        );
        
        reg [10:0]data_cnt;
        wire [10:0]data_cnt0;
        always@(posedge clk or negedge rst_n)
         begin
            if(~rst_n) begin 
            data_cnt <='d0;
          end
          else if(start_wr)begin
            data_cnt <=data_cnt + 'd1;
          end
          else begin data_cnt <=data_cnt; end
         end
        
        always@(*)
         begin
          case(cnt)
          /*
        'd1: begin data_in<= 16'hB79E        ;end 
        'd2: begin data_in<= 16'h0000        ;end 
        'd3: begin data_in<= 0        ;end 
        'd4: begin data_in<= 16'h9B5D        ;end 
        'd5: begin data_in<= 'd08        ;end 
        'd6: begin data_in<= 5        ;end 
        'd7: begin data_in<= 0        ;end 
        'd8: begin data_in<= 0        ;end 
        'd9: begin data_in<= 4        ;end 
        'd10: begin data_in<= 0        ;end 
        'd11: begin data_in<=  0       ;end 
        'd12: begin data_in<= 6       ;end 
        'd13: begin data_in<=  0       ;end 
        'd14: begin data_in<= 0        ;end 
        'd15: begin data_in<= 0        ;end 
        'd16: begin data_in<= 0        ;end 
        'd17: begin data_in<= 0        ;end 
        'd18: begin data_in<= 0        ;end 
        'd19: begin data_in<= 0        ;end 
        'd20: begin data_in<= 0        ;end 
        'd21: begin data_in<= 0        ;end 
        'd22: begin data_in<= 0        ;end 
        'd23: begin data_in<= 9        ;end 
        'd24: begin data_in<=  0       ;end 
        'd25: begin data_in<=  1       ;end 
        'd26: begin data_in<=  0       ;end 
        'd27: begin data_in<=  0       ;end 
        'd28: begin data_in<=  0       ;end 
        'd29: begin data_in<=  0       ;end 
        'd30: begin data_in<=  0       ;end 
        'd31: begin data_in<=  0       ;end 
        'd32: begin data_in<=  0       ;end 
        'd33: begin data_in<=  0       ;end 
        'd34: begin data_in<=  0       ;end 
        'd35: begin data_in<=  0       ;end 
        'd36: begin data_in<=  0       ;end 
        'd37: begin data_in<=  0       ;end 
        'd38: begin data_in<=  16'hE5C7        ;end 
        'd39: begin data_in<=  16'h4100       ;end 
        'd40: begin data_in<=  0       ;end 
        'd41: begin data_in<=  0       ;end 
        'd42: begin data_in<=  0       ;end 
        'd43: begin data_in<=  0       ;end 
        'd44: begin data_in<=  0       ;end 
        'd45: begin data_in<=  0       ;end 
        'd46: begin data_in<=  0       ;end 
        'd47: begin data_in<=  0       ;end 
        'd48: begin data_in<=  0       ;end 
        'd49: begin data_in<=  0       ;end 
        
        
        
        'd100: begin data_in<=  16'hB79E       ;end 
        */
        'd1: begin data_in<= 16'hB79E        ;end 
        'd2: begin data_in<= 16'h0000        ;end 
        'd3: begin data_in<= 0        ;end 
        'd4: begin data_in<= 16'h9B5D        ;end 
        'd5: begin data_in<= 'd02        ;end 
        'd6: begin data_in<= 16'h0080        ;end 
        'd7: begin data_in<= 0        ;end 
        'd8: begin data_in<= 16'h1c19        ;end 
        'd9: begin data_in<= 0        ;end 
        'd10: begin data_in<= 16'h0001         ;end 
        'd11: begin data_in<=  16'h0002       ;end 
        'd12: begin data_in<= 16'hff00       ;end 
        'd13: begin data_in<=  0       ;end 
        'd14: begin data_in<= 0        ;end 
        'd15: begin data_in<= 16'h1000       ;end 
        'd16: begin data_in<= 16'h007f        ;end 
        'd17: begin data_in<= 16'h007f        ;end 
        'd18: begin data_in<= 16'h007f        ;end 
        'd19: begin data_in<= 0        ;end 
        'd20: begin data_in<= 0        ;end 
        'd21: begin data_in<= 0        ;end 
        'd22: begin data_in<= 0        ;end 
        'd23: begin data_in<= 16'h3000        ;end 
        'd24: begin data_in<= 16'h7000       ;end 
        'd25: begin data_in<= 16'h0001       ;end 
        'd26: begin data_in<=  0       ;end 
        'd27: begin data_in<=  0       ;end 
        'd28: begin data_in<=  16'he5c7       ;end 
        'd29: begin data_in<=  16'h1205      ;end 
        'd30: begin data_in<=  16'he5c7       ;end 
        'd31: begin data_in<=  16'hFF07       ;end 
        'd32: begin data_in<=  16'he5c7       ;end 
        'd33: begin data_in<=  16'h0008       ;end 
        'd34: begin data_in<=  16'he5c7        ;end 
        'd35: begin data_in<=  16'h0008        ;end 
        'd36: begin data_in<=  16'he5c7        ;end 
        'd37: begin data_in<=  16'h0009        ;end 
        // 'd38: begin data_in<=  16'hE5C7        ;end //开始工作
        // 'd39: begin data_in<=  16'h0041       ;end 
        'd40: begin data_in<=  0       ;end 
        'd41: begin data_in<=  0       ;end 
        'd42: begin data_in<=  16'he5c7       ;end 
        'd43: begin data_in<=  16'h7f47       ;end 
        'd44: begin data_in<=  0       ;end 
        'd45: begin data_in<=  0       ;end 
        'd46: begin data_in<=  0       ;end 
        'd47: begin data_in<=  0       ;end 
        'd48: begin data_in<=  0       ;end 
        'd49: begin data_in<=  0       ;end 


        'd50: begin data_in<=  16'hE5C7       ;end 
        'd51: begin data_in<=  16'h0048       ;end ///////////////////
   //'d51: begin data_in<=  16'h0       ;end 

'd52: begin data_in<=  16'hE5C7 ;end 
'd53: begin data_in<=  16'h0100 ;end
'd54: begin data_in<=  16'hE5C7 ;end 
'd55: begin data_in<=  16'h0200 ;end
'd56: begin data_in<=  16'hE5C7 ;end 
'd57: begin data_in<=  16'h0300 ;end
'd58: begin data_in<=  16'hE5C7 ;end 
'd59: begin data_in<=  16'h0300 ;end
'd60: begin data_in<=  16'hE5C7 ;end 
'd61: begin data_in<=  16'h0300 ;end
'd62: begin data_in<=  16'hE5C7 ;end 
'd63: begin data_in<=  16'h0300 ;end
'd64: begin data_in<=  16'hE5C7 ;end 
'd65: begin data_in<=  16'h0300 ;end
'd66: begin data_in<=  16'hE5C7 ;end 
'd67: begin data_in<=  16'h0300 ;end
'd68: begin data_in<=  16'hE5C7 ;end 
'd69: begin data_in<=  16'h0300 ;end
'd70: begin data_in<=  16'hE5C7 ;end 
'd71: begin data_in<=  16'h0300 ;end
'd72: begin data_in<=  16'hE5C7 ;end 
'd73: begin data_in<=  16'h0300 ;end
'd74: begin data_in<=  16'hE5C7 ;end 
'd75: begin data_in<=  16'h0300 ;end
'd76: begin data_in<=  16'hE5C7 ;end 
'd77: begin data_in<=  16'h0300 ;end
'd78: begin data_in<=  16'hE5C7 ;end 
'd79: begin data_in<=  16'h0300 ;end
'd80: begin data_in<=  16'hE5C7 ;end 
'd81: begin data_in<=  16'h0300 ;end
'd82: begin data_in<=  16'hE5C7 ;end 
'd83: begin data_in<=  16'h0300 ;end
'd84: begin data_in<=  16'hE5C7 ;end 
'd85: begin data_in<=  16'h0300;end
'd86: begin data_in<=  16'hE5C7 ;end 
'd87: begin data_in<=  16'h0300 ;end
'd88: begin data_in<=  16'hE5C7 ;end 
'd89: begin data_in<=  16'h0300 ;end
'd90: begin data_in<=  16'hE5C7 ;end 
'd91: begin data_in<=  16'h0300 ;end
'd92: begin data_in<=  16'hE5C7 ;end 
'd93: begin data_in<=  16'h0300 ;end
'd94: begin data_in<=  16'hE5C7 ;end 
'd95: begin data_in<=  16'h0300 ;end
'd96: begin data_in<=  16'hE5C7 ;end 
'd97: begin data_in<=  16'h0300 ;end
'd98: begin data_in<=  16'hE5C7 ;end 
'd99: begin data_in<=  16'h0300 ;end
'd100: begin data_in<=  16'hE5C7 ;end 
'd101: begin data_in<=  16'h0300 ;end
'd102: begin data_in<=  16'hE5C7 ;end 
'd103: begin data_in<=  16'h0300 ;end
'd104: begin data_in<=  16'hE5C7 ;end 
'd105: begin data_in<=  16'h0300 ;end
'd106: begin data_in<=  16'hE5C7 ;end 
'd107: begin data_in<=  16'h0300 ;end
'd108: begin data_in<=  16'hE5C7 ;end 
'd109: begin data_in<=  16'h0300 ;end
'd110: begin data_in<=  16'hE5C7 ;end 
'd111: begin data_in<=  16'h0300 ;end
'd112: begin data_in<=  16'hE5C7 ;end 
'd113: begin data_in<=  16'h0300 ;end
'd114: begin data_in<=  16'hE5C7 ;end 
'd115: begin data_in<=  16'h0300 ;end
'd116: begin data_in<=  16'hE5C7 ;end 
'd117: begin data_in<=  16'h0300 ;end
'd118: begin data_in<=  16'hE5C7 ;end 
'd119: begin data_in<=  16'h0300 ;end
'd120: begin data_in<=  16'hE5C7 ;end 
'd121: begin data_in<=  16'h0300 ;end
'd122: begin data_in<=  16'hE5C7 ;end 
'd123: begin data_in<=  16'h0300 ;end
'd124: begin data_in<=  16'hE5C7 ;end 
'd125: begin data_in<=  16'h0300 ;end
'd126: begin data_in<=  16'hE5C7 ;end 
'd127: begin data_in<=  16'h0300 ;end
'd128: begin data_in<=  16'hE5C7 ;end 
'd129: begin data_in<=  16'h0300 ;end
'd130: begin data_in<=  16'hE5C7 ;end 
'd131: begin data_in<=  16'h0300 ;end
'd132: begin data_in<=  16'hE5C7 ;end 
'd133: begin data_in<=  16'h0300 ;end
'd134: begin data_in<=  16'hE5C7 ;end 
'd135: begin data_in<=  16'h0300 ;end
'd136: begin data_in<=  16'hE5C7 ;end 
'd137: begin data_in<=  16'h0300 ;end
'd138: begin data_in<=  16'hE5C7 ;end 
'd139: begin data_in<=  16'h0300 ;end
'd140: begin data_in<=  16'hE5C7 ;end 
'd141: begin data_in<=  16'h0300 ;end
'd142: begin data_in<=  16'hE5C7 ;end 
'd143: begin data_in<=  16'h0300 ;end
'd144: begin data_in<=  16'hE5C7 ;end 
'd145: begin data_in<=  16'h0300 ;end
'd146: begin data_in<=  16'hE5C7 ;end 
'd147: begin data_in<=  16'h0300 ;end
'd148: begin data_in<=  16'hE5C7 ;end 
'd149: begin data_in<=  16'h0300 ;end
'd150: begin data_in<=  16'hE5C7 ;end 
'd151: begin data_in<=  16'h0300 ;end
'd152: begin data_in<=  16'hE5C7 ;end 
'd153: begin data_in<=  16'h0300 ;end
'd154: begin data_in<=  16'hE5C7 ;end 
'd155: begin data_in<=  16'h0300 ;end
'd156: begin data_in<=  16'hE5C7 ;end 
'd157: begin data_in<=  16'h0300 ;end
'd158: begin data_in<=  16'hE5C7 ;end 
'd159: begin data_in<=  16'h0300 ;end
'd160: begin data_in<=  16'hE5C7 ;end 
'd161: begin data_in<=  16'h0300 ;end
'd162: begin data_in<=  16'hE5C7 ;end 
'd163: begin data_in<=  16'h0300 ;end
'd164: begin data_in<=  16'hE5C7 ;end 
'd165: begin data_in<=  16'h0300 ;end
'd166: begin data_in<=  16'hE5C7 ;end 
'd167: begin data_in<=  16'h0300 ;end
'd168: begin data_in<=  16'hE5C7 ;end 
'd169: begin data_in<=  16'h0300;end
'd170: begin data_in<=  16'hE5C7 ;end 
'd171: begin data_in<=  16'h0300 ;end
'd172: begin data_in<=  16'hE5C7 ;end 
'd173: begin data_in<=  16'h0300 ;end
'd174: begin data_in<=  16'hE5C7 ;end 
'd175: begin data_in<=  16'h0300 ;end
'd176: begin data_in<=  16'hE5C7 ;end 
'd177: begin data_in<=  16'h0300 ;end
'd178: begin data_in<=  16'hE5C7 ;end 
'd179: begin data_in<=  16'h0300 ;end

  'd180: begin data_in<=  16'hE5C7 ;end 
  'd181: begin data_in<=  16'h0300 ;end
  'd182: begin data_in<=  16'hE5C7 ;end 
  'd183: begin data_in<=  16'h0300 ;end
  'd184: begin data_in<=  16'hE5C7 ;end 
  'd185: begin data_in<=  16'h0300 ;end
  'd186: begin data_in<=  16'hE5C7 ;end 
  'd187: begin data_in<=  16'h0300 ;end
  'd188: begin data_in<=  16'hE5C7 ;end 
  'd189: begin data_in<=  16'h0300 ;end
  'd190: begin data_in<=  16'hE5C7 ;end 
  'd191: begin data_in<=  16'h0300 ;end
  'd192: begin data_in<=  16'hE5C7 ;end 
  'd193: begin data_in<=  16'h0300 ;end
  'd194: begin data_in<=  16'hE5C7 ;end 
  'd195: begin data_in<=  16'h0300 ;end
  'd196: begin data_in<=  16'hE5C7 ;end 
  'd197: begin data_in<=  16'h0300 ;end
  'd198: begin data_in<=  16'hE5C7 ;end 
  'd199: begin data_in<=  16'h0300 ;end
  'd200: begin data_in<=  16'hE5C7 ;end 
  'd201: begin data_in<=  16'h0300 ;end
  'd202: begin data_in<=  16'hE5C7 ;end 
  'd203: begin data_in<=  16'h0300 ;end
  'd204: begin data_in<=  16'hE5C7 ;end 
  'd205: begin data_in<=  16'h0300 ;end
  'd206: begin data_in<=  16'hE5C7 ;end 
  'd207: begin data_in<=  16'h0300 ;end
  'd208: begin data_in<=  16'hE5C7 ;end 
  'd209: begin data_in<=  16'h0300 ;end
  'd210: begin data_in<=  16'hE5C7 ;end 
  'd211: begin data_in<=  16'h0300 ;end
  'd212: begin data_in<=  16'hE5C7 ;end 
  'd213: begin data_in<=  16'h0300 ;end
  'd214: begin data_in<=  16'hE5C7 ;end 
  'd215: begin data_in<=  16'h0300 ;end
  'd216: begin data_in<=  16'hE5C7 ;end 
  'd217: begin data_in<=  16'h0300 ;end
  'd218: begin data_in<=  16'hE5C7 ;end 
  'd219: begin data_in<=  16'h0300 ;end
  'd220: begin data_in<=  16'hE5C7 ;end 
  'd221: begin data_in<=  16'h0300 ;end
  'd222: begin data_in<=  16'hE5C7 ;end 
  'd223: begin data_in<=  16'h0300 ;end
  'd224: begin data_in<=  16'hE5C7 ;end 
  'd225: begin data_in<=  16'h0300 ;end
  'd226: begin data_in<=  16'hE5C7 ;end 
  'd227: begin data_in<=  16'h0300 ;end
  'd228: begin data_in<=  16'hE5C7 ;end 
  'd229: begin data_in<=  16'h0300 ;end
  'd230: begin data_in<=  16'hE5C7 ;end 
  'd231: begin data_in<=  16'h0300 ;end
  'd232: begin data_in<=  16'hE5C7 ;end 
  'd233: begin data_in<=  16'h0300 ;end
  'd234: begin data_in<=  16'hE5C7 ;end 
  'd235: begin data_in<=  16'h0300 ;end
  'd236: begin data_in<=  16'hE5C7 ;end 
  'd237: begin data_in<=  16'h0300 ;end
  'd238: begin data_in<=  16'hE5C7 ;end 
  'd239: begin data_in<=  16'h0300 ;end
  'd240: begin data_in<=  16'hE5C7 ;end 
  'd241: begin data_in<=  16'h0300 ;end
  'd242: begin data_in<=  16'hE5C7 ;end 
  'd243: begin data_in<=  16'h0300 ;end
  'd244: begin data_in<=  16'hE5C7 ;end 
  'd245: begin data_in<=  16'h0300 ;end
  'd246: begin data_in<=  16'hE5C7 ;end 
  'd247: begin data_in<=  16'h0300 ;end
  'd248: begin data_in<=  16'hE5C7 ;end 
  'd249: begin data_in<=  16'h0300 ;end
  'd250: begin data_in<=  16'hE5C7 ;end 
  'd251: begin data_in<=  16'h0300 ;end
  'd252: begin data_in<=  16'hE5C7 ;end 
  'd253: begin data_in<=  16'h0300 ;end
  'd254: begin data_in<=  16'hE5C7 ;end 
  'd255: begin data_in<=  16'h0300 ;end
  'd256: begin data_in<=  16'hE5C7 ;end 
  'd257: begin data_in<=  16'h0300 ;end
  'd258: begin data_in<=  16'hE5C7 ;end 
  'd259: begin data_in<=  16'h0300 ;end
  'd260: begin data_in<=  16'hE5C7 ;end 
  'd261: begin data_in<=  16'h0300 ;end
  'd262: begin data_in<=  16'hE5C7 ;end 
  'd263: begin data_in<=  16'h0300 ;end
  'd264: begin data_in<=  16'hE5C7 ;end 
  'd265: begin data_in<=  16'h0300 ;end
  'd266: begin data_in<=  16'hE5C7 ;end 
  'd267: begin data_in<=  16'h0300 ;end
  'd268: begin data_in<=  16'hE5C7 ;end 
  'd269: begin data_in<=  16'h0300 ;end
  'd270: begin data_in<=  16'hE5C7 ;end 
  'd271: begin data_in<=  16'h0300 ;end
  'd272: begin data_in<=  16'hE5C7 ;end 
  'd273: begin data_in<=  16'h0300 ;end
  'd274: begin data_in<=  16'hE5C7 ;end 
  'd275: begin data_in<=  16'h0300 ;end
  'd276: begin data_in<=  16'hE5C7 ;end 
  'd277: begin data_in<=  16'h0300 ;end
  'd278: begin data_in<=  16'hE5C7 ;end 
  'd279: begin data_in<=  16'h0300 ;end
  'd280: begin data_in<=  16'hE5C7 ;end 
  'd281: begin data_in<=  16'h0300 ;end
  'd282: begin data_in<=  16'hE5C7 ;end 
  'd283: begin data_in<=  16'h0300 ;end
  'd284: begin data_in<=  16'hE5C7 ;end 
  'd285: begin data_in<=  16'h0300 ;end
  'd286: begin data_in<=  16'hE5C7 ;end 
  'd287: begin data_in<=  16'h0300 ;end
  'd288: begin data_in<=  16'hE5C7 ;end 
  'd289: begin data_in<=  16'h0300 ;end
  'd290: begin data_in<=  16'hE5C7 ;end 
  'd291: begin data_in<=  16'h0300 ;end
  'd292: begin data_in<=  16'hE5C7 ;end 
  'd293: begin data_in<=  16'h0300 ;end
  'd294: begin data_in<=  16'hE5C7 ;end 
  'd295: begin data_in<=  16'h0300 ;end
  'd296: begin data_in<=  16'hE5C7 ;end 
  'd297: begin data_in<=  16'h0300 ;end
  'd298: begin data_in<=  16'hE5C7 ;end 
  'd299: begin data_in<=  16'h0300 ;end
  'd300: begin data_in<=  16'hE5C7 ;end 
  'd301: begin data_in<=  16'h0300 ;end
  'd302: begin data_in<=  16'hE5C7 ;end 
  'd303: begin data_in<=  16'h0300 ;end
  'd304: begin data_in<=  16'hE5C7 ;end 
  'd305: begin data_in<=  16'h0300 ;end
  'd306: begin data_in<=  16'hE5C7 ;end 
  'd307: begin data_in<=  16'h0300 ;end
  'd308: begin data_in<=  16'hE5C7 ;end 
  'd309: begin data_in<=  16'h0300 ;end
'd310: begin data_in<=  0 ;end
'd311: begin data_in<=  0 ;end
// 'd182: begin data_in<=  16'hE5C7 ;end//计算阈值
// 'd183: begin data_in<=  16'h0049  ;end  
        //'d50: begin data_in<=  16'hB79E       ;end 
        //'d51: begin data_in<=  16'h0       ;end 
'd354: begin data_in<=  16'hE5C7 ;end//计算阈值
//'d355: begin data_in<=  16'h0349  ;end
// 'd356: begin data_in<=  16'hE5C7 ;end//计算阈值
// 'd357: begin data_in<=  16'h0150  ;end
        'd800: begin data_in<=  16'hc691       ;end 

        'd1101: begin data_in<= 16'h0        ;end 
        'd1102: begin data_in<= 16'h0000        ;end 
        'd1103: begin data_in<= 0        ;end 
        'd404: begin data_in<= 16'h9B5D        ;end 
        'd405: begin data_in<= 'd00        ;end 
        'd406: begin data_in<= 16'h0009        ;end 
        'd407: begin data_in<= 0        ;end 
        'd408: begin data_in<= 16'h1c19        ;end 
        'd409: begin data_in<= 0        ;end 
        'd410: begin data_in<= 16'h007f         ;end 
        'd411: begin data_in<=  16'h0002       ;end 
        'd412: begin data_in<= 16'hff00       ;end 
        'd413: begin data_in<=  0       ;end 
        'd414: begin data_in<= 0        ;end 
        'd415: begin data_in<= 16'h1000       ;end 
        'd416: begin data_in<= 16'h007f        ;end 
        'd417: begin data_in<= 16'h007f        ;end 
        'd418: begin data_in<= 16'h007f        ;end 
        'd419: begin data_in<= 0        ;end 
        'd420: begin data_in<= 0        ;end 
        'd421: begin data_in<= 0        ;end 
        'd422: begin data_in<= 0        ;end 
        'd423: begin data_in<= 16'h3000        ;end 
        'd424: begin data_in<=  16'h7000       ;end 
        'd425: begin data_in<=  16'h0080       ;end 
        'd426: begin data_in<=  0       ;end 
        'd427: begin data_in<=  0       ;end 
        'd428: begin data_in<=  0       ;end 
        'd429: begin data_in<=  0       ;end 
        'd430: begin data_in<=  0       ;end 
        'd431: begin data_in<=  0       ;end 
        'd432: begin data_in<=  0       ;end 
        'd433: begin data_in<=  0       ;end 
        'd434: begin data_in<=  0       ;end 
        'd435: begin data_in<=  16'h8000       ;end 
        'd436: begin data_in<=  1       ;end 
        'd437: begin data_in<=  0       ;end 
        'd438: begin data_in<=  16'hC7E5        ;end 
        'd439: begin data_in<=  16'h0041       ;end 
        'd440: begin data_in<=  0       ;end 
        'd441: begin data_in<=  0       ;end 
        'd442: begin data_in<=  0       ;end 
        'd443: begin data_in<=  0       ;end 
        'd444: begin data_in<=  0       ;end 
        'd445: begin data_in<=  0       ;end 
        'd446: begin data_in<=  0       ;end 
        'd447: begin data_in<=  0       ;end 
        'd448: begin data_in<=  0       ;end 
        'd449: begin data_in<=  0       ;end 

        'd502: begin data_in<=  16'hE5C7       ;end 
        //'d503: begin data_in<=  16'h0052       ;end ///////////////////
        'd504: begin data_in<= 16'h9B5D        ;end 
        'd505: begin data_in<= 'd00        ;end 
        'd506: begin data_in<= 16'h0009        ;end 
        'd507: begin data_in<= 0        ;end 
        'd508: begin data_in<= 16'h1c19        ;end 
        'd509: begin data_in<= 0        ;end 
        'd510: begin data_in<= 16'h007f         ;end 
        'd511: begin data_in<=  16'h0002       ;end 
        'd512: begin data_in<= 16'hff00       ;end 
        'd513: begin data_in<=  0       ;end 
        'd514: begin data_in<= 0        ;end 
        'd515: begin data_in<= 16'h1000       ;end 
        'd516: begin data_in<= 16'h007f        ;end 
        'd517: begin data_in<= 16'h007f        ;end 
        'd518: begin data_in<= 16'h007f        ;end 
        'd519: begin data_in<= 0        ;end 
        'd520: begin data_in<= 0        ;end 
        'd521: begin data_in<= 0        ;end 
        'd522: begin data_in<= 0        ;end 
        'd523: begin data_in<= 16'h3000        ;end 
        'd524: begin data_in<=  16'h7000       ;end 
        'd525: begin data_in<=  16'h0080       ;end 
        'd526: begin data_in<=  0       ;end 
        'd527: begin data_in<=  0       ;end 
        'd528: begin data_in<=  0       ;end 
        'd529: begin data_in<=  0       ;end 
        'd530: begin data_in<=  0       ;end 
        'd531: begin data_in<=  0       ;end 
        'd532: begin data_in<=  0       ;end 
        'd533: begin data_in<=  0       ;end 
        'd534: begin data_in<=  0       ;end 
        'd535: begin data_in<=  16'h8000       ;end 
        'd536: begin data_in<=  1       ;end 
        'd537: begin data_in<=  0       ;end 
        'd538: begin data_in<=  16'hC7E5        ;end 
        'd539: begin data_in<=  16'h0041       ;end 
        'd540: begin data_in<=  0       ;end 
        'd541: begin data_in<=  0       ;end 
        'd542: begin data_in<=  0       ;end 
        'd543: begin data_in<=  0       ;end 
        'd544: begin data_in<=  0       ;end 
        'd545: begin data_in<=  0       ;end 
        'd546: begin data_in<=  0       ;end 
        'd547: begin data_in<=  0       ;end 
        'd548: begin data_in<=  0       ;end 
        'd549: begin data_in<=  0       ;end 


            // 'd3704: begin data_in<= 16'h9B5D        ;end 
            // 'd3705: begin data_in<= 'd00        ;end 
            // 'd3706: begin data_in<= 16'h0009        ;end 
            // 'd3707: begin data_in<= 0        ;end 
            // 'd3708: begin data_in<= 16'h1c19        ;end 
            // 'd3709: begin data_in<= 0        ;end 
            // 'd3710: begin data_in<= 16'h007f         ;end 
            // 'd3711: begin data_in<=  16'h0002       ;end 
            // 'd3712: begin data_in<= 16'hff00       ;end 
            // 'd3713: begin data_in<=  0       ;end 
            // 'd3714: begin data_in<= 0        ;end 
            // 'd3715: begin data_in<= 16'h1000       ;end 
            // 'd3716: begin data_in<= 16'h007f        ;end 
            // 'd3717: begin data_in<= 16'h007f        ;end 
            // 'd3718: begin data_in<= 16'h007f        ;end 
            // 'd3719: begin data_in<= 0        ;end 
            // 'd3720: begin data_in<= 0        ;end 
            // 'd3721: begin data_in<= 0        ;end 
            // 'd3722: begin data_in<= 0        ;end 
            // 'd3723: begin data_in<= 16'h3000        ;end 
            // 'd3724: begin data_in<=  16'h7000       ;end 
            // 'd3725: begin data_in<=  16'h0080       ;end 
            // 'd3726: begin data_in<=  0       ;end 
            // 'd3727: begin data_in<=  0       ;end 
            // 'd3728: begin data_in<=  0       ;end 
            // 'd3729: begin data_in<=  0       ;end 
            // 'd3730: begin data_in<=  0       ;end 
            // 'd3731: begin data_in<=  0       ;end 
            // 'd3732: begin data_in<=  0       ;end 
            // 'd3733: begin data_in<=  0       ;end 
            // 'd3734: begin data_in<=  0       ;end 
            // 'd3735: begin data_in<=  16'h8000       ;end 
            // 'd3736: begin data_in<=  1       ;end 
            // 'd3737: begin data_in<=  0       ;end 
            // 'd3738: begin data_in<=  16'hC7E5        ;end 
            // 'd3739: begin data_in<=  16'h0041       ;end 
            // 'd3740: begin data_in<=  0       ;end 
            // 'd3741: begin data_in<=  0       ;end 
            // 'd3742: begin data_in<=  0       ;end 
            // 'd3743: begin data_in<=  0       ;end 
            // 'd3744: begin data_in<=  0       ;end 
            // 'd3745: begin data_in<=  0       ;end 
            // 'd3746: begin data_in<=  0       ;end 
            // 'd3747: begin data_in<=  0       ;end 
            // 'd3748: begin data_in<=  0       ;end 
            // 'd3749: begin data_in<=  0       ;end      
        
          endcase
         end
        /*
        test_top uu_test_top(
        . clk(sys_clk),
        . rst(~rst_n),
        . data_valid0(data_valid),
        . usbrx_data(data_in),
        .rx_ready_in(rx_ready_in)
        );
        
        */
reg rd_data_test;

reg [31:0]cntrd;

always@(posedge clk)
 begin
   if(~rst_n)
    begin
     cntrd <= 'd0;
     rd_data_test <= 'd0;
     rd_data_in <= 'd0;
     a <= 'd0;
    end
    else if(cnt >='d840&&data_valid )
     begin 
      rd_data_test <= 'd1;
      a <= 'd1;
      if(cntrd<= 'd393)
       begin 
        cntrd <= cntrd + 'd1;
        rd_data_in <= 'd0;
       end
       else 
        begin 
         cntrd <= 0;
         rd_data_in <= 'hC691;
        end
     end
     else begin 
         cntrd <= cntrd;
         rd_data_in <= rd_data_in;
          a <= a;
     end
 end








        reg [30:0]MOSI_in;
        reg [30:0]sck_in;
        
wire test_valid	;
wire [15:0]test_data;

reg [31:0]cnta;
      wire [5:0]channel;
      always@(posedge clk)
       begin
        if(~rst_n)
         begin
          cnta <= 'd0;
         end
        else if(test_valid)
         begin
          if(cnta < 35*1024-1)
          cnta <= cnta + 'd1;
          else 
          cnta <= 0;
         end
       end
assign test_data = bl_test_data[cnta];


        always@(posedge clk or negedge rst_n)
         begin
            if(~rst_n) begin 
            MOSI_in <='d0;
        	sck_in <='d0;
          end
        
          else begin     
        	MOSI_in <={MOSI_in[29:0],MOSI_O};
        	sck_in <={sck_in[29:0],SCK_O}; end
         end 
         wire CS,SCLK;
         reg MISO1 = 0;
        fpga_top_example_ft232h 
        #(
          .debug(1),
          .CLK_CHOSE(1),
          .RST_TIME(32'd100),
          .LENGTH(1024))
        uu(
        .clk_in(clk),   // main clock, connect to on-board crystal oscillator
        
        .CS(CS),
        .SCLK(SCLK),
.rst_i_n(1),
        .MISO1(MISO1),
        .MISO2(MISO1),
        
        //.rst_n(1),
        .SCK_I  (spi_clk),//(SCK_O),// (sck_in[15]),
        .MOSI_I (spi_mosi),//(MOSI_O),// (MOSI_in[5]),
        .CS_I   (spi_cs),//(CS_O),
        .MISO_O()
        ////
      //  .test_valid(test_valid)	,
       // .test_data (test_data)
        	///
        );
//        wire [9:0]win_cnt1;
//       pmi_counter
//#(
//  .pmi_data_width   (10 ), // integer
//  .pmi_updown       ("up" ), // "up"|"down"|"updown"
//  .pmi_family       ("common" )  // "iCE40UP" | "common"
//) win_cnt_counter (
//  .Clock    (clk ),  // I:
//  .Clk_En   (1 ),  // I:
//  .Aclr    (~rst_n),// (stop_34&&raw_data_valid ),  // I:
//  .UpDown   (1 ),  // I:
//  .Q        (win_cnt1 )   // O:
//);
wire [31:0]win_cnt1;

add_48 add_48inst(
 .clk_i(clk), 
 .rst_i(rst), 
 .add_sub_i(), 
 .data_a_re_i(), 
 .data_b_re_i(), 
 .result_re_o()) ;     

wire spi2_miso_io;
wire spi2_mosi_io;
wire spi2_sck_io;
//wire ipload_i;
wire ipdone_o;
wire [7:0]data0;
wire clkx;
wire clk_spi;

 
reg clk_d;
reg [10:0]CNT,CNT_D;
        always@(posedge sys_clk)
         begin
          if(~rst_n)
           begin
            clk_d <= 'd0;
            CNT_D <= 'd0;
           end
           else 
            begin
              clk_d <=#1 SCLK;
              CNT_D <=#1 CNT;
            end
         end
reg [10:0]state;
reg [15:0]data_mosi;
always@(posedge sys_clk )
 begin 
  if(~rst_n) begin state<='d0; CNT <= 'd0;data_mosi <= 0; end
  else begin
    case(state)
     'd0:begin
      data_mosi <= data_mosi;
       if(~CS) begin state<='d1; CNT <= 'd0; end
       else    begin state<='d0; CNT <= 'd0; end
      end
     'd1:begin
      data_mosi <= data_mosi;
       if(~clk_d&&SCLK) begin CNT <=(CNT>='d15) ? 0:  CNT + 'd1; state<=(CNT>='d15) ? 'd2:'d1;     end
       else             begin CNT <= CNT;  state<='d1;    end
      end
     'd2:begin
      state<='d0;
      CNT  <= 'd0;
      data_mosi <= data_mosi + 'd1;
      end 
    endcase
   end
 end

always@(*)
begin 
case(CNT_D)
 'd0 :begin  MISO1 = 0;end//data_mosi[15]; end
 'd1 :begin  MISO1 = 0;end//data_mosi[14]; end
 'd2 :begin  MISO1 = 0;end//data_mosi[13]; end
 'd3 :begin  MISO1 = 1;end//data_mosi[12]; end
 'd4 :begin  MISO1 = 0;end//data_mosi[11]; end 
 'd5 :begin  MISO1 = 0;end//data_mosi[10]; end
 'd6 :begin  MISO1 = 1;end//data_mosi[9]; end
 'd7 :begin  MISO1 = 0;end//data_mosi[8]; end
 'd8 :begin  MISO1 = 0;end//data_mosi[7]; end
 'd9 :begin  MISO1 = 0;end//data_mosi[6]; end  
 'd10:begin  MISO1 = 0 ;end// data_mosi[5]; end
 'd11:begin  MISO1 = 0 ;end// data_mosi[4]; end
 'd12:begin  MISO1 = 0 ;end// data_mosi[3]; end
 'd13:begin  MISO1 = 0 ;end// data_mosi[2]; end
 'd14:begin  MISO1 = 1 ;end// data_mosi[1]; end   
 'd15:begin  MISO1 = 0 ;end// data_mosi[0]; end 
endcase
end


reg [7:0]data_in0 = 'd0;
reg [10:0]datac;
wire data_in0_v;
assign data_in0_v = cnt0[0];
always@(*) 
begin 
  case(datac[1:0])
   'd0:begin data_in0 =  'h91; end 
   'd1:begin data_in0 =  'hc6; end
   'd2:begin data_in0 =  'h00; end
   'd3:begin data_in0 =  'h48; end
  endcase

end
always@(posedge sys_clk) begin 
  if(~rst_n)  begin datac<= 'd0; end
  else        begin if(data_in0_v) begin datac<= datac + 'd1; end
                    else begin datac<= datac;end
  end
end


data_rec_config data_rec_config_inst(
    .clk        (sys_clk),
    .rstn       (rst_n),
    .data_in_v  (data_in0_v),
    .data_in    (data_in0),
    .data_out_v (),
    .data_out   ()
);

// SPI Master 模拟任务
// 每次调用会发送 388 字节 (3104 bit) 时序
// clk_ref = 41MHz, SCLK = 8MHz (分频约5.125，这里用5)
task spi_master_read_388;
    output reg [3104*8-1:0] rdata;  // 接收数据
    reg [15:0] tx_word;
    integer i, j, k;
    integer sclk_half;   // 分频因子的一半
    
    begin
        tx_word = 16'h91C6;
        sclk_half = 5;  // 大约 2.5，用2或3来近似实现
        
        // 初始化
        rdata = 0;
        spi_cs   = 1'b1;
        spi_clk  = 1'b0;
        spi_mosi = 1'b0;
        #100;   // 预留一段空闲
        
        // 拉低 CS 开始传输
        spi_cs = 1'b0;
        #100;
        
        // 发送 388字节 = 3104 bit
        for (i = 0; i < 388; i = i + 1) begin
            for (j = 0; j < 8; j = j + 1) begin
                // 取 tx_word 中的 bit，循环发送
                spi_mosi = tx_word[(15 - ((i*8+j) % 16))];
                
                // 产生 SCLK 上升沿
                #(sclk_half*10);  // 用41MHz周期近似 (24ns)，自己可根据精度调整
                spi_clk = 1'b1;
                
                // 采样 MISO
                rdata[i*8 + j] = spi_miso;
                
                // 产生 SCLK 下降沿
                #(sclk_half*10);
                spi_clk = 1'b0;
            end
        end
        
        // 拉高 CS 结束
        spi_cs = 1'b1;
        #100;
    end
endtask











endmodule