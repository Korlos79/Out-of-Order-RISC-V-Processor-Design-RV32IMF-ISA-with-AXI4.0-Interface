module fu_alu_wrapper #(
    parameter DATA_WIDTH = 32,
    parameter TAG_WIDTH  = 3
)(
    input wire clk, rst_n,
    
    // --- Giao diện với Reservation Station ---
    input wire                   start,        // Lệnh từ RS bắn sang
    input wire [4:0]             opcode,
    input wire [31:0]            op1, op2,
    input wire [2:0]             branch_op,
    input wire [TAG_WIDTH-1:0]   tag_in,       // Tag của lệnh đang vào
    input wire [4:0]             dest_reg_in,  // Thanh ghi đích
    
    output wire                  busy,         // Báo bận (khi DIV đang chạy)

    // --- Giao diện với CDB Arbiter ---
    output reg                   cdb_valid,    // Yêu cầu phát kết quả
    output reg [DATA_WIDTH-1:0]  cdb_result,   // Kết quả
    output reg [TAG_WIDTH-1:0]   cdb_tag,      // Tag tương ứng
    output reg [4:0]             cdb_dest_reg, // Trả về thanh ghi đích
    input  wire                  cdb_ack       // Arbiter báo: "Đã nhận"
);

    // 1. KẾT NỐI VỚI MODULE ALU
    wire [31:0] alu_basic_res; // Kết quả ALU thường (ADD...)
    wire [31:0] alu_md_res;    // Kết quả Nhân/Chia
    wire        md_done_w;     // Tín hiệu xong của Nhân/Chia
    wire        md_busy_w;     // Tín hiệu bận của Nhân/Chia
    wire        alu_z_w;

    alu ALU_CORE (
        .clk(clk), .rst_n(rst_n),
        .A(op1), .B(op2), .opcode(opcode), .branch(branch_op),
        
        // Nối đúng tên cổng mới trong alu.v
        .alu_result(alu_basic_res), 
        .md_result(alu_md_res),
        .md_busy(md_busy_w), 
        .md_done(md_done_w), 
        .Z(alu_z_w)
        // .done() cho lệnh thường không cần nối vì logic wrapper tự xử lý
    );

    // Báo bận ra ngoài nếu khối Nhân/Chia đang bận (Blocking)
    assign busy = md_busy_w; 

    // 2. Phân loại lệnh
    wire is_mul = (opcode >= 9 && opcode <= 12);
    wire is_div = (opcode >= 13 && opcode <= 16);
    wire is_base = !is_mul && !is_div;

    // 3. Cơ chế lưu trữ Tag & DestReg
    
    // A. Cho lệnh Pipeline (MUL) - FIFO 4 tầng
    reg [TAG_WIDTH-1:0] mul_tag_fifo [0:3];
    reg [4:0]           mul_dest_fifo [0:3];
    reg [3:0]           mul_valid_fifo;
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) mul_valid_fifo <= 0;
        else begin
            // Đẩy vào FIFO
            mul_valid_fifo <= {mul_valid_fifo[2:0], (start && is_mul)};
            mul_tag_fifo[0]  <= tag_in;
            mul_dest_fifo[0] <= dest_reg_in;
            
            // Dịch chuyển
            for(i=1; i<4; i=i+1) begin
                mul_tag_fifo[i]  <= mul_tag_fifo[i-1];
                mul_dest_fifo[i] <= mul_dest_fifo[i-1];
            end
        end
    end

    // B. Cho lệnh Blocking (DIV) - Thanh ghi đơn
    reg [TAG_WIDTH-1:0] div_tag_reg;
    reg [4:0]           div_dest_reg;
    
    always @(posedge clk) begin
        if (start && is_div) begin
            div_tag_reg  <= tag_in;
            div_dest_reg <= dest_reg_in;
        end
    end

    // C. Cho lệnh Basic (ADD) - Thanh ghi đơn (Delay 1 nhịp)
    reg [TAG_WIDTH-1:0] base_tag_reg;
    reg [4:0]           base_dest_reg;
    reg [31:0]          base_res_reg;
    reg                 base_valid_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) base_valid_reg <= 0;
        else begin
            if (start && is_base) begin
                base_valid_reg <= 1;
                base_tag_reg   <= tag_in;
                base_dest_reg  <= dest_reg_in;
                base_res_reg   <= alu_basic_res; // Lấy kết quả từ cổng Basic
            end else if (cdb_ack && cdb_valid && !md_done_w) begin 
                base_valid_reg <= 0;
            end
        end
    end

    // 4. Logic Output Mux (Chọn kết quả trả về CDB)
    always @(*) begin
        cdb_valid    = 0;
        cdb_result   = 0;
        cdb_tag      = 0;
        cdb_dest_reg = 0;

        // Ưu tiên 1: Kết quả từ MUL/DIV
        if (md_done_w) begin
             cdb_valid  = 1;
             cdb_result = alu_md_res; // Lấy kết quả từ cổng MD
             
             // Phân biệt MUL hay DIV
             if (mul_valid_fifo[3]) begin
                 cdb_tag      = mul_tag_fifo[3];
                 cdb_dest_reg = mul_dest_fifo[3];
             end else begin
                 cdb_tag      = div_tag_reg;
                 cdb_dest_reg = div_dest_reg;
             end
        end 
        // Ưu tiên 2: Kết quả từ lệnh cơ bản
        else if (base_valid_reg) begin
             cdb_valid    = 1;
             cdb_result   = base_res_reg;
             cdb_tag      = base_tag_reg;
             cdb_dest_reg = base_dest_reg;
        end
    end

endmodule