module LDL_TOP #(
    parameter N = 3,              // 矩阵大小
    parameter Q = 24,             // 定点小数位
    parameter WIDTH = 32          // 数据宽度
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    //input  wire signed [WIDTH-1:0] A [0:N-1][0:N-1], // 输入矩阵 (Q 格式)
    input wire [$clog2(N*N)-1:0]WrAddress_a,
    input wr_A_ram,
    input wire [WIDTH - 1:0] Data_a, 
    output reg done,
    // output reg signed [WIDTH-1:0] L [0:N-1][0:N-1],  // L (Q 格式)
    // output reg signed [WIDTH-1:0] D [0:N-1]     ,     // D (Q 格式, 对角)
    output [WIDTH-1:0] data_Matrix_mult_o,
    output            data_Matrix_mult_v_o
);
reg [5:0] state;
    // ---------------- 状态机定义 ----------------
    localparam IDLE       = 0 ,
               STEP_K     = 1 ,
               STEP_K0    = 18,
               LOOP_J0    = 2 ,   // 计算 L(k,j)^2
               LOOP_J1    = 3 ,   // >>> Q
               LOOP_J2    = 4 ,   // * D(j)
               LOOP_J3    = 5 ,   // >>> Q
               LOOP_NEXT  = 6 ,   // sumVal 累加
               SAVE_D     = 7 ,   // 保存 D(k,k)
               STEP_I     = 8 ,
               STEP_I0    = 17,
               LOOP2_0    = 9 ,   // L(i,j)*L(k,j)
               LOOP2_1    = 10,  // >>> Q
               LOOP2_2    = 11,  // * D(j)
               LOOP2_3    = 12,  // >>> Q
               LOOP2_NEXT = 13,  // sumVal 累加
               SAVE_L     = 14,
               NEXT_K     = 15,
               FINISH     = 16;


reg  [4:0]CAL_STATE;
    localparam IDLE_CAL      = 0 ,
               LDCAL         = 1 ,
               L_N           =2  ,
               D_N0          =3  ,
               D_N1          =4  ,
               D_N2          =7  ,
               T3C_0         =8  ,
               T3C_1         =9  ,
               T3C_2         =10  ,
               T3C_3         =11  ,
               T3C_4         =12  ,
               MULT          =5  ,
               FINISH_CAL    =6  ;

reg [7:0] k, i, j_cnt;

wire [WIDTH-1:0]  D_INV_D;
// wire [WIDTH - 1:0]         Data_a; 
 wire [WIDTH - 1:0]       Q_data_a;     
// wire [$clog2(N*N)-1:0]WrAddress_a;
reg  [$clog2(N*N)-1:0]RdAddress_a;

//assign RdAddress_a = k*N + k;
wire [$clog2(N)  :0]cnt_a;
wire [$clog2(N)  :0]cnt_b;
wire [$clog2(N)  :0]cnt_c;
pmi_ram_dp
#(
  .pmi_wr_addr_depth    (N*N ), // integer
  .pmi_wr_addr_width    ($clog2(N*N) ), // integer
  .pmi_wr_data_width    (WIDTH), // integer
  .pmi_rd_addr_depth    (N*N ), // integer
  .pmi_rd_addr_width    ($clog2(N*N) ), // integer
  .pmi_rd_data_width    (WIDTH ), // integer
  .pmi_regmode          ("noreg" ), // "reg"|"noreg"
  .pmi_resetmode        ("sync" ), // "async"|"sync"
  .pmi_init_file        ("D:/YCB/YCB/PROJECT/EEGdecode/matlab/A_init.hex" ), // string
  .pmi_init_file_format ("hex" ), // "binary"|"hex"
  .pmi_family           ("common" )  // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
) A_ram(
  .Data      (Data_a ),  // I:
  .WrAddress (WrAddress_a ),  // I:
  .RdAddress (RdAddress_a ),  // I:
  .WrClock   (clk ),  // I:
  .RdClock   (clk ),  // I:
  .WrClockEn (1 ),  // I:
  .RdClockEn (1 ),  // I:
  .WE        (wr_A_ram ),  // I:
  .Reset     (~rst_n ),  // I:
  .Q         (Q_data_a )   // O:
);
reg [$clog2(N):0]cnt_i,cnt_j;
wire [WIDTH - 1:0]         Data_a_l,     Data_b_l; 
wire [WIDTH - 1:0]       Q_data_a_l,   Q_data_b_l;     
reg  [$clog2(N*N)-1:0]Address_a_l ,Address_b_l;
wire [$clog2(N*N)-1:0]RdAddress_a_l,RdAddress_b_l;
wire [$clog2(N*N)-1:0]rd_ram_addr_a,rd_ram_addr_b;
  wire [$clog2(N*N)-1:0]AddressA;
     wire wr_ram_L_INV;
   wire [WIDTH-1:0]L_INV;
