module ConverttoInt(
    input  [31:0] float_in,
    output reg [31:0] int_out
);
    wire sign = float_in[31];
    wire [7:0] exponent = float_in[30:23];
    wire [22:0] fraction = float_in[22:0];
    reg [31:0] value;
    integer E;

    always @(*) begin
        if (exponent == 8'd0) begin
            // số 0 hoặc subnormal → coi như 0
            int_out = 32'd0;
        end
        else if (exponent < 127) begin
            // |float| < 1.0 → làm tròn về 0
            int_out = 32'd0;
        end
        else if (exponent > 158) begin
            // exponent - 127 > 31 → tràn 32-bit integer
            int_out = sign ? 32'h80000000 : 32'h7FFFFFFF;
        end
        else begin
            // mantissa (1.fraction)
            value = {1'b1, fraction}; // 24-bit normalized mantissa
            E = exponent - 127;

            // Dịch bit theo mũ
            if (E > 23)
                value = value << (E - 23);
            else
                value = value >> (23 - E);

            // Áp dấu
            int_out = sign ? -value : value;
        end
    end
endmodule
