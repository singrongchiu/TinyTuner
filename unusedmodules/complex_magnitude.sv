module find_max_complex_magnitude(
  input clk,
  input rst_n,
  input logic signed [15:0] real_in [63:0], // Array of 64 real parts
  input logic signed [15:0] imag_in [63:0], // Array of 64 imaginary parts
  output logic [5-1:0] max_index_out,
  output logic max_valid
);

  localparam NUM_INPUTS = 64;
  localparam DATA_WIDTH = 16;
  localparam INDEX_WIDTH = 5;
  
  logic signed [2*DATA_WIDTH-1:0] magnitude_squared [NUM_INPUTS];
  logic signed [2*DATA_WIDTH-1:0] current_max_magnitude_squared;
  logic [INDEX_WIDTH-1:0] current_max_index;
  logic [INDEX_WIDTH-1:0] index_reg;
  assign compare_enable = (index_reg < NUM_INPUTS - 1);
  
  for (genvar i = 0; i < NUM_INPUTS; i++) begin : gen_magnitude_squared
    assign magnitude_squared[i] = real_in[i] * real_in[i] + imag_in[i] * imag_in[i];
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      current_max_magnitude_squared <= 0;
      current_max_index <= 0;
      index_reg <= 0;
      max_valid <= 1'b0;
    end else begin
      if (index_reg == 0) begin
        current_max_magnitude_squared <= magnitude_squared[0];
        current_max_index <= 0;
      end else if (magnitude_squared[index_reg] > current_max_magnitude_squared) begin
        current_max_magnitude_squared <= magnitude_squared[index_reg];
        current_max_index <= index_reg;
      end

      if (compare_enable) begin
        index_reg <= index_reg + 1;
      end else begin
        max_valid <= 1'b1;
      end
    end
  end
  
  assign max_index_out = current_max_index;
  
  endmodule
