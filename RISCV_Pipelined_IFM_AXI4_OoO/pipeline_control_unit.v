module pipeline_control_unit (
    // --- Inputs ---
    input wire ifu_busy,        // IFU đang đợi AXI (Cache Miss)
    input wire branch_taken,    // ALU báo rẽ nhánh (Flush)
    input wire issue_stall_req, // issue_logic báo Trạm chờ (RS) đã đầy
    
    // --- Outputs ---
    output reg stall_fetch,     // Dừng PC và IF/ID
    output reg flush_decode,    // Xóa lệnh ở Decode (biến thành NOP)
    output reg stall_dispatch   // Báo cho issue_logic biết để ngừng cấp phát
);

    always @(*) begin
        // Mặc định
        stall_fetch    = 0;
        flush_decode   = 0;
        stall_dispatch = 0;

        // 1. Ưu tiên cao nhất: FLUSH (Nhánh sai)
        // Nếu rẽ nhánh, phải xóa ngay lập tức các lệnh đang nạp dở
        if (branch_taken) begin
            flush_decode   = 1;
            // Flush thường không stall, nó chỉ reset về trạng thái rỗng
        end
        // 2. Ưu tiên nhì: STALL (Kẹt xe)
        else begin
            // Nếu IFU đang bận tải lệnh -> Dừng PC, Dừng Dispatch
            if (ifu_busy) begin
                stall_fetch    = 1;
                stall_dispatch = 1; // Đây chính là tín hiệu nối vào stall_pipeline của issue_logic
            end
            
            // Nếu Trạm chờ (RS) đầy -> Dừng PC, Dừng IF/ID để giữ lệnh lại
            if (issue_stall_req) begin
                stall_fetch    = 1;
            end
        end
    end

endmodule