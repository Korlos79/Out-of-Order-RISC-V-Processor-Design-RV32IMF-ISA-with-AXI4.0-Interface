
module division#(parameter XLEN=32)
                        (input [XLEN-1:0]A,
                         input [XLEN-1:0]B,
                         output zero_division,
								 output Exception,Overflow,Underflow,
                         output [XLEN-1:0] result);

wire [7:0] Exponent;
wire [31:0] temp1, temp2, temp3, temp4, temp5, temp6, temp7, result_unprotected;
wire [31:0] reciprocal;
wire [31:0] x0,x1,x2,x3;
wire [11:0] excp;
wire [7:0] over, under;
wire sign;
// zero division flag
assign zero_division = (B[30:23] == 0) ? 1'b1 : 1'b0;
/*----Initial value----       B_Mantissa * (2 ^ -1)            32 / 17 */
Multiplication M1({{1'b0,8'd126,B[22:0]}},32'h3ff0f0f1,excp[0],over[0],under[0],temp1); //verified
//                         48 / 17        -abs(temp1)
Addition_Subtraction A1(32'h4034b4b5,{1'b1,temp1[30:0]},1'b0,excp[1],x0);
/*----First Iteration----*/
Multiplication M2({{1'b0,8'd126,B[22:0]}},x0,excp[2],over[1],under[1],temp2);
//                         +2            -temp2
Addition_Subtraction A2(32'h40000000,{!temp2[31],temp2[30:0]},1'b0,excp[3],temp3);
Multiplication M3(x0,temp3,excp[4],over[2],under[2],x1);
/*----Second Iteration----*/
Multiplication M4({1'b0,8'd126,B[22:0]},x1,excp[5],over[3],under[3],temp4);
Addition_Subtraction A3(32'h40000000,{!temp4[31],temp4[30:0]},1'b0,excp[6],temp5);
Multiplication M5(x1,temp5,excp[7],over[4],under[4],x2);
/*----Third Iteration----*/
Multiplication M6({1'b0,8'd126,B[22:0]},x2,excp[8],over[5],under[5],temp6);
Addition_Subtraction A4(32'h40000000,{!temp6[31],temp6[30:0]},1'b0,excp[9],temp7);
Multiplication M7(x2,temp7,excp[10],over[6],under[6],x3);
/*----Reciprocal : 1/B----*/
assign Exponent = x3[30:23]+8'd126-B[30:23];
assign reciprocal = {B[31],Exponent,x3[22:0]};
/*----Multiplication A*1/B----*/
Multiplication M8(A,reciprocal,excp[11],over[7],under[7],result_unprotected);
assign Exception = |excp;
assign Overflow = |over;
assign Underflow = |under;
assign sign = result_unprotected[31];
assign result = Exception ? 32'd0 : zero_division ? {sign,31'd0} : Overflow ? {sign,8'hFF,23'd0} : Underflow ? {sign,31'd0} : {result_unprotected};
endmodule