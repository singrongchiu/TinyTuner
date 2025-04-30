module sevenseg
    (input logic [3:0] digit,
    input logic clock, rst_n,
    output logic [6:0] sevseg);

// ABCDEFG
// 0123456

always_ff @(posedge clock or negedge rst_n) begin
  if (!rst_n) begin
  // output 0: ABCDEF
    sevseg = 7'b1111110;
  end
  else if (digit == 0) begin
    // output 0: ABCDEF
    sevseg = 7'b1111110;
  end
  else if (digit == 1) begin
    // output 1: BC
    sevseg = 7'b0110000;
  end
  else if (digit == 2) begin
    // output 2: ABGED
    sevseg = 7'b1101101;
  end
  else if (digit == 3) begin
    // output 3: ABGCD
    sevseg = 7'b1111001;
  end
  else if (digit == 4) begin
    // output 4: FGBC
    sevseg = 7'b0110011;
  end
  else if (digit == 5) begin
    // output 4: ACDFG
    sevseg = 7'b1011011;
  end
  else if (digit == 6) begin
    // output 4: ACDEFG
    sevseg = 7'b1011111;
  end
  else if (digit == 7) begin
    // output 4: ABC
    sevseg = 7'b111000;
  end
end

endmodule : sevenseg
