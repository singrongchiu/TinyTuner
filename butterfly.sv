import complex_pkg::*;
module butterfly #(
  parameter int DATA_WIDTH = 16
) (
  input  logic clk,
  input  logic enable,

  input  complex_t a,      // Input A
  input  complex_t b,      // Input B

  output complex_t x_out,  // Output X = A + B
  output complex_t y_out   // Output Y = A - B
);

  logic signed [DATA_WIDTH:0] sum_re, sum_im; // Need one extra bit for potential adder overflow
  logic signed [DATA_WIDTH:0] diff_re, diff_im;

  /*
  // Instantiate complex multiplier
  complex_multiplier #( .DATA_WIDTH(DATA_WIDTH) ) cmul (
    .clk    (clk),
    .reset  (reset),
    .enable (enable), // Pass enable signal
    .a      (b),
    .b      (w),
    .result (b_times_w) // Output registered inside multiplier
  );
  */

  // Perform Additions/Subtractions (Can be pipelined)
  // Need to handle potential overflow/saturation if required by fixed-point scheme
  always_comb begin
      // Extend operands by 1 bit before adding/subtracting
    sum_re  = {a.re[DATA_WIDTH-1], a.re} + {b.re[DATA_WIDTH-1], b.re};
    sum_im  = {a.im[DATA_WIDTH-1], a.im} + {b.im[DATA_WIDTH-1], b.im};
    diff_re = {a.re[DATA_WIDTH-1], a.re} - {b.re[DATA_WIDTH-1], b.re};
    diff_im = {a.im[DATA_WIDTH-1], a.im} - {b.im[DATA_WIDTH-1], b.im};
  end

  // Register outputs, potentially with saturation/truncation back to DATA_WIDTH
  always_ff @(posedge clk) begin
    if (enable) begin
      x_out.re <= sum_re[DATA_WIDTH-1:0];
      x_out.im <= sum_im[DATA_WIDTH-1:0];
      y_out.re <= diff_re[DATA_WIDTH-1:0];
      y_out.im <= diff_im[DATA_WIDTH-1:0];
    end
  end

endmodule : butterfly
