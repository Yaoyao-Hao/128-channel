module myLDL_ram #(
    parameter N = 3,              // 矩阵大小
    parameter Q = 24,             // 定点小数位
    parameter WIDTH = 32          // 数据宽度
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    //input  wire signed [WIDTH-1:0] A [0:N-1][0:N-1], // 输入矩阵 (Q 格式)
    output reg[WIDTH-1:0]D_ram_data,
    input div_finish,
    output reg div_cal,
    output wire [WIDTH-1:0]div_data,
    output wire [WIDTH-1:0]A_in,
    output wire [WIDTH-1:0]cal_data,
    input  wire [WIDTH-1:0]  Q_data_a_l,   Q_data_b_l,       Q_data_d  , 
    output reg [7:0] k, i, j_cnt,
    output reg [5:0] state,
    output reg done
    // output reg signed [WIDTH-1:0] L [0:N-1][0:N-1],  // L (Q 格式)
    // output reg signed [WIDTH-1:0] D [0:N-1]          // D (Q 格式, 对角)
);

    // ---------------- 状态机定义 ----------------
    localparam IDLE       = 0,
               STEP_K     = 1,
               STEP_K0    = 18,
               LOOP_J0    = 2,   // 计算 L(k,j)^2
               LOOP_J1    = 3,   // >>> Q
               LOOP_J2    = 4,   // * D(j)
               LOOP_J3    = 5,   // >>> Q
               LOOP_NEXT  = 6,   // sumVal 累加
               SAVE_D     = 7,   // 保存 D(k,k)
               STEP_I     = 8,
               STEP_I0    = 17,
               LOOP2_0    = 9,   // L(i,j)*L(k,j)
               LOOP2_1    = 10,  // >>> Q
               LOOP2_2    = 11,  // * D(j)
               LOOP2_3    = 12,  // >>> Q
               LOOP2_NEXT = 13,  // sumVal 累加
               SAVE_L     = 14,
               NEXT_K     = 15,
               FINISH     = 16;

   // reg [4:0] state;
    // reg [7:0] k, i, j_cnt;
    reg signed [WIDTH-1:0] sumVal;
    reg signed [WIDTH*2-1:0] stage_reg;

wire signed [WIDTH*2-1:0]mult_data_out;
reg  [$clog2(N*N)-1:0]Address_a_l ,Address_b_l;
// reg signed [WIDTH-1:0]L_D_ij,L_D_kj;
// wire signed [WIDTH-1:0]D_k;
// assign D_k = D[k];
// always @(*) begin
//     case(state)
//     LOOP_J0: begin  L_D_ij  = L[k][j_cnt];   L_D_kj = L[k][j_cnt]; end 
//     LOOP2_0: begin  L_D_ij  = L[i][j_cnt];   L_D_kj = L[k][j_cnt]; end 
//     endcase
// end

 // ---------------- 主状态机 ----------------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            state <= IDLE;
            k <= 0;
            i <= 0;
            j_cnt <= 0;
            sumVal <= 0;
            done <= 0;
            div_cal <= 0;
            D_ram_data <='d0;
        end else begin
            case(state)

                // 初始化
                IDLE: begin
                    D_ram_data<=D_ram_data;
                    div_cal <= 0;
                    if(start) begin
                        
                        // integer r, c;
                        // for(r=0; r<N; r=r+1) begin
                        //     for(c=0; c<N; c=c+1) begin
                        //         if(r==c) 
                        //             L[r][c] <= (1<<<Q); // 单位阵
                        //         else
                        //             L[r][c] <= 0;
                        //     end
                        //     D[r] <= 0;
                        // end
                        k <= 0;
                        done <= 0;
                        state <= STEP_K;
                    end
                end

                // ---------------- 计算 D(k,k) ----------------
                STEP_K: begin
                    if(k < N) begin
                        sumVal <= 0;
                        j_cnt <= 0;
                        state <= STEP_K0;
                    end else begin
                        state <= FINISH;
                    end
                end
                STEP_K0:begin
                   state <= LOOP_J0;
                 end
                LOOP_J0: begin
                    if(j_cnt < k) begin
                        stage_reg <= Q_data_a_l * Q_data_b_l;
                        state <= LOOP_J1;
                    end else begin
                        state <= SAVE_D;
                    end
                end

                LOOP_J1: begin
                    stage_reg <= mult_data_out >>> Q;
                    state <= LOOP_J2;
                end

                LOOP_J2: begin
                    stage_reg <= stage_reg * Q_data_d;
                    state <= LOOP_J3;
                end

                LOOP_J3: begin
                    stage_reg <= stage_reg >>> Q;
                    state <= LOOP_NEXT;
                end

                LOOP_NEXT: begin
                    sumVal <= sumVal + stage_reg[WIDTH-1:0];
                    j_cnt <= j_cnt + 1;
                    state <= LOOP_J0;

                end

                SAVE_D: begin
                    //D[k] <= A[k][k] - sumVal;
                    D_ram_data <= A_in - sumVal;
                    i <= k+1;
                    state <= STEP_I;
                end

                // ---------------- 计算 L(i,k) ----------------
                STEP_I: begin
                    if(i < N) begin
                        sumVal <= 0;
                        j_cnt <= 0;
                        state <= STEP_I0;
                    end else begin
                        state <= NEXT_K;
                    end
                end
                STEP_I0 : begin state<=LOOP2_0;  end
                LOOP2_0: begin
                    if(j_cnt < k) begin
                        stage_reg <=  Q_data_a_l * Q_data_b_l;
                        state <= LOOP2_1;
                        div_cal <= 0;
                    end else begin
                        state <= SAVE_L;
                        div_cal <= 1;
                    end
                end

                LOOP2_1: begin
                    stage_reg <= mult_data_out >>> Q;
                    state <= LOOP2_2;
                end

                LOOP2_2: begin
                    stage_reg <= stage_reg * Q_data_d;
                    state <= LOOP2_3;
                end

                LOOP2_3: begin
                    stage_reg <= stage_reg >>> Q;
                    state <= LOOP2_NEXT;
                end

                LOOP2_NEXT: begin
                    sumVal <= sumVal + stage_reg[WIDTH-1:0];
                    j_cnt <= j_cnt + 1;
                    state <= LOOP2_0;
                end

                SAVE_L: begin
                    div_cal <= 0;
                    // L(i,k) = ((A(i,k) - sumVal)<<Q) / D(k)
                    //L[i][k] <= ((A[i][k] - sumVal) <<< Q) / Q_data_d;
                    
                    if(div_finish) begin 
                    state <= STEP_I;
                    i <= i+1;    
                    end
                    else begin 
                    state <= SAVE_L;    
                    i <= i;
                    end
                end

                NEXT_K: begin
                    k <= k+1;
                    state <= STEP_K;
                end

                FINISH: begin
                    done <= 1;
                    state <= IDLE;
                end

            endcase
        end
    end

//assign cal_data = ((A[i][k] - sumVal) <<< Q) /Q_data_d;

assign div_data =div_cal? ((A_in - sumVal) <<< Q):div_data;
mult_cal mult_cal_inst(
        .clk_i    (clk), 
        .clk_en_i (1), 
        .rst_i    (~rst_n), 
        .data_a_i (Q_data_a_l), 
        .data_b_i (Q_data_b_l), 
        .result_o (mult_data_out)) ;


endmodule
