`timescale 1ns / 1ps

module tb_rv32m_muldiv_split;

    // --- 1. Khai báo tín hiệu ---
    reg clk;
    reg rst_n;
    
    reg op_valid;
    reg [4:0] op_sel;
    reg [31:0] rs1;
    reg [31:0] rs2;

    wire busy;
    wire done;
    wire [31:0] result;

    // --- 2. Định nghĩa Opcode ---
    localparam OP_MUL    = 5'b10000;
    localparam OP_MULH   = 5'b10001;
    localparam OP_DIV    = 5'b10100;
    localparam OP_REM    = 5'b10110;

    // --- 3. Instantiate DUT ---
    // LƯU Ý QUAN TRỌNG: Hãy đảm bảo tên module con bên trong 'rv32m_muldiv_split' 
    // khớp với tên file bạn đang có (ví dụ: iter_mul32 vs pipeline_mul32).
    rv32m_muldiv_split uut (
        .clk(clk),
        .rst_n(rst_n),
        .op_valid(op_valid),
        .op_sel(op_sel),
        .rs1(rs1),
        .rs2(rs2),
        .busy(busy),
        .done(done),
        .result(result)
    );

    // --- 4. Tạo Clock (100MHz) ---
    always #5 clk = ~clk;

    // --- 5. Task gửi lệnh đơn lẻ ---
    task send_op;
        input [4:0] opcode;
        input [31:0] in1;
        input [31:0] in2;
        begin
            @(posedge clk);
            op_valid <= 1;
            op_sel   <= opcode;
            rs1      <= in1;
            rs2      <= in2;
            
            @(posedge clk);
            op_valid <= 0; // Tắt valid sau 1 chu kì
        end
    endtask

    // --- 6. Kịch bản Test ---
    initial begin
        // Khởi tạo
        clk = 0; rst_n = 0;
        op_valid = 0; op_sel = 0; rs1 = 0; rs2 = 0;

        $display("=== BAT DAU TESTBENCH MULDIV SPLIT ===");
        
        // Reset hệ thống
        #20 rst_n = 1;
        #20;

        // ====================================================
        // TEST CASE 1: Phép Nhân Đơn (Pipeline)
        // ====================================================
        $display("\n[T=%0t] TEST 1: MUL (10 * 5)", $time);
        send_op(OP_MUL, 32'd10, 32'd5);
        
        // Chờ kết quả
        @(posedge done); // Đợi cạnh lên của done
        #1; // Đợi ổn định
        if (result === 32'd50) 
            $display("[PASS] MUL Result = %d", result);
        else 
            $display("[FAIL] MUL Result = %d (Expected 50)", result);

        #30;

        // ====================================================
        // TEST CASE 2: Pipeline Stress (Nhân liên tục 100%)
        // ====================================================
        $display("\n[T=%0t] TEST 2: MUL Pipeline Stress (3 ops back-to-back)", $time);
        
        // Gửi 3 lệnh liên tiếp trong 3 chu kỳ (Không dùng task để tránh delay)
        @(posedge clk);
        op_valid <= 1; op_sel <= OP_MUL; rs1 <= 32'd2; rs2 <= 32'd3; // 2*3=6
        
        @(posedge clk);
        op_valid <= 1; op_sel <= OP_MUL; rs1 <= 32'd4; rs2 <= 32'd5; // 4*5=20
        
        @(posedge clk);
        op_valid <= 1; op_sel <= OP_MUL; rs1 <= 32'd10; rs2 <= 32'd10; // 10*10=100
        
        @(posedge clk);
        op_valid <= 0; // Kết thúc chuỗi lệnh

        // Monitor kết quả trả về (Kỳ vọng 3 kết quả liên tiếp)
        // (Bạn có thể xem trên Waveform để xác nhận rõ nhất)
        #100;

        // ====================================================
        // TEST CASE 3: Phép Chia (Blocking)
        // ====================================================
        $display("\n[T=%0t] TEST 3: DIV (100 / 4)", $time);
        send_op(OP_DIV, 32'd100, 32'd4);
        
        #1; 
        if (busy === 1) $display("[INFO] DIV Started, BUSY is HIGH (Correct)");
        else            $display("[FAIL] DIV Started but BUSY is LOW!");

        @(posedge done);
        #1;
        if (result === 32'd25) 
            $display("[PASS] DIV Result = %d", result);
        else 
            $display("[FAIL] DIV Result = %d (Expected 25)", result);

        #30;

        // ====================================================
        // TEST CASE 4: Interlock Logic (Gửi MUL khi DIV đang bận)
        // ====================================================
        $display("\n[T=%0t] TEST 4: Hazard Check (Try MUL while DIV busy)", $time);
        
        // 1. Bắt đầu chia 100 / 2 = 50
        send_op(OP_DIV, 32'd100, 32'd2);
        
        // 2. Cố tình gửi lệnh MUL (10 * 10 = 100) ngay sau đó
        #20; 
        $display("[INFO] Sending MUL while Busy=%b...", busy);
        send_op(OP_MUL, 32'd10, 32'd10);

        // 3. Kiểm tra: Kết quả tiếp theo phải là 50 (của DIV), không phải 100 (của MUL)
        @(posedge done);
        #1;
        if (result === 32'd50) 
            $display("[PASS] Correctly ignored MUL, finished DIV (Res=50).");
        else if (result === 32'd100)
            $display("[FAIL] Hazard Logic Failed! MUL executed while DIV was busy.");
        else
            $display("[INFO] Result = %d", result);

        #100;
        $display("\n=== END OF SIMULATION ===");
        $finish;
    end

endmodule