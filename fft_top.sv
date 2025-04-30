module fft_top (
  input clk,          // System clock
  input pdm_in,       // PDM microphone output
  input rst_n,
  output logic [6:0] sevseg
);

logic [7:0] pcm_out;
logic valid_out;
logic clk_slower;
/*
  input clk,          // System clock
  input pdm_in,       // PDM microphone output
  input rst_n,
  output logic [7:0] pcm_out, // 8-bit PCM output
  output logic valid_out,
  output logic clk_slower
*/
pdm_to_cdm my_pdm_to_cdm(.clk(clk), .pdm_in(pdm_in), .rst_n(rst_n), .pcm_out(pcm_out), .valid_out(valid_out), .clk_slower(clk_slower));

logic out_valid;
logic [2:0] highest_bin;
/*
  input  logic clk,
  input  logic rst_n,
  input  logic [DATA_WIDTH-1:0] in_real,
  input  logic [DATA_WIDTH-1:0] in_imag,
  input  logic in_valid,
  output logic out_valid,
  output logic [STAGES-1:0] highest_bin
*/
Radix2FFTPipeline8N myRadix2FFTPipeline8N(.clk(clk_slower), .rst_n(rst_n), .in_real(pcm_out), .in_imag(0), .in_valid(valid_out), .out_valid(out_valid), .highest_bin(highest_bin));

logic [2:0] bitreversed_bin;
/*
  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out
*/
bit_reverse mybit_reverse(.data_in(highest_bin), .data_out(bitreversed_bin));

/*
  input logic [3:0] digit,
  input logic clock, rst_n,
  output logic [6:0] sevseg
*/
sevenseg mysevenseg(.digit(bitreversed_bin), .clk(clk_slower), .rst_n(rst_n), .sevseg(sevseg)); 

endmodule
