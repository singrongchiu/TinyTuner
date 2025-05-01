`default_nettype none

module RangeFinder_test();

  logic a;
  logic clk, a_delayed;

  delaymodule mydelaymodule(.*);
  
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
    
    for (int i = 0; i < 20; i++) begin
      a = i;
      @(posedge clk)
      
      $display("a: %d", a);
      $display("a_delayed: %d", a_delayed);
      
    end
    
    @(posedge clk);
    @(posedge clk);
    $display("FINISHED");
    $finish();
    
    
  end           

endmodule : RangeFinder_test
