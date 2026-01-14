module ConvertUnstoInt(
    input  [31:0] float_in,
    output reg [31:0] int_out
);
    wire sign = float_in[31];
    wire [7:0] exponent = float_in[30:23];
    wire [22:0] fraction = float_in[22:0];
    reg [31:0] value;
    integer E;

    always @(*) begin
        if (sign) begin
            // Nếu là số âm -> ép về 0 (vì không dấu)
            int_out = 32'd0;
        end
        else if (exponent < 127) begin
            // Số < 1.0 -> làm tròn về 0
            int_out = 32'd0;
        end
        else if (exponent > 158) begin
            // exponent - 127 > 31 => vượt giới hạn 32-bit
            int_out = 32'hFFFFFFFF;  // max unsigned 32-bit
        end
        else begin
            E = exponent - 127;

            // mantissa = 1.fraction (24 bit)
            value = {1'b1, fraction};

            // Dịch bit theo mũ
            if (E > 23)
                value = value << (E - 23);
            else
                value = value >> (23 - E);

            // Không áp dấu vì là unsigned
            int_out = value;
        end
    end
endmodule
