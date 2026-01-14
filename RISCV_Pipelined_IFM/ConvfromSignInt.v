module ConvfromSignInt(
    input  [31:0] int_in,
    output reg [31:0] float_out
);
    reg sign;
    reg [31:0] abs_val;
    reg [7:0] exponent;
    reg [22:0] mantissa;
    integer i;
    reg [55:0] shifted;  // Khai báo đầy đủ mảng reg

    always @(*) begin
        if (int_in == 32'd0) begin
            float_out = 32'd0;
        end 
        else begin
            // 1. Lấy dấu và trị tuyệt đối
            sign = int_in[31];
            abs_val = sign ? -int_in : int_in;

            // 2. Tìm vị trí bit '1' cao nhất
            i = 31;
            while (i > 0 && abs_val[i] == 0)
                i = i - 1;

            // 3. Tính exponent (bias = 127)
            exponent = 127 + i;

            // 4. Dịch bit để tạo mantissa
            if (i > 23)
                shifted = abs_val >> (i - 23);
            else
                shifted = abs_val << (23 - i);

            mantissa = shifted[22:0];

            // 5. Tổ hợp IEEE-754
            float_out = {sign, exponent, mantissa};
        end
    end
endmodule
