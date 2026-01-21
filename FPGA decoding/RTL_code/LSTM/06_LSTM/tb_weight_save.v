module tb_weight_save();

GSR GSR_INST( .GSR_N(1'b1), .CLK(1'b0));
  reg clk_sys;
  reg rst_n;
  reg uart_in;
  wire uart_out;
  wire parity;




  initial
  begin
    clk_sys = 1'b0;
    rst_n = 1'b0;
    uart_in = 1'b1;


  end

  always #1 clk_sys = ~clk_sys;
  wire tx_byte_over;























endmodule