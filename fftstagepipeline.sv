module Radix2FFTPipeline #(
    parameter DATA_WIDTH = 8,
    parameter TWIDDLE_WIDTH = 8,
    parameter N = 64,
    localparam STAGES = $clog2(N)
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [DATA_WIDTH-1:0] in_real,
    input  logic [DATA_WIDTH-1:0] in_imag,
    input  logic in_valid,
//     output logic [N*DATA_WIDTH-1:0] out_real,
//     output logic [N*DATA_WIDTH-1:0] out_imag,
    output logic out_valid,
    output logic [STAGES-1:0] highest_bin
  /*
    output logic [DATA_WIDTH-1:0] out_real,
    output logic [DATA_WIDTH-1:0] out_imag,
    output logic out_valid */
);

    // Pipeline stage buffers
    logic signed [DATA_WIDTH-1:0] stage_real [0:STAGES][N-1:0];
    logic signed [DATA_WIDTH-1:0] stage_imag [0:STAGES][N-1:0];
  
    logic signed [DATA_WIDTH-1:0] mic_input_real[2][N-1:0];
    logic signed [DATA_WIDTH-1:0] mic_input_imag[2][N-1:0];
    logic stage_valid [0:STAGES];

    // Twiddle ROM outputs
    logic signed [TWIDDLE_WIDTH-1:0] tw_r, tw_i;
    logic [STAGES:0] mic_input_index;
    logic mic_inputting_array;
  // Input stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          stage_valid[0] <= 0;
          mic_input_index <= 0;
          mic_inputting_array <= 0;
        end else if (mic_input_index == N) begin
          stage_valid[0] <= 1;
          $display("LC: STAGE SHOULD BE VALID!");
          mic_input_index <= 0;
          mic_inputting_array <= ~mic_inputting_array;
          stage_real[0] <= (mic_inputting_array)? mic_input_real[1] : mic_input_real[0];
          stage_imag[0] <= (mic_inputting_array)? mic_input_imag[1] : mic_input_imag[0];
          $display("mic input 0");
          $display(mic_input_real[0]);
          $display("mic input 1");
          $display(mic_input_real[1]);
          // $display(stage_real);
        end else if (in_valid) begin
          mic_input_real[mic_inputting_array][mic_input_index] <= in_real;
          mic_input_imag[mic_inputting_array][mic_input_index] <= in_imag;
          mic_input_index <= mic_input_index + 1;
          $display("inputted one!");
        end
    end
  
