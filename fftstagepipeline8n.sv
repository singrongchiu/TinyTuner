module Radix2FFTPipeline8N #(
    parameter DATA_WIDTH = 8,
    parameter TWIDDLE_WIDTH = 8,
    parameter N = 8,
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
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
//           stage_valid[0] <= 0;
          mic_input_index <= 0;
          mic_inputting_array <= 0;
        end else if (mic_input_index == N) begin
          stage_valid0 <= 1;
//           $display("LC: STAGE SHOULD BE VALID!");
          mic_input_index <= 0;
          mic_inputting_array <= ~mic_inputting_array;
          if (mic_inputting_array) begin
            stage_real0 <= mic_input_real1;
            stage_imag0 <= mic_input_imag1;
          end
          else begin
            stage_real0 <= mic_input_real0;
            stage_imag0 <= mic_input_imag0;
          end
//           $display("mic input 0");
//           $display(mic_input_real[0]);
//           $display("mic input 1");
//           $display(mic_input_real[1]);
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
  logic signed [DATA_WIDTH-1:0] abdiff_real0;
  logic signed [DATA_WIDTH-1:0] abdiff_real1;
  logic signed [DATA_WIDTH-1:0] abdiff_real2;
  logic signed [DATA_WIDTH-1:0] abdiff_imag0;
  logic signed [DATA_WIDTH-1:0] abdiff_imag1;
  logic signed [DATA_WIDTH-1:0] abdiff_imag2;
    logic signed [DATA_WIDTH+TWIDDLE_WIDTH:0] prod_real[0:STAGES];
    logic signed [DATA_WIDTH+TWIDDLE_WIDTH:0] prod_imag[0:STAGES];
    logic signed [TWIDDLE_WIDTH-1:0] twiddle_real[N/2];
    logic signed [TWIDDLE_WIDTH-1:0] twiddle_imag[N/2];
    logic [STAGES-1:0] twiddle_index[0:STAGES];
  
//     always_ff @(negedge rst_n) begin
  assign twiddle_real[0] = 8'sd64; assign twiddle_imag[0] = 8'sd0;
  assign twiddle_real[1] = 8'sd45; assign twiddle_imag[1] = -8'sd45;
  assign twiddle_real[2] = 8'sd0; assign twiddle_imag[2] = -8'sd64;
  assign twiddle_real[3] = -8'sd45; assign twiddle_imag[3] = -8'sd45;
//     end
  
//     generate
//       for (genvar s = 0; s < STAGES; s++) begin : fft_stage
       
  ///// STAGE 1
        // note, had to watch out for bit reversal
        always_ff @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            stage_valid1 <= 0;
          end
          else if (stage_valid0) begin
            stage_valid1 <= 1;
          end
          else begin
            stage_valid1 <= 0;
          end
          for (int group = 0; group < (2**0); group++) begin : fft_group
            for (int pair = 0; pair < N / (2**(0+1)); pair++) begin : fft_pair

                // Calculate indices
              idx_a0 = group * (N >> 0) + pair;
              idx_b0 = idx_a0 + (N >> (0+1));
              twiddle_index[0] = pair * (2**0);

                // Read inputs
              a_real0 = stage_real0[idx_a0];
              a_imag0 = stage_imag0[idx_a0];
              b_real0 = stage_real0[idx_b0];
              b_imag0 = stage_imag0[idx_b0];
              abdiff_real0 = stage_real0[idx_a0] - stage_real0[idx_b0];
              abdiff_imag0 = stage_imag0[idx_a0] - stage_imag0[idx_b0];

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
//       end
//     endgenerate
  
  ////// STAGE 2
      always_ff @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            stage_valid2 <= 0;
          end
        else if (stage_valid1) begin
            //             $display("stage %d fft layer", 2);
//             $display(stage_real[s]);
//             $display(stage_imag[s]);
          stage_valid2 <= 1;
          end
          else begin
            stage_valid2 <= 0;
          end
        for (int group = 0; group < (2**1); group++) begin : fft_group
          for (int pair = 0; pair < N / (2**(1+1)); pair++) begin : fft_pair

                // Calculate indices
            idx_a1 = group * (N >> 1) + pair;
            idx_b1 = idx_a1 + (N >> (1+1));
            twiddle_index[1] = pair * (2**1);

                // Read inputs
            a_real1 = stage_real1[idx_a1];
            a_imag1 = stage_imag1[idx_a1];
            b_real1 = stage_real1[idx_b1];
            b_imag1 = stage_imag1[idx_b1];
            abdiff_real1 = stage_real1[idx_a1] - stage_real1[idx_b1];
            abdiff_imag1 = stage_imag1[idx_a1] - stage_imag1[idx_b1];

            prod_real[1] = (abdiff_real1 * twiddle_real[twiddle_index[1]] - abdiff_imag1 * twiddle_imag[twiddle_index[1]]) >>> (TWIDDLE_WIDTH - 2);
            prod_imag[1] = (abdiff_real1 * twiddle_imag[twiddle_index[1]] + abdiff_imag1 * twiddle_real[twiddle_index[1]]) >>> (TWIDDLE_WIDTH - 2);

                // Butterfly
            stage_real2[idx_a1] <= (a_real1 + b_real1) >>> 1;
            stage_imag2[idx_a1] <= (a_imag1 + b_imag1) >>> 1;
            stage_real2[idx_b1] <= (prod_real[1]) >>> 1;
            stage_imag2[idx_b1] <= (prod_imag[1]) >>> 1;
            end
          end
        end
  
  ////// STAGE 3
  always_ff @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            stage_valid3 <= 0;
          end
    else if (stage_valid2) begin
      stage_valid3 <= 1;
          end
          else begin
            stage_valid3 <= 0;
          end
    for (int group = 0; group < (2**2); group++) begin : fft_group
      for (int pair = 0; pair < N / (2**(2+1)); pair++) begin : fft_pair

                // Calculate indices
        idx_a2 = group * (N >> 2) + pair;
        idx_b2 = idx_a2 + (N >> (2+1));
        twiddle_index[2] = pair * (2**2);

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
        end else if (stage_valid3) begin
//           $display("fft output (not bitreversed)");
//           $display(stage_real[STAGES]);
//           $display(stage_imag[STAGES]);
          
          for (int i = N-1; i > 0; i--) begin
            current_magnitude = ((stage_real3[i])*(stage_real3[i])) + ((stage_imag2[i])*(stage_imag2[i]));
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
          $display("stage 3! fft layer");
          $display(stage_real3);
          $display(stage_imag3);
        end else begin
//           $display(stage_valid);
          out_valid <= 1'b0;
        end
    end

endmodule
