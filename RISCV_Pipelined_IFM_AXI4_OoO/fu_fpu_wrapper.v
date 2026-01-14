module fu_fpu_wrapper #(
    parameter DATA_WIDTH = 32,
    parameter TAG_WIDTH  = 3
)(
    input wire clk, rst_n,
    
    // --- Giao diện với Reservation Station ---
    input wire                   start,        // Lệnh từ RS bắn sang
    input wire [4:0]             opcode,       // FPUOpd
    input wire [31:0]            op1, op2, op3,
    input wire [TAG_WIDTH-1:0]   tag_in,       // Tag của lệnh đang vào
    input wire [4:0]             dest_reg_in,  // Thanh ghi đích (cho Scoreboard)
    
    output wire                  busy,         // Báo bận về RS

    // --- Giao diện với CDB Arbiter ---
    output reg                   cdb_valid,    // Yêu cầu phát kết quả
    output wire [DATA_WIDTH-1:0] cdb_result,   // Kết quả (nối thẳng từ FPU)
    output reg  [TAG_WIDTH-1:0]  cdb_tag,      // Tag tương ứng
    output reg  [4:0]            cdb_dest_reg, // Thanh ghi đích trả về
    input  wire                  cdb_ack       // Arbiter báo: "Đã nhận"
);

    // 1. KẾT NỐI VỚI MODULE FPU
    wire fpu_done;
    wire fpu_exception; 

    // Tên cổng đã khớp hoàn toàn với FPU.v của bạn
    FPU FPU_CORE (
        .clk(clk), 
        .rst_n(rst_n),
        .start(start), 
        .FPUOpd(opcode),
        .a_operand(op1), 
        .b_operand(op2), 
        .c_operand(op3),
        .result(cdb_result), // Kết quả FPU nối thẳng ra output wrapper
        .busy(busy),         // Tín hiệu busy của FPU nối thẳng ra RS
        .done(fpu_done), 
        .Exception(fpu_exception)
    );

    // 2. QUẢN LÝ TAG & DEST REG
    // Vì FPU này là dạng BLOCKING (Busy=1 suốt quá trình tính),
    // ta chỉ cần lưu Tag của lệnh đang chạy vào 1 thanh ghi đơn giản.
    // Không cần FIFO phức tạp như bộ Nhân Integer Pipeline.
    
    reg [TAG_WIDTH-1:0] current_tag;
    reg [4:0]           current_dest;
    reg                 processing; // Đánh dấu đang có lệnh chạy

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_tag  <= 0;
            current_dest <= 0;
            processing   <= 0;
            cdb_valid    <= 0;
            cdb_tag      <= 0;
            cdb_dest_reg <= 0;
        end else begin
            // --- Input Logic ---
            // Khi bắt đầu lệnh mới
            if (start) begin
                current_tag  <= tag_in;
                current_dest <= dest_reg_in;
                processing   <= 1;
                cdb_valid    <= 0; // Xóa cờ cũ nếu có
            end

            // --- Output Logic ---
            // Khi FPU tính xong (Done bật lên 1 nhịp)
            if (fpu_done && processing) begin
                cdb_valid    <= 1;
                cdb_tag      <= current_tag;
                cdb_dest_reg <= current_dest;
                processing   <= 0; // Xong việc
            end 
            // Khi CDB đã nhận (Ack)
            else if (cdb_ack && cdb_valid) begin
                cdb_valid <= 0;
            end
        end
    end

endmodule