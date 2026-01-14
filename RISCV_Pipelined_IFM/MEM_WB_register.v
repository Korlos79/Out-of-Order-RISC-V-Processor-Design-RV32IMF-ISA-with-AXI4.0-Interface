module MEM_WB_register (
	input RegWriteM, RegFWriteM, clk, reset,
	input  WriteBackM,
	input [31:0] ALUResultM, FLUResultM, ReadDataM,
	input [4:0] RdM,
	input FtoIM,
	
	output reg RegWriteW, RegFWriteW,
	output reg WriteBackW,
	output reg [31:0] ALUResultW, FLUResultW, ReadDataW,
	output reg FtoIW,
	output reg [4:0] RdW
);

always @(posedge clk or negedge reset) begin
	if (~reset) begin
		RegWriteW <= 0;
		RegFWriteW <= 0;
		WriteBackW <= 3'd0; 
		ALUResultW <= 32'd0; ReadDataW <= 32'd0;
		FLUResultW <= 32'd0;
		FtoIW <= 0;
		RdW <= 5'd0;
	end
	else begin
		RegWriteW <= RegWriteM;
		RegFWriteW <= RegFWriteM;
		WriteBackW <= WriteBackM;
		ALUResultW <= ALUResultM; ReadDataW <= ReadDataM;
		FLUResultW <= FLUResultM;
		FtoIW <= FtoIM;
		RdW <= RdM;
	end
end
endmodule 