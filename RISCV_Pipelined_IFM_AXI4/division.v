module division #(parameter XLEN=32) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [XLEN-1:0] A,
    input wire [XLEN-1:0] B,
    
    // --- THÊM CỔNG BUSY Ở ĐÂY ---
    output wire busy,             
    
    output reg done,
    output reg [XLEN-1:0] result,
    output reg zero_division,
    output reg Overflow,
    output reg Underflow
);

    // --- CÁC TRẠNG THÁI FSM ---
    localparam S_IDLE      = 3'd0;
    localparam S_PRE_CALC  = 3'd1; 
    localparam S_DIVIDE    = 3'd2; 
    localparam S_NORM      = 3'd3; 
    localparam S_PACK      = 3'd4; 

    reg [2:0] state;
    reg [3:0] iter_count; 

    // --- THÊM LOGIC BUSY Ở ĐÂY ---
    // Busy = 1 khi máy trạng thái KHÔNG ở trạng thái nghỉ (IDLE)
    assign busy = (state != S_IDLE);

    // --- THANH GHI DỮ LIỆU ---
    reg sign_res;
    reg [9:0] exp_res;      
    reg [23:0] divisor;     
    reg [25:0] divisor_x3; 
    
    reg [54:0] remainder;   
    reg [27:0] quotient;    

    reg [23:0] final_man;
    reg        guard_bit, round_bit, sticky_bit;
    reg        round_up;
    
    // --- LOGIC GIẢI MÃ ---
    wire sign_a = A[31];
    wire sign_b = B[31];
    wire [7:0] exp_a = A[30:23];
    wire [7:0] exp_b = B[30:23];
    wire [23:0] man_a = {|exp_a, A[22:0]}; // Hidden bit
    wire [23:0] man_b = {|exp_b, B[22:0]};

    // --- SỬA LỖI 1: Căn chỉnh chính xác 55-bit ---
    wire [54:0] cmp_3d = {2'b0, divisor_x3, 27'd0};      
    wire [54:0] cmp_2d = {3'b0, divisor, 1'b0, 27'd0};   
    wire [54:0] cmp_1d = {4'b0, divisor, 27'd0};         

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            done <= 0;
            result <= 0;
            zero_division <= 0; Overflow <= 0; Underflow <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        if (exp_b == 0 && B[22:0] == 0) begin
                            zero_division <= 1;
                            result <= {sign_a ^ sign_b, 8'hFF, 23'd0}; // Inf
                            done <= 1;
                        end 
                        else if (exp_a == 0 && A[22:0] == 0) begin
                            result <= {sign_a ^ sign_b, 31'd0}; // Zero
                            done <= 1;
                        end 
                        else begin
                            sign_res <= sign_a ^ sign_b;
                            exp_res <= {2'b0, exp_a} - {2'b0, exp_b} + 10'd127;
                            
                            divisor <= man_b;
                            // SỬA LỖI 1: Init Remainder căn chỉnh với cmp_1d
                            remainder <= {4'b0, man_a, 27'd0}; 
                            quotient <= 0;
                            
                            zero_division <= 0; Overflow <= 0; Underflow <= 0;
                            state <= S_PRE_CALC;
                        end
                    end
                end

                S_PRE_CALC: begin
                    // 3 * D = (D << 1) + D
                    divisor_x3 <= {divisor, 1'b0} + divisor;
                    iter_count <= 13; // 14 vòng lặp (lấy 28 bit)
                    state <= S_DIVIDE;
                end

                S_DIVIDE: begin
                    // Radix-4 Logic
                    if (remainder >= cmp_3d) begin
                        quotient <= {quotient[25:0], 2'b11};
                        remainder <= (remainder - cmp_3d) << 2; 
                    end
                    else if (remainder >= cmp_2d) begin
                        quotient <= {quotient[25:0], 2'b10};
                        remainder <= (remainder - cmp_2d) << 2;
                    end
                    else if (remainder >= cmp_1d) begin
                        quotient <= {quotient[25:0], 2'b01};
                        remainder <= (remainder - cmp_1d) << 2;
                    end
                    else begin
                        quotient <= {quotient[25:0], 2'b00};
                        remainder <= remainder << 2;
                    end

                    if (iter_count == 0) state <= S_NORM;
                    else iter_count <= iter_count - 1;
                end

                S_NORM: begin
                    // SỬA LỖI 2: Logic chuẩn hóa Mantissa
                    if (quotient[26]) begin 
                        final_man = quotient[26:3];
                        guard_bit = quotient[2];
                        round_bit = quotient[1];
                        sticky_bit = quotient[0] | (|remainder);
                    end else begin
                        exp_res = exp_res - 1;
                        final_man = quotient[25:2];
                        guard_bit = quotient[1];
                        round_bit = quotient[0];
                        sticky_bit = |remainder; 
                    end

                    // Round to Nearest Even
                    round_up = (guard_bit && (round_bit || sticky_bit || final_man[0]));
                    
                    if (round_up) begin
                        final_man = final_man + 1;
                        if (final_man == 0) begin 
                             exp_res = exp_res + 1;
                             final_man = 24'h800000; 
                        end
                    end

                    // Exception Check
                    if ($signed(exp_res) >= 255) begin
                        Overflow <= 1;
                        result <= {sign_res, 8'hFF, 23'd0}; 
                    end else if ($signed(exp_res) <= 0) begin
                        Underflow <= 1;
                        result <= {sign_res, 31'd0}; 
                    end else begin
                        result <= {sign_res, exp_res[7:0], final_man[22:0]};
                    end
                    
                    state <= S_PACK;
                end

                S_PACK: begin
                    done <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule