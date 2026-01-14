`timescale 1ns/1ps

module tb_Sqrt;
    parameter XLEN = 32;

    // Inputs
    reg [XLEN-1:0] a_operand;

    // Outputs
    wire exception;
	 wire zero_division;
    wire [XLEN-1:0] result;

    // Real values for readability
    real fa;     // float input
    real fr;     // float output

    // Instantiate DUT
    Sqrt #(XLEN) uut (
        .a_operand(a_operand),
        .exception(exception),
		  .zero_division(zero_division),
        .result(result)
    );

    // Task hiển thị HEX + float
    task display_result;
        begin
            fa = $bitstoshortreal(a_operand);
            fr = $bitstoshortreal(result);
            $display("Time=%0t ns | A=0x%h (%f) | Result=0x%h (%f) | EXC=%b | ZERO=%b",
                     $time, a_operand, fa, result, fr, exception, zero_division);
        end
    endtask

    initial begin
        $display("===== START SQRT TEST =====");
        
        // Test 4.0 (4.0 -> 0x40800000, sqrt = 2.0)
        a_operand = 32'h40800000; #50; display_result();

        // Test 9.0
        a_operand = 32'h41100000; #50; display_result();

        // Test 2.25
        a_operand = 32'h40100000; #50; display_result();

        // Test 0.5
        a_operand = 32'h3F000000; #50; display_result();

        // Test 0.0
        a_operand = 32'h00000000; #50; display_result();

        // Test underflow nhỏ
        a_operand = 32'h00800000; #50; display_result();

        // Test số âm (exception)
        a_operand = 32'hC0800000; #50; display_result();

        $display("===== END TEST =====");
        $stop;
    end

endmodule
