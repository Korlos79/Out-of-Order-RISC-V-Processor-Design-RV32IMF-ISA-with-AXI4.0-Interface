`timescale 1ns/1ps

module TB_Sqrt();
    reg clk, rst_n, start;
    reg [31:0] A;
    wire done, exc, zero;
    wire [31:0] result;

	 real a_real;
	 real start_time;
	 real res_real;
	 
    Sqrt dut (
        .clk(clk), .rst_n(rst_n), .start(start), .A(A),
        .done(done), .result(result), .exception(exc), .zero_sqrt(zero)
    );

    initial begin
        clk = 0; 
		  forever #5 clk = ~clk;
    end

    task test_sqrt;
        input [31:0] val_hex;
        begin
            A = val_hex;
				a_real = $bitstoshortreal(A);
            @(posedge clk); 
				start = 1; 
				start_time = $realtime;
				@(posedge clk); start = 0;
            wait(done);
				res_real = $bitstoshortreal(result);
				
            $display("Input: %f -> Sqrt: %f (Exc: %b)", a_real, res_real, exc);
				$display("Cycles: %0d cycles", ($realtime - start_time)/10 - 1); // Trừ 1 do delay logic
        end
    endtask

    initial begin
        rst_n = 0; 
		  start = 0; 
		  A = 0;
        #20 rst_n = 1;

        $display("=== SQRT TEST ===");
        
        // 1. Sqrt(4.0) = 2.0
        // 4.0 = 40800000 -> Expect 2.0 = 40000000
        test_sqrt(32'h40800000);

        // 2. Sqrt(2.0) = 1.4142...
        // 2.0 = 40000000 -> Expect 3FB504F3
        test_sqrt(32'h40000000);

        // 3. Sqrt(9.0) = 3.0
        // 9.0 = 41100000 -> Expect 40400000
        test_sqrt(32'h41100000);

        // 4. Sqrt(-4.0) -> NaN
        test_sqrt(32'hC0800000);
        
		  test_sqrt(32'h3F000000);
        $finish;
    end
endmodule