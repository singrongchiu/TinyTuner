// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples
`default_nettype none

module RangeFinder_test();

  complex_t a;
  complex_t b;
  complex_t w;
  logic clk, reset, enable;
  complex_t x_out, y_out;

  butterfly mybutterfly(.*);
  
  initial begin
    reset = 1'b1;
    enable = 1'b1;
    clk = 1'b0;
    #1
    clk = 1'b1;
    reset <= 1'b0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    reset = 1'b0;
    @(posedge clk);
    @(posedge clk);
    @(posedge clk);
    
    for (int i = 0; i < 10; i++) begin
      a.re = i;
      a.im = i + 1;
      b.re = i + 2;
      b.im = i + 3; 
      @(posedge clk)
      
      $display("a: %d + %dj", i, i+1);
      $display("b: %d + %dj", i+2, i+3);
      
      $display("X (a + b): %d + %dj", x_out.re, x_out.im);
      $display("Y (a - b): %d - %dj", y_out.re, y_out.im);
      
    end
    
    @(posedge clk);
    @(posedge clk);
    $display("FINISHED");
    $finish();
    
    
  end           

endmodule : RangeFinder_test
