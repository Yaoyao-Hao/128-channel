module weight_data_buffer#(
parameter hidden_size = 1, //隐藏层特征数



parameter ADDR_WIDTHAD = $clog2(hidden_size*hidden_size*4),
parameter ADDR_WIDTHBIAS = $clog2(hidden_size*4)
)
(
input clk,
input rst_n,

input read_start


);


reg [3:0]STATE_READ;//读flash状态机
localparam INTI = 0,
           READ = 1,
           FINISH =2 ;



reg [ADDR_WIDTHBIAS-1:0]read_cnt;
always@(posedge clk or negedge rst_n)
 begin 
   if(~rst_n) begin STATE_READ<= 'd0;  end
   else begin end

 end




endmodule