module rv32m_muldiv #(
  parameter integer MUL_STEPS_PER_CYCLE = 1,  
  parameter integer DIV_STEPS_PER_CYCLE = 1   
)(
  input              clk,
  input              rst_n,

  input              op_valid,      
  input      [4:0]   op_sel,        
  input      [31:0]  rs1,
  input      [31:0]  rs2,

  output reg         busy,          
  output reg         done,          
  output reg [31:0]  result         
);
  
  wire is_mul    = (op_sel == 5'b10000);
  wire is_mulh   = (op_sel == 5'b10001);
  wire is_mulhsu = (op_sel == 5'b10010);
  wire is_mulhu  = (op_sel == 5'b10011);
  wire is_div    = (op_sel == 5'b10100);
  wire is_divu   = (op_sel == 5'b10101);
  wire is_rem    = (op_sel == 5'b10110);
  wire is_remu   = (op_sel == 5'b10111);

  wire any_mul = is_mul | is_mulh | is_mulhsu | is_mulhu;
  wire any_div = is_div | is_divu | is_rem  | is_remu;

  // ---------------------------------------------
  // FSM
  // ---------------------------------------------
  localparam S_IDLE = 2'd0;
  localparam S_MUL  = 2'd1;
  localparam S_DIV  = 2'd2;

  reg [1:0] state, next_state;

  // ---------------------------------------------
  // MUL (shift-add 64-bit)
  // ---------------------------------------------
  reg         mul_signed_rs1, mul_signed_rs2; 
  reg [63:0]  mul_a;      
  reg [63:0]  mul_b;
  reg [63:0]  mul_acc;    
  reg [5:0]   mul_cnt;

  always @(*) begin
    mul_signed_rs1 = is_mulh | is_mulhsu;
    mul_signed_rs2 = is_mulh; 
  end

  wire [63:0] rs1_ext_signed = {{32{rs1[31]}}, rs1};
  wire [63:0] rs2_ext_signed = {{32{rs2[31]}}, rs2};
  wire [63:0] rs1_ext_unsigned = {32'b0, rs1};
  wire [63:0] rs2_ext_unsigned = {32'b0, rs2};

  // ---------------------------------------------
  // DIV (restoring)
  // ---------------------------------------------
  reg         div_signed;      
  reg         div_quot_out;   
  reg [31:0]  div_dividend;   
  reg [31:0]  div_divisor;     
  reg [31:0]  div_quotient;
  reg [31:0]  div_remainder;
  reg [ 5:0]  div_cnt;
  reg         quot_neg, rem_neg;

  wire div_by_zero   = (rs2 == 32'b0);
  wire signed_overfl = (is_div | is_rem) && (rs1 == 32'h8000_0000) && (rs2 == 32'hFFFF_FFFF);

  // ---------------------------------------------
  // FSM 
  // ---------------------------------------------
  integer i;

  always @(*) begin
    next_state = state;
    case (state)
      S_IDLE: begin
        if (op_valid && any_mul) next_state = S_MUL;
        else if (op_valid && any_div) next_state = S_DIV;
      end
      S_MUL: begin
        if (mul_cnt == 0) next_state = S_IDLE;
      end
      S_DIV: begin
        if (div_cnt == 0) next_state = S_IDLE;
      end
      default: next_state = S_IDLE;
    endcase
  end

  // ---------------------------------------------
  // busy/done/result
  // ---------------------------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state   <= S_IDLE;
      busy    <= 1'b0;
      done    <= 1'b0;
      result  <= 32'b0;

      mul_a   <= 64'b0;
      mul_b   <= 64'b0;
      mul_acc <= 64'b0;
      mul_cnt <= 6'd0;

      div_signed    <= 1'b0;
      div_quot_out  <= 1'b0;
      div_dividend  <= 32'b0;
      div_divisor   <= 32'b0;
      div_quotient  <= 32'b0;
      div_remainder <= 32'b0;
      div_cnt       <= 6'd0;
      quot_neg      <= 1'b0;
      rem_neg       <= 1'b0;
    end else begin
      state <= next_state;
      done  <= 1'b0;

      case (state)
        S_IDLE: begin
          busy <= 1'b0;

          if (op_valid && any_mul) begin
            
            busy  <= 1'b1;

            
            mul_a <= mul_signed_rs1 ? rs1_ext_signed  : rs1_ext_unsigned;
            mul_b <= mul_signed_rs2 ? rs2_ext_signed  : rs2_ext_unsigned;
            mul_acc <= 64'b0;
            mul_cnt <= 6'd32; 
          end

          if (op_valid && any_div) begin
            
            if (div_by_zero) begin
              done   <= 1'b1;
              busy   <= 1'b0;
              result <= (is_div  || is_divu) ? 32'hFFFF_FFFF : rs1; 
            end else if (signed_overfl) begin
              done   <= 1'b1;
              busy   <= 1'b0;
              result <= (is_div) ? 32'h8000_0000 : 32'h0; 
            end else begin
              busy        <= 1'b1;
              div_signed  <= (is_div | is_rem);
              div_quot_out<= (is_div | is_divu);

              
              quot_neg    <= (is_div && (rs1[31] ^ rs2[31]));
              rem_neg     <= (is_rem && rs1[31]);

              
              div_dividend<= (is_div | is_rem) ? (rs1[31] ? -rs1 : rs1) : rs1;
              div_divisor <= (is_div | is_rem) ? (rs2[31] ? -rs2 : rs2) : rs2;

              div_quotient<= 32'b0;
              div_remainder<=32'b0;
              div_cnt     <= 6'd32;
            end
          end
        end

        S_MUL: begin
          busy <= 1'b1;

         
          for (i = 0; i < MUL_STEPS_PER_CYCLE; i = i + 1) begin
            if (mul_cnt != 0) begin
              
              if (mul_b[0]) mul_acc <= mul_acc + mul_a;
              
              mul_a  <= mul_a  << 1;
              mul_b  <= mul_b  >> 1;
              mul_cnt<= mul_cnt-1;
            end
          end

          if (mul_cnt == 0) begin
            busy  <= 1'b0;
            done  <= 1'b1;
           
            if (is_mul)      result <= mul_acc[31:0];
            else if (is_mulh || is_mulhsu || is_mulhu)
                              result <= mul_acc[63:32];
          end
        end

        S_DIV: begin
          busy <= 1'b1;

          
          for (i = 0; i < DIV_STEPS_PER_CYCLE; i = i + 1) begin
            if (div_cnt != 0) begin
              {div_remainder, div_dividend} <= {div_remainder, div_dividend} << 1;
              if (div_remainder >= div_divisor) begin
                div_remainder <= div_remainder - div_divisor;
                div_quotient  <= {div_quotient[30:0], 1'b1};
              end else begin
                div_quotient  <= {div_quotient[30:0], 1'b0};
              end
              div_cnt <= div_cnt - 1;
            end
          end

          if (div_cnt == 0) begin
            busy <= 1'b0;
            done <= 1'b1;
            if (div_quot_out) begin
              result <= (quot_neg ? -div_quotient : div_quotient);
            end else begin
              result <= (rem_neg ? -div_remainder : div_remainder);
            end
          end
        end
      endcase
    end
  end
endmodule