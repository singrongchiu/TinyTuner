// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples
`default_nettype none
// butterfly.sv
import complex_pkg::*;

module butterfly #(
  parameter int DATA_WIDTH = 16
) (
  input  logic clk,
  input  logic reset,
  input  logic enable,

  input  complex_t a,      // Input A
  input  complex_t b,      // Input B
  input  complex_t w,      // Twiddle Factor W_N^k

  output complex_t x_out,  // Output X = A + B*W
  output complex_t y_out   // Output Y = A - B*W
);

  complex_t b_times_w;
  logic signed [DATA_WIDTH:0] sum_re, sum_im; // Need one extra bit for potential adder overflow
  logic signed [DATA_WIDTH:0] diff_re, diff_im;

  // Instantiate complex multiplier
  complex_multiplier #( .DATA_WIDTH(DATA_WIDTH) ) cmul (
    .clk    (clk),
    .reset  (reset),
    .enable (enable), // Pass enable signal
    .a      (b),
    .b      (w),
    .result (b_times_w) // Output registered inside multiplier
  );

  // Perform Additions/Subtractions (Can be pipelined)
  // Need to handle potential overflow/saturation if required by fixed-point scheme
  always_comb begin
      // Extend operands by 1 bit before adding/subtracting
      sum_re  = {a.re[DATA_WIDTH-1], a.re} + {b_times_w.re[DATA_WIDTH-1], b_times_w.re};
      sum_im  = {a.im[DATA_WIDTH-1], a.im} + {b_times_w.im[DATA_WIDTH-1], b_times_w.im};
      diff_re = {a.re[DATA_WIDTH-1], a.re} - {b_times_w.re[DATA_WIDTH-1], b_times_w.re};
      diff_im = {a.im[DATA_WIDTH-1], a.im} - {b_times_w.im[DATA_WIDTH-1], b_times_w.im};
  end

  // Register outputs, potentially with saturation/truncation back to DATA_WIDTH
  always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
      x_out <= '{default:'0};
      y_out <= '{default:'0};
    end else if (enable) begin // Latch only when enabled after multiplier latency
      /*
      // ** IMPORTANT: Implement proper saturation/truncation here! **
      // Example: Simple truncation, check MSB for saturation if needed
      x_out.re <= fixed_point_t'(sum_re[DATA_WIDTH-1:0]);
      x_out.im <= fixed_point_t'(sum_im[DATA_WIDTH-1:0]);
      y_out.re <= fixed_point_t'(diff_re[DATA_WIDTH-1:0]);
      y_out.im <= fixed_point_t'(diff_im[DATA_WIDTH-1:0]);
      */
      
      x_out.re <= sum_re[DATA_WIDTH-1:0];
      x_out.im <= sum_im[DATA_WIDTH-1:0];
      y_out.re <= diff_re[DATA_WIDTH-1:0];
      y_out.im <= diff_im[DATA_WIDTH-1:0];
    end
  end

endmodule : butterfly
