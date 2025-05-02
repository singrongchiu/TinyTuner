import complex_pkg::*;

module complex_multiplier #(
  parameter int DATA_WIDTH = 16
) (
  input  complex_t a,
  input  complex_t b,

  output complex_t result,
  output complex_t result_scaled
);

  // Internal signals might need wider width to avoid overflow before truncation/scaling
  localparam int MULT_WIDTH = 2 * DATA_WIDTH;
  localparam int SCALED_BY = DATA_WIDTH / 2;
  logic signed [MULT_WIDTH-1:0] p_re, p_im;
  logic signed [MULT_WIDTH-1:0] are_bre, aim_bim;
  logic signed [MULT_WIDTH-1:0] are_bim, aim_bre;

  // Combinational multiplication (can be pipelined for timing)
  // result = (a.re*b.re - a.im*b.im) + j*(a.re*b.im + a.im*b.re)
  assign are_bre = a.re * b.re;
  assign aim_bim = a.im * b.im;
  assign p_re  = are_bre - aim_bim; // Real part intermediate

  assign are_bim = a.re * b.im;
  assign aim_bre = a.im * b.re;
  assign p_im  = are_bim + aim_bre; // Imaginary part intermediate

  // Perform scaling/truncation/rounding to get back to DATA_WIDTH
  // This is CRITICAL and depends on the fixed-point format (e.g., Q format)
  // Simplistic truncation example (assumes result fits DATA_WIDTH LSBs):
  assign result.re = p_re;
  assign result.im = p_im;
  
  assign result_scaled.re = p_re >>> SCALED_BY;
  assign result_scaled.im = p_im >>> SCALED_BY;

endmodule : complex_multiplier