reg WrA;

reg [WIDTH - 1:0] AA; 

wire div_finish;
always@(*)
begin 
    if(~rst_n) begin
        Address_a_l = 0;
        Address_b_l = 0;
        WrA         = 0;
        RdAddress_a = 0;
        AA          = 0;
     end
    else begin 
    case(CAL_STATE)
    LDCAL :begin  case(state) 
    
          STEP_K   :begin
              Address_a_l = k * N + j_cnt;
              Address_b_l = k * N + j_cnt;
              WrA         = 0;

           end 
          STEP_K0:begin 
              Address_a_l = k + j_cnt* N;
              Address_b_l = k + j_cnt* N;
              WrA         = 0;
 
          end
          LOOP_J0:begin 
              RdAddress_a = k*N + k; 
          end
        //  SAVE_D:begin AA =  A[k][k]; end
          LOOP_NEXT:begin
              Address_a_l = (j_cnt + 'd1) * N +  k;
              Address_b_l = (j_cnt + 'd1) * N +  k;
              WrA         = 0;

           end

           STEP_I0:    begin 
              Address_a_l = (j_cnt) * N + i;
              Address_b_l = (j_cnt) * N + k;
              WrA         = 0;

          end
           LOOP2_NEXT:begin 
              Address_a_l = (j_cnt+ 'd1) * N + i  ;
              Address_b_l = (j_cnt+ 'd1) * N + k  ;
              WrA         = 0;
 
            end
          LOOP2_0: begin
              RdAddress_a = i*N+k;
            end 
           SAVE_L:    begin
              Address_a_l = (i) +k*N;//* N + k;
              Address_b_l = (i) +k*N;//* N + k;
              WrA         = div_finish;
             // AA =  A[i][k];
            end
          default:begin 
              Address_a_l = Address_a_l;
              Address_b_l = Address_b_l;
              WrA         = 0;

          end
          endcase end
   L_N: begin  Address_a_l =  AddressA       ;  Address_b_l = rd_ram_addr_b;end
 T3C_0: begin  Address_a_l =  cnt_i *N+cnt_i+ cnt_j;  end
 T3C_1: begin  Address_a_l =  cnt_i *N+cnt_i+ cnt_j;  end
 T3C_2: begin  Address_a_l =  cnt_i *N+cnt_i+ cnt_j;  end
 T3C_3: begin  Address_a_l =  cnt_i *N+cnt_i+ cnt_j;  end
 T3C_4: begin  Address_a_l =  cnt_i *N+cnt_i+ cnt_j;  end
 MULT:  begin  Address_a_l =  cnt_a + cnt_c*N;        end
   
  endcase
  end
end

wire [WIDTH-1:0]cal_data;
assign Data_a_l = wr_ram_L_INV?L_INV:D_INV_D;
pmi_ram_dp_true 
#(
  .pmi_addr_depth_a     (N*N ), // integer
  .pmi_addr_width_a     ($clog2(N*N) ), // integer
  .pmi_data_width_a     (WIDTH), // integer
  .pmi_addr_depth_b     (N*N ), // integer
  .pmi_addr_width_b     ($clog2(N*N) ), // integer
  .pmi_data_width_b     (WIDTH), // integer
  .pmi_regmode_a        ("noreg"  ), // "reg"|"noreg"     
  .pmi_regmode_b        ("noreg"  ), // "reg"|"noreg"     
  .pmi_resetmode        ("sync"	 ), // "async"|"sync"	
  .pmi_init_file        ("D:/YCB/YCB/PROJECT/EEGdecode/matlab/L_init.hex" ),//("D:/YCB/YCB/PROJECT/EEGdecode/matlab/L_init.hex"  ), // string		
  .pmi_init_file_format ("hex"     ), // "binary"|"hex"    
  .pmi_family           ("common")  // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
) L_ram (          	
  .DataInA  (Data_a_l ), // I:
  .DataInB  (Data_b_l ), // I:
  .AddressA (Address_a_l ), // I:
  .AddressB (Address_b_l ), // I:
  .ClockA   (clk ), // I:
  .ClockB   (clk ), // I:
  .ClockEnA (1 ), // I:
  .ClockEnB (1 ), // I:
  .WrA      (WrA||wr_ram_L_INV ), // I:
  .WrB      (0 ), // I:
  .ResetA   (~rst_n ), // I:
  .ResetB   (~rst_n ), // I:
  .QA       (Q_data_a_l ), // O:
  .QB       (Q_data_b_l )  // O:
);


reg [WIDTH - 1:0]         Data_d; 
wire [WIDTH - 1:0]       Q_data_d;     
reg [$clog2(N)-1:0]WrAddress_d;
reg  [$clog2(N)-1:0]RdAddress_d;
//assign WrAddress_d = k;

reg wr_div_d;
//assign Data_d = D[k];
reg wr_d;
//assign wr_d = (state == SAVE_D)? 'd1:'d0;
always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin wr_d<='d0; end
          else
        begin
            wr_d <= (state == SAVE_D)? 'd1:'d0;
         end
        end


pmi_ram_dp
#(
  .pmi_wr_addr_depth    (N), // integer
  .pmi_wr_addr_width    ($clog2(N) ), // integer
  .pmi_wr_data_width    (WIDTH), // integer
  .pmi_rd_addr_depth    (N ), // integer
  .pmi_rd_addr_width    ($clog2(N) ), // integer
  .pmi_rd_data_width    (WIDTH ), // integer
  .pmi_regmode          ("noreg" ), // "reg"|"noreg"
  .pmi_resetmode        ("sync" ), // "async"|"sync"
  .pmi_init_file        ("D:/YCB/YCB/PROJECT/EEGdecode/matlab/D_init.hex" ), // string
  .pmi_init_file_format ("hex" ), // "binary"|"hex"
  .pmi_family           ("common" )  // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
) D_ram(
  .Data      (Data_d ),  // I:
  .WrAddress (WrAddress_d ),  // I:
  .RdAddress (RdAddress_d ),  // I:
  .WrClock   (clk ),  // I:
  .RdClock   (clk ),  // I:
  .WrClockEn (1 ),  // I:
  .RdClockEn (1 ),  // I:
  .WE        (wr_d||wr_div_d ),  // I:
  .Reset     (~rst_n ),  // I:
  .Q         (Q_data_d )   // O:
);

  //  myLDL #(
  //       .N(N), .Q(Q), .WIDTH(WIDTH)
  //   ) dut (
  //       .clk(clk),
  //       .rst_n(rst_n),
  //       .start(start),
  //       .A(A),
  //       .done(),
  //       .k    (    ), 
  //       .i    (    ), 
  //       .j_cnt(),
  //       .state(),
  //       .cal_data(),
  //       .Q_data_a_l(Q_data_a_l),
  //       .Q_data_b_l(Q_data_b_l)


  //       // .L(L),
  //       // .D(D)
  //   );


wire done_LDL,done_inv;
reg cal_start_inv;

wire start_div;
wire [WIDTH-1:0]D_ram_data;
wire [WIDTH-1:0]div_data_LDL;
   myLDL_ram #(
        .N(N), .Q(Q), .WIDTH(WIDTH)
   ) dut_ram (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
       // .A(A),
        .done(done_LDL),
        .div_cal(start_div),
        .k    (k    ), 
        .i    (i    ), 
        .j_cnt(j_cnt),
        .state(state),
        .A_in(Q_data_a),
        .div_data(div_data_LDL),
        .D_ram_data(D_ram_data),
        .cal_data(cal_data),
        .Q_data_a_l(Q_data_a_l),
        .Q_data_b_l(Q_data_b_l),
        .Q_data_d  (Q_data_d)  ,
        .div_finish(div_finish)
        // .L(),
        // .D()
    );
wire cal_inv_L;

wire [WIDTH-1:0]data_in_A,data_in_B;
invLowerQ #(.N(N),.WIDTH(WIDTH),.Q(Q)) uut (
    .clk(clk),
    .rst_n(rst_n),
    .start(cal_start_inv),
    .wr_ram        (wr_ram_L_INV)    ,
    .AddressA      (AddressA)      ,
    .rd_ram_addr_a(rd_ram_addr_a),
    .rd_ram_addr_b(rd_ram_addr_b),
    .data_in_A(Q_data_a_l),
    .data_in_B(Q_data_b_l),


    .ram_data_in_o (L_INV)     ,
    .done(done_inv)

);
// reg  [4:0]CAL_STATE;
//     localparam IDLE_CAL      = 0 ,
//                LDCAL         = 1 ,
//                L_N           =2  ,
//                D_N0          =3  ,
//                D_N1          =4  ,
//                D_N2          =7  ,
//                T3C_0         =8  ,
//                T3C_1         =9  ,
//                T3C_2         =10  ,
//                T3C_3         =11  ,
//                T3C_4         =12  ,
//                MULT          =5  ,
//                FINISH_CAL    =6  ;

