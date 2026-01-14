module Control_Unit (
	input [6:0] funct7, opcode,
	input [2:0] funct3,
	input [4:0] rs2,
	output reg MemReadD, MemWriteD, JumpD, RegWriteD, RegFWriteD, BranchD, MuxjalrD, WriteBackD,
	output reg [1:0] ALUSrcA_D, ALUSrcB_D,
	output reg [4:0] ALUOpD,
	output reg [4:0] FPUOpD,
	output reg [2:0] ImmControlD,
	output reg ItoFD,
	output reg FtoID,
	output reg FLRD
);
	localparam R = 7'b0110011;
   localparam I = 7'b0010011;
	localparam LOAD = 7'b0000011;
	localparam JALR = 7'b1100111;
   localparam STORE = 7'b0100011;
   localparam B = 7'b1100011;
	localparam LUI = 7'b0110111;
	localparam AUIPC = 7'b0010111;
   localparam J = 7'b1101111;
	localparam F_R = 7'b1010011;
	localparam F_LOAD = 7'b0000111;
	localparam F_STORE = 7'b0100111;
	localparam F_MADD = 7'b1000011;
	localparam F_MSUB = 7'b1000111;
	localparam F_NMADD = 7'b1001111;
	localparam F_NMSUB = 7'b1001011;
	localparam M = 7'b0110011;
	
	always @(*) begin
		case(opcode)
			R: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 1; RegFWriteD <= 0; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b00; FLRD <= 0;
			end
			I: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 1; RegFWriteD <= 0; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b01; FLRD <= 0;
			end
			LOAD: begin
				MemReadD <= 1; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 1; RegFWriteD <= 0; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 1;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b01; FLRD <= 0;
			end
			STORE: begin
				MemReadD <= 0; MemWriteD <= 1; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 0; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b01; FLRD <= 0;
			end
			JALR: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 1; RegWriteD <= 1; RegFWriteD <= 0; BranchD <= 0; MuxjalrD <= 1; WriteBackD <= 0;
				ALUSrcA_D <= 2'b01; ALUSrcB_D <= 2'b10; FLRD <= 0;
			end
			B: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 0; BranchD <= 1; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b00; FLRD <= 0;
			end
			LUI: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 1; RegFWriteD <= 0; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b10; ALUSrcB_D <= 2'b01; FLRD <= 0;
			end
			AUIPC: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 1; RegFWriteD <= 0; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b01; ALUSrcB_D <= 2'b01; FLRD <= 0;
			end
			J: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 1; RegWriteD <= 1; RegFWriteD <= 0; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b01; ALUSrcB_D <= 2'b10; FLRD <= 0;
			end
			F_R: begin	
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 1; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b00; FLRD <= 0;
			end
			F_LOAD: begin
				MemReadD <= 1; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 1; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 1;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b01; FLRD <= 0;
			end
			F_STORE: begin
				MemReadD <= 0; MemWriteD <= 1; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 0; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b01; FLRD <= 1;
			end
			F_MADD: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 1; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b00; FLRD <= 0;
			end
			F_MSUB: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 1; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b00; FLRD <= 0;
			end
			F_NMADD: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 1; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b00; FLRD <= 0;
			end
			F_NMSUB: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 1; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b00; FLRD <= 0;	
			end
			default: begin
				MemReadD <= 0; MemWriteD <= 0; JumpD <= 0; RegWriteD <= 0; RegFWriteD <= 1; BranchD <= 0; MuxjalrD <= 0; WriteBackD <= 0;
				ALUSrcA_D <= 2'b00; ALUSrcB_D <= 2'b00; FLRD <= 0;
			end
		endcase
		
		//ALU Control
		casex({opcode, funct3, funct7})
			17'b0110011_000_0100000: ALUOpD <= 5'b01000; //sub
			17'b0110011_100_0000000: ALUOpD <= 5'b00100; //xor
			17'b0110011_110_0000000: ALUOpD <= 5'b00110; //or
			17'b0110011_111_0000000: ALUOpD <= 5'b00111; //and
			17'b0110011_001_0000000: ALUOpD <= 5'b00001; //sll
			17'b0110011_101_0000000: ALUOpD <= 5'b00101; //srl
			17'b0110011_101_0100000: ALUOpD <= 5'b01001; //sra
			17'b0110011_010_0000000: ALUOpD <= 5'b00010; //slt
			17'b0110011_011_0000000: ALUOpD <= 5'b00011; //sltu
			17'b0110011_000_0000001: ALUOpD <= 5'b01001;//mul
			17'b0110011_001_0000001: ALUOpD <= 5'b01010;//mulh
			17'b0110011_010_0000001: ALUOpD <= 5'b01011;//mulsu
			17'b0110011_011_0000001: ALUOpD <= 5'b01100;//mulu
			17'b0110011_100_0000001: ALUOpD <= 5'b01101;//div
			17'b0110011_101_0000001: ALUOpD <= 5'b01110;//divu
			17'b0110011_110_0000001: ALUOpD <= 5'b01111;//rem
			17'b0110011_111_0000001: ALUOpD <= 5'b10000;//remu
			
		
			17'b0010011_100_0000000: ALUOpD <= 5'b00100; //xori
			17'b0010011_110_0000000: ALUOpD <= 5'b00110; //ori
			17'b0010011_111_0000000: ALUOpD <= 5'b00111; //andi
			17'b0010011_001_0000000: ALUOpD <= 5'b00001; //slli
			17'b0010011_101_0000000: ALUOpD <= 5'b00101; //srli
			17'b0010011_101_0100000: ALUOpD <= 5'b01001; //srai
			17'b0010011_010_0000000: ALUOpD <= 5'b00010; //slti
			17'b0010011_011_0000000: ALUOpD <= 5'b00011; //sltui
			default: ALUOpD <= 4'b0000;
		endcase
			
		//Imm Control
		casex({opcode, funct3, funct7})
			17'b0010011_011_0000000: ImmControlD <= 3'b001; //sltui
			
			17'b0010011_001_0000000: ImmControlD <= 3'b010;  //slli
			17'b0010011_101_0000000: ImmControlD <= 3'b010;  //srli
			17'b0010011_101_0100000: ImmControlD <= 3'b010;  //srai
			
			17'b0100011_xxx_xxxxxxx: ImmControlD <= 3'b011;  //store
			
			17'b1100011_xxx_xxxxxxx: ImmControlD <= 3'b100;  //branch
			
			17'b0110111_xxx_xxxxxxx: ImmControlD <= 3'b101;  //lui
			17'b0010111_xxx_xxxxxxx: ImmControlD <= 3'b101;  //auiPC
			
			17'b1101111_xxx_xxxxxxx: ImmControlD <= 3'b110;  //jal
			
			default: ImmControlD <= 3'b000;
		endcase
		//Floating Point Control
		casex({opcode, rs2, funct3, funct7})
			22'b1010011_xxxxx_xxx_0000000: begin
			FPUOpD <= 5'd1; ItoFD <= 1'b0; FtoID <= 0;//fadd
			end
			22'b1010011_xxxxx_xxx_0000100: begin
			FPUOpD <= 5'd2; ItoFD <= 1'b0; FtoID <= 0;//fsub
			end
			22'b1010011_xxxxx_xxx_0001000: begin
			FPUOpD <= 5'd3; ItoFD <= 1'b0; FtoID <= 0;//fmul
			end
			22'b1010011_xxxxx_xxx_0001100: begin
			FPUOpD <= 5'd4; ItoFD <= 1'b0; FtoID <= 0;//fdiv
			end
			22'b1010011_00000_xxx_0101100: begin
			FPUOpD <= 5'd5; ItoFD <= 1'b0; FtoID <= 0;//fsqrt
			end
			22'b1010011_xxxxx_000_0010000: begin
			FPUOpD <= 5'd11; ItoFD <= 1'b0; FtoID <= 0;//fsgnj.s
			end
			22'b1010011_xxxxx_001_0010000: begin
			FPUOpD <= 5'd12; ItoFD <= 1'b0; FtoID <= 0;//fsgnjn.s
			end
			22'b1010011_xxxxx_010_0010000: begin
			FPUOpD <= 5'd13; ItoFD <= 1'b0; FtoID <= 0;//fsgnjx.s
			end
			22'b1010011_xxxxx_000_0010100: begin
			FPUOpD <= 5'd24; ItoFD <= 1'b0; FtoID <= 0;//fmin
			end
			22'b1010011_xxxxx_001_0010100: begin
			FPUOpD <= 5'd25; ItoFD <= 1'b0; FtoID <= 0;//fmax
			end
			22'b1010011_00000_xxx_1100000: begin
			FPUOpD <= 5'd21; ItoFD <= 1'b0; FtoID <= 1;//fcvt.w.s
			end
			22'b1010011_00001_xxx_1100000: begin
			FPUOpD <= 5'd22; ItoFD <= 1'b0; FtoID <= 1;//fcvt.wu.s
			end
			22'b1010011_00000_000_1110000: begin
			FPUOpD <= 5'd23; ItoFD <= 1'b1; FtoID <= 0;//fmv.x.w
			end
			22'b1010011_xxxxx_000_1010000: begin
			FPUOpD <= 5'd16; ItoFD <= 1'b0; FtoID <= 0;//fle.s
			end
			22'b1010011_xxxxx_001_1010000: begin
			FPUOpD <= 5'd15; ItoFD <= 1'b0; FtoID <= 0;//flt.s
			end
			22'b1010011_xxxxx_010_1010000: begin
			FPUOpD <= 5'd14; ItoFD <= 1'b0; FtoID <= 0;//feq.s
			end
			22'b1010011_00000_xxx_1101000: begin
			FPUOpD <= 5'd19; ItoFD <= 1'b1; FtoID <= 0;//fcvt.s.w
			end
			22'b1010011_00001_xxx_1101000: begin
			FPUOpD <= 5'd20; ItoFD <= 1'b1; FtoID <= 0;//fcvt.s.wu
			end
			22'b1010011_00000_000_1111000: begin
			FPUOpD <= 5'd23; ItoFD <= 1'b0; FtoID <= 1;//fmv.w.x
			end
			22'b1000011_xxxxx_xxx_xxxxx00: begin
			FPUOpD <= 5'd5; ItoFD <= 1'b0; FtoID <= 0;//fmadd
			end
			22'b1000111_xxxxx_xxx_xxxxx00: begin
			FPUOpD <= 5'd6; ItoFD <= 1'b0; FtoID <= 0;//fmsub
			end
			22'b1001011_xxxxx_xxx_xxxxx00: begin
			FPUOpD <= 5'd8; ItoFD <= 1'b0; FtoID <= 0;//fnmsub
			end
			22'b1001111_xxxxx_xxx_xxxxx00: begin
			FPUOpD <= 5'd7; ItoFD <= 1'b0; FtoID <= 0;//fnmadd
			end
			default: begin
			FPUOpD <= 5'b00000; ItoFD <= 1'b0; FtoID <= 1'b0;
			end
		endcase
	end
endmodule 
