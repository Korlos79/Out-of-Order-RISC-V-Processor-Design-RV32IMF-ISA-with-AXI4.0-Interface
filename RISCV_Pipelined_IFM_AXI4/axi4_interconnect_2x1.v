module axi4_interconnect_2x1 (
    input wire clk,
    input wire rst_n,

    // =========================================================================
    // SLAVE 0: Nối với IFU (Instruction Fetch) - Ưu tiên THẤP
    // =========================================================================
    input  wire [31:0] s0_axi_araddr, input wire s0_axi_arvalid, output reg s0_axi_arready,
    output reg  [31:0] s0_axi_rdata,  output reg s0_axi_rvalid,  input wire s0_axi_rready,
    // (IFU không ghi nên không có kênh Write)

    // =========================================================================
    // SLAVE 1: Nối với LSU (Load/Store) - Ưu tiên CAO
    // =========================================================================
    // Read Channel
    input  wire [31:0] s1_axi_araddr, input wire s1_axi_arvalid, output reg s1_axi_arready,
    output reg  [31:0] s1_axi_rdata,  output reg s1_axi_rvalid,  input wire s1_axi_rready,
    // Write Channel
    input  wire [31:0] s1_axi_awaddr, input wire s1_axi_awvalid, output reg s1_axi_awready,
    input  wire [31:0] s1_axi_wdata,  input wire [3:0] s1_axi_wstrb, input wire s1_axi_wvalid, output reg s1_axi_wready,
    output reg         s1_axi_bvalid, input wire s1_axi_bready,

    // =========================================================================
    // MASTER: Nối ra RAM (Single Port)
    // =========================================================================
    output reg [31:0] m_axi_araddr, output reg m_axi_arvalid, input wire m_axi_arready,
    input  wire [31:0] m_axi_rdata,  input wire m_axi_rvalid,  output reg m_axi_rready,
    
    output reg [31:0] m_axi_awaddr, output reg m_axi_awvalid, input wire m_axi_awready,
    output reg [31:0] m_axi_wdata,  output reg [3:0] m_axi_wstrb, output reg m_axi_wvalid, input wire m_axi_wready,
    input  wire        m_axi_bvalid, output reg m_axi_bready
);

    // Trạng thái Arbiter
    localparam GRANT_NONE = 2'd0;
    localparam GRANT_S0   = 2'd1; // IFU đang dùng
    localparam GRANT_S1   = 2'd2; // LSU đang dùng

    reg [1:0] current_grant;

    // Logic Phân xử (Arbiter Logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_grant <= GRANT_NONE;
        end else begin
            case (current_grant)
                GRANT_NONE: begin
                    // Ưu tiên LSU (S1) trước
                    if (s1_axi_arvalid || s1_axi_awvalid) 
                        current_grant <= GRANT_S1;
                    else if (s0_axi_arvalid)
                        current_grant <= GRANT_S0;
                end

                GRANT_S0: begin
                    // Nếu IFU (S0) xong việc (Read xong) -> Về IDLE
                    // Điều kiện xong: RVALID & RREADY (Last beat)
                    if (m_axi_rvalid && m_axi_rready) 
                        current_grant <= GRANT_NONE;
                end

                GRANT_S1: begin
                    // Nếu LSU (S1) xong việc
                    // Xong Read: RVALID & RREADY
                    // Xong Write: BVALID & BREADY
                    if ((m_axi_rvalid && m_axi_rready) || (m_axi_bvalid && m_axi_bready))
                        current_grant <= GRANT_NONE;
                end
            endcase
        end
    end

    // --- LOGIC MUX/DEMUX (Nối dây dựa trên Grant) ---

    always @(*) begin
        // Mặc định: Ngắt kết nối, lái về 0
        s0_axi_arready = 0; s0_axi_rvalid = 0; s0_axi_rdata = 0;
        s1_axi_arready = 0; s1_axi_rvalid = 0; s1_axi_rdata = 0;
        s1_axi_awready = 0; s1_axi_wready = 0; s1_axi_bvalid = 0;
        
        m_axi_araddr = 0; m_axi_arvalid = 0; m_axi_rready = 0;
        m_axi_awaddr = 0; m_axi_awvalid = 0;
        m_axi_wdata  = 0; m_axi_wstrb = 0; m_axi_wvalid = 0; m_axi_bready = 0;

        case (current_grant)
            GRANT_S0: begin // === KẾT NỐI IFU <-> RAM ===
                // Master (RAM) inputs lấy từ S0 (IFU)
                m_axi_araddr  = s0_axi_araddr;
                m_axi_arvalid = s0_axi_arvalid;
                m_axi_rready  = s0_axi_rready;

                // Slave (IFU) outputs lấy từ Master (RAM)
                s0_axi_arready = m_axi_arready;
                s0_axi_rvalid  = m_axi_rvalid;
                s0_axi_rdata   = m_axi_rdata;
            end

            GRANT_S1: begin // === KẾT NỐI LSU <-> RAM ===
                // 1. Read Channel
                m_axi_araddr  = s1_axi_araddr;
                m_axi_arvalid = s1_axi_arvalid;
                m_axi_rready  = s1_axi_rready;
                s1_axi_arready = m_axi_arready;
                s1_axi_rvalid  = m_axi_rvalid;
                s1_axi_rdata   = m_axi_rdata;

                // 2. Write Channel
                m_axi_awaddr  = s1_axi_awaddr;
                m_axi_awvalid = s1_axi_awvalid;
                s1_axi_awready = m_axi_awready;

                m_axi_wdata   = s1_axi_wdata;
                m_axi_wstrb   = s1_axi_wstrb;
                m_axi_wvalid  = s1_axi_wvalid;
                s1_axi_wready = m_axi_wready;

                m_axi_bready  = s1_axi_bready;
                s1_axi_bvalid = m_axi_bvalid;
            end
            
            default: ; // Giữ mặc định 0
        endcase
    end

endmodule