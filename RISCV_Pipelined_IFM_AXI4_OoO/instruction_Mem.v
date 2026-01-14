module instruction_Mem (
    input wire clk,
    input wire rst_n,

    // Giao tiếp với Pipeline (IF Stage)
    input  wire [31:0] addr,          // PC
    output reg  [31:0] inst,          // Lệnh ra (Sửa thành logic tổ hợp)
    output reg         stall_out,     // Báo CPU dừng (Sửa thành logic tổ hợp)

    // Giao diện AXI4 Master
    output wire [31:0] m_axi_araddr, 
    output wire        m_axi_arvalid, 
    input  wire        m_axi_arready,
	 
    input  wire [31:0] m_axi_rdata,  
    input  wire        m_axi_rvalid, 
    output wire        m_axi_rready
);

    // --- 1. INSTANCE AXI MASTER (Shipper) ---
    wire axi_start;
    wire axi_done;
    wire axi_busy;
    wire [31:0] axi_rdata_raw;

    axi_simple_master u_axi (
        .clk(clk), .rst_n(rst_n),
        .start(axi_start), .rw(1'b0), // Read Only
        .addr(addr),         .wdata(32'd0), .wstrb(4'b0),
        .done(axi_done),     .rdata(axi_rdata_raw), .busy(axi_busy),
        
        .m_axi_araddr(m_axi_araddr), .m_axi_arvalid(m_axi_arvalid), .m_axi_arready(m_axi_arready),
        .m_axi_rdata(m_axi_rdata),   .m_axi_rvalid(m_axi_rvalid),   .m_axi_rready(m_axi_rready),
        
        // Các cổng Write bỏ trống (Verilog 2001+)
        .m_axi_awaddr(), .m_axi_awvalid(), .m_axi_awready(1'b0),
        .m_axi_wdata(),  .m_axi_wstrb(),   .m_axi_wvalid(), .m_axi_wready(1'b0),
        .m_axi_bvalid(1'b0), .m_axi_bready()
    );

    // --- 2. CACHE 1 DÒNG (Storage) ---
    reg [31:0] cached_pc;
    reg [31:0] cached_instr;
    reg        valid; 

    // Logic Hit: Địa chỉ yêu cầu trùng với địa chỉ đang lưu
    wire hit = valid && (addr == cached_pc);

    // --- 3. LOGIC ĐIỀU KHIỂN (SỬA LỖI TIMING) ---
    
    // Logic Start AXI: Nếu Miss và AXI đang rảnh thì gọi Shipper ngay
    assign axi_start = !hit && !axi_busy; 

    // Logic Output (Combinational): Phản hồi NGAY LẬP TỨC
    always @(*) begin
        if (hit) begin
            // Nếu có trong cache: Trả lệnh ngay, không stall
            inst      = cached_instr;
            stall_out = 1'b0; 
        end else begin
            // Nếu Miss: Trả NOP (hoặc 0), YÊU CẦU STALL NGAY
            inst      = 32'd0; 
            stall_out = 1'b1; 
        end
    end

    // Logic Cập nhật Cache (Sequential): Chỉ chạy khi có xung nhịp
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= 0; 
            cached_pc <= 32'hFFFFFFFF; 
            cached_instr <= 0;
        end else begin
            // Khi AXI báo xong, lưu dữ liệu vào Cache
            // (Lần fetch tiếp theo sẽ Hit và stall_out sẽ tự động hạ xuống 0)
            if (axi_done) begin
                cached_pc    <= addr;
                cached_instr <= axi_rdata_raw;
                valid        <= 1;
            end
        end
    end

endmodule