reg [$clog2(N):0]d_inv_cnt;
reg div_start_u;
wire [WIDTH-1:0]  D_INV;
wire Mar_cal_finish;

wire [WIDTH - 1:0]         Data_a_T,     Data_b_T; 
wire [WIDTH - 1:0]       Q_data_a_T,   Q_data_b_T;     
reg  [$clog2(N*N)-1:0]Address_a_T ,Address_b_T;
wire [$clog2(N*N)-1:0]RdAddress_a_T,RdAddress_b_T;


always@(*) begin 
case(CAL_STATE) 
LDCAL:begin RdAddress_d = j_cnt;    WrAddress_d = k ;        Data_d = D_ram_data ; end
L_N:  begin RdAddress_d = j_cnt;    WrAddress_d = k ;        Data_d = D_ram_data ; end
D_N0 :begin RdAddress_d =d_inv_cnt; WrAddress_d = d_inv_cnt; Data_d = D_INV; end
D_N1 :begin RdAddress_d =d_inv_cnt; WrAddress_d = d_inv_cnt; Data_d = D_INV; end
D_N2 :begin RdAddress_d =d_inv_cnt; WrAddress_d = d_inv_cnt; Data_d = D_INV; end
T3C_0 :begin RdAddress_d = cnt_i + cnt_j;    Address_a_T =  cnt_i * N +cnt_i+ cnt_j;      end
T3C_1 :begin RdAddress_d = cnt_i + cnt_j;    Address_a_T =  cnt_i * N +cnt_i+ cnt_j;      end
T3C_2 :begin RdAddress_d = cnt_i + cnt_j;    Address_a_T =  cnt_i * N +cnt_i+ cnt_j;      end
T3C_3 :begin RdAddress_d = cnt_i + cnt_j;    Address_a_T =  cnt_i * N +cnt_i+ cnt_j;      end
T3C_4 :begin RdAddress_d = cnt_i + cnt_j;    Address_a_T =  cnt_i * N +cnt_i+ cnt_j;      end
  MULT:begin                           Address_a_T =  cnt_a + cnt_b*N;       end
