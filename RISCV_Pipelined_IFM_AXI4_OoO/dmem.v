module lsu (
    input wire clk,
    input wire rst_n,

    // --- GIAO DIỆN VỚI PIPELINE (Thay thế các cổng của dmem cũ) ---
    input  wire        we,            // Tương đương MemWriteM
    input  wire        re,            // Tương đương MemReadM
    input  wire [2:0]  mode,          // Tương đương funct3 (b, h, w...)
    input  wire [31:0] addr,          // Địa chỉ (ALUResultM)
    input  wire [31:0] write_data,    // Dữ liệu cần ghi
    output reg  [31:0] mem_out,       // Dữ liệu đọc được
    output wire        stall_out,     // Tín hiệu mới: Báo bận để Stall CPU

    // --- GIAO DIỆN AXI4 MASTER (Nối ra ngoài Top Module) ---
    // Write Channels
    output wire [31:0] m_axi_awaddr, 
	 output wire m_axi_awvalid, 
	 input wire m_axi_awready,
	 
    output wire [31:0] m_axi_wdata,  
	 output wire [3:0] m_axi_wstrb, 
	 output wire m_axi_wvalid, 
	 input wire m_axi_wready,
	 
    input  wire        m_axi_bvalid, 
	 output wire m_axi_bready,
	 
    // Read Channels
    output wire [31:0] m_axi_araddr, 
	 output wire m_axi_arvalid, 
	 input wire m_axi_arready,
	 
    input  wire [31:0] m_axi_rdata,  
	 input wire m_axi_rvalid,  
	 output wire m_axi_rready
);

    // Định nghĩa Mode (giống code cũ của bạn)
    localparam b=3'b000, h=3'b001, w=3'b010, bu=3'b100, hu=3'b101;

    // Tín hiệu nội bộ
    wire axi_busy;
    wire axi_done;
    reg [31:0] axi_wdata_reg;
    reg [3:0]  axi_wstrb_reg;
    wire [31:0] axi_rdata_raw;

    // Logic kích hoạt AXI:
    // Chạy khi có lệnh (Read hoặc Write) VÀ AXI chưa bận VÀ chưa xong việc
    wire start_axi = (re || we) && !axi_busy && !axi_done;

    // =========================================================================
    // 1. XỬ LÝ DỮ LIỆU GHI (STORE ALIGNMENT)
    // =========================================================================
    // AXI ghi theo Word (32-bit). Nếu ghi Byte/Half, ta cần:
    // - Đưa dữ liệu vào đúng vị trí trên bus 32-bit.
    // - Bật WSTRB (Mask) để RAM biết chỉ ghi vào byte đó.
    always @(*) begin
        // Mặc định (Store Word)
        axi_wdata_reg = write_data;
        axi_wstrb_reg = 4'b1111;

        if (we) begin
            case(mode)
                b: begin // SB (Store Byte)
                    // Nhân bản byte ra 4 vị trí (ví dụ AA -> AAAAAAAA)
                    axi_wdata_reg = {4{write_data[7:0]}}; 
                    // Dịch mask '1' đến đúng địa chỉ byte (0001, 0010, 0100, 1000)
                    axi_wstrb_reg = 4'b0001 << addr[1:0]; 
                end
                h: begin // SH (Store Half)
                    // Nhân bản half ra 2 vị trí (ví dụ AAAA -> AAAAAAAA)
                    axi_wdata_reg = {2{write_data[15:0]}};
                    // Dịch mask '11' (0011 hoặc 1100)
                    axi_wstrb_reg = 4'b0011 << addr[1:0]; 
                end
                default: begin // SW (Store Word)
                    axi_wdata_reg = write_data;
                    axi_wstrb_reg = 4'b1111;
                end
            endcase
        end
    end

    // =========================================================================
    // 2. GỌI SHIPPER AXI (Instantiate Master)
    // =========================================================================
    axi_simple_master u_axi_master (
        .clk(clk), .rst_n(rst_n),
        .start(start_axi),
        .rw(we),             // 1: Write, 0: Read
        .addr(addr),         // Địa chỉ từ ALU
        .wdata(axi_wdata_reg),
        .wstrb(axi_wstrb_reg),
        .done(axi_done),     // Báo xong
        .rdata(axi_rdata_raw), // Dữ liệu thô đọc về
        .busy(axi_busy),

        // Kết nối AXI ra ngoài
        .m_axi_awaddr(m_axi_awaddr), .m_axi_awvalid(m_axi_awvalid), .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),   .m_axi_wstrb(m_axi_wstrb),     .m_axi_wvalid(m_axi_wvalid),   .m_axi_wready(m_axi_wready),
        .m_axi_bvalid(m_axi_bvalid), .m_axi_bready(m_axi_bready),
        .m_axi_araddr(m_axi_araddr), .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),   .m_axi_rvalid(m_axi_rvalid),   .m_axi_rready(m_axi_rready)
    );

    // =========================================================================
    // 3. XỬ LÝ DỮ LIỆU ĐỌC (LOAD EXTENSION)
    // =========================================================================
    // AXI trả về 32-bit thô (Word aligned). Ta cần trích xuất Byte/Half cần thiết.
    
    always @(*) begin
        mem_out = 32'd0;
        
        // Chỉ xử lý khi đã đọc xong
        if (axi_done && re) begin 
            reg [7:0]  byte_val;
            reg [15:0] half_val;
            
            // Dịch phải để đưa byte cần đọc về vị trí thấp nhất [7:0]
            byte_val = axi_rdata_raw >> (addr[1:0] * 8);
            half_val = axi_rdata_raw >> (addr[1:0] * 8);

            case (mode)
                b: mem_out = {{24{byte_val[7]}}, byte_val};   // LB (Sign Extend)
                h: mem_out = {{16{half_val[15]}}, half_val};  // LH (Sign Extend)
                w: mem_out = axi_rdata_raw;                   // LW
                bu:mem_out = {24'd0, byte_val};               // LBU (Zero Extend)
                hu:mem_out = {16'd0, half_val};               // LHU (Zero Extend)
                default: mem_out = axi_rdata_raw;
            endcase
        end
    end

    // =========================================================================
    // 4. TÍN HIỆU STALL
    // =========================================================================
    // Stall CPU khi: Có lệnh Load/Store NHƯNG AXI chưa báo xong (Done)
    assign stall_out = (re || we) && !axi_done;

endmodule