module pdm_to_pcm(
  input clk,          // System clock
  input pdm_in,       // PDM microphone output
  output logic [7:0] pcm_out // 8-bit PCM output
);

  localparam int SAMPLING_RATE = 256;
  localparam int NUM_BITS = 8 // log2(256)
  
  logic [SAMPLING_RATE-1:0] pdm_buffer;
  logic [NUM_BITS-1:0] pdm_buffer_index;
  logic [7:0] accumulator; 
  
  always_ff @(posedge clk) begin
    if (pdm_buffer_index = 8'b11111111) begin
      pcm_out = pdm_buffer;
      accumulator = 0;
    end
    else begin
      if (pdm_in) begin
        accumulator = accumulator + 1;
      end
      else begin
        accumulator = 
      end
    end
  end
  

endmodule
