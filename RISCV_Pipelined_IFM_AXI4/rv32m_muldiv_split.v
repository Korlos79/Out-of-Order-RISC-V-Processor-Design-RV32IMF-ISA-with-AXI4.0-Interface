module rv32m_muldiv_split (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        op_valid,      // Tín hiệu báo có lệnh hợp lệ ở đầu vào
    input  wire [4:0]  op_sel,        // Mã lệnh: 10000->10111
    input  wire [31:0] rs1,
    input  wire [31:0] rs2,

    output wire        busy,          // Báo bận: Không nhận lệnh mới
    output wire        done,          // Báo kết quả đã xong (Pulse 1 chu kì)
    output wire [31:0] result
);

    // Giải mã nhóm lệnh
    // 100xx -> MUL group (10000, 10001, 10010, 10011)
    // 101xx -> DIV group (10100, 10101, 10110, 10111)
    wire is_mul_group = (op_sel[4:3] == 2'b10) && (op_sel[2] == 1'b0); 
    wire is_div_group = (op_sel[4:3] == 2'b10) && (op_sel[2] == 1'b1);

    // --- Submodule Signals ---
    wire mul_busy; 
    wire mul_done; 
    wire [31:0] mul_result;

    wire div_busy; 
    wire div_done; 
    wire [31:0] div_result;

    // --- Start Logic ---
    // Chỉ kích hoạt start nếu Unit tương ứng không báo bận (và Unit kia cũng không bận để tránh tranh chấp bus)
    // Lưu ý: pipeline_mul32 luôn có mul_busy = 0.
    wire mul_start = op_valid & is_mul_group & ~div_busy; 
    wire div_start = op_valid & is_div_group & ~div_busy;

    // --- 1. INSTANTIATE PIPELINE MULTIPLIER (4 Cycles) ---
    iter_mul32 u_mul (
        .clk(clk),
        .rst_n(rst_n),
        .start(mul_start),
        .op_sel(op_sel),
        .rs1(rs1),
        .rs2(rs2),
        .busy(mul_busy), // Luôn bằng 0
        .done(mul_done),
        .result(mul_result)
    );

    // --- 2. INSTANTIATE FSM DIVIDER (34 Cycles) ---
    iter_div32 u_div (
        .clk(clk),
        .rst_n(rst_n),
        .start(div_start),
        .op_sel(op_sel),
        .rs1(rs1),
        .rs2(rs2),
        .busy(div_busy), // =1 trong suốt quá trình chia
        .done(div_done),
        .result(div_result)
    );

    // --- Output Logic ---
    
    // Wrapper bận khi Bộ chia đang tính. 
    // Bộ nhân pipeline không bao giờ chặn (non-blocking), trừ khi ta muốn chặn start của nó.
    assign busy = div_busy; 

    // Kết quả xong khi một trong hai xong
    assign done = mul_done | div_done;

    // Multiplexer chọn kết quả
    // Ưu tiên: Khi mul_done bật lên thì lấy mul_result. 
    // Vì div_done và mul_done khó xảy ra cùng lúc (do logic busy chặn start), 
    // nhưng nếu có thì thiết kế này ưu tiên MUL (hoặc bạn có thể OR/MUX tùy ý).
    assign result = mul_done ? mul_result : div_result;

endmodule