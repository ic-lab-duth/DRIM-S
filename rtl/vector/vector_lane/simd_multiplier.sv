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

    // Generate masks for multiplication
    logic [RATIO - 1 : 0][MAX_WIDTH - 1 : 0] mul_masks;
    genvar gv;
    generate
        for (gv = 0; gv < RATIO; ++gv) begin
            simd_mask #(
                .MIN_WIDTH  (MIN_WIDTH),
                .MAX_WIDTH  (MAX_WIDTH),
                .ID         (0),
                .TARGET     (gv))
            simd_mask (
                .sew        (sew),
                .result     (mul_masks[gv])
            );
        end
    endgenerate

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
    simd_unsigned #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) simd_unsigned_opA (
        .carry_i(1'b0),
        .sew(sew),
        .opA(opA),
        .result(opA_unsigned),
        .carry_o()
    );
    simd_unsigned #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) simd_unsigned_opB (
        .carry_i(1'b0),
        .sew(sew),
        .opA(opB),
        .result(opB_unsigned),
        .carry_o()
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
    simd_signed #(
        .MIN_WIDTH(2*MIN_WIDTH),
        .MAX_WIDTH(2*MAX_WIDTH)
    ) simd_signed_result (
        .carry_i(1'b0),
        .sew(sew_ff),
        .opA(result_unsigned),
        .change(result_signs),
        .result(result_full),
        .carry_o()
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