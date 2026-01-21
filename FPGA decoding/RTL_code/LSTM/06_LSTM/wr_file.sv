module wr_file#(WIDTH = 16,
LENGTH = 64,

parameter FILE_PATH_2D_H   = "C:/Users/BCI/Desktop/test_data/FPGAdataah.txt"

)
(input clk,
 input rst_n,
 input signed[WIDTH-1: 0] data_in,
 input data_in_valid
);

reg    [WIDTH-1: 0]    dat2_comp[LENGTH-1: 0];

integer fid;
initial begin
fid = $fopen( FILE_PATH_2D_H, "w" );
end
reg [31:0]cnt = 0;
always@(posedge clk or negedge rst_n) begin 
    if(data_in_valid) begin 
    if(cnt <= LENGTH-1) begin 
        $fwrite(fid, "%d\n",data_in);
        cnt <= cnt + 'd1;end
    else begin 
        $fwrite(fid, "%d\n",data_in);
        cnt <= 0;
    end
    end
    
    end





endmodule