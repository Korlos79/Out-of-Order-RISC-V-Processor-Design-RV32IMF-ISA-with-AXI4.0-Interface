`timescale 1ns/1ps

module tb_Multiplication();

    reg [31:0] a_operand, b_operand;
    wire Exception, Overflow, Underflow;
    wire [31:0] result;

    // Gọi module cần test
    Multiplication uut (
        .a_operand(a_operand),
        .b_operand(b_operand),
        .Exception(Exception),
        .Overflow(Overflow),
        .Underflow(Underflow),
        .result(result)
    );

    initial begin
        $display("TIME | A | B | RESULT | Exception | Overflow | Underflow");
        $monitor("%0dns | %h | %h | %h | %b | %b | %b",
                  $time, a_operand, b_operand, result, Exception, Overflow, Underflow);

        // ----------- TEST 1: 2.5 * 4.0 = 10.0 -----------
        // 2.5  = 0x40200000   | 4.0 = 0x40800000   | Expected = 0x41200000
        a_operand = 32'h40200000;  
        b_operand = 32'h40800000;
        #10;

        // ----------- TEST 2: (-3.0) * (2.0) = -6.0 -----------
        // -3.0 = 0xC0400000   | 2.0 = 0x40000000   | Expected = 0xC0C00000
        a_operand = 32'hC0400000;  
        b_operand = 32'h40000000;
        #10;

        // ----------- TEST 3: Very small * Very large (check underflow/overflow) -----------
        // Small = 1.0e-38 ≈ 0x00800000 | Big = 3.4e38 ≈ 0x7F7FFFFF
        a_operand = 32'h00800000;  
        b_operand = 32'h7F7FFFFF;
        #10;

        // ----------- TEST 4: 0 * 123.456 (Zero case) -----------
        // 0 = 0x00000000 | 123.456 ≈ 0x42F6E979
        a_operand = 32'h00000000;  
        b_operand = 32'h42F6E979;
        #10;

        // ----------- TEST 5: INF * 2.0 (Exception) -----------
        // INF = 0x7F800000 | 2.0 = 0x40000000
        a_operand = 32'h7F800000;  
        b_operand = 32'h40000000;
        #10;

        // END SIMULATION
        $finish;
    end

endmodule
