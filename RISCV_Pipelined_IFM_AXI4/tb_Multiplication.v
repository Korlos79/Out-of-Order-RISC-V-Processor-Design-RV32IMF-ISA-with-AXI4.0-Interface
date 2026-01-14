`timescale 1ns / 1ps

module tb_Multiplication;

    // --- 1. Khai báo tín hiệu ---
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] a_in;
    reg [31:0] b_in;

    wire [31:0] result;
    wire done;
    wire Exception;

    // Biến hỗ trợ hiển thị (Real numbers)
    real a_real, b_real, res_real;
    real start_time;

    // --- 2. Instantiate DUT (Device Under Test) ---
    multiplication uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start), 
        .a_in(a_in), 
        .b_in(b_in), 
        .result(result), 
        .done(done),
        .Exception(Exception)
    );

    // --- 3. Tạo Clock (10ns = 100MHz) ---
    always #5 clk = ~clk;

    // --- 4. Monitor: Tự động in kết quả khi xong ---
    // Vì là pipeline, kết quả sẽ ra trễ 4 chu kì, ta dùng block này để bắt kết quả
    always @(posedge clk) begin
        if (done) begin
            res_real = $bitstoshortreal(result);
            $display("[OUTPUT] Time %t | Cycle %0d | Result = %f (Hex: %h) | Exception = %b", 
                     $time, ($realtime - start_time)/10 - 1, res_real, result, Exception);
        end
    end

    // --- 5. Task gửi dữ liệu (Single Input) ---
    task send_input;
        input [31:0] a;
        input [31:0] b;
        begin
            // Convert để in log
            a_real = $bitstoshortreal(a);
            b_real = $bitstoshortreal(b);
            
            // Setup tại cạnh lên
            a_in <= a;
            b_in <= b;
            
            @(posedge clk);
            start <= 1;
				start_time = $realtime;
            $display("-------------------------------------------------------------");
            $display("[INPUT]  Time %t | Sending: %f * %f", $time, a_real, b_real);
            
            @(posedge clk);
            start <= 0; // Tắt start sau 1 chu kì
        end
    endtask

    // --- 7. Main Test Sequence ---
    initial begin
        // Khởi tạo
        clk = 0;
        rst_n = 0;
        start = 0;
        a_in = 0;
        b_in = 0;

        // Reset hệ thống
        $display("=== RESET SYSTEM ===");
        #20 rst_n = 1;
        #20;

        // ==========================================
        // TEST CASE 1: Phép nhân cơ bản
        // ==========================================
        $display("\n=== TEST 1: Basic Multiplication (1.5 * 2.0) ===");
        // 1.5 = 0x3FC00000, 2.0 = 0x40000000 -> Expect 3.0
        send_input(32'h3FC00000, 32'h40000000);
        
        // Đợi kết quả (Latency ~ 4 chu kì)
        #50;

        // ==========================================
        // TEST CASE 2: Số âm
        // ==========================================
        $display("\n=== TEST 2: Negative Numbers (-1.5 * 2.0) ===");
        // -1.5 = 0xBFC00000 -> Expect -3.0
        send_input(32'hBFC00000, 32'h40000000);
        #50;

        // ==========================================
        // TEST CASE 3: Nhân với 0
        // ==========================================
        $display("\n=== TEST 3: Zero Multiplication (100.0 * 0.0) ===");
        send_input(32'h42C80000, 32'd0);
        #55;

        // ==========================================
        // TEST CASE 4: PIPELINE STRESS TEST (Back-to-back)
        // Gửi 3 phép tính liên tiếp trong 3 chu kì
        // ==========================================
        $display("\n=== TEST 4: Pipeline Throughput Test (3 ops in 3 cycles) ===");
        
        // Op 1: 2.0 * 3.0 = 6.0
        a_in <= 32'h40000000; b_in <= 32'h40400000; start <= 1;
        $display("[INPUT 1] Time %t | 2.0 * 3.0", $time);
        @(posedge clk);

        // Op 2: 4.0 * 0.5 = 2.0
        a_in <= 32'h40800000; b_in <= 32'h3F000000; start <= 1;
        $display("[INPUT 2] Time %t | 4.0 * 0.5", $time);
        @(posedge clk);

        // Op 3: 10.0 * 10.0 = 100.0
        a_in <= 32'h41200000; b_in <= 32'h41200000; start <= 1;
        $display("[INPUT 3] Time %t | 10.0 * 10.0", $time);
        @(posedge clk);

        // Ngắt input
        start <= 0;
        a_in <= 0; b_in <= 0;

        // Đợi tất cả kết quả trôi ra khỏi pipeline (khoảng 6-8 chu kì)
        #80;

        $display("\n=== END OF SIMULATION ===");
        $finish;
    end

endmodule