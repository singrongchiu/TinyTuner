// Code your testbench here
// or browse Examples
`default_nettype none
module RangeFinder_test();

  logic [7:0] pcm_out;
  logic       clk, pdm_in, reset, valid_out;
  logic [255:0] accumulatingval;

  pdm_to_pcm mymic(.*);
  
  initial begin
    reset = 1'b1;
    pdm_in = 1'b0;
    clk = 1'b0;
    #1
    clk = 1'b1;
    reset <= 1'b0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    pdm_in <= 0; 
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    
    accumulatingval = 256'd795177076470617;
    for (int i = 0; i < 256; i++) begin
      if (valid_out) begin
        $display("%d <- outputted!", pcm_out);
      end
      pdm_in <= accumulatingval[i];
      @(posedge clk);
    end
    
    $display("FINISHED");
    @(posedge clk);
    if (valid_out) begin
        $display("%d <- outputted!", pcm_out);
      end
    @(posedge clk);
    if (valid_out) begin
        $display("%d <- outputted!", pcm_out);
      end
    $finish();
    
    
  end           

endmodule : RangeFinder_test
