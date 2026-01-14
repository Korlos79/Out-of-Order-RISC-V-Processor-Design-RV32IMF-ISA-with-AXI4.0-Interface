module axi_simple_master (
    input wire clk,
    input wire rst_n,

    // --- GIAO DIỆN VỚI CPU CORE (User Interface) ---
    input  wire        start,        // Kích hoạt giao dịch (1 chu kì)
    input  wire        rw,           // 0: Read (Đọc), 1: Write (Ghi)
    input  wire [31:0] addr,         // Địa chỉ truy cập
    input  wire [31:0] wdata,        // Dữ liệu ghi (cho Write)
    input  wire [3:0]  wstrb,        // Byte mask (cho Write: 4'b1111 = 32bit)
    
    output reg         done,         // Báo xong (Pulse 1 chu kì)
    output reg  [31:0] rdata,        // Dữ liệu đọc về (cho Read)
    output wire        busy,         // Trạng thái bận (1: Đang chạy AXI, 0: Rảnh)

    // --- GIAO DIỆN AXI4 MASTER (Nối ra RAM/Interconnect) ---
    
    // 1. Write Address Channel (AW)
    output reg [31:0] m_axi_awaddr,
    output reg        m_axi_awvalid,
    input  wire       m_axi_awready,
    
    // 2. Write Data Channel (W)
    output reg [31:0] m_axi_wdata,
    output reg [3:0]  m_axi_wstrb,
    output reg        m_axi_wvalid,
    input  wire       m_axi_wready,
    
    // 3. Write Response Channel (B)
    input  wire       m_axi_bvalid,
    output reg        m_axi_bready,
    
    // 4. Read Address Channel (AR)
    output reg [31:0] m_axi_araddr,
    output reg        m_axi_arvalid,
    input  wire       m_axi_arready,
    
    // 5. Read Data Channel (R)
    input  wire [31:0] m_axi_rdata,
    input  wire        m_axi_rvalid,
    output reg         m_axi_rready
);

    // --- FSM STATES ---
    localparam S_IDLE    = 3'd0;
    
    // Read States
    localparam S_AR_ADDR = 3'd1; // Gửi địa chỉ đọc
    localparam S_R_DATA  = 3'd2; // Nhận dữ liệu
    
    // Write States
    localparam S_AW_ADDR = 3'd3; // Gửi địa chỉ ghi
    localparam S_W_DATA  = 3'd4; // Gửi dữ liệu ghi
    localparam S_B_RESP  = 3'd5; // Chờ phản hồi ghi

    reg [2:0] state;

    // Output busy khi không ở trạng thái IDLE
    assign busy = (state != S_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            done  <= 0;
            rdata <= 0;
            // Reset toàn bộ tín hiệu AXI
            m_axi_awvalid <= 0; m_axi_awaddr <= 0;
            m_axi_wvalid  <= 0; m_axi_wdata  <= 0; m_axi_wstrb <= 0;
            m_axi_bready  <= 0;
            m_axi_arvalid <= 0; m_axi_araddr <= 0;
            m_axi_rready  <= 0;
        end else begin
            // Mặc định done chỉ bật trong 1 chu kì rồi tắt
            done <= 0;

            case (state)
                // --- TRẠNG THÁI CHỜ ---
                S_IDLE: begin
                    if (start) begin
                        if (rw) begin 
                            // === WRITE REQUEST ===
                            // Chuẩn bị kênh Address (AW)
                            m_axi_awaddr  <= addr;  // <--- Gán trước
                            m_axi_awvalid <= 1;
                            m_axi_wdata   <= wdata; // <--- Chuẩn bị sẵn dữ liệu
                            m_axi_wstrb   <= wstrb;                                                  
                            state <= S_AW_ADDR;
                        end else begin 
                            // === READ REQUEST ===
                            // Chuẩn bị kênh Address (AR)
                            m_axi_araddr  <= addr;  // <--- Gán trước
                            m_axi_arvalid <= 1;
                            m_axi_rready  <= 1;                          
                            state <= S_AR_ADDR;
                        end
                    end
                end

                // ==========================================
                // READ PATH (AR -> R)
                // ==========================================
                S_AR_ADDR: begin
                    // Giữ ARVALID cho đến khi RAM trả lời ARREADY = 1
                    if (m_axi_arready && m_axi_arvalid) begin
                        m_axi_arvalid <= 0; // Đã gửi xong địa chỉ, tắt valid
                        state         <= S_R_DATA;
                    end
                end

                S_R_DATA: begin
                    // Đợi RVALID từ RAM (báo dữ liệu đã có)
                    // Vì ta đã set RREADY=1 từ đầu nên handshake xảy ra ngay khi RVALID=1
                    if (m_axi_rvalid && m_axi_rready) begin
                        rdata        <= m_axi_rdata; // Lấy dữ liệu vào
                        done         <= 1;           // Báo xong cho CPU
                        m_axi_rready <= 0;           // Tắt nhận để tiết kiệm điện/an toàn
                        state        <= S_IDLE;
                    end
                end

                // ==========================================
                // WRITE PATH (AW -> W -> B)
                // ==========================================
                S_AW_ADDR: begin
                    // Gửi địa chỉ ghi (AW Channel)
                    if (m_axi_awready && m_axi_awvalid) begin

                        m_axi_awvalid <= 0; // Xong địa chỉ
                        m_axi_wvalid  <= 1; // Bắt đầu gửi dữ liệu (W Channel)
                        state         <= S_W_DATA;
                    end
                end

                S_W_DATA: begin
                    // Gửi dữ liệu ghi (W Channel)
                    if (m_axi_wready && m_axi_wvalid) begin
                        m_axi_wvalid <= 0; // Xong dữ liệu
                        m_axi_bready <= 1; // Bật sẵn sàng nhận phản hồi (B Channel)
                        state        <= S_B_RESP;
                    end
                end

                S_B_RESP: begin
                    // Đợi RAM xác nhận "Ghi thành công" (BVALID)
                    if (m_axi_bvalid) begin
                        m_axi_bready <= 0; // Tắt ready
                        done         <= 1; // Báo xong cho CPU
                        state        <= S_IDLE;
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule