`timescale 1ns/1ps

module testlenh;

    // clk & rst
    reg clk;
    reg reset;

    //====================== FETCH STAGE ======================
    wire [31:0] nextPCF_check;
    wire [31:0] PCF_check;
    wire [31:0] InstrF_check;

    //====================== DECODE STAGE =====================
    wire [31:0] InstrD_check;
    wire [31:0] ImmExtD_check;
    wire [4:0]  Rs1D_check, Rs2D_check, Rs3D_check, RdD_check;
    wire        ResultSrcD_check;
    wire        RegWriteD_check, RegFWriteD_check;
    wire        MemReadD_check, MemWriteD_check;
    wire        BranchD_check, JumpD_check;
    wire        MuxjalrD_check;
    wire [3:0]  ALUControlD_check;
    wire [4:0]  FLUControlD_check;
    wire [1:0]  ALUSrcAD_check, ALUSrcBD_check;

    //====================== EXECUTE STAGE ====================
    wire [31:0]  PCD_check;
    wire [4:0]   Rs1E_check, Rs2E_check, Rs3E_check, RdE_check;
    wire [31:0]  RD1E_check, RD2E_check;
    wire [31:0]  RFD1E_check, RFD2E_check, RFD3E_check;
    wire [31:0]  SrcAE_check, SrcBE_check, WriteDataE_check;
	 wire [31:0]  SrcAFE_check, SrcBFE_check, SrcCFE_check;
    wire [31:0]  PCTargetE_check;
    wire [31:0]  ALUResultE_check, FLUResultE_check;
    wire         ResultSrcE_check;
    wire         RegWriteE_check, RegFWriteE_check;
    wire         MemReadE_check, MemWriteE_check;
    wire         BranchE_check, JumpE_check;
    wire         MuxjalrE_check;
    wire [3:0]   ALUControlE_check;
    wire [4:0]   FLUControlE_check;
    wire [1:0]   ALUSrcAE_check, ALUSrcBE_check;
    wire         PCSrcE_check, FlagE_check;
    wire         ItoFE_check, FtoIE_check;

    //====================== MEMORY STAGE =====================
    wire [4:0]   RdM_check;
    wire [31:0]  ALUResultM_check, FLUResultM_check, ReadDataM_check;
    wire         ResultSrcM_check;
    wire         RegWriteM_check, RegFWriteM_check;
    wire         MemReadM_check, MemWriteM_check;
    wire         FLRM_check;

    //====================== WRITEBACK STAGE ==================
    wire [4:0]   RdW_check;
    wire [31:0]  ResultW_check;
    wire         ResultSrcW_check;
    wire         RegWriteW_check, RegFWriteW_check;
    wire         RegWriteWFinal_check, RegFWriteWFinal_check;
    wire         FtoIW_check;

    //====================== CONTROL & HAZARD =================
    wire         Stall_check, Flush_check;
    wire [1:0]   ForwardAE_check, ForwardBE_check;
    wire [1:0]   ForwardFAE_check, ForwardFBE_check, ForwardFCE_check;

    //====================== FLOATING CONTROL =================
    wire         FLRE_check, FLRD_check;
    wire         ItoFD_check, FtoID_check;
	
	 integer f,i;
    // Instantiate DUT
    rv32i_pipeline rvp (
        .clk(clk), .reset(reset),
        // FETCH
        .nextPCF_check(nextPCF_check),
        .PCF_check(PCF_check),
        .InstrF_check(InstrF_check),
        // DECODE
        .InstrD_check(InstrD_check),
        .ImmExtD_check(ImmExtD_check),
        .Rs1D_check(Rs1D_check), .Rs2D_check(Rs2D_check), .Rs3D_check(Rs3D_check), .RdD_check(RdD_check),
        .ResultSrcD_check(ResultSrcD_check),
        .RegWriteD_check(RegWriteD_check), .RegFWriteD_check(RegFWriteD_check),
        .MemReadD_check(MemReadD_check), .MemWriteD_check(MemWriteD_check),
        .BranchD_check(BranchD_check), .JumpD_check(JumpD_check),
        .MuxjalrD_check(MuxjalrD_check),
        .ALUControlD_check(ALUControlD_check),
        .FLUControlD_check(FLUControlD_check),
        .ALUSrcAD_check(ALUSrcAD_check), .ALUSrcBD_check(ALUSrcBD_check),
        // EXECUTE
        .PCD_check(PCD_check),
        .Rs1E_check(Rs1E_check), .Rs2E_check(Rs2E_check), .Rs3E_check(Rs3E_check), .RdE_check(RdE_check),
        .RD1E_check(RD1E_check), .RD2E_check(RD2E_check),
        .RFD1E_check(RFD1E_check), .RFD2E_check(RFD2E_check), .RFD3E_check(RFD3E_check),
        .SrcAE_check(SrcAE_check), .SrcBE_check(SrcBE_check), .SrcAFE_check(SrcAFE_check), .SrcBFE_check(SrcBFE_check), .SrcCFE_check(SrcCFE_check), .WriteDataE_check(WriteDataE_check),
        .PCTargetE_check(PCTargetE_check),
        .ALUResultE_check(ALUResultE_check), .FLUResultE_check(FLUResultE_check),
        .ResultSrcE_check(ResultSrcE_check),
        .RegWriteE_check(RegWriteE_check), .RegFWriteE_check(RegFWriteE_check),
        .MemReadE_check(MemReadE_check), .MemWriteE_check(MemWriteE_check),
        .BranchE_check(BranchE_check), .JumpE_check(JumpE_check),
        .MuxjalrE_check(MuxjalrE_check),
        .ALUControlE_check(ALUControlE_check),
        .FLUControlE_check(FLUControlE_check),
        .ALUSrcAE_check(ALUSrcAE_check), .ALUSrcBE_check(ALUSrcBE_check),
        .PCSrcE_check(PCSrcE_check), .FlagE_check(FlagE_check),
        .ItoFE_check(ItoFE_check), .FtoIE_check(FtoIE_check),
        // MEMORY
        .RdM_check(RdM_check),
        .ALUResultM_check(ALUResultM_check), .FLUResultM_check(FLUResultM_check), .ReadDataM_check(ReadDataM_check),
        .ResultSrcM_check(ResultSrcM_check),
        .RegWriteM_check(RegWriteM_check), .RegFWriteM_check(RegFWriteM_check),
        .MemReadM_check(MemReadM_check), .MemWriteM_check(MemWriteM_check),
        .FLRM_check(FLRM_check),
        // WRITEBACK
        .RdW_check(RdW_check),
        .ResultW_check(ResultW_check),
        .ResultSrcW_check(ResultSrcW_check),
        .RegWriteW_check(RegWriteW_check), .RegFWriteW_check(RegFWriteW_check),
        .RegWriteWFinal_check(RegWriteWFinal_check), .RegFWriteWFinal_check(RegFWriteWFinal_check),
        .FtoIW_check(FtoIW_check),
        // HAZARD & forwarding
        .Stall_check(Stall_check), .Flush_check(Flush_check),
        .ForwardAE_check(ForwardAE_check), .ForwardBE_check(ForwardBE_check),
        .ForwardFAE_check(ForwardFAE_check), .ForwardFBE_check(ForwardFBE_check), .ForwardFCE_check(ForwardFCE_check),
        // FLOAT
        .FLRE_check(FLRE_check), .FLRD_check(FLRD_check),
        .ItoFD_check(ItoFD_check), .FtoID_check(FtoID_check)
    );
    always #50 clk = ~clk;


    initial begin
        clk = 1;
        reset = 0;

        #50 reset = 1;

        #1000;
        f = $fopen("regfile_output.txt", "w");
        for (i = 0; i < 32; i = i + 1)
            $fdisplay(f, "x%0d = 0x%08h", i, rvp.rf.rf[i]);
        $fclose(f);

        #10 $stop;
    end
endmodule