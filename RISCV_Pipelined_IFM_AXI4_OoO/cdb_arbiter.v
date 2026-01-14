module cdb_arbiter #(
    parameter DATA_WIDTH = 32,
    parameter TAG_WIDTH  = 3
)(
    // ============================================================
    // INPUT TỪ CÁC FUNCTIONAL UNIT WRAPPERS
    // ============================================================
    
    // 1. Từ Integer Unit (ALU Wrapper)
    input  wire                   alu_valid,
    input  wire [DATA_WIDTH-1:0]  alu_result,
    input  wire [TAG_WIDTH-1:0]   alu_tag,
    input  wire [4:0]             alu_dest_reg,
    output reg                    alu_ack,

    // 2. Từ Floating Point Unit (FPU Wrapper)
    input  wire                   fpu_valid,
    input  wire [DATA_WIDTH-1:0]  fpu_result,
    input  wire [TAG_WIDTH-1:0]   fpu_tag,
    input  wire [4:0]             fpu_dest_reg,
    output reg                    fpu_ack,

    // 3. Từ Load/Store Unit (LSU Wrapper)
    input  wire                   lsu_valid,
    input  wire [DATA_WIDTH-1:0]  lsu_result,
    input  wire [TAG_WIDTH-1:0]   lsu_tag,
    input  wire [4:0]             lsu_dest_reg,
    output reg                    lsu_ack,

    // ============================================================
    // OUTPUT RA COMMON DATA BUS (Broadcast)
    // ============================================================
    output reg                    cdb_valid_out,
    output reg [DATA_WIDTH-1:0]   cdb_value_out,
    output reg [TAG_WIDTH-1:0]    cdb_tag_out,
    output reg [4:0]              cdb_dest_reg_out,
    output reg                    cdb_is_float_out,
    
    // --- THÊM MỚI: ID CỦA NGƯỜI PHÁT ---
    output reg [2:0]              cdb_source_fu_out 
);

    // Định nghĩa ID nội bộ cho nhất quán
    localparam ID_ALU = 3'd1;
    localparam ID_FPU = 3'd2;
    localparam ID_LSU = 3'd3;

    always @(*) begin
        // Mặc định
        cdb_valid_out    = 0;
        cdb_value_out    = 0;
        cdb_tag_out      = 0;
        cdb_dest_reg_out = 0;
        cdb_is_float_out = 0;
        cdb_source_fu_out = 3'd0; // Mặc định 0
        
        alu_ack = 0;
        fpu_ack = 0;
        lsu_ack = 0;

        // --- LOGIC ƯU TIÊN ---

        // 1. Ưu tiên LSU
        if (lsu_valid) begin
            cdb_valid_out     = 1;
            cdb_value_out     = lsu_result;
            cdb_tag_out       = lsu_tag;
            cdb_dest_reg_out  = lsu_dest_reg;
            cdb_is_float_out  = 0;
            cdb_source_fu_out = ID_LSU; // <--- Gán ID 3
            
            lsu_ack           = 1;
        end
        // 2. Ưu tiên FPU
        else if (fpu_valid) begin
            cdb_valid_out     = 1;
            cdb_value_out     = fpu_result;
            cdb_tag_out       = fpu_tag;
            cdb_dest_reg_out  = fpu_dest_reg;
            cdb_is_float_out  = 1;
            cdb_source_fu_out = ID_FPU; // <--- Gán ID 2
            
            fpu_ack           = 1;
        end
        // 3. Ưu tiên ALU
        else if (alu_valid) begin
            cdb_valid_out     = 1;
            cdb_value_out     = alu_result;
            cdb_tag_out       = alu_tag;
            cdb_dest_reg_out  = alu_dest_reg;
            cdb_is_float_out  = 0;
            cdb_source_fu_out = ID_ALU; // <--- Gán ID 1
            
            alu_ack           = 1;
        end
    end

endmodule