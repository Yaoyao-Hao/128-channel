`timescale 1ns / 1ps
module test_weight



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
     input [31-1:0]addr_wih,


     output [QZ-1:0]weight_out_wih


   );

  wire [1:0]GATEstate;
  wire [ADDR_Whh-1:0]addr_whh0;
  wire [ADDR_Wih-1:0]addr_wih0,addr_wih1;
  //assign addr_whh0 = addr_whh[1:0]*col*col+addr_whh[ADDR_Whh-1:2];

  wire rd_chos;

  //assign rd_chos = (addr_whh>col*col*4-1)?'d1:'d0;


  //assign addr_wih0 = addr_whh - col*col*4;
  //assign addr_wih1 = addr_wih0[1:0]*col*cow+addr_wih0[ADDR_Wih-1:2];

  localparam length_wih = col*cow*4+ col*col*5  ;
  reg [QZ/2-1:0]mem_w0[0:length_wih-1];
  reg [QZ/2-1:0]mem_w1[0:length_wih-1];
  reg[32:0] n;


  integer file0,file1,file2,file3;
  integer temp0,temp1,temp2,temp3;
  integer i;
  genvar j;

  wire[ADDR_bih-1:0]addr_bih0[0:3];
  wire[ADDR_bhh-1:0]addr_bhh0[0:3];

  wire [QZ/2-1:0]weight_out_wih0;
  wire [QZ/2-1:0]weight_out_wih1; 

  generate if(DEBUG)
    begin

      initial
      begin
        file0 = $fopen("D:/YCB/YCB/testdata/LSTM_Q/file_all_w0.txt","r");
        file1 = $fopen("D:/YCB/YCB/testdata/LSTM_Q/file_all_w1.txt","r");
        for(i=0 ; i <= length_wih-1 ; i=i+1)
        begin
          temp0 = $fscanf(file0,"%d",mem_w0[i]); //每次读取一个数据，以空格或回车以及tab为区分。
          temp1 = $fscanf(file1,"%d",mem_w1[i]); //每次读取一个数据，以空格或回车以及tab为区分
        end

        //$readmemb("C:/Users/Lenovo/Desktop/testdata/LSTM_Q/file_wih.dat",mem_wih);
        //$readmemb("C:/Users/Lenovo/Desktop/testdata/LSTM_Q/file_whh.txt",mem_whh);
        //$readmemb("C:/Users/Lenovo/Desktop/testdata/LSTM_Q/file_bih.txt",mem_bih);
        //$readmemb("C:/Users/Lenovo/Desktop/testdata/LSTM_Q/file_bhh.txt",mem_bhh);

      end
      assign weight_out_wih0 =  mem_w0[addr_wih];
      assign weight_out_wih1 =  mem_w1[addr_wih];
      assign weight_out_wih= {weight_out_wih1,weight_out_wih0};
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