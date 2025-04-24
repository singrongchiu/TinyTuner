`default_nettype none

module delaymodule #(
  parameter int DELAY = 8
) (
  input a, 
  input clk,
  output a_delayed
);
  logic [DELAY - 1:0] temp;
  
  always_ff @(posedge clk) begin
    temp = {temp[DELAY - 2:0], a};
  end
  
  assign a_delayed = temp[DELAY-1];
  
endmodule : delaymodule
