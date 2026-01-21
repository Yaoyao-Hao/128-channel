module SPI_config
#( parameter RAW_HEADER = 16'hC691,
   parameter SPIKE_HEADER = 16'h1999
 )
(
input clk ,
input rst ,

input [15:0]spi_data_in,
input data_in_valid,

input [9:0]raw_length,
//input [6:0]spike_length,
output reg [4:0]STATE,
//input se_fifo_rd,
input rd_en_raw0,
input rd_en_spike0,
output start_SPIKE,
output reg start_RAW,
input send_finish,
output reg valid_state_raw,
output reg valid_state_spike,
output reg state_spike,
output reg state_raw,
output reg test_signal,

input almost_full_raw,
input wire [12:0]rd_data_cnt_o,
input cal_busy,
output reg [9:0]length_cnt0,
output wire tra_overout

);

reg tra_over;



//reg [4:0]STATE;

reg [4:0]next_state;

//reg [6:0]length_cnt1;
localparam INIT = 0,
           RAW = 1,
           SPIKE = 2,
           FINISH =3;

always@(posedge clk or posedge rst)
 begin
    if(rst) begin 
      STATE <= INIT;
    end
    else begin
      STATE<= next_state;
    end
 end  
//assign start_RAW = (STATE!=RAW)&& (next_state==RAW);
//assign start_SPIKE = (STATE!=SPIKE)&& (next_state==SPIKE);
//reg valid_state;

always@(*)
 begin
  case (STATE)
    INIT: begin 
      tra_over = 0;
     if(spi_data_in == RAW_HEADER&&data_in_valid&&(rd_data_cnt_o>= 'd700)) begin next_state = RAW;start_RAW = 1; end
    //  if(data_in_valid&&(rd_data_cnt_o>= 'd350)) begin next_state = RAW;start_RAW = 1; end
    //if(spi_data_in == RAW_HEADER&&data_in_valid) begin next_state = RAW;start_RAW = 1; end
    // if(spi_data_in == SPIKE_HEADER&&data_in_valid) begin next_state = SPIKE; end
     else begin next_state = INIT;  start_RAW = 0;end
     valid_state_raw = 0;
     valid_state_spike =0;
     test_signal =0;
    end
    RAW: begin 
      tra_over = 0;
      start_RAW = 0;
     if(length_cnt0 >= raw_length&&send_finish) begin next_state = FINISH; valid_state_raw = 1;end
     else begin next_state = RAW; valid_state_raw =0;end
     test_signal =1;
     valid_state_spike =0;
     //x = 1;
     end
     
//   SPIKE: begin 
//    if(length_cnt1 >= spike_length&&send_finish) begin next_state = FINISH;valid_state_spike =1; end
//    else begin next_state = SPIKE; valid_state_spike =0;end
//    valid_state_raw = 0;
//    test_signal =0;
//    end
    FINISH: begin 
      start_RAW = 0;
      tra_over = 1;
        if(send_finish) begin next_state = INIT; end 
        else begin next_state = next_state; end
        test_signal =0;
        valid_state_raw = 0;
        valid_state_spike =0;
        
    end
  endcase


 end            
        

reg tra_overd;
        always@(posedge clk or posedge rst)
         begin 
          if(rst) begin tra_overd<= 'd0; end
          else begin tra_overd<= tra_over; end 
         end
         assign tra_overout = tra_over&&~tra_overd;
always@(posedge clk or posedge rst)
 begin
    if(rst) begin 
      length_cnt0 <= 'd0;
    //  length_cnt1 <= 'd0;
      state_spike <= 'd0;
      state_raw <= 'd0;
    end
    else begin
      case(STATE)
    INIT: begin length_cnt0 <= 'd0; end
   // length_cnt1 <= 'd0;end
    RAW: begin 
            state_spike <= 'd0;
      state_raw <= 'd1;
     if(rd_en_raw0) begin length_cnt0 <= length_cnt0 + 'd1; end
     else begin length_cnt0 <= length_cnt0; end
     end
//    SPIKE: begin
//      state_spike <= 'd1;
//      state_raw <= 'd0;
//     if(rd_en_spike0) begin length_cnt1 <= length_cnt1 + 'd1; end
//     else begin length_cnt1 <= length_cnt1; end
//     end
    FINISH: begin
        length_cnt0 <= 'd0;
     //   length_cnt1 <= 'd0;
        state_spike <= 'd0;
        state_raw <= 'd0;
     end
    


      endcase
    end


 end  




endmodule 