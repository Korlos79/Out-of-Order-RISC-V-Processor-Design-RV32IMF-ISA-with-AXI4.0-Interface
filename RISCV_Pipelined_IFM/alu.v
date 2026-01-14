module alu (
	 input clk,
    input	[31:0] 	A,
	 input	[31:0]	B,
	 input	[4:0]		opcode,
	 input	[2:0]		branch,
	 output	reg 	[31:0]	result,
	 output	reg	Z,
	 output  reg busy,
	 output reg done
);

	 localparam beq = 3'b000 ;
    localparam bne = 3'b001 ;
    localparam blt = 3'b100 ;
    localparam bge = 3'b101 ;
    localparam bltu = 3'b110 ;
    localparam bgeu = 3'b111 ;
	 
	 wire [31:0] Mul, Mulh, Mulsu, Mulhu, Div, Divu, Rem, Remu;
	 wire busy1, busy2, busy3, busy4, busy5, busy6, busy7, busy8;
	 wire done1, done2, done3, done4, done5, done6, done7, done8;
	 reg op_valid;
	 
rv32m_muldiv_split MUL (.clk(clk), .rst_n(1'b1), .op_valid(op_valid), .op_sel(5'b10000), .rs1(A), .rs2(B), .busy(busy1), .done(done1), .result(Mul));
rv32m_muldiv_split MULH (.clk(clk), .rst_n(1'b1), .op_valid(op_valid), .op_sel(5'b10001), .rs1(A), .rs2(B), .busy(busy2), .done(done2), .result(Mulh)); 
rv32m_muldiv_split MULSU (.clk(clk), .rst_n(1'b1), .op_valid(op_valid), .op_sel(5'b10010), .rs1(A), .rs2(B), .busy(busy3), .done(done3), .result(Mulsu)); 
rv32m_muldiv_split MULHU (.clk(clk), .rst_n(1'b1), .op_valid(op_valid), .op_sel(5'b10011), .rs1(A), .rs2(B), .busy(busy4), .done(done4), .result(Mulhu)); 
rv32m_muldiv_split DIV (.clk(clk), .rst_n(1'b1), .op_valid(op_valid), .op_sel(5'b10100), .rs1(A), .rs2(B), .busy(busy5), .done(done5), .result(Div)); 
rv32m_muldiv_split DIVU (.clk(clk), .rst_n(1'b1), .op_valid(op_valid), .op_sel(5'b10101), .rs1(A), .rs2(B), .busy(busy6), .done(done6), .result(Divu)); 
rv32m_muldiv_split REM (.clk(clk), .rst_n(1'b1), .op_valid(op_valid), .op_sel(5'b10110), .rs1(A), .rs2(B), .busy(busy7), .done(done7), .result(Rem)); 
rv32m_muldiv_split REMU (.clk(clk), .rst_n(1'b1), .op_valid(op_valid), .op_sel(5'b10111), .rs1(A), .rs2(B), .busy(busy8), .done(done8), .result(Remu));   
	 always @(*) begin
		case(opcode)
			0: result <= A + B;
			1: result <= A << B[4:0];
			2: result <= ($signed(A) < $signed(B));
			3: result <= ($unsigned(A) < $unsigned(B));
			4: result <= A ^ B;
			5: result <= A >> B[4:0];
			6: result <= A | B ;
			7: result <= A & B;
			8: result <= A - B;
			9: begin 
			result <= Mul;
			busy <= busy1;
			done <= done1;
			op_valid <= 1'b1;
			end //mul
			10: begin 
			result <= Mulh;
			busy <= busy2;
			done <= done2;
			op_valid <= 1'b1;
			end //mulh
			11: begin 
			result <= Mulsu;
			busy <= busy3;
			done <= done3;
			op_valid <= 1'b1;
			end //mulsu
			12: begin 
			result <= Mulhu;
			busy <= busy4;
			done <= done4;
			op_valid <= 1'b1;
			end //mulhu
			13: begin 
			result <= Div;
			busy <= busy5;
			done <= done5;
			op_valid <= 1'b1;
			end //div
			14: begin 
			result <= Divu;
			busy <= busy6;
			done <= done6;
			op_valid <= 1'b1;
			end //divu
			15: begin 
			result <= Rem;
			busy <= busy7;
			done <= done7;
			op_valid <= 1'b1;
			end //rem
			16: begin 
			result <= Remu;
			busy <= busy8;
			done <= done8;
			op_valid <= 1'b1;
			end //remu
			default: begin 
			result <= 0;
			busy <= 0;
			done <= 0;
			op_valid <= 0;
			end
		endcase
		
		case (branch)
            beq:    Z = (A == B) ;
            bne:    Z = (A != B);
            blt:    Z = ($signed(A) < $signed(B));
            bge:    Z = ~($signed(A) < $signed(B));
            bltu:   Z =  $unsigned(A) < $unsigned(B) ;
            bgeu:   Z = ~($unsigned(A) < $unsigned(B));
            default: Z = 0;
       endcase
	end
	
endmodule 