// Code your design here
// complex_multiplier.sv
import complex_pkg::*;

module complex_multiplier #(
  parameter int DATA_WIDTH = 16
) (
  input  logic clk,
  input  logic reset,
  input  logic enable, // Optional enable

  input  complex_t a,
  input  complex_t b,

  output complex_t result
);

  // Internal signals might need wider width to avoid overflow before truncation/scaling
  localparam int MULT_WIDTH = 2 * DATA_WIDTH;
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
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      result.re <= '0;
      result.im <= '0;
    end else if (enable) begin
      $display("p_re: %d", p_re);
      $display("p_im: %d", p_im); 
      result.re <= p_re;
      result.im <= p_im;
      
      /*
      // Example: Right shift if needed based on fixed-point representation
      result.re <= fixed_point_t'(p_re >>> (DATA_WIDTH)); // Example: Assume result needs scaling
      result.im <= fixed_point_t'(p_im >>> (DATA_WIDTH)); // Example: Assume result needs scaling
      */
    end
  end

endmodule : complex_multiplier
