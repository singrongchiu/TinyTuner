module Radix2FFTPipeline #(
    parameter DATA_WIDTH = 16,
    parameter TWIDDLE_WIDTH = 16,
    parameter N = 256,
    localparam STAGES = $clog2(N)
)(
    input  logic clk,
    input  logic rst_n,
    input  logic [DATA_WIDTH-1:0] in_real,
    input  logic [DATA_WIDTH-1:0] in_imag,
    input  logic in_valid,
    output logic [DATA_WIDTH-1:0] out_real [N-1:0],
    output logic [DATA_WIDTH-1:0] out_imag [N-1:0],
    output logic out_valid
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
        end else if (mic_input_index == 256) begin
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
    logic signed [DATA_WIDTH+TWIDDLE_WIDTH:0] prod_real[0:STAGES];
    logic signed [DATA_WIDTH+TWIDDLE_WIDTH:0] prod_imag[0:STAGES];
    logic signed [DATA_WIDTH-1:0] twiddle_real[N/2];
    logic signed [DATA_WIDTH-1:0] twiddle_imag[N/2];
    logic [STAGES-1:0] twiddle_index[0:STAGES];
  
    always_ff @(negedge rst_n) begin
      twiddle_real[0] = 16'sd32768; twiddle_imag[0] = 16'sd0;
      twiddle_real[1] = 16'sd32758; twiddle_imag[1] = -16'sd804;
      twiddle_real[2] = 16'sd32729; twiddle_imag[2] = -16'sd1608;
      twiddle_real[3] = 16'sd32679; twiddle_imag[3] = -16'sd2411;
      twiddle_real[4] = 16'sd32610; twiddle_imag[4] = -16'sd3212;
      twiddle_real[5] = 16'sd32522; twiddle_imag[5] = -16'sd4011;
      twiddle_real[6] = 16'sd32413; twiddle_imag[6] = -16'sd4808;
      twiddle_real[7] = 16'sd32286; twiddle_imag[7] = -16'sd5602;
      twiddle_real[8] = 16'sd32138; twiddle_imag[8] = -16'sd6393;
      twiddle_real[9] = 16'sd31972; twiddle_imag[9] = -16'sd7180;
      twiddle_real[10] = 16'sd31786; twiddle_imag[10] = -16'sd7962;
      twiddle_real[11] = 16'sd31581; twiddle_imag[11] = -16'sd8740;
      twiddle_real[12] = 16'sd31357; twiddle_imag[12] = -16'sd9512;
      twiddle_real[13] = 16'sd31114; twiddle_imag[13] = -16'sd10279;
      twiddle_real[14] = 16'sd30853; twiddle_imag[14] = -16'sd11039;
      twiddle_real[15] = 16'sd30572; twiddle_imag[15] = -16'sd11793;
      twiddle_real[16] = 16'sd30274; twiddle_imag[16] = -16'sd12540;
      twiddle_real[17] = 16'sd29957; twiddle_imag[17] = -16'sd13279;
      twiddle_real[18] = 16'sd29622; twiddle_imag[18] = -16'sd14010;
      twiddle_real[19] = 16'sd29269; twiddle_imag[19] = -16'sd14733;
      twiddle_real[20] = 16'sd28899; twiddle_imag[20] = -16'sd15447;
      twiddle_real[21] = 16'sd28511; twiddle_imag[21] = -16'sd16151;
      twiddle_real[22] = 16'sd28106; twiddle_imag[22] = -16'sd16846;
      twiddle_real[23] = 16'sd27684; twiddle_imag[23] = -16'sd17531;
      twiddle_real[24] = 16'sd27246; twiddle_imag[24] = -16'sd18205;
      twiddle_real[25] = 16'sd26791; twiddle_imag[25] = -16'sd18868;
      twiddle_real[26] = 16'sd26320; twiddle_imag[26] = -16'sd19520;
      twiddle_real[27] = 16'sd25833; twiddle_imag[27] = -16'sd20160;
      twiddle_real[28] = 16'sd25330; twiddle_imag[28] = -16'sd20788;
      twiddle_real[29] = 16'sd24812; twiddle_imag[29] = -16'sd21403;
      twiddle_real[30] = 16'sd24279; twiddle_imag[30] = -16'sd22006;
      twiddle_real[31] = 16'sd23732; twiddle_imag[31] = -16'sd22595;
      twiddle_real[32] = 16'sd23170; twiddle_imag[32] = -16'sd23170;
      twiddle_real[33] = 16'sd22595; twiddle_imag[33] = -16'sd23732;
      twiddle_real[34] = 16'sd22006; twiddle_imag[34] = -16'sd24279;
      twiddle_real[35] = 16'sd21403; twiddle_imag[35] = -16'sd24812;
      twiddle_real[36] = 16'sd20788; twiddle_imag[36] = -16'sd25330;
      twiddle_real[37] = 16'sd20160; twiddle_imag[37] = -16'sd25833;
      twiddle_real[38] = 16'sd19520; twiddle_imag[38] = -16'sd26320;
      twiddle_real[39] = 16'sd18868; twiddle_imag[39] = -16'sd26791;
      twiddle_real[40] = 16'sd18205; twiddle_imag[40] = -16'sd27246;
      twiddle_real[41] = 16'sd17531; twiddle_imag[41] = -16'sd27684;
      twiddle_real[42] = 16'sd16846; twiddle_imag[42] = -16'sd28106;
      twiddle_real[43] = 16'sd16151; twiddle_imag[43] = -16'sd28511;
      twiddle_real[44] = 16'sd15447; twiddle_imag[44] = -16'sd28899;
      twiddle_real[45] = 16'sd14733; twiddle_imag[45] = -16'sd29269;
      twiddle_real[46] = 16'sd14010; twiddle_imag[46] = -16'sd29622;
      twiddle_real[47] = 16'sd13279; twiddle_imag[47] = -16'sd29957;
      twiddle_real[48] = 16'sd12540; twiddle_imag[48] = -16'sd30274;
      twiddle_real[49] = 16'sd11793; twiddle_imag[49] = -16'sd30572;
      twiddle_real[50] = 16'sd11039; twiddle_imag[50] = -16'sd30853;
      twiddle_real[51] = 16'sd10279; twiddle_imag[51] = -16'sd31114;
      twiddle_real[52] = 16'sd9512; twiddle_imag[52] = -16'sd31357;
      twiddle_real[53] = 16'sd8740; twiddle_imag[53] = -16'sd31581;
      twiddle_real[54] = 16'sd7962; twiddle_imag[54] = -16'sd31786;
      twiddle_real[55] = 16'sd7180; twiddle_imag[55] = -16'sd31972;
      twiddle_real[56] = 16'sd6393; twiddle_imag[56] = -16'sd32138;
      twiddle_real[57] = 16'sd5602; twiddle_imag[57] = -16'sd32286;
      twiddle_real[58] = 16'sd4808; twiddle_imag[58] = -16'sd32413;
      twiddle_real[59] = 16'sd4011; twiddle_imag[59] = -16'sd32522;
      twiddle_real[60] = 16'sd3212; twiddle_imag[60] = -16'sd32610;
      twiddle_real[61] = 16'sd2411; twiddle_imag[61] = -16'sd32679;
      twiddle_real[62] = 16'sd1608; twiddle_imag[62] = -16'sd32729;
      twiddle_real[63] = 16'sd804; twiddle_imag[63] = -16'sd32758;
      twiddle_real[64] = 16'sd0; twiddle_imag[64] = -16'sd32768;
      twiddle_real[65] = -16'sd804; twiddle_imag[65] = -16'sd32758;
      twiddle_real[66] = -16'sd1608; twiddle_imag[66] = -16'sd32729;
      twiddle_real[67] = -16'sd2411; twiddle_imag[67] = -16'sd32679;
      twiddle_real[68] = -16'sd3212; twiddle_imag[68] = -16'sd32610;
      twiddle_real[69] = -16'sd4011; twiddle_imag[69] = -16'sd32522;
      twiddle_real[70] = -16'sd4808; twiddle_imag[70] = -16'sd32413;
      twiddle_real[71] = -16'sd5602; twiddle_imag[71] = -16'sd32286;
      twiddle_real[72] = -16'sd6393; twiddle_imag[72] = -16'sd32138;
      twiddle_real[73] = -16'sd7180; twiddle_imag[73] = -16'sd31972;
      twiddle_real[74] = -16'sd7962; twiddle_imag[74] = -16'sd31786;
      twiddle_real[75] = -16'sd8740; twiddle_imag[75] = -16'sd31581;
      twiddle_real[76] = -16'sd9512; twiddle_imag[76] = -16'sd31357;
      twiddle_real[77] = -16'sd10279; twiddle_imag[77] = -16'sd31114;
      twiddle_real[78] = -16'sd11039; twiddle_imag[78] = -16'sd30853;
      twiddle_real[79] = -16'sd11793; twiddle_imag[79] = -16'sd30572;
      twiddle_real[80] = -16'sd12540; twiddle_imag[80] = -16'sd30274;
      twiddle_real[81] = -16'sd13279; twiddle_imag[81] = -16'sd29957;
      twiddle_real[82] = -16'sd14010; twiddle_imag[82] = -16'sd29622;
      twiddle_real[83] = -16'sd14733; twiddle_imag[83] = -16'sd29269;
      twiddle_real[84] = -16'sd15447; twiddle_imag[84] = -16'sd28899;
      twiddle_real[85] = -16'sd16151; twiddle_imag[85] = -16'sd28511;
      twiddle_real[86] = -16'sd16846; twiddle_imag[86] = -16'sd28106;
      twiddle_real[87] = -16'sd17531; twiddle_imag[87] = -16'sd27684;
      twiddle_real[88] = -16'sd18205; twiddle_imag[88] = -16'sd27246;
      twiddle_real[89] = -16'sd18868; twiddle_imag[89] = -16'sd26791;
      twiddle_real[90] = -16'sd19520; twiddle_imag[90] = -16'sd26320;
      twiddle_real[91] = -16'sd20160; twiddle_imag[91] = -16'sd25833;
      twiddle_real[92] = -16'sd20788; twiddle_imag[92] = -16'sd25330;
      twiddle_real[93] = -16'sd21403; twiddle_imag[93] = -16'sd24812;
      twiddle_real[94] = -16'sd22006; twiddle_imag[94] = -16'sd24279;
      twiddle_real[95] = -16'sd22595; twiddle_imag[95] = -16'sd23732;
      twiddle_real[96] = -16'sd23170; twiddle_imag[96] = -16'sd23170;
      twiddle_real[97] = -16'sd23732; twiddle_imag[97] = -16'sd22595;
      twiddle_real[98] = -16'sd24279; twiddle_imag[98] = -16'sd22006;
      twiddle_real[99] = -16'sd24812; twiddle_imag[99] = -16'sd21403;
      twiddle_real[100] = -16'sd25330; twiddle_imag[100] = -16'sd20788;
      twiddle_real[101] = -16'sd25833; twiddle_imag[101] = -16'sd20160;
      twiddle_real[102] = -16'sd26320; twiddle_imag[102] = -16'sd19520;
      twiddle_real[103] = -16'sd26791; twiddle_imag[103] = -16'sd18868;
      twiddle_real[104] = -16'sd27246; twiddle_imag[104] = -16'sd18205;
      twiddle_real[105] = -16'sd27684; twiddle_imag[105] = -16'sd17531;
      twiddle_real[106] = -16'sd28106; twiddle_imag[106] = -16'sd16846;
      twiddle_real[107] = -16'sd28511; twiddle_imag[107] = -16'sd16151;
      twiddle_real[108] = -16'sd28899; twiddle_imag[108] = -16'sd15447;
      twiddle_real[109] = -16'sd29269; twiddle_imag[109] = -16'sd14733;
      twiddle_real[110] = -16'sd29622; twiddle_imag[110] = -16'sd14010;
      twiddle_real[111] = -16'sd29957; twiddle_imag[111] = -16'sd13279;
      twiddle_real[112] = -16'sd30274; twiddle_imag[112] = -16'sd12540;
      twiddle_real[113] = -16'sd30572; twiddle_imag[113] = -16'sd11793;
      twiddle_real[114] = -16'sd30853; twiddle_imag[114] = -16'sd11039;
      twiddle_real[115] = -16'sd31114; twiddle_imag[115] = -16'sd10279;
      twiddle_real[116] = -16'sd31357; twiddle_imag[116] = -16'sd9512;
      twiddle_real[117] = -16'sd31581; twiddle_imag[117] = -16'sd8740;
      twiddle_real[118] = -16'sd31786; twiddle_imag[118] = -16'sd7962;
      twiddle_real[119] = -16'sd31972; twiddle_imag[119] = -16'sd7180;
      twiddle_real[120] = -16'sd32138; twiddle_imag[120] = -16'sd6393;
      twiddle_real[121] = -16'sd32286; twiddle_imag[121] = -16'sd5602;
      twiddle_real[122] = -16'sd32413; twiddle_imag[122] = -16'sd4808;
      twiddle_real[123] = -16'sd32522; twiddle_imag[123] = -16'sd4011;
      twiddle_real[124] = -16'sd32610; twiddle_imag[124] = -16'sd3212;
      twiddle_real[125] = -16'sd32679; twiddle_imag[125] = -16'sd2411;
      twiddle_real[126] = -16'sd32729; twiddle_imag[126] = -16'sd1608;
      twiddle_real[127] = -16'sd32758; twiddle_imag[127] = -16'sd804;
    end
    
    
  
    generate
      for (genvar s = 0; s < STAGES; s++) begin : fft_stage
        always_ff @(posedge clk or negedge rst_n) begin
          if (!rst_n) begin
            stage_valid[s+1] <= 0;
          end else if (stage_valid[s]) begin
            stage_valid[s+1] <= 1;
//             $display("stage valid for %d", s);
//             $display(stage_real[0]);
//             $display("^ Stage Real!");
          end else begin
//             $display("stage NOT valid for %d", s);
            stage_valid[s+1] <= 0;
          end
        end
        
        always_ff @(posedge clk or negedge rst_n) begin
          for (int group = 0; group < N / (2**(s+1)); group++) begin : fft_group
            for (int pair = 0; pair < (2**s); pair++) begin : fft_pair

                // Calculate indices
                idx_a[s] = group * (2**(s+1)) + pair;
                idx_b[s] = idx_a[s] + (2**s);
                twiddle_index[s] = pair * (N >> (s+1));

                // Read inputs
                a_real[s] = stage_real[s][idx_a[s]];
                a_imag[s] = stage_imag[s][idx_a[s]];
                b_real[s] = stage_real[s][idx_b[s]];
                b_imag[s] = stage_imag[s][idx_b[s]];
//                 a_real[s] = stage_real[s][group * (2**(s+1)) + pair];
//                 a_imag[s] = stage_imag[s][group * (2**(s+1)) + pair];
//                 b_real[s] = stage_real[s][group * (2**(s+1)) + pair + (2**s)];
//                 b_imag[s] = stage_imag[s][group * (2**(s+1)) + pair + (2**s)];

                // Twiddle multiply
                prod_real[s] = (b_real[s] * twiddle_real[twiddle_index[s]] - b_imag[s] * twiddle_imag[twiddle_index[s]]) >>> (TWIDDLE_WIDTH - 1);
                prod_imag[s] = (b_real[s] * twiddle_imag[twiddle_index[s]] + b_imag[s] * twiddle_real[twiddle_index[s]]) >>> (TWIDDLE_WIDTH - 1);

                // Butterfly
                stage_real[s+1][idx_a[s]] <= a_real[s] + prod_real[s];
                stage_imag[s+1][idx_a[s]] <= a_imag[s] + prod_imag[s];
                stage_real[s+1][idx_b[s]] <= a_real[s] - prod_real[s];
                stage_imag[s+1][idx_b[s]] <= a_imag[s] - prod_imag[s];
//               stage_real[s+1][group * (2**(s+1)) + pair] <= a_real[s][group] + prod_real[s];
//               stage_imag[s+1][group * (2**(s+1)) + pair] <= a_imag[s][group] + prod_imag[s];
//               stage_real[s+1][group * (2**(s+1)) + pair + (2**s)] <= a_real[s][group] - prod_real[s];
//               stage_imag[s+1][group * (2**(s+1)) + pair + (2**s)] <= a_imag[s][group] - prod_imag[s];
            end
          end
        end
      end
    endgenerate


    // Output
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid <= 1'b0;
          for (int i = 0; i < N; i++) begin
            out_real[i]  <= '0;
            out_imag[i]  <= '0;
          end
        end else if (stage_valid[STAGES]) begin
//           $display(stage_valid);
//           $display("outputting out_real and out_imag");
          for (int i = 0; i < N; i++) begin
            out_real[i]  <= stage_real[STAGES][i]; // No bit reversal here
            out_imag[i]  <= stage_imag[STAGES][i];
          end
          out_valid <= 1'b1;
        end else begin
//           $display(stage_valid);
          out_valid <= 1'b0;
        end
    end

endmodule
