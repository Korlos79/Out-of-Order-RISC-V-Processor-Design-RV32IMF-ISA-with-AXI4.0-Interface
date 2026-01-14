`timescale 1ns/1ps

module tb_Addition_Subtraction();

reg [31:0] a_operand;
reg [31:0] b_operand;
reg AddBar_Sub; // 0: cộng, 1: trừ
wire Exception;
wire [31:0] result;

// DUT
Addition_Subtraction DUT (
    .a_operand(a_operand),
    .b_operand(b_operand),
    .AddBar_Sub(AddBar_Sub),
    .Exception(Exception),
    .result(result)
);

// Task hiển thị dạng IEEE-754 rõ ràng
task display_op;
    input [31:0] a, b, res;
    begin
        $display("Time=%0t | A=%h | B=%h | Mode=%s | Result=%h | Exception=%b",
                  $time, a, b, (AddBar_Sub ? "SUB" : "ADD"), res, Exception);
    end
endtask

initial begin
    $display("=== BẮT ĐẦU TESTBENCH CHO ADDITION_SUBTRACTION ===");

    // Test 1: 1.5 + 2.5 = 4.0
    // 1.5 -> 0x3FC00000, 2.5 -> 0x40200000, Result expected = 0x40800000
    a_operand = 32'h3FC00000;  // 1.5
    b_operand = 32'h40200000;  // 2.5
    AddBar_Sub = 1'b0; #10; display_op(a_operand, b_operand, result);

    // Test 2: 5.75 - 2.5 = 3.25
    // 5.75 -> 0x40B80000, 3.25 -> 0x40500000
    a_operand = 32'h40B80000;  // 5.75
    b_operand = 32'h40200000;  // 2.5
    AddBar_Sub = 1'b1; #10; display_op(a_operand, b_operand, result);

    // Test 3: -3.0 + 1.5 = -1.5
    a_operand = 32'hC0400000;  // -3.0
    b_operand = 32'h3FC00000;  // 1.5
    AddBar_Sub = 1'b0; #10; display_op(a_operand, b_operand, result);

    // Test 4: 2.5 - 5.75 = -3.25 (test hoán đổi toán hạng)
    a_operand = 32'h40200000;  // 2.5
    b_operand = 32'h40B80000;  // 5.75
    AddBar_Sub = 1'b1; #10; display_op(a_operand, b_operand, result);

    // Test 5: Ngoại lệ (Exponent = 255) -> NaN / Infinity
    a_operand = 32'h7F800000;  // +Inf
    b_operand = 32'h3FC00000;  // 1.5
    AddBar_Sub = 1'b0; #10; display_op(a_operand, b_operand, result);

    // Test 6: 0.0 + 0.0
    a_operand = 32'h00000000;  
    b_operand = 32'h00000000;
    AddBar_Sub = 1'b0; #10; display_op(a_operand, b_operand, result);

    // Test 7: -1.25 - (-0.75) = -0.5
    a_operand = 32'hBFA00000; // -1.25
    b_operand = 32'hBF400000; // -0.75
    AddBar_Sub = 1'b1; #10; display_op(a_operand, b_operand, result);

    $display("=== KẾT THÚC TEST ===");
    $stop;
end

endmodule
