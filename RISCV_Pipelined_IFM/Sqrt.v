
module Sqrt#(parameter XLEN=32)
                    (input [XLEN-1:0] a_operand,                                      
                     output exception,
							output zero_division,
                     output [XLEN-1:0] result);
wire [7:0] Exponent;
wire [22:0] Mantissa;
wire Sign;
wire [XLEN-1:0] temp1,temp2,temp3,temp4,temp5,temp6,temp7,temp8,temp;
wire [XLEN-1:0] x0,x1,x2,x3;
wire [XLEN-1:0] sqrt_1by05,sqrt_2,sqrt_1by2;
wire [7:0] Exp_2,Exp_Adjust;
wire remainder;
wire pos;

assign x0 = 32'h3f5a827a;
assign sqrt_1by05 = 32'h3fb504f3;  // 1/sqrt(0.5)
assign sqrt_2 = 32'h3fb504f3;
assign sqrt_1by2 = 32'h3f3504f3;
assign Sign = a_operand[31];
assign Exponent = a_operand[30:23];
assign Mantissa = a_operand[22:0];

// ----- Exception detect -----
assign exception = &a_operand[30:23];
assign zero_division = (a_operand[30:0] == 31'd0) ? 1'b1 : 1'b0;
/*----First Iteration----*/
Division2 D1({1'b0,8'd126,Mantissa},x0,,,temp1);
Addition_Subtraction A1(temp1,x0,0,,temp2);
assign x1 = {temp2[31],temp2[30:23]-1,temp2[22:0]};
/*----Second Iteration----*/
Division2 D2({1'b0,8'd126,Mantissa},x1,,,temp3);
Addition_Subtraction A2(temp3,x1,0,,temp4);
assign x2 = {temp4[31],temp4[30:23]-1,temp4[22:0]};
/*----Third Iteration----*/
Division2 D3({1'b0,8'd126,Mantissa},x2,,,temp5);
Addition_Subtraction A3(temp5,x2,0,,temp6);
assign x3 = {temp6[31],temp6[30:23]-1,temp6[22:0]};
Multiplication M1(x3,sqrt_1by05,,,,temp7);
assign pos = (Exponent>=8'd127) ? 1'b1 : 1'b0;
assign Exp_2 = pos ? (Exponent-8'd127)/2 : (Exponent-8'd127-1)/2 ;
assign remainder = (Exponent-8'd127)%2;
assign temp = {temp7[31],Exp_2 + temp7[30:23],temp7[22:0]};
//assign temp7[30:23] = Exp_2 + temp7[30:23];
Multiplication M2(temp,sqrt_2,,,,temp8);
assign final_exp = remainder ? temp8 : temp;
// ----- Final result -----
assign result = exception ? 32'hFFC00000 : zero_division ? {Sign,31'd0} : (remainder ? {Sign,temp8[30:0]} : {Sign,temp[30:0]});                                           
endmodule