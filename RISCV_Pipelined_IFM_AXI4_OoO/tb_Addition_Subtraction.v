`timescale 1ns / 1ps

module tb_Addition_Subtraction;

    // --- 1. Khai báo tín hiệu ---
    reg clk;
    reg rst_n;
    reg start;
    reg [31:0] a_operand;
    reg [31:0] b_operand;
    reg AddBar_Sub;

    wire Exception;
    wire [31:0] result;
    wire done;
    
    // Biến hiển thị Debug (Real numbers)
    real a_real, b_real, res_real;
    real start_time;
    
    // --- 2. Instantiate Module ---
    Addition_subtraction uut (
        .clk(clk), 
        .rst_n(rst_n), 
        .start(start), 
        .a_operand(a_operand), 
        .b_operand(b_operand), 
        .AddBar_Sub(AddBar_Sub), 
        .Exception(Exception), 
        .result(result), 
        .done(done)
    );

    // --- 3. Tạo Clock (10ns = 100MHz) ---
    always #5 clk = ~clk;

    // --- 5. Task gửi dữ liệu và đợi kết quả (Latency Test Mode) ---
    task send_input;
        input [31:0] a;
        input [31:0] b;
        input is_sub; // 0: Add, 1: Sub
        begin
            // 1. Convert sang real ngay từ input để tránh race condition
            a_real = $bitstoshortreal(a);
            b_real = $bitstoshortreal(b);
            
            // 2. Setup input tại cạnh lên clock
            a_operand <= a;
            b_operand <= b;
            AddBar_Sub <= is_sub;
            
            @(posedge clk);
            start <= 1;
            start_time = $realtime; // Ghi lại thời điểm bắt đầu
            
            @(posedge clk);
            start <= 0;
            
            // 3. Đợi kết quả (Blocking wait)
            wait(done);
            
            // 4. Lấy kết quả hiển thị
            res_real = $bitstoshortreal(result);
            
            $display("-------------------------------------------------------------");
            if (is_sub) $display("[INPUT]  %f - %f", a_real, b_real);
            else        $display("[INPUT]  %f + %f", a_real, b_real);
            
            $display("[OUTPUT] Result = %f (Hex: %h) | Exception = %b", res_real, result, Exception);
            // Công thức tính cycle chuẩn: Delta_Time / Clock_Period
            // (Đã bỏ -1 để phản ánh đúng số chu kì pipeline)
            $display("[TIMING] Latency: %0d cycles", ($realtime - start_time)/10);
            
            // Đợi thêm 1 chu kì để tách biệt các lần test
            @(posedge clk);
        end
    endtask

    // --- 7. Main Test Sequence ---
    initial begin
        // Khởi tạo
        clk = 0;
        rst_n = 0;
        start = 0;
        a_operand = 0;
        b_operand = 0;
        AddBar_Sub = 0;

        // Reset hệ thống
        $display("=== RESET SYSTEM ===");
        #20 rst_n = 1;
        #20;

        // CASE 1: 1.5 + 2.5 = 4.0
        // 1.5 = 0x3FC00000, 2.5 = 0x40200000
        send_input(32'h3FC00000, 32'h40200000, 0); 

        // CASE 2: 10.0 + 2.0 = 12.0
        // 10.0 = 0x41200000, 2.0 = 0x40000000
        send_input(32'h41200000, 32'h40000000, 0); 

        // CASE 3: 5.5 - 1.5 = 4.0
        // 5.5 = 0x40B00000, 1.5 = 0x3FC00000
        send_input(32'h40B00000, 32'h3FC00000, 1); 

        // CASE 4: 1.0 + 1.0 = 2.0
        // 1.0 = 0x3F800000, 1.0 = 0x3F800000 
        send_input(32'h3F800000, 32'h3F800000, 0);

        // CASE 5: Exception (NaN)
        send_input(32'h7F800000, 32'h40000000, 0);

        #50;
        $display("=== END OF SIMULATION ===");
        $finish;
    end

endmodule