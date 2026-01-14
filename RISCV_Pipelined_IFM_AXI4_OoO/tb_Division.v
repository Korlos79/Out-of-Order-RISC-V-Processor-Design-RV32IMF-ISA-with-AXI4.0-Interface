`timescale 1ns/1ps

module tb_Division();

    // --- 1. KHAI BÁO TÍN HIỆU ---
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] a_in, b_in;
    
    wire done;
    wire [31:0] result;
    wire zero_division, Overflow, Underflow;

    // Biến shortreal để hiển thị và nhập liệu dễ dàng
    real a_real, b_real, res_real;
    
    // Biến đo thời gian
    real start_time;

    // --- 2. KẾT NỐI MODULE (DUT) ---
    division dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .A(a_in),
        .B(b_in),
        .done(done),
        .result(result),
        .zero_division(zero_division),
        .Overflow(Overflow),
        .Underflow(Underflow)
    );

    // --- 3. TẠO CLOCK (100MHz -> T=10ns) ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- 4. TASK TỰ ĐỘNG HÓA TEST ---
    // Task này nhận đầu vào là số thực (ví dụ: 5.5), tự convert sang bits để đưa vào module
    task test_div;
        input [31:0] val_a;
        input [31:0] val_b;
        begin
            // 1. Gửi dữ liệu vào
            a_in = val_a;
            b_in = val_b;
            
            // Chuyển đổi sang số thực để in log cho đẹp (Chỉ dùng để hiển thị)
            a_real = $bitstoshortreal(a_in);
            b_real = $bitstoshortreal(b_in);

            // 2. Đợi 1 chu kì để data được latch vào Stage 1
            @(posedge clk);
            start = 1;
            start_time = $realtime; // Ghi lại thời gian bắt đầu
            
            @(posedge clk);
            start = 0;

            // C. Chờ kết quả
            wait(done);
            
            // D. Chuyển đổi Bits -> Real để hiển thị
            // Lưu ý: Nếu là Infinity hoặc NaN, shortreal có thể in ra "inf" hoặc "nan"
            res_real = $bitstoshortreal(result);
            
            // E. In kết quả
            $display("-------------------------------------------------------------");
            $display("Input:  %f / %f", a_real, b_real);          
            if (zero_division) 
                $display("Status: [ZERO DIVISION DETECTED] -> Result: %f (Hex: %h)", res_real, result);
            else if (Overflow)
                $display("Status: [OVERFLOW] -> Result: %f (Hex: %h)", res_real, result);
            else if (Underflow)
                $display("Status: [UNDERFLOW] -> Result: %f (Hex: %h)", res_real, result);
            else
                $display("Result: %f (Hex: 0x%h)", res_real, result);
                
            $display("Cycles: %0d cycles", ($realtime - start_time)/10 - 1); // Trừ 1 do delay logic
        end
    endtask

    // --- 5. MAIN TEST SCENARIOS ---
    initial begin
        // Khởi tạo
        $display("=== START RADIX-4 SRT DIVISION TEST ===");
        rst_n = 0;
        start = 0;
        a_in = 0; b_in = 0;
		  #20 rst_n = 1; // Thả Reset
        #10;

		  $display("\nTest 1: 10.0 / 2.0");
        test_div(32'h41200000, 32'h40000000);

        // CASE 2: 1.0 / 3.0 = 0.3333...
        // Hex: 3F800000 / 40400000 -> Expect: 3EAAAAAB
        $display("\nTest 2: 1.0 / 3.0");
        test_div(32'h3F800000, 32'h40400000);

        // CASE 3: -15.5 / 2.0 = -7.75
        // Hex: C1780000 / 40000000 -> Expect: C0F80000
        $display("\nTest 3: -15.5 / 2.0");
        test_div(32'hC1780000, 32'h40000000);
        
        // CASE 4: Chia số lớn (1000.0 / 0.001)
        // Hex: 447A0000 / 3A83126F -> Expect: 49742400
        $display("\nTest 4: 1000.0 / 0.001");
        test_div(32'h447A0000, 32'h3A83126F);

        // CASE 5: Zero Division (5.0 / 0.0)
        // Hex: 40A00000 / 00000000 -> Expect: Infinity (7F800000)
        $display("\nTest 5: Zero Division");
        test_div(32'h40A00000, 32'h00000000);
        
        // CASE 6: Overflow Test (Max Float / 0.5)
        // Hex: 7F7FFFFF / 3F000000 -> Expect: Overflow Flag
        $display("\nTest 6: Overflow Check");
        test_div(32'h7F7FFFFF, 32'h3F000000);
        $display("-------------------------------------------------------------");
        $display("Testing Manual Overflow Case (Max_Float / 0.5):");
        a_in = 32'h7F7FFFFF; // ~3.4028235e38
        b_in = 32'h3F000000; // 0.5
        start = 1; @(posedge clk); start = 0; wait(done);
        $display("Result Hex: %h | Overflow Flag: %b", result, Overflow);


        #50;
        $display("=== TEST FINISHED ===");
        $finish;
    end

endmodule