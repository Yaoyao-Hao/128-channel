module ramdata
#(
    parameter addr_width = 4,
    parameter data_width = 8,
    parameter data_deepth = 16,

    parameter INITdata = 'd0
    )
(
    input clka,
    input clkb,
    input rst_n,
    input cs,
    //wr
    input [addr_width - 1:0]wr_addr,
    input [data_width - 1:0]wr_data,
    input wr_en,
    //rd
    input [addr_width - 1:0]rd_addr,
    input rd_en,
    output reg [data_width - 1:0]rd_data
    );
reg [data_width-1:0] register [data_deepth-1:0]     ;
integer i;

always@(posedge clka or negedge rst_n)
begin
    if(!rst_n)begin
        for(i=0;i<data_deepth;i=i+1)
            register[i] <=INITdata;
        end
    else if(wr_en == 1 && cs == 1)
        register[wr_addr] <= wr_data;
    else
        register[wr_addr] <= register[wr_addr];
end

always@(posedge clkb or negedge rst_n)
begin
    if(!rst_n)
        rd_data <= 0;
    else if(rd_en == 1 && cs == 1)
        rd_data <= register[rd_addr];
    else
        rd_data <= rd_data;
end




endmodule

