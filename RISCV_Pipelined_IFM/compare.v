module compare (
    input  [31:0] a_operand, 
    input  [31:0] b_operand,
    input  [1:0]  mode,   // 00: equal, 01: less-than, 10: less-or-equal
    output reg    result
);

wire signA = a_operand[31];
wire signB = b_operand[31];
wire [7:0] expA = a_operand[30:23];
wire [7:0] expB = b_operand[30:23];
wire [22:0] fracA = a_operand[22:0];
wire [22:0] fracB = a_operand[22:0];

// Chuẩn IEEE-754: +0.0 == -0.0
wire both_zero = (a_operand[30:0] == 31'd0) && (b_operand[30:0] == 31'd0);

always @(*) begin
    result = 1'b0; // default

    case(mode)

        // ========= MODE 00: A == B (feq.s) =========
        2'b00: begin
            if ((a_operand == b_operand) || both_zero)
                result = 1'b1;
            else
                result = 1'b0;
        end

        // ========= MODE 01: A < B (flt.s) =========
        2'b01: begin
            if (both_zero) begin
                result = 1'b0; // +0 < -0 => false
            end else if (signA != signB) begin
                result = (signA); // nếu A âm và B dương => A < B
            end else begin
                if (expA != expB)
                    result = (signA) ? (expA > expB) : (expA < expB);
                else if (fracA != fracB)
                    result = (signA) ? (fracA > fracB) : (fracA < fracB);
                else
                    result = 1'b0; // bằng nhau thì không < 
            end
        end

        // ========= MODE 10: A <= B (fle.s) =========
        2'b10: begin
            if ((a_operand == b_operand) || both_zero) begin
                result = 1'b1; // bằng nhau => TRUE
            end else begin
                // tái sử dụng logic của A < B
                if (signA != signB)
                    result = (signA); 
                else begin
                    if (expA != expB)
                        result = (signA) ? (expA > expB) : (expA < expB);
                    else if (fracA != fracB)
                        result = (signA) ? (fracA > fracB) : (fracA < fracB);
                    else
                        result = 1'b0; 
                end
            end
        end

        default: result = 1'b0;

    endcase
end

endmodule
