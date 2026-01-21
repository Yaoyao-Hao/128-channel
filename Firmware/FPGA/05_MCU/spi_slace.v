
//极性特点：时钟空闲时为高电平
//在上升沿采样数据，获取MOSI的输入
//在下降沿发送数据,将数据发送到MISO
//sck的时钟要大大小于clk的时钟，至多为clk/8
module spi_slace(
				clk,
				rstn,
				cs,
				sck,
				MOSI,
				MISO,
				rxd_out_o,
				txd_data,
				rxd_flag, //接受数据脉冲信号 接受到一个数据会产生一个正脉冲信号
        send_finish,
        read_next_o,
        test_signal0,
        test_signal1
				);
input clk,cs,rstn,sck,MOSI;
output rxd_flag;
output reg MISO;
output reg[7:0] rxd_out_o;
output reg send_finish;
output wire read_next_o;
output wire test_signal0;
output test_signal1;

reg[7:0] rxd_data;
input [7:0] txd_data;
reg sck_r0,sck_r1,sck_r2;
wire sck_n,sck_p;
reg read_next;
reg [3:0]spi_sck;
reg[7:0] rxd_out = 'd0;
reg MOSI_D,MOSI_DD;
always @(posedge clk or negedge rstn)
begin
   if(!rstn)
    begin
	   sck_r0<=1'b1;
	   sck_r1<=1'b1;
	   sck_r2<=1'b1;
     spi_sck <= 4'b1111;
     MOSI_D<=  0; 
     MOSI_DD<= 0;
	end 
   else
    begin
	   sck_r0 <= sck;
	   sck_r1 <= sck_r0;
     sck_r2<=sck_r1;
     MOSI_D<=  MOSI; 
     MOSI_DD<= MOSI_D;
spi_sck <= {spi_sck[2:0],sck_r1};

	end
end
assign sck_n = (~sck_r0 & sck_r1)? 1'b1:1'b0;
//assign sck_n = (spi_sck[2:0]==3'b100)? 1'b1:1'b0; //(~sck_r0 & sck_r1)? 1'b1:1'b0; 
assign sck_p = (~sck_r1 & sck_r0)? 1'b1:1'b0;
//assign sck_p = (spi_sck[2:0]==3'b011)? 1'b1:1'b0;
//(spi_sck==4'b0111)?1'b1:1'b0;//
//-----------------------spi_slaver read data-------------------------------
reg rxd_flag_r;
reg [2:0] rxd_state;
always@(posedge clk or posedge cs)
begin
    if(cs)
        begin
            rxd_data <= 1'b0;
            rxd_flag_r <= 1'b0;
            rxd_state <= 1'b0;
            rxd_out   <= rxd_out;
           //test_signal0 <='d0;
        end
    else if(sck_p)// && !cs)   
        begin
         // if(sck_p) begin 
            case(rxd_state)
                3'd0:begin
                        //rxd_data[7] <= MOSI_DD;
                        rxd_flag_r <= 1'b0;   //reset rxd_flag
                        rxd_state <= 3'd1;
                        rxd_out   <= {rxd_out[6:0],MOSI_DD};
                       // test_signal0 <=MOSI_DD;
                      end
                3'd1:begin
                        //rxd_data[6] <= MOSI_DD;
                        rxd_state <= 3'd2;
                        rxd_out   <= {rxd_out[6:0],MOSI_DD};
                      //  test_signal0 <=MOSI_DD;
                      end
                3'd2:begin
                        //rxd_data[5] <= MOSI_DD;
                        rxd_state <= 3'd3;
                        rxd_out   <= {rxd_out[6:0],MOSI_DD};
                     //   test_signal0 <=MOSI_DD;
                      end
                3'd3:begin
                        //rxd_data[4] <= MOSI_DD;
                        rxd_state <= 3'd4;
                        rxd_out   <= {rxd_out[6:0],MOSI_DD};
                      //  test_signal0 <=MOSI_DD;
                      end
                3'd4:begin
                        //rxd_data[3] <= MOSI_DD;
                        rxd_state <= 3'd5;
                        rxd_out   <= {rxd_out[6:0],MOSI_DD};
                      //  test_signal0 <=MOSI_DD;
                      end
                3'd5:begin
                        //rxd_data[2] <= MOSI_DD;
                        rxd_state <= 3'd6;
                        rxd_out   <= {rxd_out[6:0],MOSI_DD};
                      //  test_signal0 <=MOSI_DD;
                      end
                3'd6:begin
                        //rxd_data[1] <= MOSI_DD;
                        rxd_state <= 3'd7;
                        rxd_out   <= {rxd_out[6:0],MOSI_DD};
                      //  test_signal0 <=MOSI_DD;
                      end
                3'd7:begin
                        rxd_out<={rxd_out[6:0],MOSI_DD};
                        //rxd_data[0] <= MOSI_DD;
                        rxd_flag_r <= 1'b1;  //set rxd_flag
                        rxd_state <= 3'd0;
                     //   test_signal0 <=MOSI_DD;
                      end
                default: begin 
                rxd_out<=rxd_out;
                rxd_data <= rxd_data;
                rxd_flag_r <= rxd_flag_r;  //set rxd_flag
                rxd_state <= rxd_state;
              //  test_signal0 <=test_signal0;
                end
            endcase end
            else begin 
              rxd_out<=rxd_out;
              rxd_data <= rxd_data;
              rxd_flag_r <= 0;  //set rxd_flag
              rxd_state <= rxd_state;
            //  test_signal0 <=test_signal0;
            end
