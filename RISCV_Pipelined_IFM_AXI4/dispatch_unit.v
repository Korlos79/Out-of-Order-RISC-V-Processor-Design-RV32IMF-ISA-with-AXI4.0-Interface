module dispatch_unit (
    // --- 1. INPUT DỮ LIỆU TỪ REGFILE & DECODE ---
    input wire [31:0] rdata1,       // Int Value
    input wire [31:0] rdata2,
    input wire [31:0] frdata1,      // Float Value
    input wire [31:0] frdata2,
    input wire [31:0] frdata3,
    
    input wire [31:0] pc,
    input wire [31:0] imm,

    // --- 2. TÍN HIỆU ĐIỀU KHIỂN ---
    input wire [1:0]  alusrc_a,     // 00: Reg, 01: PC...
    input wire [1:0]  alusrc_b,     // 00: Reg, 01: Imm...
    input wire        src1_is_float,// Để chọn rdata1 hay frdata1
    input wire        src2_is_float,
    input wire        src3_is_float,

    // --- 3. INPUT TỪ SCOREBOARD (Đã được đơn giản hóa) ---
    // Scoreboard đã tự check Int/Float dựa trên rs_addr, nên chỉ trả về 1 kết quả duy nhất
    input wire        sb_op1_ready, input wire [2:0] sb_op1_tag,
    input wire        sb_op2_ready, input wire [2:0] sb_op2_tag,
    input wire        sb_op3_ready, input wire [2:0] sb_op3_tag,

    // --- 4. OUTPUT ĐẾN RESERVATION STATION ---
    // Toán hạng 1
    output reg [31:0] disp_op1_val, 
    output reg [2:0]  disp_op1_tag, 
    output reg        disp_op1_ready,

    // Toán hạng 2
    output reg [31:0] disp_op2_val,
    output reg [2:0]  disp_op2_tag,
    output reg        disp_op2_ready,
    
    // Toán hạng 3 (FMA)
    output reg [31:0] disp_op3_val,
    output reg [2:0]  disp_op3_tag,
    output reg        disp_op3_ready
);

    // ============================================================
    // LOGIC TOÁN HẠNG 1
    // ============================================================
    always @(*) begin
        case (alusrc_a)
            2'b00: begin // Chọn Register
                // 1. Chọn giá trị (Value Mux)
                reg [31:0] val_mux;
                if (src1_is_float) val_mux = frdata1;
                else               val_mux = rdata1;

                // 2. Kiểm tra trạng thái từ Scoreboard
                if (sb_op1_ready) begin
                    disp_op1_val   = val_mux;    // Lấy giá trị thực
                    disp_op1_ready = 1'b1;       // Đánh dấu có sẵn
                    disp_op1_tag   = 3'b0;
                end else begin
                    disp_op1_val   = 32'd0;
                    disp_op1_ready = 1'b0;       // Phải chờ
                    disp_op1_tag   = sb_op1_tag; // Lưu thẻ bài
                end
            end
            
            2'b01: begin // Chọn PC
                disp_op1_val   = pc;
                disp_op1_ready = 1'b1;
                disp_op1_tag   = 3'b0;
            end
            
            default: begin
                disp_op1_val   = 32'd0;
                disp_op1_ready = 1'b1;
                disp_op1_tag   = 3'b0;
            end
        endcase
    end

    // ============================================================
    // LOGIC TOÁN HẠNG 2
    // ============================================================
    always @(*) begin
        case (alusrc_b)
            2'b00: begin // Chọn Register
                // 1. Chọn giá trị
                reg [31:0] val_mux;
                if (src2_is_float) val_mux = frdata2;
                else               val_mux = rdata2;

                // 2. Kiểm tra trạng thái
                if (sb_op2_ready) begin
                    disp_op2_val   = val_mux;
                    disp_op2_ready = 1'b1;
                    disp_op2_tag   = 3'b0;
                end else begin
                    disp_op2_val   = 32'd0;
                    disp_op2_ready = 1'b0;
                    disp_op2_tag   = sb_op2_tag;
                end
            end
            
            2'b01: begin // Chọn Immediate
                disp_op2_val   = imm;
                disp_op2_ready = 1'b1;
                disp_op2_tag   = 3'b0;
            end
            
            2'b10: begin // Chọn Constant 4
                disp_op2_val   = 32'd4;
                disp_op2_ready = 1'b1;
                disp_op2_tag   = 3'b0;
            end

            default: begin
                disp_op2_val   = 32'd0;
                disp_op2_ready = 1'b1;
                disp_op2_tag   = 3'b0;
            end
        endcase
    end

    // ============================================================
    // LOGIC TOÁN HẠNG 3 (Chỉ Float Register cho FMA)
    // ============================================================
    always @(*) begin
        if (src3_is_float) begin
            if (sb_op3_ready) begin
                disp_op3_val   = frdata3;
                disp_op3_ready = 1'b1;
                disp_op3_tag   = 3'b0;
            end else begin
                disp_op3_val   = 32'd0;
                disp_op3_ready = 1'b0;
                disp_op3_tag   = sb_op3_tag;
            end
        end else begin
            // Không dùng toán hạng 3
            disp_op3_val   = 32'd0;
            disp_op3_ready = 1'b1;
            disp_op3_tag   = 3'b0;
        end
    end

endmodule