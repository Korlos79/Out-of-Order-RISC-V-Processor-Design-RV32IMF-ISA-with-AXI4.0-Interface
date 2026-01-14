module ConvfromUnsInt(
    input  [31:0] int_in,
    output reg [31:0] float_out
);
    reg [31:0] abs_val, shifted;
    reg [7:0] exponent;
    reg [22:0] mantissa;
    integer i;

    always @(*) begin
        if (int_in == 32'd0) begin
            float_out = 32'd0;  // 0.0
        end else begin
            abs_val = int_in;

            // Tìm vị trí bit '1' cao nhất
            i = 31;
            while (i > 0 && abs_val[i] == 0)
                i = i - 1;

            exponent = 127 + i;

            // Dịch trái để chuẩn hóa (chia làm 2 bước)
            if (i > 23)
                shifted = abs_val << (31 - i);
            else
                shifted = abs_val << (23 - i);

            mantissa = shifted[31:9];  // cắt riêng

            float_out = {1'b0, exponent, mantissa};
        end
    end
endmodule
