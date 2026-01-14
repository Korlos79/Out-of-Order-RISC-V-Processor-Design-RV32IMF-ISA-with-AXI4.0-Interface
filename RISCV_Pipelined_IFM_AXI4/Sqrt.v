module Sqrt #(parameter XLEN=32) (
    input wire clk,
    input wire rst_n,
    input wire start,
    input wire [XLEN-1:0] A,
    
    // --- THÊM CỔNG BUSY ---
    output wire busy,             
    
    output reg done,
    output reg [XLEN-1:0] result,
    output reg exception,     // NaN or Neg Input
    output reg zero_sqrt      // Input is Zero
);

    // --- CÁC TRẠNG THÁI ---
    localparam S_IDLE  = 2'd0;
    localparam S_CALC  = 2'd1; // Tính toán lặp
    localparam S_NORM  = 2'd2; // Làm tròn & Đóng gói

    reg [1:0] state;
    reg [4:0] iter_count; // Đếm 26 vòng lặp

    // --- THÊM LOGIC BUSY ---
    // Busy = 1 khi máy trạng thái KHÔNG ở trạng thái nghỉ (IDLE)
    assign busy = (state != S_IDLE);

    // --- REGISTERS ---
    reg sign_res;
    reg [7:0] exp_res;
    
    // Các biến tạm (dùng cho logic tổ hợp bên trong always)
    reg [51:0] rem_next;
    reg [27:0] test_val; 
    reg [23:0] final_man;
    
    // Thuật toán Sqrt Integer cần thanh ghi rộng gấp đôi để dịch
    reg [25:0] q_root;    // Kết quả căn (Quotient)
    reg [51:0] rem;       // Số dư (Remainder)
    reg [51:0] rad;       // Số bị căn (Radicand) - Dịch dần ra

    // Logic giải mã đầu vào
    wire sign_a = A[31];
    wire [7:0] exp_a = A[30:23];
    wire [23:0] man_a = {|exp_a, A[22:0]}; // Hidden bit (1.xxx)

    // Kiểm tra Exponent biased có chẵn không (Unbiased sẽ lẻ)
    // Exp_a = 127 (0) -> Lẻ. Exp_a = 128 (1) -> Chẵn.
    wire exp_is_odd = (exp_a[0] == 1'b0); 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            done <= 0;
            result <= 0;
            exception <= 0; zero_sqrt <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        // 1. Kiểm tra số 0
                        if (exp_a == 0 && A[22:0] == 0) begin
                            zero_sqrt <= 1;
                            result <= {A[31], 31'd0};
                            done <= 1;
                        end
                        // 2. Kiểm tra số Âm (NaN)
                        else if (sign_a) begin
                            exception <= 1;
                            result <= 32'h7FC00000; // Quiet NaN
                            done <= 1;
                        end
                        else begin
                            sign_res <= 0; // Sqrt luôn dương
                            exception <= 0; zero_sqrt <= 0;
                            
                            // --- [ĐÃ SỬA LỖI TRÀN SỐ TẠI ĐÂY] ---
                            // Code cũ: (exp_a + 127) >> 1 -> Bị sai nếu tổng > 255
                            // Code mới: ({1'b0, exp_a} + 9'd127) >> 1 -> Ép kiểu 9-bit để giữ giá trị đúng
                            exp_res <= ({1'b0, exp_a} + 9'd127) >> 1;

                            // Chuẩn bị Mantissa (Radicand)
                            // Nếu mũ lẻ (ví dụ 2^1), ta phải căn bậc 2 của (2 * Mantissa)
                            if (exp_is_odd) 
                                rad <= {man_a, 27'b0} << 1; 
                            else 
                                rad <= {man_a, 27'b0};
                            
                            rem <= 0;
                            q_root <= 0;
                            iter_count <= 25; // Chạy 26 vòng để lấy đủ bit chính xác và round
                            state <= S_CALC;
                        end
                    end
                end

                S_CALC: begin
                    // --- THUẬT TOÁN RESTORING SQUARE ROOT ---
                    
                    // 1. Shift Radicand vào Remainder (Lấy 2 bit cao nhất)
                    rem_next = (rem << 2) | (rad[51:50]);
                    rad <= rad << 2; 

                    // 2. Test value: (4 * Root) + 1
                    test_val = {q_root, 2'b01};

                    // 3. Compare & Update
                    if (rem_next >= test_val) begin
                        rem <= rem_next - test_val;
                        q_root <= (q_root << 1) | 1'b1;
                    end else begin
                        rem <= rem_next;
                        q_root <= (q_root << 1); 
                    end

                    if (iter_count == 0) state <= S_NORM;
                    else iter_count <= iter_count - 1;
                end

                S_NORM: begin
                    // q_root format: [25:Hidden] [24..2:Mantissa] [1:Guard] [0:Round]
                    
                    // Logic làm tròn (Round to Nearest Even)
                    // Kiểm tra Guard Bit (bit 1) và (Round Bit (bit 0) hoặc Sticky Bit (|rem))
                    if (q_root[1] && (q_root[0] || (|rem))) begin
                        final_man = q_root[25:2] + 1; // Round up
                    end else begin
                        final_man = q_root[25:2];
                    end

                    // Đóng gói kết quả
                    result <= {sign_res, exp_res, final_man[22:0]};
                    done <= 1;
                    state <= S_IDLE;
                end
            endcase
        end
    end
endmodule