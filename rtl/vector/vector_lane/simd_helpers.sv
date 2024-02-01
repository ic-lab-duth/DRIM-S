module simd_neg #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int RATIO     = MAX_WIDTH/MIN_WIDTH,
    parameter int SEW_WIDTH = $clog2(RATIO) + 1
)(
    input   logic [SEW_WIDTH-1:0]   sew,
    input   logic [RATIO-1:0]       enable,
    input   logic [MAX_WIDTH-1:0]   opA,
    output  logic [MAX_WIDTH-1:0]   result
);

    logic [RATIO-1:0]       inv;
    logic [MAX_WIDTH-1:0]   result_inv;

    simd_inv #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    )
    invert (
        .sew(sew),
        .enable(enable),
        .opA(opA),
        .inv(inv),
        .result(result_inv)
    );

    simd_inc #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH)
    )
    increment (
        .sew(sew),
        .enable(inv),
        .opA(result_inv),
        .result(result)
    );

endmodule

module simd_inv #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int RATIO     = MAX_WIDTH/MIN_WIDTH,
    parameter int SEW_WIDTH = $clog2(RATIO) + 1
)(
    input   logic [SEW_WIDTH-1:0]   sew,
    input   logic [RATIO-1:0]       enable,
    input   logic [MAX_WIDTH-1:0]   opA,
    output  logic [RATIO-1:0]       inv,
    output  logic [MAX_WIDTH-1:0]   result
);

    logic [SEW_WIDTH-1:0][RATIO-1:0] inv_temp;
    genvar i, j;
    generate
        for (i = 0; i < SEW_WIDTH; ++i) begin
            localparam int CURRENT_RATIO = 2**(SEW_WIDTH - i - 1);
            for (j = 0; j < RATIO; j += CURRENT_RATIO) begin
                assign inv_temp[i][j +: CURRENT_RATIO] = {CURRENT_RATIO{enable[j + CURRENT_RATIO - 1]}};
            end
        end
    endgenerate
    mux #(.INPUTS(SEW_WIDTH), .WIDTH(RATIO)) mux (.data_i(inv_temp), .sel(sew), .data_o(inv));
    always_comb for (int i = 0; i < RATIO; ++i) result[i*MIN_WIDTH +: MIN_WIDTH] = opA[i*MIN_WIDTH +: MIN_WIDTH] ^ {MIN_WIDTH{inv[i]}};

endmodule

module simd_inc #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int RATIO     = MAX_WIDTH/MIN_WIDTH,
    parameter int SEW_WIDTH = $clog2(RATIO) + 1
)(
    input   logic [SEW_WIDTH-1:0] sew,
    input   logic [RATIO-1:0] enable,
    input   logic [MAX_WIDTH-1:0] opA,
    output  logic [MAX_WIDTH-1:0] result
);

    logic [RATIO-2:0] stop;
    always_comb begin
        stop = 0;
        for (int i = 0; i < SEW_WIDTH; ++i) begin
            for (int j = RATIO/(2**i); j < RATIO; j += RATIO/(2**i))
                stop[j - 1] |= sew[i];
        end
    end

    genvar i;
    generate
        for (i = 0; i < RATIO; ++i) begin : gen_inc
            logic carry_o;
            if (i == 0) begin
                part_inc #(.WIDTH(MIN_WIDTH)) pinc (
                    .carry_i    (enable[i]),
                    .opA        (opA[i*MIN_WIDTH +: MIN_WIDTH]),
                    .result     (result[i*MIN_WIDTH +: MIN_WIDTH]),
                    .carry_o    (carry_o)
                );
            end else begin
                part_inc #(.WIDTH(MIN_WIDTH)) pinc (
                    .carry_i    (stop[i - 1] ? enable[i] : gen_inc[i - 1].carry_o),
                    .opA        (opA[i*MIN_WIDTH +: MIN_WIDTH]),
                    .result     (result[i*MIN_WIDTH +: MIN_WIDTH]),
                    .carry_o    (carry_o)
                );
            end
        end
    endgenerate
endmodule

module part_inc #(
    parameter int WIDTH = 8
)(
    input   logic carry_i,
    input   logic [WIDTH-1:0] opA,
    output  logic [WIDTH-1:0] result,
    output  logic carry_o
);

    assign {carry_o, result} = opA + carry_i;

endmodule