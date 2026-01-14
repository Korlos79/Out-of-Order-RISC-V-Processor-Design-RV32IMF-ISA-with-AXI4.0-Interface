module rv32m_muldiv_split (
  input  wire        clk,
  input  wire        rst_n,

  input  wire        op_valid,     
  input  wire [4:0]  op_sel,       // 10000->10111
  input  wire [31:0] rs1,
  input  wire [31:0] rs2,

  output wire        busy,
  output wire        done,
  output wire [31:0] result
);
  wire is_mul_group = (op_sel[4:3] == 2'b10) && (op_sel[2] == 1'b0); // 10000..10011
  wire is_div_group = (op_sel[4:2] == 3'b101);                       // 10100..10111

  // Submodule handshakes
  reg  mul_busy_q, div_busy_q;
  wire mul_busy, mul_done; wire [31:0] mul_result;
  wire div_busy, div_done; wire [31:0] div_result;

  // Tạo xung start 1 chu kỳ khi thấy op_valid & chưa bận
  wire mul_start = op_valid & is_mul_group & ~mul_busy_q & ~div_busy_q;
  wire div_start = op_valid & is_div_group & ~div_busy_q & ~mul_busy_q;

  iter_mul32 u_mul (
    .clk(clk), .rst_n(rst_n),
    .start(mul_start), .op_sel(op_sel),
    .rs1(rs1), .rs2(rs2),
    .busy(mul_busy), .done(mul_done), .result(mul_result)
  );

  iter_div32 u_div (
    .clk(clk), .rst_n(rst_n),
    .start(div_start), .op_sel(op_sel),
    .rs1(rs1), .rs2(rs2),
    .busy(div_busy), .done(div_done), .result(div_result)
  );

  // Latch busy for start-gating
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin mul_busy_q <= 1'b0; div_busy_q <= 1'b0; end
    else begin       mul_busy_q <= mul_busy; div_busy_q <= div_busy; end
  end

  assign busy   = mul_busy | div_busy;
  assign done   = mul_done | div_done;
  assign result = is_mul_group ? mul_result : div_result;
endmodule
