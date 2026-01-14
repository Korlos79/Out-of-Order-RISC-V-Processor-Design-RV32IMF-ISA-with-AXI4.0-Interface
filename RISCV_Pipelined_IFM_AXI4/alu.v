module alu (
    input  wire        clk,
    input  wire        rst_n, // Thêm reset active low để đồng bộ với các module con
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [4:0]  opcode,
    input  wire [2:0]  branch,
    
    output reg  [31:0] result,
    output reg         Z,
    output reg         busy,
    output reg         done
);

    // --- 1. DEFINITIONS ---
    // Branch Codes
    localparam beq  = 3'b000;
    localparam bne  = 3'b001;
    localparam blt  = 3'b100;
    localparam bge  = 3'b101;
    localparam bltu = 3'b110;
    localparam bgeu = 3'b111;

    // --- 2. M-EXTENSION HANDLING ---
    // Xác định xem có phải lệnh Nhân/Chia không (Opcode 9 đến 16)
    wire is_m_op = (opcode >= 5'd9 && opcode <= 5'd16);

    // Chuyển đổi Opcode của ALU sang Opcode chuẩn của RV32M (cho module con)
    // ALU Opcode: 9 (MUL) -> 16 (REMU)
    // RV32M Opcode: 10000 (MUL) -> 10111 (REMU)
    // Công thức: RV32M_OP = 5'b10000 + (ALU_OP - 9)
    reg [4:0] muldiv_op_sel;
    always @(*) begin
        if (is_m_op) 
            muldiv_op_sel = 5'b10000 + (opcode - 5'd9);
        else 
            muldiv_op_sel = 5'b00000;
    end

    wire [31:0] md_result;
    wire        md_busy;
    wire        md_done;

    rv32m_muldiv_split U_MULDIV (
        .clk(clk),
        .rst_n(rst_n),
        .op_valid(is_m_op),     // Kích hoạt khi gặp opcode 9-16
        .op_sel(muldiv_op_sel),
        .rs1(A),
        .rs2(B),
        .busy(md_busy),
        .done(md_done),
        .result(md_result)
    );

    // --- 3. BASE INTEGER ALU LOGIC ---
    reg [31:0] base_result;
    
    always @(*) begin
        case(opcode)
            5'd0: base_result = A + B;
            5'd1: base_result = A << B[4:0];
            5'd2: base_result = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // SLT
            5'd3: base_result = ($unsigned(A) < $unsigned(B)) ? 32'd1 : 32'd0; // SLTU
            5'd4: base_result = A ^ B;
            5'd5: base_result = A >> B[4:0]; // Logic Shift Right. Note: SRA needs >>>
            5'd6: base_result = A | B;
            5'd7: base_result = A & B;
            5'd8: base_result = A - B;
            default: base_result = 32'd0;
        endcase
    end

    // --- 4. OUTPUT MUXING ---
    always @(*) begin
        if (is_m_op) begin
            // Nếu là lệnh Nhân/Chia: Lấy tín hiệu từ module con
            result = md_result;
            busy   = md_busy;
            done   = md_done;
        end else begin
            // Nếu là lệnh cơ bản: Kết quả có ngay (Combinational)
            result = base_result;
            busy   = 1'b0; // Không bao giờ bận
            done   = 1'b1; // Xong ngay lập tức
        end
    end

    // --- 5. BRANCH COMPARATOR ---
    always @(*) begin
        case (branch)
            beq:  Z = (A == B);
            bne:  Z = (A != B);
            blt:  Z = ($signed(A) < $signed(B));
            bge:  Z = ($signed(A) >= $signed(B)); // Sửa logic: bge là >= (ngược của <)
            bltu: Z = ($unsigned(A) < $unsigned(B));
            bgeu: Z = ($unsigned(A) >= $unsigned(B));
            default: Z = 1'b0;
        endcase
    end

endmodule