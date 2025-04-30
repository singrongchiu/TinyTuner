module bit_reverse #(
    parameter DATA_WIDTH = 3 // Parameter for data width, change as needed
) (
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out
);
  
     always_comb begin
       case (DATA_WIDTH)
         3: data_out = {data_in[0], data_in[1], data_in[2]};
         4: data_out = {data_in[0], data_in[1], data_in[2], data_in[3]};
         // more if needed
         default: data_out = data_in;
       endcase
     end

endmodule
