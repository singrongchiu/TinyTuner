// Code your design here
module pdm_to_pcm(
  input clk,          // System clock
  input pdm_in,       // PDM microphone output
  input reset,
  output logic [7:0] pcm_out, // 8-bit PCM output
  output logic valid_out
);

  localparam int SAMPLING_RATE = 256;
  localparam int NUM_BITS = 8; // max = 256
  
  // logic [SAMPLING_RATE-1:0] pdm_buffer;
  logic [NUM_BITS-1:0] pdm_buffer_index;
  logic [7:0] accumulator; 
  
  always_ff @(posedge clk) begin
    if (reset) begin
      pdm_buffer_index = 0;
      accumulator = 0;
      // $display("RESET!!!!!!!!!!!!!!!!");
      // $display("index1: %d", pdm_buffer_index);
    end
    else if (pdm_buffer_index == 8'b11111111) begin
      pcm_out = (accumulator + pdm_in);
      accumulator = 0;
      valid_out = 1;
      pdm_buffer_index = 0;
      // $display("AM AT MAX INDEX!!!!!!!!!!!!!!!!!!");
    end
    else begin
      accumulator = accumulator + pdm_in;
      valid_out = 0;
      // $display("index2: %d", pdm_buffer_index);
      pdm_buffer_index = pdm_buffer_index + 1;
    end
  end
  
endmodule

