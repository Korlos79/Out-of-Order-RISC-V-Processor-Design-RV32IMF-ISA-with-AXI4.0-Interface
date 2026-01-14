module FPU(
    input  [31:0] a_operand,
    input  [31:0] b_operand,
    input  [31:0] c_operand,
    input  [4:0]  FPUOpd,   // tăng lên 5-bit để chứa thêm lệnh
    output reg [31:0] result
);

wire [31:0] mul_ab, mul_neg_ab;
wire [31:0] add_res, sub_res;
wire [31:0] div_res, sqrt_res;
wire [31:0] madd_res, msub_res, nmadd_res, nmsub_res;
wire [31:0] fcvt_sw_res, fcvt_swu_res, fcvt_ws_res, fcvt_wsu_res;
wire cmp_eq, cmp_lt, cmp_le;

wire [31:0] a_neg = {~a_operand[31], a_operand[30:0]};
wire sign_xor = a_operand[31] ^ b_operand[31];

// --- gọi các module toán học ---
Multiplication M1(a_operand, b_operand, , , , mul_ab);
Multiplication M2(a_neg,     b_operand, , , , mul_neg_ab);
Addition_Subtraction ADD(a_operand, b_operand, 1'b0, , add_res);
Addition_Subtraction SUB(a_operand, b_operand, 1'b1, , sub_res);
division DIV(a_operand, b_operand, , , , , div_res);
Sqrt SQRT(a_operand, , , sqrt_res);
Addition_Subtraction AADD(mul_ab, c_operand, 1'b0, ,madd_res);
Addition_Subtraction BADD(mul_ab, c_operand, 1'b1, ,msub_res);
Addition_Subtraction CADD(mul_neg_ab, c_operand, 1'b0, ,nmadd_res);
Addition_Subtraction DADD(mul_neg_ab, c_operand, 1'b1, ,nmsub_res);
// --- Các module chuyển đổi ---
ConvfromSignInt  CVT1(a_operand, fcvt_sw_res);
ConvfromUnsInt CVT2(a_operand, fcvt_swu_res);
ConverttoInt  CVT3(a_operand, fcvt_ws_res);
ConvertUnstoInt CVT4(a_operand, fcvt_wsu_res);

// --- Bộ so sánh ---
compare CMP_EQ (a_operand, b_operand, 2'b00, cmp_eq);
compare CMP_LT (a_operand, b_operand, 2'b01, cmp_lt);
compare CMP_LE (a_operand, b_operand, 2'b10, cmp_le);

// --- Multiplexer điều khiển theo opcode ---
always @(*) begin
    case(FPUOpd)
        0:  result = add_res;             // fadd.s 
        1:  result = sub_res;             // fsub.s
        2:  result = mul_ab;              // fmul.s
        3:  result = div_res;             // fdiv.s
        4:  result = sqrt_res;            // fsqrt.s
        5:  result = madd_res;            // fmadd.s
        6:  result = msub_res;            // fmsub.s
        7:  result = nmadd_res;           // fnmadd.s
        8:  result = nmsub_res;           // fnmsub.s
        11: result = {b_operand[31], a_operand[30:0]};         // fsgnj.s
        12: result = {~b_operand[31], a_operand[30:0]};        // fsgnjn.s
        13: result = {sign_xor, a_operand[30:0]};              // fsgnjx.s
        14: result = {31'd0, cmp_eq};                          // feq.s
        15: result = {31'd0, cmp_lt};                          // flt.s
        16: result = {31'd0, cmp_le};                          // fle.s
        19: result = fcvt_sw_res;         // fcvt.s.w
        20: result = fcvt_swu_res;        // fcvt.s.wu
        21: result = fcvt_ws_res;         // fcvt.w.s
        22: result = fcvt_wsu_res;        // fcvt.wu.s
		  23: result = a_operand; 				// fmv.x.w & fmv.w.x
		  24: result = cmp_lt ? a_operand : b_operand; //fmin
		  25: result = cmp_lt ? b_operand : a_operand; //fmax
        default: result = 32'd0;
    endcase
end

endmodule
