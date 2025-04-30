// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples
`default_nettype none

module RangeFinder_test();

  logic [3-1:0] data_in;
  logic clk;
  logic [3-1:0] data_out;

  bit_reverse mybit_reverse(.*);
  
  initial begin
    clk = 1'b0;
    #1
    clk = 1'b1;
    forever #5 clk = ~clk;
  end
  
  initial begin
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    
    for (int i = 0; i < 8; i++) begin
      data_in = i;
      @(posedge clk)
      
      $display("data_in: %d", data_in);
      $display("data_out: %d", data_out);
      
    end
    
    @(posedge clk);
    @(posedge clk);
    $display("FINISHED");
    $finish();
    
    
  end           

endmodule : RangeFinder_test
