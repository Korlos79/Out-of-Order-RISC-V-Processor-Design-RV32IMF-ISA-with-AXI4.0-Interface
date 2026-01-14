module ID_EX_register (
	input MemReadD, MemWriteD, JumpD, RegWriteD, RegFWriteD, BranchD, MuxjalrD, Stall, clk, reset, flush, WriteBackD,
	input [4:0] OpD,
	input [2:0]  funct3D,
	input [31:0] RD1D, RD2D, PCD, 
	input [31:0] RFD1D, RFD2D, RFD3D,
	input [4:0] RdD, Rs1D, Rs2D, Rs3D,
	input [31:0] ImmExtD,
	input [1:0] ALUSrcAD, ALUSrcBD,
	input FLRD, FtoID,
	input src1_is_floatD,
   input src2_is_floatD,
   input src3_is_floatD,
	
	output reg MemReadE, MemWriteE, JumpE, RegWriteE, RegFWriteE, BranchE, MuxjalrE, WriteBackE,
	output reg [4:0] OpE,
	output reg [2:0] funct3E,
	output reg [31:0] RD1E, RD2E, PCE,
	output reg [31:0] RFD1E, RFD2E, RFD3E,
	output reg [4:0] RdE, Rs1E, Rs2E, Rs3E,
	output reg [31:0] ImmExtE,
	output reg [1:0] ALUSrcAE, ALUSrcBE,
	output reg FtoIE, FLRE,
	output reg src1_is_floatE,
   output reg src2_is_floatE,
   output reg src3_is_floatE
);

	always @(posedge clk or negedge reset) begin
		if (~reset) begin
			MemReadE <= 0; MemWriteE <= 0; JumpE <= 0; RegWriteE <= 0; RegFWriteE <= 0; BranchE <= 0; MuxjalrE <= 0; src1_is_floatE <= 0; src2_is_floatE <= 0; src3_is_floatE <= 0;
			OpE <= 5'b00000; WriteBackE <= 0; RD1E <= 32'd0; RD2E <= 32'd0; RFD1E <= 32'b0; RFD2E <= 32'b0; RFD3E <= 32'b0; PCE <= 32'd0;
			RdE <= 5'd0; ImmExtE <= 32'd0; funct3E <= 3'b000; Rs1E <= 5'd0; Rs2E <= 5'd0; Rs3E <= 5'd0 ; ALUSrcAE = 2'd0; ALUSrcBE = 2'd0; FLRE <= 1'b0; FtoIE <= 1'b0;
		end
		else if(flush) begin
			MemReadE <= 0; MemWriteE <= 0; JumpE <= 0; RegWriteE <= 0; RegFWriteE <= 0; BranchE <= 0; MuxjalrE <= 0; src1_is_floatE <= 0; src2_is_floatE <= 0; src3_is_floatE <= 0;
			OpE <= 5'b00000; WriteBackE <= 0; RD1E <= 32'd0; RD2E <= 32'd0; RFD1E <= 32'b0; RFD2E <= 32'b0; RFD3E <= 32'b0; PCE <= 32'd0;
			RdE <= 5'd0; ImmExtE <= 32'd0; funct3E <= 3'b000; Rs1E <= 5'd0; Rs2E <= 5'd0; Rs3E <= 5'd0 ; ALUSrcAE = 2'd0; ALUSrcBE = 2'd0; FLRE <= 1'b0; FtoIE <= 1'b0;
		end
		else if(!Stall)begin
			MemReadE <= MemReadD;
			MemWriteE <= MemWriteD;
			JumpE <= JumpD;
			RegWriteE <= RegWriteD;
			RegFWriteE <= RegFWriteD;
			BranchE <= BranchD;
			MuxjalrE <= MuxjalrD;
			OpE <= OpD;
			WriteBackE <= WriteBackD;
			RD1E <= RD1D; 
			RD2E <= RD2D;
			RFD1E <= RFD1D;
			RFD2E <= RFD2D;
			RFD3E <= RFD3D;
			PCE <= PCD;
			RdE <= RdD;
			ImmExtE <= ImmExtD;
			ALUSrcAE <= ALUSrcAD; 
			ALUSrcBE <= ALUSrcBD;
			funct3E <= funct3D;
			Rs1E <= Rs1D; Rs2E <= Rs2D; Rs3E <= Rs3D;
			FLRE <= FLRD; FtoIE <= FtoID;
			src1_is_floatE <= src1_is_floatD;
			src2_is_floatE <= src2_is_floatD;
			src3_is_floatE <= src3_is_floatD;
		end
		else begin
			RegWriteE <= 0; 
			RegFWriteE <= 0;
			MemWriteE <= 0;
			MemReadE <= MemReadE;
			JumpE <= JumpE;
			BranchE <= BranchE;
			MuxjalrE <= MuxjalrE;
			OpE <= OpE;
			WriteBackE <= WriteBackE;
			RD1E <= RD1E; 
			RD2E <= RD2E;
			PCE <= PCE;
			RdE <= RdE;
			ImmExtE <= ImmExtE;
			funct3E <= funct3E;
			Rs1E <= Rs1E; Rs2E <= Rs2E; Rs3E <= Rs3E;
			ALUSrcAE <= ALUSrcAE;
			ALUSrcBE <= ALUSrcBE;
			FLRE <= FLRE; FtoIE <= FtoIE;
			RFD1E <= RFD1E;
			RFD2E <= RFD2E;
			RFD3E <= RFD3E;
			src1_is_floatE <= src1_is_floatE;
			src2_is_floatE <= src2_is_floatE;
			src3_is_floatE <= src3_is_floatE;
		end
	end
endmodule 



