// complex_pkg.sv
package complex_pkg;

  parameter int DATA_WIDTH = 16; // signed fixpoint

  typedef logic signed [DATA_WIDTH-1:0] fixed_point_t;

  typedef struct packed {
    fixed_point_t re; // Real
    fixed_point_t im; // Imaginary
  } complex_t;

endpackage : complex_pkg


