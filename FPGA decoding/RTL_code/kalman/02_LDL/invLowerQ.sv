module invLowerQ #(
    parameter N = 4,  // 矩阵阶数
    parameter Q = 24,             // 定点小数位
    parameter WIDTH = 32          // 数据宽度
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,
  
    output  [$clog2(N*N)-1:0]rd_ram_addr_a,rd_ram_addr_b,
    input wire [WIDTH-1:0]data_in_A,data_in_B,
    output reg wr_ram,
    output wire[$clog2(N*N)-1:0]AddressA,
    output  [WIDTH-1:0]ram_data_in_o,

    output reg done
);
wire [WIDTH*2-1:0]mult_data_out;
//wire [WIDTH-1:0]data_in_A,data_in_B;
reg  [WIDTH*2+$clog2(N)-1:0]ram_data_in;
assign ram_data_in_o = ram_data_in[WIDTH-1:0];

    // FSM states
    typedef enum logic [4:0] {
        IDLE,
        INIT_J,
        INIT_I,
        INIT_K,
        BODY_K,
        INC_K,
        INC_I,
        INC_J,
        WAIT_K,
        WAIT_K0,
        WAIT_I,
        WAIT_J,

        DONE_STATE
    } state_t;
    reg [WIDTH*2+$clog2(N)-1:0]reg_add;
    state_t state;
    
    // loop indices
    integer j, i, k;
// pmi_ram_dp_true 
// #(
//   .pmi_addr_depth_a     (N*N ), // integer
//   .pmi_addr_width_a     ($clog2(N*N) ), // integer
//   .pmi_data_width_a     (WIDTH), // integer
//   .pmi_addr_depth_b     (N*N ), // integer
//   .pmi_addr_width_b     ($clog2(N*N) ), // integer
//   .pmi_data_width_b     (WIDTH), // integer
//   .pmi_regmode_a        ("noreg"  ), // "reg"|"noreg"     
//   .pmi_regmode_b        ("noreg"  ), // "reg"|"noreg"     
//   .pmi_resetmode        ("sync"	 ), // "async"|"sync"	
//   .pmi_init_file        ("D:/YCB/YCB/PROJECT/EEGdecode/matlab/Lq_init.hex"  ), // string		
//   .pmi_init_file_format ("hex"     ), // "binary"|"hex"    
//   .pmi_family           ("common")  // "LIFCL"|"LFD2NX"|"LFCPNX"|"LFMXO5"|"UT24C"|"UT24CP"|"common"
// ) L_ram (          	
//   .DataInA  (ram_data_in[WIDTH-1:0] ), // I:
//   .DataInB  (Data_b_l ), // I:
//   .AddressA (AddressA ), // I:
//   .AddressB (rd_ram_addr_b ), // I:
//   .ClockA   (clk ), // I:
//   .ClockB   (clk ), // I:
//   .ClockEnA (1 ), // I:
//   .ClockEnB (1 ), // I:
//   .WrA      (wr_ram ), // I:
//   .WrB      (0 ), // I:
//   .ResetA   (~rst_n ), // I:
//   .ResetB   (~rst_n ), // I:
//   .QA       ( ), // O:
//   .QB       ( )  // O:
// );

reg [$clog2(N*N)-1:0]wr_AddressA;
assign AddressA =wr_ram? wr_AddressA:rd_ram_addr_a;
assign rd_ram_addr_a = j *N + k;
assign rd_ram_addr_b = k *N + i;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin wr_AddressA<='d0; end
        else begin wr_AddressA<=j *N + i; end
        end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            j <= 0; i <= 0; k <= 0;
            reg_add <='d0;
            wr_ram  <= 0;
            ram_data_in<='d0;
            done <= 0;
        end else begin
            case(state)
                IDLE: begin
                    done <= 0;
                    reg_add <='d0;
                    wr_ram  <= 0;
                    j <= 0; i <= 0; k <= 0;
                    if(start) state <= INIT_J;
                end

                INIT_J: begin
                    j <= 0;  // MATLAB j = 1 -> Verilog j=0
                    state <= INIT_I;
                end

                INIT_I: begin
                    i <= j + 1;  // MATLAB i = 1
                    state <= INIT_K;
                end

                INIT_K: begin
                    reg_add<='d0;
                    k <= 0;  // MATLAB k = 1
                    state <= WAIT_K;
                end

                BODY_K: begin
                    // 这里放置 k 循环体逻辑
                    state <= INC_K;
                    reg_add <= reg_add + {{$clog2(N){mult_data_out[WIDTH*2-1]}},mult_data_out};
                end

                INC_K: begin
                    if(k < i-1) begin
                        k <= k + 1;
                        state <= WAIT_K;
                    end else begin
                        state <= INC_I;
                    end
                end

                WAIT_K: begin
                    // 纯延迟 1 拍
                    state <= WAIT_K0;
                    
                end
               WAIT_K0: begin
                    // 纯延迟 1 拍
                    state <= BODY_K;
                    
                end
                INC_I: begin
                                wr_ram  <= 1;
                    ram_data_in <= -(reg_add>>Q);
                    if(i < N-1) begin
                        i <= i + 1;
                        state <= WAIT_I;
                    end else begin
                        state <= INC_J;
                    end
                end

                WAIT_I: begin
                    // 延迟 1 拍
                     wr_ram  <= 0;
                    state <= INIT_K;
                end

                INC_J: begin
                     wr_ram  <= 0;
                    if(j < N-1 -1) begin
                        j <= j + 1;
                        state <= WAIT_J;
                    end else begin
                        state <= DONE_STATE;
                    end
                end

                WAIT_J: begin
                    // 延迟 1 拍
                    state <= INIT_I;
                end

                DONE_STATE: begin
                    done <= 1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
mult_cal mult_cal_inst(
        .clk_i    (clk), 
        .clk_en_i (1), 
        .rst_i    (~rst_n), 
        .data_a_i (data_in_A), 
        .data_b_i (data_in_B), 
        .result_o (mult_data_out)) ;
endmodule