endcase
end
reg Mar_cal_start;
reg WrA_T;
always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
        CAL_STATE<=IDLE_CAL;
        d_inv_cnt<='d0;
        div_start_u <='d0;
        cal_start_inv<='d0;
        wr_div_d    <='d0;
        Mar_cal_start <='d0;
        cnt_i<='d0;
        cnt_j<='d0;
        WrA_T<='d0;
        done <='d1;
        end
        else 
        begin
   case(CAL_STATE)
IDLE_CAL   : begin 
    d_inv_cnt<='d0;
    done <='d0;
     cal_start_inv<='d0;
     wr_div_d <='d0;
    if(start) begin CAL_STATE<= LDCAL    ; end
                    else      begin CAL_STATE<= CAL_STATE; end 
                     end  
LDCAL      : begin if(done_LDL) begin CAL_STATE<= L_N      ;  cal_start_inv<='d1; end
                   else         begin CAL_STATE<= LDCAL    ;  cal_start_inv<='d0; end   
                   end     
L_N        : begin 
   cal_start_inv<='d0;
  if(done_inv) begin  CAL_STATE<= D_N0    ; end 
  else        begin  CAL_STATE<= L_N    ; end  end           
D_N0       : begin    
            CAL_STATE <= D_N1;
            div_start_u <='d1;
            wr_div_d <='d0;
   end     
