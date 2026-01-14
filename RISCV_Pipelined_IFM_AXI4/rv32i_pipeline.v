module rv32i_pipeline (
	input clk, reset,

    // =========================================================================
    // GIAO DIỆN AXI4 MASTER (Kết nối ra RAM ngoài / Testbench)
    // =========================================================================
    // Write Address
    output [31:0] m_axi_awaddr,
    output        m_axi_awvalid,
    input         m_axi_awready,
    // Write Data
    output [31:0] m_axi_wdata,
    output [3:0]  m_axi_wstrb,
    output        m_axi_wvalid,
    input         m_axi_wready,
    // Write Response
    input         m_axi_bvalid,
    output        m_axi_bready,
    // Read Address
    output [31:0] m_axi_araddr,
    output        m_axi_arvalid,
    input         m_axi_arready,
    // Read Data
    input  [31:0] m_axi_rdata,
    input         m_axi_rvalid,
    output        m_axi_rready,

	//====================== FETCH STAGE ======================
	output [31:0] nextPCF_check,
	output [31:0] PCF_check,
	output [31:0] InstrF_check,

//====================== DECODE STAGE =====================
	output [31:0] InstrD_check,
	output [31:0] ImmExtD_check,
	output [4:0]  Rs1D_check, Rs2D_check, Rs3D_check, RdD_check,
	output        ResultSrcD_check,
	output        RegWriteD_check, RegFWriteD_check,
	output        MemReadD_check, MemWriteD_check,
	output        BranchD_check, JumpD_check,
	output        MuxjalrD_check,
	output [3:0]  ALUControlD_check,
	output [4:0]  FLUControlD_check,
	output [1:0]  ALUSrcAD_check, ALUSrcBD_check,

//====================== EXECUTE STAGE ====================
	output [31:0]  PCD_check,
	output [4:0]   Rs1E_check, Rs2E_check, Rs3E_check, RdE_check,
	output [31:0]  RD1E_check, RD2E_check,
	output [31:0]  RFD1E_check, RFD2E_check, RFD3E_check,
	output [31:0]  SrcAE_check, SrcBE_check, WriteDataE_check,
	output [31:0]  SrcAFE_check, SrcBFE_check, SrcCFE_check,
	output [31:0]  PCTargetE_check,
	output [31:0]  ALUResultE_check, FLUResultE_check,
	output         ResultSrcE_check,
	output         RegWriteE_check, RegFWriteE_check,
	output         MemReadE_check, MemWriteE_check,
	output         BranchE_check, JumpE_check,
	output         MuxjalrE_check,
	output [3:0]   ALUControlE_check,
	output [4:0]   FLUControlE_check,
	output [1:0]   ALUSrcAE_check, ALUSrcBE_check,
	output busyA_check, doneA_check,
	output busyF_check, doneF_check,
	
	output         PCSrcE_check, FlagE_check,
	output         ItoFE_check, FtoIE_check,

//====================== MEMORY STAGE =====================
	output [4:0]   RdM_check,
	output [31:0]  ALUResultM_check, FLUResultM_check, ReadDataM_check,
	output         ResultSrcM_check,
	output         RegWriteM_check, RegFWriteM_check,
	output         MemReadM_check, MemWriteM_check,
	output         FLRM_check,

//====================== WRITEBACK STAGE ==================
	output [4:0]   RdW_check,
	output [31:0]  ResultW_check,
	output         ResultSrcW_check,
	output         RegWriteW_check, RegFWriteW_check,
	output         RegWriteWFinal_check, RegFWriteWFinal_check,
	output         FtoIW_check,

//====================== CONTROL & HAZARD =================
	output         Stall_check, Flush_check,
	output [1:0]   ForwardAE_check, ForwardBE_check,
	output [1:0]   ForwardFAE_check, ForwardFBE_check, ForwardFCE_check,

//====================== FLOATING CONTROL =================
	output         FLRE_check, FLRD_check,
	output         ItoFD_check, FtoID_check

);

	// existing wires (kept as in your original file)
	wire PCSrcE;
	wire [31:0] nextPCF, PCF, PCPlus4F, InstrD, InstrF, PCTargetE, PCD;
	
	wire MemReadD, RegWriteD, RegFWriteD, MemWriteD, JumpD, BranchD, ALUSrcD, MuxjalrD, RegWriteE;
	wire RegWriteW, RegFWriteW, ResultSrcD;
	wire [2:0] ImmSrc;
	wire [4:0] ALUControlD;
	wire [4:0] FLUControlD;
	wire [31:0] RD1D, RD2D, RFD1D, RFD2D, RFD3D, ImmExtD,  ResultW, ResultFW, ResultWFinal;
	wire [4:0] RdW;
	wire [1:0] ALUSrcAD, ALUSrcBD, ALUSrcAE, ALUSrcBE;
	wire FLRD, ItoFD, FtoID;
	
	wire Stall, Flush, MemReadE, MemWriteE, JumpE, BranchE, ALUSrcE, MuxjalrE, ResultSrcE;
	wire [2:0] f3E;
	wire [4:0] ALUControlE;
	wire [4:0] FLUControlE;
	wire [31:0] RD1E, RD2E, RFD1E, RFD2E, RFD3E, ImmExtE, PCE;
	wire [4:0] Rs1E, Rs2E, Rs3E, RdE;
	wire FLRE, ItoFE, FtoIE;
	wire busyA, doneA;
	wire busyF, doneF;
	
	wire FlagE;
	wire [31:0] SrcAE, SrcBE, SrcAFE, SrcBFE, SrcCFE, ALUResultE, ALUResultM, FLUResultE, FLUResultM, WriteDataE, WriteFDataE;
	wire [31:0] AS1; //output mux forwarding A
	wire [31:0] AS2;
	wire [1:0] ForwardAE, ForwardBE;
	wire [1:0] ForwardFAE, ForwardFBE, ForwardFCE;
	wire [31:0] PC_RS1;
	
	wire RegWriteM, RegFWriteM, RegWriteWFinal, RegFWriteWFinal, MemReadM, MemWriteM;
	wire [2:0] f3M;
	wire [31:0] WriteDataM, WriteFDataM, WriteData, ReadDataM;
	wire [4:0] RdM;
	wire FLRM, FtoIM, FtoIW; 
	wire ResultSrcW, ResultSrcM;
	wire [31:0] ALUResultW, FLUResultW, ReadDataW;
	
    // --- KHAI BÁO CÁC DÂY TÍN HIỆU AXI NỘI BỘ (Giữa Controllers và Interconnect) ---
    // IFU (Slave 0)
    wire [31:0] ifu_araddr; wire ifu_arvalid, ifu_arready;
    wire [31:0] ifu_rdata;  wire ifu_rvalid, ifu_rready;
    
    // LSU (Slave 1)
    wire [31:0] lsu_awaddr; wire lsu_awvalid, lsu_awready;
    wire [31:0] lsu_wdata;  wire lsu_wvalid, lsu_wready; wire [3:0] lsu_wstrb;
    wire lsu_bvalid, lsu_bready;
    wire [31:0] lsu_araddr; wire lsu_arvalid, lsu_arready;
    wire [31:0] lsu_rdata;  wire lsu_rvalid, lsu_rready;

    // Tín hiệu Stall từ bộ nhớ
    wire ifu_stall, lsu_stall;

	//-----------------------IF Stage-------------------------------------------------------------------------------------------
	PC pc (.clk(clk), .en(~Stall), .rst(reset), .addr_in(nextPCF), .addr_out(PCF));
	assign nextPCF = (PCSrcE) ? PCTargetE : PCPlus4F;
	
    // --- [NEW] INSTRUCTION FETCH UNIT (AXI) ---
    // Thay thế instruction_Mem bằng ifu_axi_controller
    instruction_Mem IFU (
        .clk(clk), .rst_n(reset),
        .addr(PCF),
        .inst(InstrF),
        .stall_out(ifu_stall), // Dùng để Stall Pipeline
        
        // Nối vào Interconnect (Slave 0)
        .m_axi_araddr(ifu_araddr), .m_axi_arvalid(ifu_arvalid), .m_axi_arready(ifu_arready),
        .m_axi_rdata(ifu_rdata),   .m_axi_rvalid(ifu_rvalid),   .m_axi_rready(ifu_rready)
    );
	
	assign PCPlus4F = PCF + 4;
	IF_ID_register if_id (.clk(clk), .stall(Stall), .flush(Flush), .instF(InstrF), .PCF(PCF), .instD(InstrD), .rst(reset), 
	.PCD(PCD));
	
	
	//---------------------ID Stage---------------------------------------------------------------------------------------------
	Control_Unit controlunit(
		.funct7(InstrD[31:25]), .opcode(InstrD[6:0]),
		.funct3(InstrD[14:12]), .rs2(InstrD[24:20]),
		.MemReadD(MemReadD), .MemWriteD(MemWriteD), .JumpD(JumpD), .RegWriteD(RegWriteD), .RegFWriteD(RegFWriteD), .BranchD(BranchD), .MuxjalrD(MuxjalrD),
		.ALUOpD(ALUControlD), .FPUOpD(FLUControlD), .ImmControlD(ImmSrc), .WriteBackD(ResultSrcD), .ALUSrcA_D(ALUSrcAD), .ALUSrcB_D(ALUSrcBD), .ItoFD(ItoFD), .FtoID(FtoID), .FLRD(FLRD)
	);
	
	rf_32_32 rf (.clk(clk), .reg_write(RegWriteWFinal), .rst(reset), .data_write(ResultWFinal), .wa(RdW), .ra1(InstrD[19:15]), .ra2(InstrD[24:20]), 
	.rd1(RD1D), .rd2(RD2D));
	
	fpr_32_32 rff (.clk(clk), .reg_write(RegFWriteWFinal), .rst(reset), .data_write(ResultFW), .wa(RdW), .ra1(InstrD[19:15]), .ra2(InstrD[24:20]), 
	.ra3(InstrD[31:27]), .rd1(RFD1D), .rd2(RFD2D), .rd3(RFD3D));
	
	Sign_Extend sign_extend (.inst(InstrD[31:7]), .control(ImmSrc), .imm(ImmExtD));
	
	ID_EX_register id_ex (
		.MemReadD(MemReadD), .MemWriteD(MemWriteD), .ALUSrcAD(ALUSrcAD), .ALUSrcBD(ALUSrcBD), .JumpD(JumpD), .RegWriteD(RegWriteD), .RegFWriteD(RegFWriteD), .BranchD(BranchD), 
		.MuxjalrD(MuxjalrD), .Stall(Stall), .clk(clk), .reset(reset), .flush(Flush), // Stall lan truyền vào đây
		.ALUOpD(ALUControlD), .FLUOpD(FLUControlD),
		.WriteBackD(ResultSrcD), .funct3D(InstrD[14:12]),
		.RD1D(RD1D), .RD2D(RD2D), .PCD(PCD), 
		.RFD1D(RFD1D), .RFD2D(RFD2D), .RFD3D(RFD3D),
		.RdD(InstrD[11:7]), .Rs1D(InstrD[19:15]), .Rs2D(InstrD[24:20]), .Rs3D(InstrD[31:27]),
		.ImmExtD(ImmExtD), .FLRD(FLRD), .ItoFD(ItoFD), .FtoID(FtoID),
	
		.MemReadE(MemReadE), .MemWriteE(MemWriteE), .ALUSrcAE(ALUSrcAE), .ALUSrcBE(ALUSrcBE), .JumpE(JumpE), .RegWriteE(RegWriteE), .RegFWriteE(RegFWriteE), .BranchE(BranchE), 
		.MuxjalrE(MuxjalrE),
		.ALUOpE(ALUControlE), .FLUOpE(FLUControlE),
		.WriteBackE(ResultSrcE), .funct3E(f3E),
		.RD1E(RD1E), .RD2E(RD2E), .PCE(PCE), 
		.RFD1E(RFD1E), .RFD2E(RFD2E), .RFD3E(RFD3E),
		.RdE(RdE), .Rs1E(Rs1E), .Rs2E(Rs2E), .Rs3E(Rs3E),
		.ImmExtE(ImmExtE), .FLRE(FLRE), .ItoFE(ItoFE), .FtoIE(FtoIE)
	);
	
	//---------------------EX Stage---------------------------------------------------------------------------------------------
	
	assign PCSrcE = (FlagE && BranchE) || JumpE;
	
    alu ALU (
        .clk(clk), .rst_n(reset), 
        .A(SrcAE), .B(SrcBE), .opcode(ALUControlE), .branch(f3E), 
        .result(ALUResultE), .Z(FlagE), .busy(busyA), .done(doneA)
    );
	

    FPU fpu (
        .clk(clk), .rst_n(reset),  
        .a_operand(SrcAFE), .b_operand(SrcBFE), .c_operand(SrcCFE), 
        .FPUOpd(FLUControlE), 
        .result(FLUResultE), .busy(busyF), .done(doneF)
        // .Exception() // Thêm exception nếu cần
    );
	
    // Forwarding Logic (Giữ nguyên)
    assign AS1 = (ForwardAE==2'b00) ? RD1E :
					(ForwardAE==2'b01) ? ResultW : ALUResultM;
	assign SrcAE = (ALUSrcAE == 2'b00) ? AS1 :
						(ALUSrcAE == 2'b01) ? PCE : 32'd0;
	assign WriteFDataE = SrcBFE;
	assign SrcBFE = (ForwardFBE == 2'b00) ? RFD2E :
						 (ForwardFBE==2'b01) ? ResultW : FLUResultM;
	assign AS2 = (ForwardFAE == 2'b00) ? RFD1E:
					 (ForwardFAE == 2'b01) ? ResultW : FLUResultM;
	assign SrcAFE = ItoFE ? RD1E : AS2;
	assign SrcCFE = (ForwardFCE == 2'b00) ? RFD3E:
						 (ForwardFCE == 2'b01) ? ResultW : FLUResultM;
	assign SrcBE = (ALUSrcBE == 2'b00) ? WriteDataE:
						(ALUSrcBE == 2'b01) ? ImmExtE: 32'd4;					
	assign WriteDataE = (ForwardBE==2'b00) ? RD2E :
							  (ForwardBE==2'b01) ? ResultW : ALUResultM;
							  
	assign PC_RS1 = (MuxjalrE) ? AS1 : PCE;
	assign PCTargetE = PC_RS1 + ImmExtE;
	
	EX_M_register ex_m (
		.clk(clk), .rst_n(reset),
		.regWrite_E(RegWriteE), .regFWrite_E(RegFWriteE), .memWrite_E(MemWriteE), .memRead_E(MemReadE),
		.resultScr_E(ResultSrcE), 
		.alu_rsl_E(ALUResultE),
		.flu_rs1_E(FLUResultE),
		.write_Data_E(WriteDataE),
		.write_DataF_E(WriteFDataE),
		.FtoIE(FtoIE),
		.rd_E(RdE),
		.mode_E(f3E), 

		.regWrite_M(RegWriteM), .regFWrite_M(RegFWriteM), .memWrite_M(MemWriteM), .memRead_M(MemReadM),
		.resultScr_M(ResultSrcM), //write_back_M,
		.alu_rsl_M(ALUResultM),
		.flu_rs1_M(FLUResultM),
		.write_Data_M(WriteDataM), 
		.write_DataF_M(WriteFDataM),
		.FtoIM(FtoIM),
		.rd_M(RdM),
		.mode_M(f3M)
		);
	
	assign WriteData = (FLRM) ? WriteFDataM : WriteDataM;
	//---------------------MEM Stage---------------------------------------------------------------------------------------------
	
    dmem LSU (
        .clk(clk), .rst_n(reset),
        .we(MemWriteM), .re(MemReadM),
        .mode(f3M),
        .addr(ALUResultM),
        .write_data(WriteData),
        .mem_out(ReadDataM),
        .stall_out(lsu_stall), // Báo stall
        
        // Nối vào Interconnect (Slave 1)
        .m_axi_awaddr(lsu_awaddr), .m_axi_awvalid(lsu_awvalid), .m_axi_awready(lsu_awready),
        .m_axi_wdata(lsu_wdata),   .m_axi_wstrb(lsu_wstrb),     .m_axi_wvalid(lsu_wvalid),   .m_axi_wready(lsu_wready),
        .m_axi_bvalid(lsu_bvalid), .m_axi_bready(lsu_bready),
        .m_axi_araddr(lsu_araddr), .m_axi_arvalid(lsu_arvalid), .m_axi_arready(lsu_arready),
        .m_axi_rdata(lsu_rdata),   .m_axi_rvalid(lsu_rvalid),   .m_axi_rready(lsu_rready)
    );

    // --- [NEW] AXI INTERCONNECT ---
    // Gộp IFU và LSU ra 1 cổng Master duy nhất
    axi4_interconnect_2x1 INTERCONNECT (
        .clk(clk), .rst_n(reset),
        
        // Slave 0: IFU
        .s0_axi_araddr(ifu_araddr), .s0_axi_arvalid(ifu_arvalid), .s0_axi_arready(ifu_arready),
        .s0_axi_rdata(ifu_rdata),   .s0_axi_rvalid(ifu_rvalid),   .s0_axi_rready(ifu_rready),
        
        // Slave 1: LSU
        .s1_axi_awaddr(lsu_awaddr), .s1_axi_awvalid(lsu_awvalid), .s1_axi_awready(lsu_awready),
        .s1_axi_wdata(lsu_wdata),   .s1_axi_wstrb(lsu_wstrb),     .s1_axi_wvalid(lsu_wvalid),   .s1_axi_wready(lsu_wready),
        .s1_axi_bvalid(lsu_bvalid), .s1_axi_bready(lsu_bready),
        .s1_axi_araddr(lsu_araddr), .s1_axi_arvalid(lsu_arvalid), .s1_axi_arready(lsu_arready),
        .s1_axi_rdata(lsu_rdata),   .s1_axi_rvalid(lsu_rvalid),   .s1_axi_rready(lsu_rready),
        
        // Master: Nối ra Top Module Ports (Kết nối RAM ngoài)
        .m_axi_awaddr(m_axi_awaddr), .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),   .m_axi_wstrb(m_axi_wstrb),     .m_axi_wvalid(m_axi_wvalid),   .m_axi_wready(m_axi_wready),
        .m_axi_bvalid(m_axi_bvalid), .m_axi_bready(m_axi_bready),
        .m_axi_araddr(m_axi_araddr), .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),   .m_axi_rvalid(m_axi_rvalid),   .m_axi_rready(m_axi_rready)
    );

	MEM_WB_register mem_wb (
	.RegWriteM(RegWriteM), .RegFWriteM(RegFWriteM), .clk(clk), .reset(reset),
	.WriteBackM(ResultSrcM),
	.ALUResultM(ALUResultM), .FLUResultM(FLUResultM), .ReadDataM(ReadDataM),
	.FtoIM(FtoIM),
	.RdM(RdM),
	
	.RegWriteW(RegWriteW), .RegFWriteW(RegFWriteW),
	.WriteBackW(ResultSrcW),
	.ALUResultW(ALUResultW), .FLUResultW(FLUResultW), .ReadDataW(ReadDataW),
	.FtoIW(FtoIW),
	.RdW (RdW)
	);
	
	//---------------------WB Stage---------------------------------------------------------------------------------------------
	assign ResultW = (!ResultSrcW) ? ALUResultW : ReadDataW; 
	assign ResultFW = (!ResultSrcW) ? FLUResultW : ReadDataW;
	assign ResultWFinal = FtoIW ?	ResultFW : ResultW;	
	assign RegFWriteWFinal = (~FtoIW) & RegFWriteW;
	assign RegWriteWFinal  = FtoIW | RegWriteW;
	
	//---------------------Control Hazard---------------------------------------------------------------------------------------------
    
    wire hazard_stall;

	hazard_unit controlhazard (
		.regWrite_M(RegWriteM),
		.regFWrite_M(RegFWriteM),
		.regWrite_W(RegWriteWFinal),
		.regFWrite_W(RegFWriteWFinal),
		.PCSrc_E(PCSrcE),
		.resultSrc_E(ResultSrcE),
		.rd_M(RdM),
		.rd_W(RdW),
		.rs1_D(InstrD[19:15]),
		.rs2_D(InstrD[24:20]),
		.rs3_D(InstrD[31:27]),
		.rs1_E(Rs1E),
		.rs2_E(Rs2E),
		.rs3_E(Rs3E),
		.rd_E(RdE),
		.busyA(busyA),
		.doneA(doneA),
		.busyF(busyA), // Bận nếu ALU hoặc FPU bận
		.doneF(doneA), 
		.forwardAE(ForwardAE),
		.forwardBE(ForwardBE),
		.forwardAFE(ForwardFAE),
		.forwardBFE(ForwardFBE),
		.forwardCFE(ForwardFCE),
		.stall(hazard_stall), // Chỉ lấy stall nội bộ (do data hazard)
		.flush(Flush)
		);
	
    // LOGIC STALL TỔNG HỢP:
    // Stall = Hazard (Load-use) HOẶC Memory Busy (IFU/LSU)
    assign Stall = hazard_stall | ifu_stall | lsu_stall;

	//--------------------------------------------------------------------------------------------------------------------------------------
	
    // Debug ports
	assign nextPCF_check      = nextPCF;
	assign PCF_check          = PCF;
	assign InstrF_check       = InstrF;
	assign InstrD_check       = InstrD;
	assign ImmExtD_check      = ImmExtD;
	assign Rs1D_check         = InstrD[19:15];
	assign Rs2D_check         = InstrD[24:20];
	assign Rs3D_check         = InstrD[31:27];
	assign RdD_check          = InstrD[11:7];
	assign RdE_check          = RdE;
	assign RdM_check          = RdM;
	assign RdW_check          = RdW;
	assign PCD_check          = PCD;
	assign RD1E_check         = RD1E;
	assign RD2E_check         = RD2E;
	assign RFD1E_check        = RFD1E;
	assign RFD2E_check        = RFD2E;
	assign RFD3E_check        = RFD3E;
	assign SrcAE_check        = SrcAE;
	assign SrcBE_check        = SrcBE;
	assign SrcAFE_check 	  = SrcAFE;
	assign SrcBFE_check		  = SrcBFE;
	assign SrcCFE_check       = SrcCFE;
	assign WriteDataE_check   = WriteDataE;
	assign PCTargetE_check    = PCTargetE;
	assign busyA_check = busyA;
	assign doneA_check = doneA;
	assign busyF_check = busyF;
	assign doneF_check = doneF;
	assign ResultSrcD_check   = ResultSrcD;
	assign ResultSrcE_check   = ResultSrcE;
	assign ResultSrcM_check   = ResultSrcM;
	assign ResultSrcW_check   = ResultSrcW;
	assign RegWriteD_check    = RegWriteD;
	assign RegWriteE_check    = RegWriteE;
	assign RegWriteM_check    = RegWriteM;
	assign RegWriteW_check    = RegWriteW;
	assign RegWriteWFinal_check = RegWriteWFinal;
	assign RegFWriteD_check   = RegFWriteD;
	assign RegFWriteE_check   = RegFWriteE;
	assign RegFWriteM_check   = RegFWriteM;
	assign RegFWriteW_check   = RegFWriteW;
	assign RegFWriteWFinal_check = RegFWriteWFinal;
	assign MemReadD_check     = MemReadD;
	assign MemReadE_check     = MemReadE;
	assign MemReadM_check     = MemReadM;
	assign MemWriteD_check    = MemWriteD;
	assign MemWriteE_check    = MemWriteE;
	assign MemWriteM_check    = MemWriteM;
	assign BranchD_check      = BranchD;
	assign BranchE_check      = BranchE;
	assign JumpD_check        = JumpD;
	assign JumpE_check        = JumpE;
	assign MuxjalrD_check     = MuxjalrD;
	assign MuxjalrE_check     = MuxjalrE;
	assign ALUControlD_check  = ALUControlD;
	assign ALUControlE_check  = ALUControlE;
	assign FLUControlD_check  = FLUControlD;
	assign FLUControlE_check  = FLUControlE;
	assign ForwardAE_check    = ForwardAE;
	assign ForwardBE_check    = ForwardBE;
	assign ForwardFAE_check   = ForwardFAE;
	assign ForwardFBE_check   = ForwardFBE;
	assign ForwardFCE_check   = ForwardFCE;
	assign Stall_check        = Stall;
	assign Flush_check        = Flush;
	assign ALUResultE_check   = ALUResultE;
	assign ALUResultM_check   = ALUResultM;
	assign ReadDataM_check    = ReadDataM;
	assign ResultW_check      = ResultW;
	assign FLUResultE_check   = FLUResultE;
	assign FLUResultM_check   = FLUResultM;
	assign Rs1E_check         = Rs1E;
	assign Rs2E_check         = Rs2E;
	assign Rs3E_check         = Rs3E;
	assign ALUSrcAD_check     = ALUSrcAD;
	assign ALUSrcBD_check     = ALUSrcBD;
	assign ALUSrcAE_check     = ALUSrcAE;
	assign ALUSrcBE_check     = ALUSrcBE;
	assign PCSrcE_check       = PCSrcE;
	assign FlagE_check        = FlagE;
	assign ItoFD_check        = ItoFD;
	assign ItoFE_check        = ItoFE;
	assign FtoIE_check        = FtoIE;
	assign FtoID_check        = FtoID;
	assign FtoIW_check        = FtoIW;
	assign FLRE_check         = FLRE;
	assign FLRD_check         = FLRD;
	assign FLRM_check         = FLRM;

endmodule