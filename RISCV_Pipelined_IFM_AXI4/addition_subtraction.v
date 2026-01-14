module addition_subtraction(
    input wire clk,             
    input wire rst_n,           
    input wire start,           
    input wire [31:0] a_operand,
    input wire [31:0] b_operand,
    input wire AddBar_Sub,      
    output reg Exception,
    output reg [31:0] result,
	 output wire busy,   
    output reg done             
);

    // =========================================================================
    // STAGE 1: ALIGNMENT (SO SÁNH, HOÁN ĐỔI, DỊCH BIT)
    // =========================================================================
    reg s1_valid;
    reg s1_sign_final;
    reg s1_is_sub_op;
    reg [7:0] s1_exp_common;
    reg [26:0] s1_man_large;    
    reg [26:0] s1_man_small;
    reg s1_exception;

	 assign busy = 1'b0;
	 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 0;
            s1_sign_final <= 0; s1_is_sub_op <= 0; s1_exp_common <= 0;
            s1_man_large <= 0; s1_man_small <= 0; s1_exception <= 0;
        end else begin
            s1_valid <= start;
            s1_exception <= (&a_operand[30:23]) | (&b_operand[30:23]);

            if (a_operand[30:0] < b_operand[30:0]) begin
                s1_exp_common <= b_operand[30:23];
                s1_sign_final <= AddBar_Sub ? !b_operand[31] : b_operand[31]; 
                s1_is_sub_op <= AddBar_Sub ? ~(a_operand[31] ^ b_operand[31]) : (a_operand[31] ^ b_operand[31]);
                s1_man_large <= { (|b_operand[30:23]), b_operand[22:0], 3'b0 };
                s1_man_small <= { (|a_operand[30:23]), a_operand[22:0], 3'b0 } >> (b_operand[30:23] - a_operand[30:23]);
            end else begin
                s1_exp_common <= a_operand[30:23];
                s1_sign_final <= a_operand[31];
                // SỬA LỖI LOGIC: Đã đảo ngược lại logic cho khớp với nhánh if ở trên
                s1_is_sub_op <= AddBar_Sub ? ~(a_operand[31] ^ b_operand[31]) : (a_operand[31] ^ b_operand[31]);
                s1_man_large <= { (|a_operand[30:23]), a_operand[22:0], 3'b0 };
                s1_man_small <= { (|b_operand[30:23]), b_operand[22:0], 3'b0 } >> (a_operand[30:23] - b_operand[30:23]);
            end
        end
    end

    // =========================================================================
    // STAGE 2: ARITHMETIC (CỘNG HOẶC TRỪ MANTISSA)
    // =========================================================================
    reg s2_valid;
    reg [27:0] s2_sum;  
    reg [7:0]  s2_exp;
    reg        s2_sign;
    reg        s2_exception;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_valid <= 0;
            s2_sum <= 0; s2_exp <= 0; s2_sign <= 0; s2_exception <= 0;
        end else begin
            s2_valid <= s1_valid;
            s2_exp       <= s1_exp_common;
            s2_sign      <= s1_sign_final;
            s2_exception <= s1_exception;

            if (s1_is_sub_op) begin
                s2_sum <= s1_man_large - s1_man_small;
            end else begin
                s2_sum <= s1_man_large + s1_man_small;
            end
        end
    end

    // =========================================================================
    // STAGE 3: NORMALIZATION (CHUẨN HÓA & ĐÓNG GÓI)
    // =========================================================================
    reg [4:0] leading_zeros;
    
    // Priority Encoder
    always @(*) begin
        if      (s2_sum[26]) leading_zeros = 0;
        else if (s2_sum[25]) leading_zeros = 1;
        else if (s2_sum[24]) leading_zeros = 2;
        else if (s2_sum[23]) leading_zeros = 3;
        else if (s2_sum[22]) leading_zeros = 4;
        else if (s2_sum[21]) leading_zeros = 5;
        else if (s2_sum[20]) leading_zeros = 6;
        else if (s2_sum[19]) leading_zeros = 7;
        else if (s2_sum[18]) leading_zeros = 8;
        else if (s2_sum[17]) leading_zeros = 9;
        else if (s2_sum[16]) leading_zeros = 10;
        else if (s2_sum[15]) leading_zeros = 11;
        else if (s2_sum[14]) leading_zeros = 12;
        else if (s2_sum[13]) leading_zeros = 13;
        else if (s2_sum[12]) leading_zeros = 14;
        else if (s2_sum[11]) leading_zeros = 15;
        else if (s2_sum[10]) leading_zeros = 16;
        else if (s2_sum[9])  leading_zeros = 17;
        else if (s2_sum[8])  leading_zeros = 18;
        else if (s2_sum[7])  leading_zeros = 19;
        else if (s2_sum[6])  leading_zeros = 20;
        else if (s2_sum[5])  leading_zeros = 21;
        else if (s2_sum[4])  leading_zeros = 22;
        else if (s2_sum[3])  leading_zeros = 23;
        else                 leading_zeros = 24; 
    end

    // Biến tạm để xử lý shift
    reg [27:0] shifted_sum;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 0;          
            result <= 0;
            Exception <= 0;
            shifted_sum <= 0;
        end else begin
            done <= s2_valid;
            Exception <= s2_exception;

            if (s2_exception) begin
                result <= 32'd0; 
            end else if (s2_sum == 0) begin
                result <= {s2_sign, 31'd0};
            end else if (s2_sum[27]) begin
                // TRƯỜNG HỢP TRÀN (1x.xxxxx) -> Dịch phải
                // Mantissa mới: Bỏ bit 27 (Hidden), lấy từ 26 xuống 4
                result <= {s2_sign, s2_exp + 8'd1, s2_sum[26:4]};
            end else begin
                // TRƯỜNG HỢP THƯỜNG / CẦN CHUẨN HÓA
                if (s2_exp > leading_zeros) begin
                    // Dịch trái để đưa bit 1 về vị trí Hidden (bit 26)
                    shifted_sum = s2_sum << leading_zeros;
                    // Mantissa mới: Bỏ bit 26 (Hidden), lấy từ 25 xuống 3
                    result <= {s2_sign, s2_exp - {3'b0, leading_zeros}, shifted_sum[25:3]}; 
                end else begin
                    // Underflow
                    result <= {s2_sign, 31'd0}; 
                end
            end
        end
    end

endmodule