D_N1       : begin    
    div_start_u <='d0;
    if(div_finish) begin CAL_STATE <= D_N2;wr_div_d <='d1; end   
    else           begin CAL_STATE <= D_N1;wr_div_d <='d0; end
   end    
D_N2       : begin    
  wr_div_d <='d0;
     if(d_inv_cnt>=N-1)  begin d_inv_cnt<='d0; CAL_STATE<= T3C_0 ; end
     else                begin d_inv_cnt<=d_inv_cnt+'d1; CAL_STATE<= D_N0 ; end
   end        

T3C_0:begin
  WrA_T<='d0;
  CAL_STATE<= T3C_1 ;
  cnt_i<=cnt_i;
  cnt_j<=cnt_i;
 end
T3C_1:begin
  CAL_STATE<= T3C_2 ;
 end
T3C_2:begin
  CAL_STATE<= T3C_3 ;
  WrA_T<='d1;
 end
T3C_3:begin
  WrA_T<='d0;
 if(cnt_j<N-cnt_i - 1) begin CAL_STATE<= T3C_1 ; cnt_j<= cnt_j +'d1; end
 else                  begin CAL_STATE<= T3C_4 ; cnt_j<= 0         ; end
 end
T3C_4:begin
  WrA_T<='d0;
 if(cnt_i<N-1) begin CAL_STATE<= T3C_1 ; cnt_i<= cnt_i +'d1; end
 else          begin CAL_STATE<= MULT  ; cnt_i<= 0         ; Mar_cal_start <='d1;end
 end

MULT       : begin    
wr_div_d <='d0;
Mar_cal_start <='d0;
if(Mar_cal_finish) begin CAL_STATE<= FINISH_CAL  ; end
 else              begin CAL_STATE<= MULT  ; end
   end            
FINISH_CAL : begin    
done <='d1;
CAL_STATE<= IDLE_CAL  ;
   end           
            endcase
         end
        end
