module simd_shifter #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input logic right,
    input logic sign,

    input   logic [SEW_WIDTH - 1 : 0]   sew,
    input   logic [MAX_WIDTH - 1 : 0]   opA,
    input   logic [MAX_WIDTH - 1 : 0]   opB,
    output  logic [MAX_WIDTH - 1 : 0]   result
);

    localparam int RATIO = MAX_WIDTH/MIN_WIDTH;
    // Get signs of all bytes
    logic [RATIO - 1 : 0] opA_signs;
    always_comb begin
        for (int i = 0; i < RATIO; ++i) begin
            opA_signs[i] = opA[(i + 1)*MIN_WIDTH - 1];
        end
    end

    logic [MAX_WIDTH - 1 : 0] opA_unsigned, opA_rev, correct_opA, result_temp;
    simd_inv #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) simd_unsigned_opA (
        .sew(sew),
        .enable(opA_signs),
        .opA(opA),
        .inv(),
        .result(opA_unsigned)
    );
    simd_reverse #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) reverse_opA (
        .sew    (sew),
        .opA    (opA),
        .result (opA_rev)
    );
    assign correct_opA =    sign    ? opA_unsigned  :
                            !right  ? opA_rev       : opA;

    logic [MAX_WIDTH - 1 : 0] result_signed, result_rev;
    simd_inv #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) simd_signed_result (
        .sew(sew),
        .enable(opA_signs),
        .opA(result_temp),
        .inv(),
        .result(result_signed)
    );
    simd_reverse #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    ) result_reverse (
        .sew    (sew),
        .opA    (result_temp),
        .result (result_rev)
    );
    assign result = sign    ? result_signed :
                    !right  ? result_rev    : result_temp;

    logic [RATIO - 2 : 0] keep;
    always_comb begin
        keep = {RATIO - 1{1'b1}};
        for (int i = 0; i < SEW_WIDTH - 1; ++i) begin
            for (int j = 2**i - 1; j < RATIO - 1; j += 2**i) begin
                keep[j] &= ~sew[SEW_WIDTH - i - 1];
            end
        end
    end

    logic [SEW_WIDTH - 1 : 0] sew_therm;
    logic [$clog2(MAX_WIDTH) - 1: 0] mask;
    always_comb for (int i = 0; i < SEW_WIDTH; ++i) begin
        if (i == 0) sew_therm[SEW_WIDTH - i - 1] = sew[i];
        else sew_therm[SEW_WIDTH - i - 1] = sew[i] | sew_therm[SEW_WIDTH - i];
    end
    assign mask = {sew_therm, {$clog2(MIN_WIDTH) - 1{1'b1}}};

    logic [RATIO - 1 : 0][$clog2(MAX_WIDTH) - 1 : 0] shamt;
    always_comb begin
        for (int j = 0; j < SEW_WIDTH; ++j) begin
            if (sew[j]) begin
                for (int i = 0; i < RATIO; ++i) begin
                    shamt[i] = opB[((i/(RATIO/(2**j)))*(RATIO/(2**j)))*MIN_WIDTH +: $clog2(MAX_WIDTH)] & mask;
                end
            end
        end
    end

    logic [RATIO-1:0][$clog2(MIN_WIDTH)-1:0] small_shamt;
    logic [RATIO-1:0][$clog2(MAX_WIDTH)-$clog2(MIN_WIDTH):0] big_shamt;
    always_comb for (int i = 0; i < RATIO; ++i) {big_shamt[i], small_shamt[i]} = shamt[i];

    logic [RATIO-1:0][MIN_WIDTH-1:0] result_small;
    genvar i, j, k;
    generate
        for (i = 0; i < RATIO; ++i) begin : gen_shift
            if (i == RATIO - 1) begin
                part_shifter #(.WIDTH(MIN_WIDTH), .HALF(1)) pshift (
                    .keep   (1'b0),
                    .data   (correct_opA[i*MIN_WIDTH +: MIN_WIDTH]),
                    .left   ({MIN_WIDTH-1{1'b0}}),
                    .shamt  (small_shamt[i]),
                    .result  (result_small[i])
                );
            end else begin
                part_shifter #(.WIDTH(MIN_WIDTH), .HALF(0)) pshift (
                    .keep   (keep[i]),
                    .data   (correct_opA[i*MIN_WIDTH +: MIN_WIDTH]),
                    .left   (correct_opA[(i + 1)*MIN_WIDTH +: MIN_WIDTH - 1]),
                    .shamt  (small_shamt[i]),
                    .result  (result_small[i])
                );
            end
        end
    endgenerate

    logic [RATIO-1:0][MIN_WIDTH-1:0]    result_big;
    logic [SEW_WIDTH-1:0][RATIO-1:0][RATIO-1:0] matrix;
    generate
        for (i = 0; i < SEW_WIDTH; ++i) begin
            logic [2**i-1:0][RATIO/(2**i)-1:0][RATIO/(2**i)-1:0] mat;
            for (j = 0; j < 2**i; ++j) begin
                for (k = 0; k < RATIO/(2**i); ++k) begin
                    assign mat[j][k] = (1 << k) >> big_shamt[j*RATIO/(2**i)];
                end
            end
            for (j = 0; j < RATIO; ++j) begin
                for (k = 0; k < RATIO; ++k) begin
                    if (k/(RATIO/(2**i))== j/(RATIO/(2**i))) begin
                        assign matrix[i][j][k] = mat[k/(RATIO/(2**i))][j%(RATIO/(2**i))][k%(RATIO/(2**i))];
                    end else begin
                        assign matrix[i][j][k] = 1'b0;
                    end
                end
            end
        end
    endgenerate

    logic [RATIO-1:0][RATIO-1:0] sel_matrix;
    always_comb for (int i = 0; i < SEW_WIDTH; ++i) if (sew[i]) sel_matrix = matrix[i];

    permutation #(
        .WIDTH(MIN_WIDTH),
        .NUM(RATIO)
    )
    perm (
        .data_i(result_small),
        .data_o(result_big),
        .matrix(sel_matrix)
    );

    always_comb for (int i = 0; i < RATIO; ++i) result_temp[i*RATIO +: RATIO] = result_big[i];
endmodule

module simd_reverse #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input   logic [SEW_WIDTH - 1 : 0]   sew,
    input   logic [MAX_WIDTH - 1 : 0]   opA,
    output  logic [MAX_WIDTH - 1 : 0]   result
);

    localparam int RATIO = MAX_WIDTH/MIN_WIDTH;

    logic [SEW_WIDTH-1:0][MAX_WIDTH-1:0] result_temp;
    genvar i, j, k;
    generate
        for (i = 0; i < SEW_WIDTH; ++i) begin
            localparam int CURRENT_RATIO = 2**(SEW_WIDTH - i - 1);
            localparam int CURRENT_WIDTH = MIN_WIDTH*CURRENT_RATIO;
            for (j = 0; j < MAX_WIDTH; j += CURRENT_WIDTH) begin
                for (k = 0; k < CURRENT_WIDTH; ++k) begin
                    assign result_temp[i][j + k] = opA[j + CURRENT_WIDTH - k - 1];
                end
            end
        end
    endgenerate
    mux #(.INPUTS(SEW_WIDTH), .WIDTH(MAX_WIDTH)) mux (.data_i(result_temp), .sel(sew), .data_o(result));
endmodule

module part_shifter #(
    parameter int WIDTH = 8,
    parameter bit HALF = 0
)(
    input logic keep,
    input logic [WIDTH-1:0]     data,
    input logic [WIDTH-2:0]     left,
    input logic [$clog2(WIDTH)-1:0] shamt,

    output logic [WIDTH-1:0] result
);

generate
    if (HALF) begin
        assign result = data >> shamt;
    end else begin
        logic [WIDTH-2:0] left_real;
        assign left_real = left & {WIDTH-1{keep}};
        assign result = {left_real, data} >> shamt;
    end
endgenerate
endmodule

module permutation #(
    WIDTH = 8,
    NUM = 4
)(
    input   logic [NUM-1:0] [WIDTH-1:0] data_i,
    output  logic [NUM-1:0] [WIDTH-1:0] data_o,

    input   logic [NUM-1:0] [NUM-1:0] matrix
);

    always_comb begin
        for (int i = 0; i < NUM; i++) begin
            data_o[i] = 0;
            for (int j = 0; j < NUM; j++) begin
                for (int k = 0; k < WIDTH; k++) begin
                    data_o[i][k] |= matrix[j][i] & data_i[j][k];
                end
            end
        end
    end
endmodule