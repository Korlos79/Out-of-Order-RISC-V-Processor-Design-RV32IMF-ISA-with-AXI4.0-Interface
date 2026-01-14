module Control_Unit (
    input [6:0] funct7, opcode,
    input [2:0] funct3,
    input [4:0] rs2,
    output reg IsFPU,
    output reg MemReadD, MemWriteD, JumpD, RegWriteD, RegFWriteD, BranchD, MuxjalrD, WriteBackD,
    output reg [1:0] ALUSrcA_D, ALUSrcB_D,
    
    // --- OUTPUT OPCODE CHUNG (5 BIT) ---
    // Đủ để chứa các giá trị từ 0 đến 31 (FMAX=25 là lớn nhất)
    output reg [4:0] OpD, 
    
    output reg [2:0] ImmControlD,
    output reg        src1_is_float,// Để chọn rdata1 hay frdata1
    output reg        src2_is_float,
    output reg        src3_is_float,
    output reg FtoID,
    output reg FLRD
);
    // ... (Giữ nguyên phần Definitions localparam) ...
    localparam R_TYPE  = 7'b0110011;
    localparam I_TYPE  = 7'b0010011;
    localparam LOAD    = 7'b0000011;
    localparam STORE   = 7'b0100011;
    localparam BRANCH  = 7'b1100011;
    localparam JALR    = 7'b1100111;
    localparam LUI     = 7'b0110111;
    localparam AUIPC   = 7'b0010111;
    localparam JAL     = 7'b1101111;
    
    localparam F_R     = 7'b1010011;
    localparam F_LOAD  = 7'b0000111;
    localparam F_STORE = 7'b0100111;
    localparam F_MADD  = 7'b1000011;
    localparam F_MSUB  = 7'b1000111;
    localparam F_NMADD = 7'b1001111;
    localparam F_NMSUB = 7'b1001011;

    always @(*) begin
        // Reset defaults
        MemReadD = 0; MemWriteD = 0; JumpD = 0; RegWriteD = 0; RegFWriteD = 0; 
        BranchD = 0; MuxjalrD = 0; WriteBackD = 0;
        ALUSrcA_D = 2'b00; ALUSrcB_D = 2'b00; FLRD = 0;
		  src1_is_float = 0; src2_is_float = 0; src3_is_float = 1;
        // --- 1. MAIN CONTROL SIGNALS ---
        case(opcode)
            R_TYPE: begin RegWriteD = 1; end
            I_TYPE: begin RegWriteD = 1; ALUSrcB_D = 2'b01; end
            LOAD:   begin MemReadD = 1; RegWriteD = 1; WriteBackD = 1; ALUSrcB_D = 2'b01; end
            STORE:  begin MemWriteD = 1; ALUSrcB_D = 2'b01; end
            JALR:   begin JumpD = 1; RegWriteD = 1; MuxjalrD = 1; ALUSrcA_D = 2'b01; ALUSrcB_D = 2'b10; end
            BRANCH: begin BranchD = 1; end
            LUI:    begin RegWriteD = 1; ALUSrcA_D = 2'b10; ALUSrcB_D = 2'b01; end
            AUIPC:  begin RegWriteD = 1; ALUSrcA_D = 2'b01; ALUSrcB_D = 2'b01; end
            JAL:    begin JumpD = 1; RegWriteD = 1; ALUSrcA_D = 2'b01; ALUSrcB_D = 2'b10; end
            
            // Float Instructions
            F_R:     begin RegFWriteD = 1; src1_is_float = 1; src2_is_float = 1; IsFPU = 1; end 
            F_LOAD:  begin MemReadD = 1; RegFWriteD = 1; WriteBackD = 1; ALUSrcB_D = 2'b01; IsFPU = 1; end
            F_STORE: begin MemWriteD = 1; ALUSrcB_D = 2'b01; FLRD = 1; src1_is_float = 0; src2_is_float = 1; IsFPU = 1;  end
            F_MADD, F_MSUB, F_NMADD, F_NMSUB: begin RegFWriteD = 1; src1_is_float = 1; src2_is_float = 1; IsFPU = 1;  end
            default: ;
        endcase

        // --- 2. OPCODE MAPPING (OpD) ---
        OpD = 5'd0;
        FtoID = 0;

        casex({opcode, funct3, funct7, rs2})
            // === NHÓM INTEGER (Khớp với ALU.v) ===
            {R_TYPE, 3'b000, 7'b0000000, 5'bxxxxx}: OpD = 5'd0;  // ADD
            {R_TYPE, 3'b000, 7'b0100000, 5'bxxxxx}: OpD = 5'd8;  // SUB
            {R_TYPE, 3'b100, 7'b0000000, 5'bxxxxx}: OpD = 5'd4;  // XOR
            {R_TYPE, 3'b110, 7'b0000000, 5'bxxxxx}: OpD = 5'd6;  // OR
            {R_TYPE, 3'b111, 7'b0000000, 5'bxxxxx}: OpD = 5'd7;  // AND
            {R_TYPE, 3'b001, 7'b0000000, 5'bxxxxx}: OpD = 5'd1;  // SLL
            {R_TYPE, 3'b101, 7'b0000000, 5'bxxxxx}: OpD = 5'd5;  // SRL
            {R_TYPE, 3'b101, 7'b0100000, 5'bxxxxx}: OpD = 5'd17; // SRA
            {R_TYPE, 3'b010, 7'b0000000, 5'bxxxxx}: OpD = 5'd2;  // SLT
            {R_TYPE, 3'b011, 7'b0000000, 5'bxxxxx}: OpD = 5'd3;  // SLTU

            // M-Extension (Khớp với ALU.v)
            {R_TYPE, 3'b000, 7'b0000001, 5'bxxxxx}: OpD = 5'd9;  // MUL
            {R_TYPE, 3'b001, 7'b0000001, 5'bxxxxx}: OpD = 5'd10; // MULH
            {R_TYPE, 3'b010, 7'b0000001, 5'bxxxxx}: OpD = 5'd11; // MULSU
            {R_TYPE, 3'b011, 7'b0000001, 5'bxxxxx}: OpD = 5'd12; // MULU
            {R_TYPE, 3'b100, 7'b0000001, 5'bxxxxx}: OpD = 5'd13; // DIV
            {R_TYPE, 3'b101, 7'b0000001, 5'bxxxxx}: OpD = 5'd14; // DIVU
            {R_TYPE, 3'b110, 7'b0000001, 5'bxxxxx}: OpD = 5'd15; // REM
            {R_TYPE, 3'b111, 7'b0000001, 5'bxxxxx}: OpD = 5'd16; // REMU
            
            // I-Type
            {I_TYPE, 3'b000, 7'bxxxxxxx, 5'bxxxxx}: OpD = 5'd0;  // ADDI -> ADD
            {I_TYPE, 3'b100, 7'bxxxxxxx, 5'bxxxxx}: OpD = 5'd4;  // XORI -> XOR
            {I_TYPE, 3'b110, 7'bxxxxxxx, 5'bxxxxx}: OpD = 5'd6;  // ORI  -> OR
            {I_TYPE, 3'b111, 7'bxxxxxxx, 5'bxxxxx}: OpD = 5'd7;  // ANDI -> AND
            {I_TYPE, 3'b001, 7'b0000000, 5'bxxxxx}: OpD = 5'd1;  // SLLI -> SLL
            {I_TYPE, 3'b101, 7'b0000000, 5'bxxxxx}: OpD = 5'd5;  // SRLI -> SRL
            {I_TYPE, 3'b101, 7'b0100000, 5'bxxxxx}: OpD = 5'd17; // SRAI -> SRA
            {I_TYPE, 3'b010, 7'bxxxxxxx, 5'bxxxxx}: OpD = 5'd2;  // SLTI -> SLT
            {I_TYPE, 3'b011, 7'bxxxxxxx, 5'bxxxxx}: OpD = 5'd3;  // SLTUI -> SLTU

            // === NHÓM FLOAT (Khớp với FPU.v) ===
            {F_R, 3'b000, 7'b0000000, 5'bxxxxx}: OpD = 5'd0; // FADD
            {F_R, 3'b000, 7'b0000100, 5'bxxxxx}: OpD = 5'd1; // FSUB
            {F_R, 3'b000, 7'b0001000, 5'bxxxxx}: OpD = 5'd2; // FMUL
            {F_R, 3'b000, 7'b0001100, 5'bxxxxx}: OpD = 5'd3; // FDIV
            {F_R, 3'b000, 7'b0101100, 5'b00000}: OpD = 5'd4; // FSQRT
            
            // Fused
            {F_MADD,  3'bxxx, 7'bxxxxx00, 5'bxxxxx}: OpD = 5'd5;
            {F_MSUB,  3'bxxx, 7'bxxxxx00, 5'bxxxxx}: OpD = 5'd6;
            {F_NMADD, 3'bxxx, 7'bxxxxx00, 5'bxxxxx}: OpD = 5'd7;
            {F_NMSUB, 3'bxxx, 7'bxxxxx00, 5'bxxxxx}: OpD = 5'd8;
            
            // Sign Injection
            {F_R, 3'b000, 7'b0010000, 5'bxxxxx}: OpD = 5'd9;
            {F_R, 3'b001, 7'b0010000, 5'bxxxxx}: OpD = 5'd10;
            {F_R, 3'b010, 7'b0010000, 5'bxxxxx}: OpD = 5'd11;
            
            // Compare (Ghi vào Int Reg)
            {F_R, 3'b010, 7'b1010000, 5'bxxxxx}: begin OpD = 5'd12; RegWriteD=1; RegFWriteD=0; end // FEQ
            {F_R, 3'b001, 7'b1010000, 5'bxxxxx}: begin OpD = 5'd13; RegWriteD=1; RegFWriteD=0; end // FLT
            {F_R, 3'b000, 7'b1010000, 5'bxxxxx}: begin OpD = 5'd14; RegWriteD=1; RegFWriteD=0; end // FLE
            
            // Convert
            {F_R, 3'bxxx, 7'b1100000, 5'b00000}: begin OpD = 5'd15; FtoID=1; RegWriteD=1; RegFWriteD=0; end // FCVT.W.S
            {F_R, 3'bxxx, 7'b1100000, 5'b00001}: begin OpD = 5'd16; FtoID=1; RegWriteD=1; RegFWriteD=0; end // FCVT.WU.S
            {F_R, 3'bxxx, 7'b1101000, 5'b00000}: begin OpD = 5'd17; src1_is_float = 0; end // FCVT.S.W
            {F_R, 3'bxxx, 7'b1101000, 5'b00001}: begin OpD = 5'd18; src1_is_float = 0; end // FCVT.S.WU
            
            // Move
            {F_R, 3'b000, 7'b1110000, 5'b00000}: begin OpD = 5'd19; src1_is_float = 0; end // FMV.W.X
            {F_R, 3'b000, 7'b1111000, 5'b00000}: begin OpD = 5'd19; FtoID=1; RegWriteD=1; RegFWriteD=0; end // FMV.X.W
            
            // Min/Max
            {F_R, 3'b000, 7'b0010100, 5'bxxxxx}: OpD = 5'd20;
            {F_R, 3'b001, 7'b0010100, 5'bxxxxx}: OpD = 5'd21;
            
            default: ;
        endcase

        // --- 4. IMMEDIATE CONTROL ---
        case(opcode)
            I_TYPE, LOAD, F_LOAD, JALR: ImmControlD = 3'b000;
            STORE, F_STORE:             ImmControlD = 3'b011;
            BRANCH:                     ImmControlD = 3'b100;
            LUI, AUIPC:                 ImmControlD = 3'b101;
            JAL:                        ImmControlD = 3'b110;
            default:                    ImmControlD = 3'b000;
        endcase
    end
endmodule