end
//--------------------capture spi_flag posedge--------------------------------
reg rxd_flag_r0,rxd_flag_r1;
reg read_n_d,read_n_dd;
always@(posedge clk or negedge rstn)
begin
    if(!rstn)
        begin
            rxd_flag_r0 <= 1'b0;
            rxd_flag_r1 <= 1'b0;
            read_n_d    <= 'd0;
            read_n_dd   <= 'd0;
            rxd_out_o     <= 'd0;
        end
    else
        begin
            rxd_flag_r0 <= rxd_flag_r;
            rxd_flag_r1 <= rxd_flag_r0;
            read_n_d    <= read_next;
            read_n_dd   <= read_n_d;
            if(rxd_flag_r) begin 
              rxd_out_o <= rxd_out;
            end
            else begin
              rxd_out_o <= rxd_out_o;
             end
        end
end
assign rxd_flag = (~rxd_flag_r1 & rxd_flag_r0)? 1'b1:1'b0;   //下降沿采样
//---------------------spi_slaver send data---------------------------
reg [2:0] txd_state;
always@(posedge clk or posedge cs)//or negedge rstn)
begin
    if(cs)
        begin
            txd_state <= 3'd0;
            send_finish <= 'd0;
            read_next <='d0;
			 MISO<=1'b1;
        end
    else if(sck_n )
        begin
            case(txd_state)
                3'd0:begin
                        MISO <= txd_data[7];
                        txd_state <= 3'd1;
                        send_finish <= 'd0;
                        read_next <='d0;
                      end
                3'd1:begin
                        MISO <= txd_data[6];
                        txd_state <= 3'd2;
                        send_finish <= 'd0;
                        read_next <='d0;
                      end
                3'd2:begin
                        MISO <= txd_data[5];
                        txd_state <= 3'd3;
                        send_finish <= 'd0;
                        read_next <='d0;
                      end
                3'd3:begin
                        MISO <= txd_data[4];
                        txd_state <= 3'd4;
                        send_finish <= 'd0;
                        read_next <='d0;
                      end
                3'd4:begin
                        MISO <= txd_data[3];
                        txd_state <= 3'd5;
                        send_finish <= 'd0;
                        read_next <='d0;
                      end
                3'd5:begin
                        MISO <= txd_data[2];
                        txd_state <= 3'd6;
                        send_finish <= 'd0;
                        read_next <='d0;
                      end
                3'd6:begin
                        MISO <= txd_data[1];
                        txd_state <= 3'd7;
                        send_finish <= 'd0;
                        read_next <='d1;
                      end
                3'd7:begin
                        MISO <= txd_data[0];
                        txd_state <= 3'd0;
                        send_finish <= 'd1;
                        read_next <='d0;
                      end
                default: ;
            endcase

        end
        else begin send_finish <= 'd0;
          MISO <= MISO;
          txd_state <= txd_state;
          read_next <='d0;  end
end


// always@(*)//or negedge rstn)
// begin
//     if(cs)
//         begin
// 			 MISO<=1'bz;
//         end
//     else 
//             case(txd_state)
//                 3'd0:begin
//                         MISO <= txd_data[7];
//                       end
//                 3'd1:begin
//                         MISO <= txd_data[6];
//                       end
//                 3'd2:begin
//                         MISO <= txd_data[5];
//                       end
//                 3'd3:begin
//                         MISO <= txd_data[4];
//                       end
//                 3'd4:begin
//                         MISO <= txd_data[3];
//                       end
//                 3'd5:begin
//                         MISO <= txd_data[2];
//                       end
//                 3'd6:begin
//                         MISO <= txd_data[1];
//                       end
//                 3'd7:begin
//                         MISO <= txd_data[0];
//                       end
//                 default:
//                 MISO <= MISO ;
//             endcase

//         end

assign test_signal0 = rxd_out[0];
assign test_signal1 = sck_p;
assign read_next_o = read_next;
endmodule
