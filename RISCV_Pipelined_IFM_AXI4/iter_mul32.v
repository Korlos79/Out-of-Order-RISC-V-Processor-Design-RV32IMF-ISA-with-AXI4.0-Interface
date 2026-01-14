module iter_mul32 (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        start,       // Tín hiệu valid đầu vào
    input  wire [4:0]  op_sel,      // 10000->10011

    input  wire [31:0] rs1,
    input  wire [31:0] rs2,

    output wire        busy,        // Luôn bằng 0 vì pipeline nhận lệnh liên tục
    output reg         done,        // Valid đầu ra
    output reg  [31:0] result
);

    // Opcodes Definition
    localparam OP_MUL    = 5'b10000;
    localparam OP_MULH   = 5'b10001;
    localparam OP_MULHSU = 5'b10010;
    localparam OP_MULHU  = 5'b10011;

    // Trong kiến trúc Pipeline hoàn toàn, ta có thể nhận lệnh mới mỗi chu kì.
    // Do đó busy luôn thấp (hoặc chỉ cao khi bị stall từ bên ngoài, ở đây ta ko xét).
    assign busy = 1'b0; 

    // =========================================================================
    // STAGE 1: DECODE & ABSOLUTE VALUE (Chuẩn bị toán hạng)
    // =========================================================================
    reg        s1_valid;
    reg        s1_want_high;
    reg        s1_neg_res;      // Dấu của kết quả cuối cùng
    reg [31:0] s1_abs_a;
    reg [31:0] s1_abs_b;
	 reg is_a_signed, is_b_signed;
	 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s1_valid <= 0;
            s1_want_high <= 0; s1_neg_res <= 0; s1_abs_a <= 0; s1_abs_b <= 0;
        end else begin
            s1_valid <= start;

            // 1. Giải mã Opcode
            // Signed A: MULH, MULHSU
            // Signed B: MULH
            // (MUL thường ta coi như unsigned hoặc signed đều ra 32-bit thấp giống nhau)
            
            // Logic xác định dấu
            is_a_signed = (op_sel == OP_MULH) | (op_sel == OP_MULHSU);
            is_b_signed = (op_sel == OP_MULH);

            s1_want_high <= (op_sel != OP_MUL);

            // 2. Tính trị tuyệt đối (ABS)
            // Nếu là số có dấu và bit dấu = 1 thì lấy bù 2, ngược lại giữ nguyên
            if (is_a_signed && rs1[31]) 
                s1_abs_a <= (~rs1 + 1);
            else 
                s1_abs_a <= rs1;

            if (is_b_signed && rs2[31]) 
                s1_abs_b <= (~rs2 + 1);
            else 
                s1_abs_b <= rs2;

            // 3. Tính dấu kết quả
            // Kết quả âm nếu (A âm XOR B âm)
            s1_neg_res <= (is_a_signed & rs1[31]) ^ (is_b_signed & rs2[31]);
        end
    end

    // =========================================================================
    // STAGE 2: MULTIPLICATION PART 1 (Tính tích 64-bit)
    // =========================================================================
    // Dùng toán tử *, tools sẽ map vào DSP. 
    // Ta tách ra register để đảm bảo timing.
    reg        s2_valid;
    reg        s2_want_high;
    reg        s2_neg_res;
    reg [63:0] s2_product_raw;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s2_valid <= 0;
            s2_want_high <= 0; s2_neg_res <= 0; s2_product_raw <= 0;
        end else begin
            s2_valid <= s1_valid;
            s2_want_high <= s1_want_high;
            s2_neg_res   <= s1_neg_res;

            // Nhân 2 số dương 32-bit -> Kết quả 64-bit
            s2_product_raw <= s1_abs_a * s1_abs_b;
        end
    end

    // =========================================================================
    // STAGE 3: BUFFER / DELAY (Giữ nhịp pipeline 4 chu kì)
    // =========================================================================
    // Nếu nhân 64-bit quá chậm, Stage 2 và Stage 3 có thể được synthesis 
    // gộp lại thành DSP có pipeline nội bộ (M-REG).
    reg        s3_valid;
    reg        s3_want_high;
    reg        s3_neg_res;
    reg [63:0] s3_product;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s3_valid <= 0;
            s3_want_high <= 0; s3_neg_res <= 0; s3_product <= 0;
        end else begin
            s3_valid <= s2_valid;
            s3_want_high <= s2_want_high;
            s3_neg_res   <= s2_neg_res;
            s3_product   <= s2_product_raw;
        end
    end

    // =========================================================================
    // STAGE 4: FINALIZE (Xử lý dấu & Chọn kết quả)
    // =========================================================================
    reg [63:0] final_product;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            done <= 0;
            result <= 0;
        end else begin
            done <= s3_valid;

            // 1. Áp lại dấu (nếu cần thiết)
            // Nếu kết quả cần là số âm, lấy bù 2 của tích dương
            if (s3_neg_res) 
                final_product = ~s3_product + 64'd1;
            else 
                final_product = s3_product;

            // 2. Chọn Low (32 bit thấp) hay High (32 bit cao)
            if (s3_want_high)
                result <= final_product[63:32]; // MULH, MULHSU, MULHU
            else
                result <= final_product[31:0];  // MUL
        end
    end

endmodule