//除法器
wire [WIDTH-1:0]dividend;
wire [WIDTH-1:0]divisor_d_U;
wire [WIDTH*2-1:0]quotient_d_U;
wire [WIDTH-1:0]div_data_LDL_sign;
assign div_data_LDL_sign =div_data_LDL[WIDTH-1]? ~div_data_LDL + 'd1:div_data_LDL;
assign dividend =(CAL_STATE =='d1)?div_data_LDL_sign:1<<Q;//div_data_LDL:1<<Q;//start_div? div_data_LDL:1<<Q;
divider#(
  .WIDTH    (WIDTH*2)
)divider_inst_U(
  .clk      (clk), 
  .rst      (~rst_n), 
  .start    (div_start_u||start_div), 
  .dividend ({dividend,{WIDTH{1'b0}}}), 
  .divisor  ({{WIDTH{1'b0}},Q_data_d}), 
  .quotient (quotient_d_U ), 
  .remainder(), 
  .zeroErr  (), 
  .valid    (div_finish) 
);

assign D_INV_D =div_data_LDL[WIDTH-1]? ~quotient_d_U[WIDTH*2-1:WIDTH] + 'd1: quotient_d_U[WIDTH*2-1:WIDTH];
assign D_INV = quotient_d_U[WIDTH*2-Q-1:WIDTH-Q];
wire [WIDTH-1:0]dataA;
assign dataA = Q_data_a_l;
wire [WIDTH-1:0]dataB;
assign dataB = Q_data_a_T;
wire [WIDTH-1:0]data_Matrix_mult;
Matrix_mult
  #(.MAX_COL  (N),
    .MAX_ROW0 (N),
    .MAX_ROW1 (N),
    .DATA_W  (WIDTH),
    .Q       (Q)

  )Matrix_mult_inst
   (
     .clk_i             (clk),
     .rst_i             (~rst_n),
     .start_i           (Mar_cal_start),
     .COL               (N),
     .ROW0              (N),
     .ROW1              (N),
     .cal_finish_o      (Mar_cal_finish),
     .cnt_a             (cnt_a),
     .cnt_b             (cnt_b),
     .cnt_c             (cnt_c),
     .dataA             (dataA),
     .dataB             (dataB),
     .data_o_v          (data_Matrix_mult_v),
     .data_o            (data_Matrix_mult) 
     );

assign  data_Matrix_mult_o  = {data_Matrix_mult[WIDTH-1],data_Matrix_mult[WIDTH-1:1]};
assign  data_Matrix_mult_v_o= data_Matrix_mult_v;

pmi_ram_dp_true 
#(
  .pmi_addr_depth_a     (N*N ), // integer
  .pmi_addr_width_a     ($clog2(N*N) ), // integer
  .pmi_data_width_a     (WIDTH), // integer
  .pmi_addr_depth_b     (N*N ), // integer
  .pmi_addr_width_b     ($clog2(N*N) ), // integer
  .pmi_data_width_b     (WIDTH), // integer
  .pmi_regmode_a        ("noreg"  ), // "reg"|"noreg"     
  .pmi_regmode_b        ("noreg"  ), // "reg"|"noreg"     
  .pmi_resetmode        ("sync"	 ), // "async"|"sync"	
  .pmi_init_file        ("D:/YCB/YCB/PROJECT/EEGdecode/matlab/L_init.hex"  ), // string		
  .pmi_init_file_format ("hex"     ), // "binary"|"hex"    
  .pmi_family           ("common")  // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
) T_ram (          	
  .DataInA  (Data_a_T ), // I:
  .DataInB  (Data_b_T ), // I:
  .AddressA (Address_a_T ), // I:
  .AddressB (Address_b_T ), // I:
  .ClockA   (clk ), // I:
  .ClockB   (clk ), // I:
  .ClockEnA (1 ), // I:
  .ClockEnB (1 ), // I:
  .WrA      (WrA_T ), // I:
  .WrB      (0 ), // I:
  .ResetA   (~rst_n ), // I:
  .ResetB   (~rst_n ), // I:
  .QA       (Q_data_a_T ), // O:
  .QB       (Q_data_b_T )  // O:
);
wire [WIDTH - 1:0]  mult0; 
wire [WIDTH - 1:0]  mult1; 
assign  mult0 = Q_data_d;
assign  mult1 = Q_data_a_l;
wire [WIDTH*2 - 1:0] mult_data_out;
wire [WIDTH - 1:0] wr_Data_a_T;
mult_cal mult_cal_inst(
        .clk_i    (clk), 
        .clk_en_i (1), 
        .rst_i    (~rst_n), 
        .data_a_i (mult0), 
        .data_b_i (mult1), 
        .result_o (mult_data_out)) ;
     assign wr_Data_a_T = mult_data_out[Q+WIDTH-1:Q];
     assign Data_a_T    = wr_Data_a_T;
endmodule