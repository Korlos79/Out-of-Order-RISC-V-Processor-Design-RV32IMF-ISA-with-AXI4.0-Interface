`timescale 1ns/1ps

module division_tb;
    parameter XLEN = 32;
    reg  [XLEN-1:0] A, B;
    wire [XLEN-1:0] result;
    wire zero_division, Exception, Overflow, Underflow;

    division #(XLEN) dut (
        .A(A),
        .B(B),
        .zero_division(zero_division),
        .Exception(Exception),
        .Overflow(Overflow),
        .Underflow(Underflow),
        .result(result)
    );

    // Helper to convert float
    real fa, fb, fr;
    task show;
        begin
            fa = $bitstoshortreal(A);
            fb = $bitstoshortreal(B);
            fr = $bitstoshortreal(result);
            $display("[T=%0dns] A=%h (%.5f) / B=%h (%.5f) => R=%h (%.5f) | ZDIV=%b | EXC=%b | OVF=%b | UNF=%b",
                     $time, A, fa, B, fb, result, fr, zero_division, Exception, Overflow, Underflow);
        end
    endtask

    initial begin
        $display("\n==== FLOATING DIVISION TESTBENCH START ====\n");

        // Test 1: 10.0 / 2.0
        A = 32'h41200000; B = 32'h40000000; #200; show(); 

        // Test 2: 7.5 / 3.0 = 2.5
        A = 32'h40F00000; B = 32'h40400000; #200; show();

        // Test 3: 1.0 / 0.0 => DIV 0
        A = 32'h3F800000; B = 32'h00000000; #200; show();

        // Test 4: -8.0 / 2.0 = -4.0
        A = 32'hC1000000; B = 32'h40000000; #200; show();

        // Test 5: Very small / large (Underflow expected)
        A = 32'h00800000; B = 32'h7F7FFFFF; #200; show();

        // Test 6: NaN / 3.0 (Exception expected)
        A = 32'h7FC00001; B = 32'h40400000; #200; show();

        $display("\n==== TEST END ====\n");
        $finish;
    end
endmodule
