module scoreboard (
    input wire clk,
    input wire rst_n,

    // =================================================================
    // 1. GIAO DIỆN VỚI DISPATCHER (Giai đoạn Issue)
    // =================================================================
    // Khi Decode giải mã xong lệnh, nó hỏi Scoreboard: "Tôi gửi lệnh này đi được không?"
    input  wire       issue_valid,       // Decode báo có lệnh mới
    input  wire [4:0] issue_rd,          // Thanh ghi đích lệnh muốn ghi
    input  wire       issue_rd_is_float, // 1: Float reg (f0-f31), 0: Int reg (x0-x31)
    input  wire [2:0] issue_fu_id,       // ID của Unit sẽ thực thi (ALU=0, MUL=1, LSU=2...)
    
    output reg        can_issue,         // Scoreboard trả lời: 1=Được, 0=Dừng (Stall do WAW)

    // =================================================================
    // 2. GIAO DIỆN KIỂM TRA TOÁN HẠNG (Read Operands)
    // =================================================================
    // Dispatcher hỏi: "Dữ liệu nguồn RS1, RS2 đang ở đâu?"
    
    // Kiểm tra RS1
    input  wire [4:0] rs1,
    input  wire       rs1_is_float,
    output reg        rs1_ready,         // 1: Có sẵn trong RegFile, 0: Đang bận (đợi tính toán)
    output reg  [2:0] rs1_tag,           // Nếu bận, thì đang đợi FU nào (Tag)?

    // Kiểm tra RS2
    input  wire [4:0] rs2,
    input  wire       rs2_is_float,
    output reg        rs2_ready,
    output reg  [2:0] rs2_tag,

    // Kiểm tra RS3 (Cho lệnh FMA 3 ngôi)
    input  wire [4:0] rs3,
    input  wire       rs3_is_float,
    output reg        rs3_ready,
    output reg  [2:0] rs3_tag,

    // =================================================================
    // 3. GIAO DIỆN VỚI CDB (Writeback / Broadcast)
    // =================================================================
    // Khi các Unit (ALU, MUL...) tính xong, nó báo về đây để giải phóng thanh ghi
    input  wire       cdb_valid,
    input  wire [4:0] cdb_rd,            // Thanh ghi vừa được cập nhật
    input  wire       cdb_rd_is_float,
    input  wire [2:0] cdb_source_fu      // Ai vừa tính xong?
);

    // --- CẤU TRÚC DỮ LIỆU ---
    // Bảng trạng thái BUSY: 1 bit cho mỗi thanh ghi
    reg [31:0] int_busy;   // x0-x31
    reg [31:0] float_busy; // f0-f31
    
    // Bảng TAG: Lưu ID của FU đang chiếm giữ thanh ghi đó
    reg [2:0] int_tag   [31:0];
    reg [2:0] float_tag [31:0];

    // --- LOGIC 1: ISSUE CHECK (Kiểm tra xung đột WAW) ---
    // Nếu thanh ghi đích đang bận -> Không cho Issue lệnh mới vào đè lên (tránh sai thứ tự)
    // (Trong CPU xịn dùng Register Renaming để bỏ qua bước này, nhưng Scoreboard cơ bản thì cần)
    always @(*) begin
        if (issue_rd == 0 && !issue_rd_is_float) begin
            can_issue = 1'b1; // Ghi vào x0 luôn OK
        end else begin
            if (issue_rd_is_float)
                can_issue = ~float_busy[issue_rd];
            else
                can_issue = ~int_busy[issue_rd];
        end
    end

    // --- LOGIC 2: READ OPERANDS (Kiểm tra RAW) ---
    // Trả lời xem nguồn đang Rảnh hay Bận
    
    // RS1
    always @(*) begin
        if (!rs1_is_float && rs1 == 0) begin
            rs1_ready = 1; rs1_tag = 0; // x0 luôn sẵn sàng
        end else if (rs1_is_float) begin
            rs1_ready = ~float_busy[rs1];
            rs1_tag   = float_tag[rs1];
        end else begin
            rs1_ready = ~int_busy[rs1];
            rs1_tag   = int_tag[rs1];
        end
    end

    // RS2 (Tương tự)
    always @(*) begin
        if (!rs2_is_float && rs2 == 0) begin
            rs2_ready = 1; rs2_tag = 0;
        end else if (rs2_is_float) begin
            rs2_ready = ~float_busy[rs2];
            rs2_tag   = float_tag[rs2];
        end else begin
            rs2_ready = ~int_busy[rs2];
            rs2_tag   = int_tag[rs2];
        end
    end

    // RS3 (Tương tự)
    always @(*) begin
        if (rs3_is_float) begin
            rs3_ready = ~float_busy[rs3];
            rs3_tag   = float_tag[rs3];
        end else begin
            // Ít khi dùng RS3 Integer, nhưng cứ để logic tương tự
            rs3_ready = (rs3 == 0) ? 1 : ~int_busy[rs3];
            rs3_tag   = int_tag[rs3];
        end
    end

    // --- LOGIC 3: UPDATE STATUS (Sequential) ---
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            int_busy   <= 0;
            float_busy <= 0;
            for (i=0; i<32; i=i+1) begin
                int_tag[i]   <= 0;
                float_tag[i] <= 0;
            end
        end else begin
            
            // A. KHI ISSUE THÀNH CÔNG -> Đánh dấu BẬN
            if (issue_valid && can_issue) begin
                if (issue_rd_is_float) begin
                    float_busy[issue_rd] <= 1'b1;
                    float_tag[issue_rd]  <= issue_fu_id;
                end else if (issue_rd != 0) begin
                    int_busy[issue_rd] <= 1'b1;
                    int_tag[issue_rd]  <= issue_fu_id;
                end
            end

            // B. KHI CÓ KẾT QUẢ VỀ (CDB) -> Đánh dấu RẢNH
            // (Chỉ giải phóng nếu Tag trên Bus khớp với Tag đang lưu trong bảng - đề phòng ghi đè)
            if (cdb_valid) begin
                if (cdb_rd_is_float) begin
                    if (float_tag[cdb_rd] == cdb_source_fu) 
                        float_busy[cdb_rd] <= 1'b0;
                end else if (cdb_rd != 0) begin
                    if (int_tag[cdb_rd] == cdb_source_fu)
                        int_busy[cdb_rd] <= 1'b0;
                end
            end
        end
    end

endmodule