//     assign stage_real[0] = (mic_inputting_array)? mic_input_real[0] : mic_input_real[1];
//     assign stage_imag[0] = (mic_inputting_array)? mic_input_imag[0] : mic_input_imag[1];

    /*
    // Instantiate one TwiddleROM (shared across butterflies, accessed combinationally)
    logic [$clog2(N/2)-1:0] twiddle_index[0:STAGES];
    twiddlevalues #(
        .TWIDDLE_WIDTH(TWIDDLE_WIDTH),
        .N(N)
    ) twiddle_vals (
        .clk(clk),
        .index(twiddle_index),
        .twiddle_real(tw_r),
        .twiddle_imag(tw_i)
    );
    */

    // FFT stages
    int idx_a[0:STAGES];
    int idx_b[0:STAGES];
    logic signed [DATA_WIDTH-1:0] a_real[0:STAGES];
    logic signed [DATA_WIDTH-1:0] a_imag[0:STAGES];
    logic signed [DATA_WIDTH-1:0] b_real[0:STAGES];
    logic signed [DATA_WIDTH-1:0] b_imag[0:STAGES];
    logic signed [DATA_WIDTH-1:0] abdiff_real[0:STAGES];
    logic signed [DATA_WIDTH-1:0] abdiff_imag[0:STAGES];
    logic signed [DATA_WIDTH+TWIDDLE_WIDTH:0] prod_real[0:STAGES];
    logic signed [DATA_WIDTH+TWIDDLE_WIDTH:0] prod_imag[0:STAGES];
    logic signed [TWIDDLE_WIDTH-1:0] twiddle_real[N/2];
    logic signed [TWIDDLE_WIDTH-1:0] twiddle_imag[N/2];
    logic [STAGES-1:0] twiddle_index[0:STAGES];
  
    always_ff @(negedge rst_n) begin
      twiddle_real[0] = 8'sd64; twiddle_imag[0] = 8'sd0;
      twiddle_real[1] = 8'sd64; twiddle_imag[1] = -8'sd6;
      twiddle_real[2] = 8'sd63; twiddle_imag[2] = -8'sd12;
      twiddle_real[3] = 8'sd61; twiddle_imag[3] = -8'sd19;
      twiddle_real[4] = 8'sd59; twiddle_imag[4] = -8'sd24;
      twiddle_real[5] = 8'sd56; twiddle_imag[5] = -8'sd30;
      twiddle_real[6] = 8'sd53; twiddle_imag[6] = -8'sd36;
      twiddle_real[7] = 8'sd49; twiddle_imag[7] = -8'sd41;
      twiddle_real[8] = 8'sd45; twiddle_imag[8] = -8'sd45;
      twiddle_real[9] = 8'sd41; twiddle_imag[9] = -8'sd49;
      twiddle_real[10] = 8'sd36; twiddle_imag[10] = -8'sd53;
      twiddle_real[11] = 8'sd30; twiddle_imag[11] = -8'sd56;
      twiddle_real[12] = 8'sd24; twiddle_imag[12] = -8'sd59;
      twiddle_real[13] = 8'sd19; twiddle_imag[13] = -8'sd61;
      twiddle_real[14] = 8'sd12; twiddle_imag[14] = -8'sd63;
      twiddle_real[15] = 8'sd6; twiddle_imag[15] = -8'sd64;
      twiddle_real[16] = 8'sd0; twiddle_imag[16] = -8'sd64;
      twiddle_real[17] = -8'sd6; twiddle_imag[17] = -8'sd64;
      twiddle_real[18] = -8'sd12; twiddle_imag[18] = -8'sd63;
      twiddle_real[19] = -8'sd19; twiddle_imag[19] = -8'sd61;
      twiddle_real[20] = -8'sd24; twiddle_imag[20] = -8'sd59;
      twiddle_real[21] = -8'sd30; twiddle_imag[21] = -8'sd56;
      twiddle_real[22] = -8'sd36; twiddle_imag[22] = -8'sd53;
      twiddle_real[23] = -8'sd41; twiddle_imag[23] = -8'sd49;
      twiddle_real[24] = -8'sd45; twiddle_imag[24] = -8'sd45;
      twiddle_real[25] = -8'sd49; twiddle_imag[25] = -8'sd41;
      twiddle_real[26] = -8'sd53; twiddle_imag[26] = -8'sd36;
      twiddle_real[27] = -8'sd56; twiddle_imag[27] = -8'sd30;
      twiddle_real[28] = -8'sd59; twiddle_imag[28] = -8'sd24;
      twiddle_real[29] = -8'sd61; twiddle_imag[29] = -8'sd19;
      twiddle_real[30] = -8'sd63; twiddle_imag[30] = -8'sd12;
      twiddle_real[31] = -8'sd64; twiddle_imag[31] = -8'sd6;
    end
  
    generate
      for (genvar s = 0; s < STAGES; s++) begin : fft_stage
        always_ff @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            stage_valid[s+1] <= 0;
          end else if (stage_valid[s]) begin
//             $display("stage 0 fft layer");
//             $display(stage_real[0]);
//             $display("stage 1 fft layer");
//             $display(stage_real[1]);
            stage_valid[s+1] <= 1;
//             $display("stage valid for %d", s);
//             $display(stage_real[0]);
//             $display("^ Stage Real!");
          end else begin
//             $display("stage NOT valid for %d", s);
            stage_valid[s+1] <= 0;
          end
        end
        
        // note, had to watch out for bit reversal
        always_ff @(posedge clk or negedge rst_n) begin
          if (stage_valid[s]) begin
            $display("stage %d fft layer", s);
            $display(stage_real[s]);
            $display(stage_imag[s]);
          for (int group = 0; group < (2**s); group++) begin : fft_group
            for (int pair = 0; pair < N / (2**(s+1)); pair++) begin : fft_pair

                // Calculate indices
                idx_a[s] = group * (N >> s) + pair;
                idx_b[s] = idx_a[s] + (N >> (s+1));
                twiddle_index[s] = pair * (2**s);
//                 $display("s %d, idx_a %d", s, idx_a[s]); 
//                 $display("s %d, idx_b %d", s, idx_b[s]); 
//                 $display("s %d twiddle_index %d", s, twiddle_index[s]);
//               $display(stage_real[0]);

                // Read inputs
                a_real[s] = stage_real[s][idx_a[s]];
                a_imag[s] = stage_imag[s][idx_a[s]];
                b_real[s] = stage_real[s][idx_b[s]];
                b_imag[s] = stage_imag[s][idx_b[s]];
                abdiff_real[s] = stage_real[s][idx_a[s]] - stage_real[s][idx_b[s]];
                abdiff_imag[s] = stage_imag[s][idx_a[s]] - stage_imag[s][idx_b[s]];
