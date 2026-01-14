module iter_div32 (
  input  wire        clk,
  input  wire        rst_n,

  input  wire        start,     
  input  wire [4:0]  op_sel,    // 10100->10111

  input  wire [31:0] rs1,
  input  wire [31:0] rs2,

  output wire        busy,
  output wire        done,
  output reg  [31:0] result
);
  // Opcodes
  localparam OP_DIV  = 5'b10100;
  localparam OP_DIVU = 5'b10101;
  localparam OP_REM  = 5'b10110;
  localparam OP_REMU = 5'b10111;

  // FSM
  localparam S_IDLE=3'd0, S_PREP=3'd1, S_RUN=3'd2, S_FIX=3'd3, S_DONE=3'd4, S_BYPASS=3'd5;
  reg [2:0] state, state_n;

  assign busy = (state==S_PREP)||(state==S_RUN)||(state==S_FIX);
  assign done = (state==S_DONE);

  // Mode flags
  wire is_div   = (op_sel==OP_DIV)  || (op_sel==OP_DIVU);
  wire is_rem   = (op_sel==OP_REM)  || (op_sel==OP_REMU);
  wire is_uns   = (op_sel==OP_DIVU) || (op_sel==OP_REMU); // unsigned mode

  // Special cases
  wire div_by_zero  = (rs2 == 32'd0);
  wire ovf_minus1   = ((op_sel==OP_DIV)||(op_sel==OP_REM)) &&
                      (rs1 == 32'h8000_0000) && (rs2 == 32'hFFFF_FFFF);

  // Working regs (unsigned)
  reg [31:0] dividend_abs, divisor_abs;
  reg [31:0] quotient, quotient_next;
  reg [31:0] remainder, remainder_next;
  reg [5:0]  i; // 0..31

  wire rs1_neg = rs1[31], rs2_neg = rs2[31];
  wire [31:0] rs1_abs = (is_uns ? rs1 : (rs1_neg ? (~rs1 + 32'd1) : rs1));
  wire [31:0] rs2_abs = (is_uns ? rs2 : (rs2_neg ? (~rs2 + 32'd1) : rs2));

  // Next-state
  always @* begin
    state_n = state;
    case (state)
      S_IDLE : if (start) state_n = (div_by_zero || ovf_minus1) ? S_BYPASS : S_PREP;
      S_BYPASS:           state_n = S_DONE;
      S_PREP:             state_n = S_RUN;
      S_RUN : if (i==6'd31) state_n = S_FIX;
      S_FIX :               state_n = S_DONE;
      S_DONE:               state_n = S_IDLE;
      default:              state_n = S_IDLE;
    endcase
  end

  // Datapath
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state <= S_IDLE; result <= 32'd0;
      dividend_abs<=32'd0; divisor_abs<=32'd0;
      quotient<=32'd0; remainder<=32'd0; i<=6'd0;
    end else begin
      state <= state_n;

      case (state)
        // Bypass: chia 0 & overflow
        S_BYPASS: begin
          if (div_by_zero) begin
            if (op_sel==OP_DIV)      result <= 32'hFFFF_FFFF;
            else if (op_sel==OP_DIVU)result <= 32'hFFFF_FFFF;
            else if (op_sel==OP_REM) result <= rs1;
            else                     result <= rs1; // REMU
          end else if (ovf_minus1) begin
            if (op_sel==OP_DIV)      result <= 32'h8000_0000; // INT_MIN
            else                     result <= 32'h0000_0000; // REM = 0
          end
        end

        S_PREP: begin
          dividend_abs <= rs1_abs;
          divisor_abs  <= rs2_abs;
          quotient     <= 32'd0;
          remainder    <= 32'd0;
          i            <= 6'd0;
        end

        S_RUN: begin
          if (i < 6'd32) begin
            reg [31:0] remainder_trial;
            reg        next_bit;
            next_bit        = dividend_abs[31 - i];
            remainder_trial = {remainder[30:0], next_bit};
            if (remainder_trial >= divisor_abs) begin
              remainder <= remainder_trial - divisor_abs;
              quotient  <= {quotient[30:0], 1'b1};
            end else begin
            remainder <= remainder_trial;
            quotient  <= {quotient[30:0], 1'b0};
            end
            i <= i + 6'd1;
          end
        end

        S_FIX: begin
          // Áp dấu về signed nếu cần
          reg [31:0] quot_final, rem_final;
          quot_final = quotient;
          rem_final  = remainder;

          if (!is_uns) begin
            if (is_div && (rs1_neg ^ rs2_neg)) quot_final = (~quot_final) + 32'd1;
            if (is_rem && rs1_neg)             rem_final  = (~rem_final ) + 32'd1;
          end
          result <= is_div ? quot_final : rem_final;
        end

        default: ;
      endcase
    end
  end
endmodule
