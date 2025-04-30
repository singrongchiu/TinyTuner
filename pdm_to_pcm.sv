// Code your design here
module pdm_to_pcm(
  input clk,          // System clock
  input pdm_in,       // PDM microphone output
  input rst_n,
  output logic [7:0] pcm_out, // 8-bit PCM output
  output logic valid_out,
  output logic clk_slower
);

  localparam int SAMPLING_RATE = 5000;
//  localparam int NUM_BITS = 8; // max = 256
  
  // logic [SAMPLING_RATE-1:0] pdm_buffer;
  logic [14:0] pdm_buffer_index;
  logic [14:0] accumulator; 
  
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      pdm_buffer_index = 0;
      accumulator = 0;
      // $display("RESET!!!!!!!!!!!!!!!!");
      // $display("index1: %d", pdm_buffer_index);
    end
    else if (pdm_buffer_index == 5000) begin
      pcm_out = (accumulator + pdm_in) >> 5;
      accumulator = 0;
      valid_out = 1;
      pdm_buffer_index = 0;
      clk_slower <= 1;
      // $display("AM AT MAX INDEX!!!!!!!!!!!!!!!!!!");
    end
    else begin
      accumulator = accumulator + pdm_in;
      valid_out = 0;
      // $display("index2: %d", pdm_buffer_index);
      pdm_buffer_index = pdm_buffer_index + 1;
      if (pdm_buffer_index == 2500) begin
        clk_slower <= 0;
      end
    end
  end
  
endmodule

