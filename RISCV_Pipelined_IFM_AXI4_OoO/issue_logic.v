module issue_logic (
    // --- 1. INPUT TỪ PIPELINE CONTROL (Trạng thái hệ thống) ---
    input wire       stall_pipeline, // Pipeline đang bị dừng (do Fetch/LSU busy)
    input wire       flush_pipeline, // Pipeline bị xóa (do Branch sai)
    
    // --- 2. INPUT TỪ CONTROL UNIT (Thông tin lệnh) ---
    // Dùng các cờ này để biết lệnh thuộc về Unit nào
    input wire       mem_read,       // MemReadD (Load)
    input wire       mem_write,      // MemWriteD (Store)
    input wire       is_fpu_inst,    // IsFPU (Từ Control Unit)
    // Hoặc bạn có thể dùng opcode để check kĩ hơn nếu cần
    input wire [4:0] opcode,         // Opcode 5-bit (để check NOP/Bubble)

    // --- 3. INPUT TỪ SCOREBOARD ---
    input wire       sb_can_issue,   // Scoreboard: "Thanh ghi đích OK, không bị trùng (WAW)"
    
    // --- 4. INPUT TỪ RESERVATION STATIONS (Trạng thái đầy/vơi) ---
    input wire       rs_alu_full,    // Trạm ALU đầy
    input wire       rs_fpu_full,    // Trạm FPU đầy
    input wire       rs_lsu_full,    // Trạm Load/Store đầy

    // --- 5. OUTPUT ENABLE (Gửi đi đâu?) ---
    output reg       disp_en_alu,    // Kích hoạt nạp vào RS_ALU
    output reg       disp_en_fpu,    // Kích hoạt nạp vào RS_FPU
    output reg       disp_en_lsu,    // Kích hoạt nạp vào LSU (RS_LSU)
    
    // --- 6. OUTPUT STALL (Phản hồi ngược lại) ---
    output wire      issue_stall     // Báo dừng Fetch/Decode nếu không Issue được
);

    // --- PHÂN LOẠI LỆNH (Instruction Classification) ---
    
    // Lệnh LSU: Load hoặc Store
    wire is_lsu_op = mem_read || mem_write;
    
    // Lệnh FPU: Được Control Unit đánh dấu là IsFPU
    // (Lưu ý: F_LOAD/F_STORE cũng có IsFPU=1, nhưng chúng là LSU nên phải loại trừ)
    wire is_fpu_op = is_fpu_inst && !is_lsu_op;
    
    // Lệnh ALU: Không phải FPU, không phải LSU, và phải là lệnh hợp lệ (không phải NOP/Bubble)
    // Giả sử opcode 0 là NOP hoặc bong bóng do stall trước đó
    // (Nếu NOP là ADDI x0, x0, 0 thì nó là ALU op, nhưng ghi vào x0 nên không sao)
    // Tạm thời coi mọi lệnh còn lại là ALU
    wire is_alu_op = !is_fpu_op && !is_lsu_op; 

    // --- LOGIC CẤP PHÁT (ISSUE) ---
    always @(*) begin
        // Mặc định tắt hết
        disp_en_alu = 0;
        disp_en_fpu = 0;
        disp_en_lsu = 0;

        // Chỉ cấp phát khi:
        // 1. Không có Stall từ bên ngoài (ví dụ IFU đang đi lấy lệnh)
        // 2. Không có Flush (Lệnh sai nhánh)
        // 3. Scoreboard cho phép (Không xung đột WAW)
        if (!stall_pipeline && !flush_pipeline && sb_can_issue) begin
            
            if (is_fpu_op) begin
                // Nếu là lệnh Float -> Check trạm FPU
                if (!rs_fpu_full) 
                    disp_en_fpu = 1;
            end 
            else if (is_lsu_op) begin
                // Nếu là lệnh Memory -> Check trạm LSU
                if (!rs_lsu_full) 
                    disp_en_lsu = 1;
            end 
            else begin
                // Mặc định là ALU (Int) -> Check trạm ALU
                if (!rs_alu_full) 
                    disp_en_alu = 1;
            end
        end
    end

    // --- LOGIC STALL (KHI NÀO CẦN DỪNG?) ---
    // Stall khi: Cần Issue một lệnh vào một trạm, nhưng trạm đó ĐẦY hoặc Scoreboard CHẶN
    // Tín hiệu này sẽ được OR với các stall khác ở Top Module để dừng PC
    
    assign issue_stall = 
           (is_fpu_op && rs_fpu_full) || 
           (is_lsu_op && rs_lsu_full) || 
           (is_alu_op && rs_alu_full) ||
           (!sb_can_issue); // Hoặc Scoreboard chặn (WAW)

endmodule