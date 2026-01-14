module hazard_unit (
    input regWrite_M,
	 input regFWrite_M,
    input regWrite_W,
	 input regFWrite_W,
	 input PCSrc_E,
	 input resultSrc_E,
    input [4:0] rd_M,
    input [4:0] rd_W,
    input [4:0] rs1_D,
    input [4:0] rs2_D,
	 input [4:0] rs3_D,
    input [4:0] rs1_E,
    input [4:0] rs2_E,
	 input [4:0] rs3_E,
    input [4:0] rd_E,
	 input busy,done,
	 
    output reg [1:0] forwardAE,
    output reg [1:0] forwardBE,
	 output reg [1:0] forwardAFE,
	 output reg [1:0] forwardBFE,
	 output reg [1:0] forwardCFE,
    output stall,
    output flush
);
// forward AE
    always @(*) begin
        if (regWrite_M && (rd_M != 0) && (rd_M == rs1_E)) begin
            forwardAE <= 2'b10;
        end
        else if (regWrite_W && (rd_M != 0) && (rd_W == rs1_E)) begin         
            forwardAE <= 2'b01;
        end
        else forwardAE <= 2'b00;
    end
// forward BE
    always @(*) begin
        if (regWrite_M && (rd_M != 0) && (rd_M == rs2_E)) begin
            forwardBE <= 2'b10;
        end
        else if (regWrite_W && (rd_M != 0) && (rd_W == rs2_E)) begin
            forwardBE <= 2'b01;
        end
        else forwardBE <= 2'b00;
    end
// forward AFE
	 always @(*) begin
        if (regFWrite_M && (rd_M != 0) && (rd_M == rs1_E)) begin
            forwardAFE <= 2'b10;
        end
        else if (regFWrite_W && (rd_M != 0) && (rd_W == rs1_E)) begin
            forwardAFE <= 2'b01;
        end
        else forwardAFE <= 2'b00;
    end
// forward BFE
	 always @(*) begin
        if (regFWrite_M && (rd_M != 0) && (rd_M == rs2_E)) begin
            forwardBFE <= 2'b10;
        end
        else if (regWrite_W && (rd_M != 0) && (rd_W == rs2_E)) begin
            forwardBFE <= 2'b01;
        end
        else forwardBFE <= 2'b00;
    end
// forward CFE 
	 always @(*) begin
        if (regFWrite_M && (rd_M != 0) && (rd_M == rs3_E)) begin
            forwardCFE <= 2'b10;
        end
        else if (regWrite_W && (rd_M != 0) && (rd_W == rs3_E)) begin
            forwardCFE <= 2'b01;
        end
        else forwardCFE <= 2'b00;
    end
// Load hazard
    assign stall = (((resultSrc_E == 1'b1) && ((rs1_D == rd_E) || (rs2_D == rd_E) || (rs3_D == rd_E))) || (busy == 1'b1) || (done == 1'b1)) ? 1'b1 : 1'b0;

    assign flush = PCSrc_E;
endmodule
