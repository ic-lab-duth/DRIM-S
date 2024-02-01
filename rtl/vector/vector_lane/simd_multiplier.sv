module simd_multiplier #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input   logic clk,
    input   logic high,
    input   logic signA,
    input   logic signB,
    input   logic [SEW_WIDTH - 1 : 0] sew,
    input   logic [MAX_WIDTH - 1 : 0] opA,
    input   logic [MAX_WIDTH - 1 : 0] opB,
    output  logic [MAX_WIDTH - 1 : 0] result
);
    localparam int RATIO = MAX_WIDTH/MIN_WIDTH;

    logic [SEW_WIDTH-1:0][RATIO - 1 : 0][RATIO - 1 : 0] masks_temp;
    logic [RATIO - 1 : 0][RATIO - 1 : 0] masks;
    logic [RATIO - 1 : 0][MAX_WIDTH - 1 : 0] mul_masks;
    genvar i, j, k;
    generate
        for (i = 0; i < SEW_WIDTH; ++i) begin
            localparam int CURRENT_RATIO = 2**(SEW_WIDTH - i - 1);
            for (j = 0; j < RATIO; ++j) begin
                for (k = 0; k < RATIO; ++k) begin
                    assign masks_temp[i][j][k] = (k/CURRENT_RATIO == j/CURRENT_RATIO);
                end
            end
        end
    endgenerate
    mux #(.INPUTS(SEW_WIDTH), .WIDTH(RATIO*RATIO)) mux (.data_i(masks_temp), .sel(sew), .data_o(masks));
    always_comb for (int i = 0; i < RATIO; ++i) for (int j = 0; j < RATIO; ++j) mul_masks[i][j*MIN_WIDTH +: MIN_WIDTH] = {MIN_WIDTH{masks[i][j]}};

    // Get signs of all bytes
    logic [RATIO - 1 : 0] opA_signs;
    logic [RATIO - 1 : 0] opB_signs;
    always_comb begin
        for (int i = 0; i < RATIO; ++i) begin
            opA_signs[i] = opA[(i + 1)*MIN_WIDTH - 1];
            opB_signs[i] = opB[(i + 1)*MIN_WIDTH - 1];
        end
    end

    // Make all the elements unsigned
    logic [MAX_WIDTH - 1 : 0] opA_unsigned;
    logic [MAX_WIDTH - 1 : 0] opB_unsigned;
    simd_neg #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) simd_unsigned_opA (
        .sew(sew),
        .enable(opA_signs),
        .opA(opA),
        .result(opA_unsigned)
    );
    simd_neg #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) simd_unsigned_opB (
        .sew(sew),
        .enable(opB_signs),
        .opA(opB),
        .result(opB_unsigned)
    );

    // Choose signed or unsigned vector based on opcode
    logic [MAX_WIDTH - 1 : 0] correct_opA;
    logic [MAX_WIDTH - 1 : 0] correct_opB;
    assign correct_opA = signA ? opA_unsigned : opA;
    assign correct_opB = signB ? opB_unsigned : opB;

    // Multiply vector A with every bit of vector B
    logic [MAX_WIDTH - 1 : 0][MAX_WIDTH - 1 : 0] parts;
    always_comb for (int i = 0; i < MAX_WIDTH; ++i) parts[i] = correct_opB[i] ? correct_opA & mul_masks[i/MIN_WIDTH] : 0;

    // Shift parts to be reduced from MAX_WIDTH to RATIO
    logic [MAX_WIDTH - 1 : 0][MAX_WIDTH + MIN_WIDTH - 1 : 0] shifted_parts;
    always_comb for (int i = 0; i < MAX_WIDTH; ++i) shifted_parts[i] = parts[i] << i%MIN_WIDTH;

    // Perform the addition and shift for the second addition
    logic [RATIO - 1 : 0][2*MAX_WIDTH - 1 : 0] part_results;
    always_comb begin
        part_results = 0;
        for (int i = 0; i < MAX_WIDTH; ++i) part_results[i/MIN_WIDTH] += shifted_parts[i] << (i/MIN_WIDTH)*MIN_WIDTH;
    end

    // Pipeline
    logic high_ff;
    logic [SEW_WIDTH - 1 : 0] sew_ff;
    logic [RATIO - 1 : 0] result_signs;
    logic [RATIO - 1 : 0][2*MAX_WIDTH - 1 : 0] part_results_ff;
    always_ff @(posedge clk) begin
        sew_ff <= sew;
        high_ff <= high;
        result_signs <= (signA ? opA_signs : 0) ^ (signB ? opB_signs : 0);
        part_results_ff <= part_results;
    end

    // Last addition
    logic [2*MAX_WIDTH - 1 : 0] result_unsigned;
    always_comb begin
        result_unsigned = 0;
        for (int i = 0; i < RATIO; ++i) result_unsigned += part_results_ff[i];
    end

    // Make result signed again
    logic [2*MAX_WIDTH - 1 : 0] result_full;
    simd_neg #(
        .MIN_WIDTH(2*MIN_WIDTH),
        .MAX_WIDTH(2*MAX_WIDTH)
    ) simd_signed_result (
        .sew(sew_ff),
        .enable(result_signs),
        .opA(result_unsigned),
        .result(result_full)
    );

    // Choose between mul and mulh
    simd_half #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) simd_result_half (
        .high(high_ff),
        .sew(sew_ff),
        .opA(result_full),
        .result(result)
    );
endmodule

module simd_half #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input   logic high,
    input   logic [SEW_WIDTH - 1 : 0] sew,
    input   logic [2*MAX_WIDTH - 1 : 0] opA,
    output  logic [MAX_WIDTH - 1 : 0] result
);
    localparam int RATIO = MAX_WIDTH/MIN_WIDTH;

    logic [SEW_WIDTH-1:0][MAX_WIDTH-1:0] temp_high, temp_low, temp_result;
    genvar i, j;
    generate
        for (i = 0; i < SEW_WIDTH; ++i) begin
            localparam int CURRENT_RATIO = 2**(SEW_WIDTH - i - 1);
            localparam int CURRENT_WIDTH = MIN_WIDTH*CURRENT_RATIO;
            for (j = 0; j < MAX_WIDTH; j += CURRENT_WIDTH) begin
                assign {temp_high[i][j +: CURRENT_WIDTH], temp_low[i][j +: CURRENT_WIDTH]} = opA[2*j +: 2*CURRENT_WIDTH];
            end
        end
    endgenerate
    assign temp_result = high ? temp_high : temp_low;
    mux #(.INPUTS(SEW_WIDTH), .WIDTH(MAX_WIDTH)) mux (.data_i(temp_result), .sel(sew), .data_o(result));

endmodule
