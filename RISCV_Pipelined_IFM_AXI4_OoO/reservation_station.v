module reservation_station #(
    parameter DATA_WIDTH = 32,
    parameter TAG_WIDTH  = 3,   
    parameter NUM_ENTRIES = 4   
)(
    input wire clk,
    input wire rst_n,
    
    // --- THÊM INPUT FLUSH ---
    input wire flush, // Xóa sạch hàng đợi khi Branch Mispredict

    // --- 1. GIAO DIỆN VỚI DISPATCHER (Nhận lệnh) ---
    input  wire                   dispatch_enable,
    
    // Toán hạng 1
    input  wire [DATA_WIDTH-1:0]  src1_val,
    input  wire [TAG_WIDTH-1:0]   src1_tag,
    input  wire                   src1_ready,
    
    // Toán hạng 2
    input  wire [DATA_WIDTH-1:0]  src2_val,
    input  wire [TAG_WIDTH-1:0]   src2_tag,
    input  wire                   src2_ready,

    // Toán hạng 3
    input  wire [DATA_WIDTH-1:0]  src3_val,
    input  wire [TAG_WIDTH-1:0]   src3_tag,
    input  wire                   src3_ready,
    
    input  wire [4:0]             dest_reg,
    input  wire [4:0]             opcode,
    input  wire [TAG_WIDTH-1:0]   my_rob_tag,

    output wire                   rs_full,

    // --- 2. GIAO DIỆN VỚI CDB (Lắng nghe kết quả) ---
    input  wire                   cdb_valid,
    input  wire [TAG_WIDTH-1:0]   cdb_tag,
    input  wire [DATA_WIDTH-1:0]  cdb_value,

    // --- 3. GIAO DIỆN VỚI FU (Đẩy lệnh đi tính) ---
    input  wire                   fu_ready,
    output reg                    fu_start,
    
    output reg [DATA_WIDTH-1:0]   fu_op1,
    output reg [DATA_WIDTH-1:0]   fu_op2,
    output reg [DATA_WIDTH-1:0]   fu_op3,
    
    output reg [4:0]              fu_opcode,
    output reg [TAG_WIDTH-1:0]    fu_dest_tag,
    output reg [4:0]              fu_dest_reg
);

    // --- CẤU TRÚC LƯU TRỮ ---
    reg [NUM_ENTRIES-1:0] busy;
    reg [4:0]             op [NUM_ENTRIES-1:0];
    
    // Operand 1
    reg [DATA_WIDTH-1:0]  v1 [NUM_ENTRIES-1:0];
    reg [TAG_WIDTH-1:0]   q1 [NUM_ENTRIES-1:0];
    reg [NUM_ENTRIES-1:0] r1;

    // Operand 2
    reg [DATA_WIDTH-1:0]  v2 [NUM_ENTRIES-1:0];
    reg [TAG_WIDTH-1:0]   q2 [NUM_ENTRIES-1:0];
    reg [NUM_ENTRIES-1:0] r2;

    // Operand 3
    reg [DATA_WIDTH-1:0]  v3 [NUM_ENTRIES-1:0];
    reg [TAG_WIDTH-1:0]   q3 [NUM_ENTRIES-1:0];
    reg [NUM_ENTRIES-1:0] r3;

    reg [4:0]             dest [NUM_ENTRIES-1:0];
    reg [TAG_WIDTH-1:0]   rob_tag [NUM_ENTRIES-1:0];

    // --- LOGIC TÌM CHỖ TRỐNG ---
    integer i;
    reg [31:0] alloc_idx;
    reg        found_slot;

    always @(*) begin
        found_slot = 0;
        alloc_idx  = 0;
        for (i = 0; i < NUM_ENTRIES; i = i + 1) begin
            if (!busy[i] && !found_slot) begin
                alloc_idx  = i;
                found_slot = 1;
            end
        end
    end
    
    assign rs_full = !found_slot;

    // --- LOGIC ISSUE (Chọn lệnh để chạy) ---
    reg [31:0] issue_idx;
    reg        can_fire;

    always @(*) begin
        can_fire  = 0;
        issue_idx = 0;
        for (i = 0; i < NUM_ENTRIES; i = i + 1) begin
            // Điều kiện: Busy VÀ Đủ cả 3 toán hạng
            if (busy[i] && r1[i] && r2[i] && r3[i] && !can_fire) begin
                issue_idx = i;
                can_fire  = 1;
            end
        end
    end

    // --- SEQUENTIAL LOGIC ---
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy     <= 0;
            fu_start <= 0;
            r1 <= 0; r2 <= 0; r3 <= 0;
        end else begin
            // --- XỬ LÝ FLUSH (Quan trọng cho OoO) ---
            if (flush) begin
                busy     <= 0; // Xóa sạch lệnh trong RS
                fu_start <= 0;
            end else begin
                // Nếu không Flush thì chạy bình thường
                
                fu_start <= 0;

                // 1. DISPATCH: Nhận lệnh mới vào
                if (dispatch_enable && found_slot) begin
                    busy[alloc_idx]    <= 1;
                    op[alloc_idx]      <= opcode;
                    dest[alloc_idx]    <= dest_reg;
                    rob_tag[alloc_idx] <= my_rob_tag;
                    
                    // Toán hạng 1 (có Forwarding tại cửa vào)
                    if (!src1_ready && cdb_valid && (src1_tag == cdb_tag)) begin
                        v1[alloc_idx] <= cdb_value; r1[alloc_idx] <= 1; q1[alloc_idx] <= 0;
                    end else begin
                        v1[alloc_idx] <= src1_val; q1[alloc_idx] <= src1_tag; r1[alloc_idx] <= src1_ready;
                    end

                    // Toán hạng 2
                    if (!src2_ready && cdb_valid && (src2_tag == cdb_tag)) begin
                        v2[alloc_idx] <= cdb_value; r2[alloc_idx] <= 1; q2[alloc_idx] <= 0;
                    end else begin
                        v2[alloc_idx] <= src2_val; q2[alloc_idx] <= src2_tag; r2[alloc_idx] <= src2_ready;
                    end

                    // Toán hạng 3
                    if (!src3_ready && cdb_valid && (src3_tag == cdb_tag)) begin
                        v3[alloc_idx] <= cdb_value; r3[alloc_idx] <= 1; q3[alloc_idx] <= 0;
                    end else begin
                        v3[alloc_idx] <= src3_val; q3[alloc_idx] <= src3_tag; r3[alloc_idx] <= src3_ready;
                    end
                end

                // 2. SNOOP CDB
                if (cdb_valid) begin
                    for (i = 0; i < NUM_ENTRIES; i = i + 1) begin
                        if (busy[i]) begin
                            if (!r1[i] && q1[i] == cdb_tag) begin v1[i] <= cdb_value; r1[i] <= 1; end
                            if (!r2[i] && q2[i] == cdb_tag) begin v2[i] <= cdb_value; r2[i] <= 1; end
                            if (!r3[i] && q3[i] == cdb_tag) begin v3[i] <= cdb_value; r3[i] <= 1; end
                        end
                    end
                end

                // 3. EXECUTE
                if (can_fire && fu_ready) begin
                    fu_start    <= 1;
                    fu_op1      <= v1[issue_idx];
                    fu_op2      <= v2[issue_idx];
                    fu_op3      <= v3[issue_idx];
                    fu_opcode   <= op[issue_idx];
                    fu_dest_tag <= rob_tag[issue_idx];
                    fu_dest_reg <= dest[issue_idx];

                    busy[issue_idx] <= 0; 
                end
            end
        end
    end

endmodule