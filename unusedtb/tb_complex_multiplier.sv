// Code your testbench here
// or browse Examples
// Code your testbench here
// or browse Examples
`default_nettype none

module RangeFinder_test();

  complex_t a;
  complex_t b;
  logic clk, rst_n, enable;
  complex_t result;
  complex_t result_scaled; 

  complex_multiplier mymult(.*);
  
  initial begin
    rst_n = 1'b1;
    enable = 1'b1; // this enable & reset does nothing
    clk = 1'b0;
    #1
    clk = 1'b1;
    rst_n <= 1'b0;
    forever #5 clk = ~clk;
  end
  
  initial begin
    rst_n = 1'b0;
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
      $display("result: %d + %dj", result.re, result.im);
      $display("result_scaled: %d + %dj", result_scaled.re, result_scaled.im);
      
    end
    
    @(posedge clk);
    @(posedge clk);
    $display("FINISHED");
    $finish();
    
    
  end           

endmodule : RangeFinder_test
