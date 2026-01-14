module multiplication (
    input wire clk,
    input wire rst_n,
    input wire start, 
    input wire [31:0] a_in,
    input wire [31:0] b_in,
    
    output reg [31:0] result,
    output wire busy,      // Sửa thành wire
    output reg done,       // Chỉ gán ở Stage 4
    output reg Exception
);

    // Pipeline luôn sẵn sàng nhận lệnh mới -> Busy luôn bằng 0
    assign busy = 1'b0;

    // --- FUNCTION: Partial Product Sum ---
    function [47:0] calc_partial_sum;
        input [23:0] operand_a;
        input [11:0] operand_b_part;
        integer i;
        begin
            calc_partial_sum = 48'd0;
            for (i = 0; i < 12; i = i + 1) begin
                if (operand_b_part[i]) begin
                    calc_partial_sum = calc_partial_sum + (operand_a << i);
                end
            end
        end
    endfunction

    // =========================================================================
    // STAGE 1: DECODE & PRE-CALC (1 Cycle)
    // =========================================================================
    reg s1_valid;
    reg s1_sign;
    reg signed [9:0] s1_exp;
    reg [23:0] s1_man_a, s1_man_b;
    reg s1_is_zero;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 0;
            s1_sign <= 0; s1_exp <= 0; s1_man_a <= 0; s1_man_b <= 0; s1_is_zero <= 0;
        end else begin
            s1_valid <= start; // Nhận tín hiệu start
            
            s1_sign <= a_in[31] ^ b_in[31];
            s1_exp <= {2'b0, a_in[30:23]} + {2'b0, b_in[30:23]} - 10'd127;
            s1_man_a <= {|a_in[30:23], a_in[22:0]};
            s1_man_b <= {|b_in[30:23], b_in[22:0]};

            if (a_in[30:0] == 0 || b_in[30:0] == 0) 
                s1_is_zero <= 1;
            else 
                s1_is_zero <= 0;
        end
    end

    // =========================================================================
    // STAGE 2: MULTIPLY SPLIT (1 Cycle)
    // =========================================================================
    reg s2_valid;
    reg s2_sign;
    reg signed [9:0] s2_exp;
    reg [47:0] s2_prod_low;
    reg [47:0] s2_prod_high;
    reg s2_is_zero;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_valid <= 0;
            s2_sign <= 0; s2_exp <= 0; 
            s2_prod_low <= 0; s2_prod_high <= 0; s2_is_zero <= 0;
        end else begin
            s2_valid <= s1_valid; // Truyền valid từ S1 sang S2
            
            s2_sign <= s1_sign;
            s2_exp  <= s1_exp;
            s2_is_zero <= s1_is_zero;
            s2_prod_low  <= calc_partial_sum(s1_man_a, s1_man_b[11:0]);
            s2_prod_high <= calc_partial_sum(s1_man_a, s1_man_b[23:12]);
        end
    end

    // =========================================================================
    // STAGE 3: MERGE SUM (1 Cycle)
    // =========================================================================
    reg s3_valid;
    reg s3_sign;
    reg signed [9:0] s3_exp;
    reg [47:0] s3_prod_final;
    reg s3_is_zero;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s3_valid <= 0;
            s3_sign <= 0; s3_exp <= 0; s3_prod_final <= 0; s3_is_zero <= 0;
        end else begin
            s3_valid <= s2_valid; // Truyền valid từ S2 sang S3
            
            s3_sign  <= s2_sign;
            s3_exp   <= s2_exp;
            s3_is_zero <= s2_is_zero;
            s3_prod_final <= (s2_prod_high << 12) + s2_prod_low;
        end
    end

    // =========================================================================
    // STAGE 4: NORMALIZE & ROUNDING (1 Cycle)
    // =========================================================================
    reg [23:0] t_norm_mantissa;
    reg        t_guard, t_round, t_sticky, t_round_up;
    reg [24:0] t_rounded_mantissa;
    reg signed [9:0] t_final_exp;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 0;
            result <= 0;
            Exception <= 0;
        end else begin
            // DONE chỉ được gán ở đây
            done <= s3_valid; // Nếu S3 có dữ liệu hợp lệ thì S4 xong việc (Done)

            if (s3_is_zero) begin
                result <= {s3_sign, 31'd0};
                Exception <= 0;
            end else begin
                // ... (Giữ nguyên logic tính toán của bạn) ...
                if (s3_prod_final[47]) begin
                    t_final_exp     = s3_exp + 1;
                    t_norm_mantissa = s3_prod_final[47:24];
                    t_guard         = s3_prod_final[23];
                    t_round         = s3_prod_final[22];
                    t_sticky        = |s3_prod_final[21:0];
                end else begin
                    t_final_exp     = s3_exp;
                    t_norm_mantissa = s3_prod_final[46:23];
                    t_guard         = s3_prod_final[22];
                    t_round         = s3_prod_final[21];
                    t_sticky        = |s3_prod_final[20:0];
                end

                if (t_guard && (t_round || t_sticky || t_norm_mantissa[0]))
                    t_round_up = 1'b1;
                else
                    t_round_up = 1'b0;

                t_rounded_mantissa = {1'b0, t_norm_mantissa} + t_round_up;

                if (t_rounded_mantissa[24]) begin
                    t_final_exp = t_final_exp + 1;
                    t_rounded_mantissa = t_rounded_mantissa >> 1;
                end

                if (t_final_exp >= 255) begin
                    result <= {s3_sign, 8'hFF, 23'd0};
                    Exception <= 1;
                end else if (t_final_exp <= 0) begin
                    result <= {s3_sign, 31'd0};
                    Exception <= 1; 
                end else begin
                    result <= {s3_sign, t_final_exp[7:0], t_rounded_mantissa[22:0]};
                    Exception <= 0;
                end
            end
        end
    end

endmodule