//                 a_real[s] = stage_real[s][group * (2**(s+1)) + pair];
//                 a_imag[s] = stage_imag[s][group * (2**(s+1)) + pair];
//                 b_real[s] = stage_real[s][group * (2**(s+1)) + pair + (2**s)];
//                 b_imag[s] = stage_imag[s][group * (2**(s+1)) + pair + (2**s)];

                // Twiddle multiply
//                 prod_real[s] = (b_real[s] * twiddle_real[twiddle_index[s]] - b_imag[s] * twiddle_imag[twiddle_index[s]]) >>> (TWIDDLE_WIDTH - 1);
//                 prod_imag[s] = (b_real[s] * twiddle_imag[twiddle_index[s]] + b_imag[s] * twiddle_real[twiddle_index[s]]) >>> (TWIDDLE_WIDTH - 1);
//               prod_real[s] = (b_real[s] * twiddle_real[twiddle_index[s]] - b_imag[s] * twiddle_imag[twiddle_index[s]]);
//               prod_imag[s] = (b_real[s] * twiddle_imag[twiddle_index[s]] + b_imag[s] * twiddle_real[twiddle_index[s]]);
              
//               prod_real[s] = (abdiff_real[s] * twiddle_real[twiddle_index[s]] - abdiff_imag[s] * twiddle_imag[twiddle_index[s]]);
//               prod_imag[s] = (abdiff_real[s] * twiddle_imag[twiddle_index[s]] + abdiff_imag[s] * twiddle_real[twiddle_index[s]]);
              prod_real[s] = (abdiff_real[s] * twiddle_real[twiddle_index[s]] - abdiff_imag[s] * twiddle_imag[twiddle_index[s]]) >>> (TWIDDLE_WIDTH - 2);
              prod_imag[s] = (abdiff_real[s] * twiddle_imag[twiddle_index[s]] + abdiff_imag[s] * twiddle_real[twiddle_index[s]]) >>> (TWIDDLE_WIDTH - 2);
//               $display("s %d b_real %d", s, b_real[s]);
//               $display("s %d a_real %d", s, a_real[s]);
//               $display("s %d b_imag %d", s, b_imag[s]);
//               $display("s %d a_imag %d", s, a_imag[s]);
//               $display("s %d twiddle_real[index] %d", s, twiddle_real[twiddle_index[s]]);
//               $display("s %d twiddle_imag[index] %d", s, twiddle_imag[twiddle_index[s]]);
              //               $display("s %d prod_real %d", s, prod_real[s]);
//               $display("s %d prod_imag %d", s, prod_imag[s]);

                // Butterfly
              stage_real[s+1][idx_a[s]] <= (a_real[s] + b_real[s]) >>> 1;
              stage_imag[s+1][idx_a[s]] <= (a_imag[s] + b_imag[s]) >>> 1;
              stage_real[s+1][idx_b[s]] <= (prod_real[s]) >>> 1;
              stage_imag[s+1][idx_b[s]] <= (prod_imag[s]) >>> 1;
//               stage_real[s+1][group * (2**(s+1)) + pair] <= a_real[s][group] + prod_real[s];
//               stage_imag[s+1][group * (2**(s+1)) + pair] <= a_imag[s][group] + prod_imag[s];
//               stage_real[s+1][group * (2**(s+1)) + pair + (2**s)] <= a_real[s][group] - prod_real[s];
//               stage_imag[s+1][group * (2**(s+1)) + pair + (2**s)] <= a_imag[s][group] - prod_imag[s];
            end
          end
        end
        end
      end
    endgenerate

    logic [STAGES-1:0] max_bin;
  logic signed [DATA_WIDTH*2:0] max_magnitude;
  logic signed [DATA_WIDTH*2:0] current_magnitude;
    
    // Output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
          out_valid = 1'b0;
//           for (int i = 0; i < N; i++) begin
//             out_real[i]  <= '0;
//             out_imag[i]  <= '0;
//           end
          max_bin = 0;
          max_magnitude = 0;
          current_magnitude = 0;
        end else if (stage_valid[STAGES]) begin
          $display("fft output (not bitreversed)");
          $display(stage_real[STAGES]);
          $display(stage_imag[STAGES]);
          
          for (int i = N-1; i > 0; i--) begin
            current_magnitude = ((stage_real[STAGES][i])*(stage_real[STAGES][i])) + ((stage_imag[STAGES][i])*(stage_imag[STAGES][i]));
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
          highest_bin <= max_bin;
          out_valid <= 1'b1;
          $display("highest_bin: %d", max_bin);
          $display("highest_magnitude: %d", max_magnitude);
          $display("stage 6! fft layer");
          $display(stage_real[6]);
          $display(stage_imag[6]);
        end else begin
//           $display(stage_valid);
          out_valid <= 1'b0;
        end
    end

endmodule
