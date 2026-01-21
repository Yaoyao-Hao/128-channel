`timescale 1ns / 1ps
module weight_rom
  #(
     parameter DEBUG = 1,

     parameter col = 512,
     parameter cow = 96,
     parameter RAMADDR_W =$clog2(col*col*4+col*cow*4),
     parameter ADDR_Wih = $clog2(col*cow*4),
     parameter ADDR_Whh = $clog2(col*col*4),
     parameter ADDR_bih = $clog2(col*4),
     parameter ADDR_bhh = $clog2(col*4),
     parameter QZ = 16 //数据量化位宽

   )
   (
     input [ADDR_Wih-1:0]addr_wih,
     input [RAMADDR_W-1:0]addr_whh,
     input [ADDR_bih-1:0]addr_bih,
     input [ADDR_bhh-1:0]addr_bhh,

     output [QZ-1:0]weight_out_wih,
     output [QZ-1:0]weight_out_whh,
     output [QZ*4-1:0]bias_out_bih,
     output [QZ*4-1:0]bias_out_bhh

   );

  wire [1:0]GATEstate;
  assign GATEstate = addr_whh[1:0];
  wire [ADDR_Whh-1:0]addr_whh0;
  wire [ADDR_Wih-1:0]addr_wih0,addr_wih1;
  assign addr_whh0 = addr_whh[1:0]*col*col+addr_whh[ADDR_Whh-1:2];

  wire rd_chos;

  assign rd_chos = (addr_whh>col*col*4-1)?'d1:'d0;


  assign addr_wih0 = addr_whh - col*col*4;
  assign addr_wih1 = addr_wih0[1:0]*col*cow+addr_wih0[ADDR_Wih-1:2];

  localparam length_wih = col*cow*4,
             length_whh = col*col*4,
             length_bih = col*1*4,
             length_bhh = col*1*4;
  reg [QZ-1:0]mem_wih[0:col*cow*4-1];
  reg [QZ-1:0]mem_whh[0:col*col*4-1];
  reg [QZ-1:0]mem_bih[0:col*4-1];
  reg [QZ-1:0]mem_bhh[0:col*4-1];
  reg[32:0] n;


  integer file0,file1,file2,file3;
  integer temp0,temp1,temp2,temp3;
  integer i;
  genvar j;

  wire[ADDR_bih-1:0]addr_bih0[0:3];
  wire[ADDR_bhh-1:0]addr_bhh0[0:3];

  generate for(j=0;j<4;j=j+1)
    begin :b

      assign addr_bih0[j] = addr_bih+(j)*col;
      assign addr_bhh0[j] = addr_bhh+(j)*col;

      assign bias_out_bih[QZ*(j+1)-1:QZ*j] =    mem_bih[addr_bih0[j]];
      assign bias_out_bhh[QZ*(j+1)-1:QZ*j] =    mem_bhh[addr_bhh0[j]];
    end
  endgenerate

  generate if(DEBUG)
    begin

      initial
      begin
        file0 = $fopen("D:/YCB/YCB/testdata/LSTM_Q/file_wih.txt","r");
        file1 = $fopen("D:/YCB/YCB/testdata/LSTM_Q/file_whh.txt","r");
        file2 = $fopen("D:/YCB/YCB/testdata/LSTM_Q/file_bih.txt","r");
        file3 = $fopen("D:/YCB/YCB/testdata/LSTM_Q/file_bhh.txt","r");
        for(i=0 ; i <= length_wih-1 ; i=i+1)
        begin
          temp0 = $fscanf(file0,"%d",mem_wih[i]); //每次读取一个数据，以空格或回车以及tab为区分。
        end
        for(i=0 ; i <= length_whh-1 ; i=i+1)
        begin
          temp1 = $fscanf(file1,"%d",mem_whh[i]); //每次读取一个数据，以空格或回车以及tab为区分。
        end
        for(i=0 ; i <= length_bih-1 ; i=i+1)
        begin
          temp2 = $fscanf(file2,"%d",mem_bih[i]); //每次读取一个数据，以空格或回车以及tab为区分。
        end
        for(i=0 ; i <= length_bhh-1 ; i=i+1)
        begin
          temp3 = $fscanf(file3,"%d",mem_bhh[i]); //每次读取一个数据，以空格或回车以及tab为区分。
        end
        //$readmemb("C:/Users/Lenovo/Desktop/testdata/LSTM_Q/file_wih.dat",mem_wih);
        //$readmemb("C:/Users/Lenovo/Desktop/testdata/LSTM_Q/file_whh.txt",mem_whh);
        //$readmemb("C:/Users/Lenovo/Desktop/testdata/LSTM_Q/file_bih.txt",mem_bih);
        //$readmemb("C:/Users/Lenovo/Desktop/testdata/LSTM_Q/file_bhh.txt",mem_bhh);

      end
      assign weight_out_wih =  mem_wih[addr_wih1];
      assign weight_out_whh =rd_chos?  mem_wih[addr_wih1]:mem_whh[addr_whh0];
      //assign bias_out_bih =    mem_bih[addr_bih];
      //assign bias_out_bhh =    mem_bhh[addr_bhh];
    end
    else
    begin
      /*
      pmi_rom 
      #(
        .pmi_addr_depth       (col*col*4 ), // integer
        .pmi_addr_width       ($clog2(col*col*4) ), // integer
        .pmi_data_width       (QZ ), // integer
        .pmi_regmode          ("reg" ), // "reg"|"noreg"
        .pmi_resetmode        ("async" ), // "async"|"sync"	
        .pmi_init_file        ( ), // string		
        .pmi_init_file_format ( ), // "binary"|"hex"    
        .pmi_family           ("common" )  // "common"
      ) pmi_romwh (
        .Address    (addr_whh ),  // I:
        .OutClock   (clk ),  // I:
        .OutClockEn (1 ),  // I:
        .Reset      (0 ),  // I:
        .Q          (weight_out_whh )   // O:
      );
       
       
      pmi_rom 
      #(
        .pmi_addr_depth       (col*cow*4 ), // integer
        .pmi_addr_width       ($clog2(col*cow*4) ), // integer
        .pmi_data_width       (QZ ), // integer
        .pmi_regmode          ("reg" ), // "reg"|"noreg"
        .pmi_resetmode        ("async" ), // "async"|"sync"	
        .pmi_init_file        ( ), // string		
        .pmi_init_file_format ( ), // "binary"|"hex"    
        .pmi_family           ("common" )  // "common"
      ) pmi_romwhh (
        .Address    (addr_whh ),  // I:
        .OutClock   (clk ),  // I:
        .OutClockEn (1 ),  // I:
        .Reset      (0 ),  // I:
        .Q          (weight_out_wih )   // O:
      );
      */
      assign bias_out_bih =    'd2333;
      assign bias_out_bhh =    'd2333;
      assign weight_out_wih =  'd2335;
      assign weight_out_whh =  'd2335;

    end

  endgenerate










endmodule
