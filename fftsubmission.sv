`default_nettype none

// Code your design here

/*
// diamond 3.7 accepts this PLL
// diamond 3.8-3.9 is untested
// diamond 3.10 or higher is likely to abort with error about unable to use feedback signal
// cause of this could be from wrong CPHASE/FPHASE parameters
module slowerclk
(
    input clkin, // 25 MHz, 0 deg
    output clkout0, // 5 MHz, 0 deg
    output locked
);
(* FREQUENCY_PIN_CLKI="25" *)
(* FREQUENCY_PIN_CLKOP="5" *)
(* ICP_CURRENT="12" *) (* LPF_RESISTOR="8" *) (* MFG_ENABLE_FILTEROPAMP="1" *) (* MFG_GMCREF_SEL="2" *)
EHXPLLL #(
        .PLLRST_ENA("DISABLED"),
        .INTFB_WAKE("DISABLED"),
        .STDBY_ENABLE("DISABLED"),
        .DPHASE_SOURCE("DISABLED"),
        .OUTDIVIDER_MUXA("DIVA"),
        .OUTDIVIDER_MUXB("DIVB"),
        .OUTDIVIDER_MUXC("DIVC"),
        .OUTDIVIDER_MUXD("DIVD"),
        .CLKI_DIV(5),
        .CLKOP_ENABLE("ENABLED"),
        .CLKOP_DIV(120),
        .CLKOP_CPHASE(60),
        .CLKOP_FPHASE(0),
        .FEEDBK_PATH("CLKOP"),
        .CLKFB_DIV(1)
    ) pll_i (
        .RST(1'b0),
        .STDBY(1'b0),
        .CLKI(clkin),
        .CLKOP(clkout0),
        .CLKFB(clkout0),
        .CLKINTFB(),
        .PHASESEL0(1'b0),
        .PHASESEL1(1'b0),
        .PHASEDIR(1'b1),
        .PHASESTEP(1'b1),
        .PHASELOADREG(1'b1),
        .PLLWAKESYNC(1'b0),
        .ENCLKOP(1'b0),
        .LOCK(locked)
	);
endmodule : slowerclk
*/
module slowerclk
(
    input clkin, // 30 MHz, 0 deg
    output clkout0, // 5 MHz, 0 deg
    output locked
);
logic [7:0] counter;
always_ff @(posedge clkin) begin
  if (counter == 3) begin
    clkout0 <= 0;
    counter <= counter + 1;
  end
  else if (counter == 6) begin
    clkout0 <= 1;
    counter <= 0;
  end
  else begin
    counter <= counter + 1;
  end
end
assign locked = 1;

endmodule : slowerclk

module pdm_to_pcm#(
  parameter DATA_WIDTH = 6,
)(
  input clk,          // System clock - we are getting 5 MHz - will need 2.5 MHz
  input pdm_in,       // PDM microphone output
  input reset,
  output logic [DATA_WIDTH-1:0] pcm_out, // 8-bit PCM output
  output logic valid_out,
  output logic mic_clk,
  output logic clk_slower_fft
);

  localparam int SAMPLING_RATE = 500;
//  localparam int NUM_BITS = 8; // max = 256
  
  // logic [SAMPLING_RATE-1:0] pdm_buffer;
  logic [9:0] pdm_buffer_index;
  logic [DATA_WIDTH-1:0] accumulator; 
  
always_ff @(posedge clk or negedge reset) begin
	if (!reset) begin
      pdm_buffer_index = 0;
      accumulator = 0;
      // $display("RESET!!!!!!!!!!!!!!!!");
      // $display("index1: %d", pdm_buffer_index);
    end
    else if (pdm_buffer_index == 500) begin
      pcm_out = (accumulator + pdm_in) >> 3;
      accumulator = 0;
      valid_out = 1;
      pdm_buffer_index = 0;
      clk_slower_fft = 1;
      // $display("AM AT MAX INDEX!!!!!!!!!!!!!!!!!!");
    end
    else begin
      if (pdm_buffer_index == 250) begin
        clk_slower_fft = 0;
        accumulator = accumulator + pdm_in;
        mic_clk = ~mic_clk;
      // $display("index2: %d", pdm_buffer_index);
        pdm_buffer_index = pdm_buffer_index + 1;
      end
      else begin
        // valid_out = 0;
        accumulator = accumulator + pdm_in;
        mic_clk = ~mic_clk;
        // $display("index2: %d", pdm_buffer_index);
        pdm_buffer_index = pdm_buffer_index + 1;
      end
    end
  end
  
endmodule : pdm_to_pcm

module Radix2FFTPipeline8N #(
    parameter DATA_WIDTH = 8,
    parameter TWIDDLE_WIDTH = 8,
    parameter N = 8,
    localparam STAGES = $clog2(N)
)(
    input  logic clk,
    input  logic reset,
    input  logic [DATA_WIDTH-1:0] in_real,
    input  logic [DATA_WIDTH-1:0] in_imag,
    input  logic in_valid,
//     output logic [N*DATA_WIDTH-1:0] out_real,
//     output logic [N*DATA_WIDTH-1:0] out_imag,
    output logic out_valid,
    output logic [STAGES-1:0] highest_bin,
    output logic [DATA_WIDTH<<1:0] out_max_magnitude
  /*
    output logic [DATA_WIDTH-1:0] out_real,
    output logic [DATA_WIDTH-1:0] out_imag,
    output logic out_valid */
);

    // Pipeline stage buffers
//     logic signed [DATA_WIDTH-1:0] stage_real [0:STAGES][N-1:0];
  logic signed [DATA_WIDTH-1:0] stage_real0 [N-1:0];
  logic signed [DATA_WIDTH-1:0] stage_real1 [N-1:0];
  logic signed [DATA_WIDTH-1:0] stage_real2 [N-1:0];
  logic signed [DATA_WIDTH-1:0] stage_real3 [N-1:0];
//     logic signed [DATA_WIDTH-1:0] stage_imag [0:STAGES][N-1:0];
  logic signed [DATA_WIDTH-1:0] stage_imag0 [N-1:0];
  logic signed [DATA_WIDTH-1:0] stage_imag1 [N-1:0];
  logic signed [DATA_WIDTH-1:0] stage_imag2 [N-1:0];
  logic signed [DATA_WIDTH-1:0] stage_imag3 [N-1:0];
  
//     logic signed [DATA_WIDTH-1:0] mic_input_real[2][N-1:0];
//     logic signed [DATA_WIDTH-1:0] mic_input_imag[2][N-1:0];
  logic signed [DATA_WIDTH-1:0] mic_input_real0[N-1:0];
  logic signed [DATA_WIDTH-1:0] mic_input_real1[N-1:0];
  logic signed [DATA_WIDTH-1:0] mic_input_imag0[N-1:0];
  logic signed [DATA_WIDTH-1:0] mic_input_imag1[N-1:0];
  logic stage_valid0;
  logic stage_valid1;
  logic stage_valid2;
  logic stage_valid3;

    // Twiddle ROM outputs
    logic signed [TWIDDLE_WIDTH-1:0] tw_r, tw_i;
    logic [STAGES:0] mic_input_index;
    logic mic_inputting_array;
  // Input stage
	always_ff @(posedge clk or negedge reset) begin
		if (!reset) begin
//           stage_valid[0] <= 0;
          mic_input_index <= 0;
          mic_inputting_array <= 0;
        end else if (mic_input_index == N) begin
          stage_valid0 <= 1;
//           $display("LC: STAGE SHOULD BE VALID!");
          mic_input_index <= 0;
          mic_inputting_array <= ~mic_inputting_array;
          if (mic_inputting_array) begin
            for (int i = 0; i < N; i++) begin
              stage_real0[i] <= mic_input_real1[i];
              stage_imag0[i] <= mic_input_imag1[i];
            end
          end
          else begin
            for (int i = 0; i < N; i++) begin
              stage_real0[i] <= mic_input_real0[i];
              stage_imag0[i] <= mic_input_imag0[i];
            end
          end
          /*
          $display("mic input 0");
          $display(mic_input_real0);
           $display("mic input 1");
          $display(mic_input_real1);
          */
          // $display(stage_real);
        end else if (in_valid) begin
          if (mic_inputting_array) begin
            mic_input_real1[mic_input_index] <= in_real;
            mic_input_imag1[mic_input_index] <= in_imag;
          end else begin
            mic_input_real0[mic_input_index] <= in_real;
            mic_input_imag0[mic_input_index] <= in_imag;
          end
          mic_input_index <= mic_input_index + 1;
//           $display("inputted one!");
        end
    end
  
//     assign stage_real[0] = (mic_inputting_array)? mic_input_real[0] : mic_input_real[1];
//     assign stage_imag[0] = (mic_inputting_array)? mic_input_imag[0] : mic_input_imag[1];

    // FFT stages
//     int idx_a[0:STAGES];
//     int idx_b[0:STAGES];
  logic [STAGES:0] idx_a0;
  logic [STAGES:0] idx_a1;
  logic [STAGES:0] idx_a2;
  logic [STAGES:0] idx_b0;
  logic [STAGES:0] idx_b1;
  logic [STAGES:0] idx_b2;
//     logic signed [DATA_WIDTH-1:0] a_real[0:STAGES];
//     logic signed [DATA_WIDTH-1:0] a_imag[0:STAGES];
//     logic signed [DATA_WIDTH-1:0] b_real[0:STAGES];
//     logic signed [DATA_WIDTH-1:0] b_imag[0:STAGES];
  logic signed [DATA_WIDTH-1:0] a_real0;
  logic signed [DATA_WIDTH-1:0] a_real1;
  logic signed [DATA_WIDTH-1:0] a_real2;
  logic signed [DATA_WIDTH-1:0] a_imag0;
  logic signed [DATA_WIDTH-1:0] a_imag1;
  logic signed [DATA_WIDTH-1:0] a_imag2;
  logic signed [DATA_WIDTH-1:0] b_real0;
  logic signed [DATA_WIDTH-1:0] b_real1;
  logic signed [DATA_WIDTH-1:0] b_real2;
  logic signed [DATA_WIDTH-1:0] b_imag0;
  logic signed [DATA_WIDTH-1:0] b_imag1;
  logic signed [DATA_WIDTH-1:0] b_imag2;
//     logic signed [DATA_WIDTH-1:0] abdiff_real[0:STAGES];
//     logic signed [DATA_WIDTH-1:0] abdiff_imag[0:STAGES];
  logic signed [DATA_WIDTH:0] abdiff_real0;
  logic signed [DATA_WIDTH:0] abdiff_real1;
  logic signed [DATA_WIDTH:0] abdiff_real2;
  logic signed [DATA_WIDTH:0] abdiff_imag0;
  logic signed [DATA_WIDTH:0] abdiff_imag1;
  logic signed [DATA_WIDTH:0] abdiff_imag2;
    logic signed [DATA_WIDTH+TWIDDLE_WIDTH:0] prod_real[STAGES-1:0];
    logic signed [DATA_WIDTH+TWIDDLE_WIDTH:0] prod_imag[STAGES-1:0];
    logic signed [TWIDDLE_WIDTH-1:0] twiddle_real[N/2];
    logic signed [TWIDDLE_WIDTH-1:0] twiddle_imag[N/2];
    logic [STAGES-1:0] twiddle_index[0:STAGES];
  
  assign twiddle_real[0] = 8'sd64; assign twiddle_imag[0] = 8'sd0;
  assign twiddle_real[1] = 8'sd45; assign twiddle_imag[1] = -8'sd45;
  assign twiddle_real[2] = 8'sd0; assign twiddle_imag[2] = -8'sd64;
  assign twiddle_real[3] = -8'sd45; assign twiddle_imag[3] = -8'sd45;
  
//     generate
//       for (genvar s = 0; s < STAGES; s++) begin : fft_stage
    
  /*
  function automatic signed [DATA_WIDTH+TWIDDLE_WIDTH-1:0] simple_mult; 
    input signed [DATA_WIDTH-1:0] a;
    input signed [TWIDDLE_WIDTH-1:0] b;
    begin
        simple_mult = 
            (b[0] ? a       : 0) +
            (b[1] ? a << 1  : 0) +
            (b[2] ? a << 2  : 0) +
            (b[3] ? a << 3  : 0) +
            (b[4] ? a << 4  : 0) +
            (b[5] ? a << 5  : 0) +
            (b[6] ? a << 6  : 0) +
            (b[7] ? a << 7  : 0);
    end
  endfunction
  */
  function automatic signed [15:0] simple_mult(
    input signed [7:0] a,
    input signed [7:0] b
  );
      logic signed [15:0] pp0, pp1, pp2, pp3, pp4, pp5, pp6, pp7;
  begin
      // parallel partial products
    pp0 = b[0] ? { {8{a[7]}}, a }         : 16'b0;  // sign-extended a << 0
      pp1 = b[1] ? { {7{a[7]}}, a, 1'b0 }   : 16'b0;  // a << 1
      pp2 = b[2] ? { {6{a[7]}}, a, 2'b00 }  : 16'b0;  // a << 2
      pp3 = b[3] ? { {5{a[7]}}, a, 3'b000 } : 16'b0;  // a << 3
      pp4 = b[4] ? { {4{a[7]}}, a, 4'b0000 } : 16'b0; // a << 4
      pp5 = b[5] ? { {3{a[7]}}, a, 5'b00000 } : 16'b0;
      pp6 = b[6] ? { {2{a[7]}}, a, 6'b000000 } : 16'b0;
      pp7 = b[7] ? { {1{a[7]}}, a, 7'b0000000 } : 16'b0; // a << 7

      simple_mult = pp0 + pp1 + pp2 + pp3 + pp4 + pp5 + pp6 + pp7;
  end
  endfunction

  ///// STAGE 1
        // note, had to watch out for bit reversal
	always_ff @(posedge clk or negedge reset) begin
	  if (!reset) begin
            stage_valid1 <= 0;
          end
          else if (stage_valid0) begin
            stage_valid1 <= 1;
            for (int group = 0; group < (1); group++) begin : fft_group
            for (int pair = 0; pair < 4; pair++) begin : fft_pair

                // Calculate indices
              idx_a0 = (group << 3) + pair;
              idx_b0 = idx_a0 + (N >> (0+1));
              twiddle_index[0] = pair;
              /*
              $display("pair %d", pair);
              $display("idx_a0 %d", idx_a0);
              $display("idx_b0 %d", idx_b0);
              */

                // Read inputs
              a_real0 = stage_real0[idx_a0];
              a_imag0 = stage_imag0[idx_a0];
              b_real0 = stage_real0[idx_b0];
              b_imag0 = stage_imag0[idx_b0];
              abdiff_real0 = stage_real0[idx_a0] - stage_real0[idx_b0];
              abdiff_imag0 = stage_imag0[idx_a0] - stage_imag0[idx_b0];
              
              /*
              $display("a_real0 %d", a_real0);
              $display("a_imag0 %d", a_imag0);
              $display("b_real0 %d", b_real0);
              $display("b_imag0 %d", b_imag0);
              $display("abdiff_real0 %d", abdiff_real0);
              $display("abdiff_imag0 %d", abdiff_imag0);
              */
               
              prod_real[0] = (abdiff_real0 * twiddle_real[twiddle_index[0]] - abdiff_imag0 * twiddle_imag[twiddle_index[0]]) >>> (TWIDDLE_WIDTH - 2);
              prod_imag[0] = (abdiff_real0 * twiddle_imag[twiddle_index[0]] + abdiff_imag0 * twiddle_real[twiddle_index[0]]) >>> (TWIDDLE_WIDTH - 2);

                // Butterfly
              stage_real1[idx_a0] <= (a_real0 + b_real0) >>> 1;
              stage_imag1[idx_a0] <= (a_imag0 + b_imag0) >>> 1;
              stage_real1[idx_b0] <= (prod_real[0]) >>> 1;
              stage_imag1[idx_b0] <= (prod_imag[0]) >>> 1;
            end
          end
          end
          else begin
            stage_valid1 <= 0;
          end
        end
//       end
//     endgenerate

  logic signed [DATA_WIDTH*2:0] temp_real1;
  logic signed [DATA_WIDTH*2:0] temp_imag1;
  
  ////// STAGE 2
	always_ff @(posedge clk or negedge reset) begin
	  if (!reset) begin
            stage_valid2 <= 0;
          end
        else if (stage_valid1) begin
          /*
          $display("stage %d", 1);
          $display(stage_real1);
          $display(stage_imag1); 
          */
          stage_valid2 <= 1;
          for (int group = 0; group < 2; group++) begin : fft_group
            for (int pair = 0; pair < 2; pair++) begin : fft_pair

                // Calculate indices
            idx_a1 = (group << 2) + pair;
            idx_b1 = idx_a1 + (N >> (1+1));
              twiddle_index[1] = pair << 1;
    //          $display("idx_a1: %d", idx_a1);
      //        $display("idx_b1: %d", idx_b1);

                // Read inputs
            a_real1 = stage_real1[idx_a1];
            a_imag1 = stage_imag1[idx_a1];
            b_real1 = stage_real1[idx_b1];
            b_imag1 = stage_imag1[idx_b1];
            abdiff_real1 = stage_real1[idx_a1] - stage_real1[idx_b1];
            abdiff_imag1 = stage_imag1[idx_a1] - stage_imag1[idx_b1];
              
              
              
            temp_real1 = simple_mult(abdiff_real1, twiddle_real[twiddle_index[1]]) - simple_mult(abdiff_imag1, twiddle_imag[twiddle_index[1]]);
        
              temp_imag1 = simple_mult(twiddle_imag[twiddle_index[1]], abdiff_real1) + simple_mult(twiddle_real[twiddle_index[1]], abdiff_imag1);
              /*
              $display("twiddle");
              $display(twiddle_real[twiddle_index[1]]);
              $display(twiddle_imag[twiddle_index[1]]);
              $display("temp!");
              $display(temp_real1);
              $display(temp_imag1);
              */
        // Apply scaling
              prod_real[1] = temp_real1 >>> (TWIDDLE_WIDTH - 2);
              prod_imag[1] = temp_imag1 >>> (TWIDDLE_WIDTH - 2);  
              /*
              $display("prod!");
              $display(prod_real[1]);
              $display(prod_imag[1]); */
              
              
  //        prod_real[1] = (abdiff_real1 * twiddle_real[twiddle_index[1]] - abdiff_imag1 * twiddle_imag[twiddle_index[1]]) >>> (TWIDDLE_WIDTH - 2);
  //        prod_imag[1] = (abdiff_real1 * twiddle_imag[twiddle_index[1]] + abdiff_imag1 * twiddle_real[twiddle_index[1]]) >>> (TWIDDLE_WIDTH - 2);

                // Butterfly
            stage_real2[idx_a1] <= (a_real1 + b_real1) >>> 1;
            stage_imag2[idx_a1] <= (a_imag1 + b_imag1) >>> 1;
            stage_real2[idx_b1] <= (prod_real[1]) >>> 1;
            stage_imag2[idx_b1] <= (prod_imag[1]) >>> 1;
            end
          end
          end
          else begin
            stage_valid2 <= 0;
          end
       
        end
  
  ////// STAGE 3
    always_ff @(posedge clk or negedge reset) begin
	if (!reset) begin
          stage_valid3 <= 0;
        end
    else if (stage_valid2) begin
      /*
      $display("stage %d", 2);
      $display(stage_real2);
      $display(stage_imag2); 
      */
      stage_valid3 <= 1;
      for (int group = 0; group < (4); group++) begin : fft_group
      for (int pair = 0; pair < N / (8); pair++) begin : fft_pair

                // Calculate indices
        idx_a2 = (group << 1) + pair;
        idx_b2 = idx_a2 + (N >> (3));
        twiddle_index[2] = pair << 2;

                // Read inputs
        a_real2 = stage_real2[idx_a2];
        a_imag2 = stage_imag2[idx_a2];
        b_real2 = stage_real2[idx_b2];
        b_imag2 = stage_imag2[idx_b2];
        abdiff_real2 = stage_real2[idx_a2] - stage_real2[idx_b2];
        abdiff_imag2 = stage_imag2[idx_a2] - stage_imag2[idx_b2];

        prod_real[2] = (abdiff_real2 * twiddle_real[twiddle_index[2]] - abdiff_imag2 * twiddle_imag[twiddle_index[2]]) >>> (TWIDDLE_WIDTH - 2);
        prod_imag[2] = (abdiff_real2 * twiddle_imag[twiddle_index[2]] + abdiff_imag2 * twiddle_real[twiddle_index[2]]) >>> (TWIDDLE_WIDTH - 2);

                // Butterfly
        stage_real3[idx_a2] <= (a_real2 + b_real2) >>> 1;
        stage_imag3[idx_a2] <= (a_imag2 + b_imag2) >>> 1;
        stage_real3[idx_b2] <= (prod_real[2]) >>> 1;
        stage_imag3[idx_b2] <= (prod_imag[2]) >>> 1;
            end
          end
          end
          else begin
            stage_valid3 <= 0;
          end
     end

  logic [STAGES-1:0] max_bin;
  logic signed [DATA_WIDTH<<1:0] max_magnitude;
  logic signed [DATA_WIDTH<<1:0] current_magnitude;
   assign out_max_magnitude = max_magnitude;
   
    // Output
	always_ff @(posedge clk or negedge reset) begin
		if (!reset) begin
          out_valid = 1'b0;
//           for (int i = 0; i < N; i++) begin
//             out_real[i]  <= '0;
//             out_imag[i]  <= '0;
//           end
          max_bin = 0;
          max_magnitude = 0;
          current_magnitude = 0;
        end else if (stage_valid3) begin
//           $display("fft output (not bitreversed)");
//           $display(stage_real[STAGES]);
//           $display(stage_imag[STAGES]);
           max_magnitude = 0;
           for (int i = 0; i < N; i++) begin
         // for (int i = N-1; i >= 0; i--) begin
         // NOTE: Not enough space on FPGA for real magnitude, so just going to do pseudo magnitude
         //   current_magnitude = ((stage_real3[i])*(stage_real3[i])) + ((stage_imag3[i])*(stage_imag3[i]));
              if (stage_real3[i] < 0) begin
                current_magnitude = (~stage_real3[i]) + 1;
              end
              else begin
                current_magnitude = stage_real3[i];
              end
              
              if (stage_imag3[i] < 0) begin
                current_magnitude = current_magnitude + ((~stage_imag3[i]) + 1);
              end
              else begin
                current_magnitude = current_magnitude + stage_imag3[i];
              end
//             $display("i: %d", i);
//             $display(stage_real[STAGES][i]);
//             $display(stage_real[STAGES][i] >>> (DATA_WIDTH/4));
//             $display(stage_imag[STAGES][i]);
//             $display(stage_imag[STAGES][i] >>> (DATA_WIDTH/4));
// //             $display("stage_real squared");
// //             $display(stage_real[STAGES][i]**2);
//             $display("current_magnitude");
//             $display(current_magnitude);
//             $display("highest_bin");
//             $display(max_bin);
            if (current_magnitude >= max_magnitude) begin
              max_bin = i;
              max_magnitude = current_magnitude;
            end
          end
          highest_bin = max_bin;
          out_valid = 1'b1;
          // max_magnitude = 0;
          
          /*
          $display("highest_bin: %d", max_bin);
          $display("highest_magnitude: %d", max_magnitude);
          $display("stage 3! fft layer");
          $display(stage_real3);
          $display(stage_imag3);
          */
          
        end else begin
//           $display(stage_valid);
          out_valid = 1'b0;
        end
    end

endmodule : Radix2FFTPipeline8N 

module bit_reverse #(
    parameter BIN_WIDTH = 3 // Parameter for data width, change as needed
) (
    input  logic [BIN_WIDTH-1:0] data_in,
    output logic [BIN_WIDTH-1:0] data_out
);
  
     always_comb begin
       case (BIN_WIDTH)
         3: data_out = {data_in[0], data_in[1], data_in[2]};
         // 4: data_out = {data_in[0], data_in[1], data_in[2], data_in[3]};
         // more if needed
         // default: data_out = data_in;
       endcase
     end

endmodule : bit_reverse

module sevenseg
    (input logic [3:0] digit,
    input logic clock, reset,
    output logic [6:0] sevseg);

// ABCDEFG
// 0123456

always_ff @(posedge clock or negedge reset) begin
  if (!reset) begin
  // output 0: ABCDEF
    sevseg = 7'b1111111;
  end
  else if (digit == 0) begin
    // output 0: ABCDEF
    sevseg = 7'b1111110;
  end
  else if (digit == 3'b010) begin
    // output 1: BC
    sevseg = 7'b0110000;
  end
  else if (digit == 3'b010) begin
    // output 2: ABGED
    sevseg = 7'b1101101;
  end
  else if (digit == 3'b011) begin
    // output 3: ABGCD
    sevseg = 7'b1111001;
  end
  else if (digit == 3'b100) begin
    // output 4: FGBC
    sevseg = 7'b0110011;
  end
  else if (digit == 3'b101) begin
    // output 4: ACDFG
    sevseg = 7'b1011011;
  end
  else if (digit == 3'b110) begin
    // output 4: ACDEFG
    sevseg = 7'b1011111;
  end
  else if (digit == 3'b111) begin
    // output 4: ABC
    sevseg = 7'b1110000;
  end
end

endmodule : sevenseg

module my_chip (
    input logic [11:0] io_in, // Inputs to your chip
    output logic [11:0] io_out, // Outputs from your chip
    input logic clock,
    input logic reset // Important: Reset is ACTIVE-HIGH
);
    
   //  logic pdm_in;
   //  assign pdm_in = io_in[0];
    // Basic counter design as an example
    // TODO: remove the counter design and use this module to insert your own design
    // DO NOT change the I/O header of this design

    logic [6:0] sevseg;
    assign io_out[6:0] = sevseg;

    parameter DATA_WIDTH = 8;
/*
  input clkin, // 25 MHz, 0 deg
  output clkout0, // 5 MHz, 0 deg
  output locked
*/
   logic pllclkout;
   slowerclk myslowerclk(.clkin(clock), .clkout0(pllclkout), .locked());

  logic [DATA_WIDTH-1:0] pcm_out;
  logic valid_out;
  // logic mic_clk;
  // assign io_out[7] = mic_clk;
  logic clk_slower;
/*
  input clk,          // System clock - we are getting 5 MHz - will need 2.5 MHz
  input pdm_in,       // PDM microphone output
  input reset,
  output logic [7:0] pcm_out, // 8-bit PCM output
  output logic valid_out,
  output logic mic_clk,
  output logic clk_slower_fft
*/
  pdm_to_pcm my_pdm_to_cdm(.clk(pllclkout), .pdm_in(io_in[0]), .reset(reset), .pcm_out(pcm_out), .valid_out(valid_out), .mic_clk(io_out[7]), .clk_slower_fft(clk_slower));

  logic out_valid;
  logic [2:0] highest_bin;
  logic [DATA_WIDTH<<1:0] max_magnitude;
/*
  input  logic clk,
  input  logic reset,
  input  logic [DATA_WIDTH-1:0] in_real,
  input  logic [DATA_WIDTH-1:0] in_imag,
  input  logic in_valid,
  output logic out_valid,
  output logic [STAGES-1:0] highest_bin
*/
  Radix2FFTPipeline8N myRadix2FFTPipeline8N(.clk(clk_slower), .reset(reset), .in_real(pcm_out), .in_imag(0), .in_valid(valid_out), .out_valid(out_valid), .highest_bin(highest_bin), .out_max_magnitude(max_magnitude));

  logic [2:0] bitreversed_bin;
/*
  input  logic [DATA_WIDTH-1:0] data_in,
  output logic [DATA_WIDTH-1:0] data_out
*/
  bit_reverse mybit_reverse(.data_in(highest_bin), .data_out(bitreversed_bin));

/*
  input logic [3:0] digit,
  input logic clock, reset,
  output logic [6:0] sevseg
*/
  sevenseg mysevenseg(.digit(bitreversed_bin), .clock(clk_slower), .reset(reset), .sevseg(sevseg)); 

endmodule
