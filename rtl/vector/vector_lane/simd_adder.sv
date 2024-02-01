module simd_adder #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input   logic sub,
    input   logic rev,
    input   logic carry,
    input   logic [SEW_WIDTH - 1 : 0]   sew,
    input   logic [MAX_WIDTH/MIN_WIDTH - 1 : 0] mask,
    input   logic [MAX_WIDTH - 1 : 0]   opA,
    input   logic [MAX_WIDTH - 1 : 0]   opB,
    output  logic [MAX_WIDTH - 1 : 0]   result
);

    logic [MAX_WIDTH - 1 : 0] correct_opA, correct_opB;
    assign correct_opA = rev ? opB : opA;
    assign correct_opB = rev ? opA : opB;

    logic [MAX_WIDTH - 1 : 0] opB_real;
    assign opB_real = sub ? ~correct_opB : correct_opB;

    logic [MAX_WIDTH/MIN_WIDTH - 1 : 0] carries;
    assign carries =    carry   ? mask :
                        sub     ? {MAX_WIDTH/MIN_WIDTH{1'b1}} : {MAX_WIDTH/MIN_WIDTH{1'b0}};

    simd_internal_add #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH))
    internal_adder (
        .sew        (sew),
        .carry      (carries),
        .opA        (correct_opA),
        .opB        (opB_real),
        .result     (result)
    );

endmodule
module simd_internal_add #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input   logic [SEW_WIDTH-1:0] sew,
    input   logic [MAX_WIDTH/MIN_WIDTH-1:0] carry,
    input   logic [MAX_WIDTH-1:0] opA,
    input   logic [MAX_WIDTH-1:0] opB,
    output  logic [MAX_WIDTH-1:0] result
);

    localparam int RATIO = MAX_WIDTH/MIN_WIDTH;
    logic [RATIO-2:0] stop_carry;

    always_comb begin
        stop_carry = 0;
        for (int i = 0; i < SEW_WIDTH; ++i) begin
            for (int j = RATIO/(2**i); j < RATIO; j += RATIO/(2**i))
                stop_carry[j - 1] |= sew[i];
        end
    end

    genvar i, j;
    generate
        for (i = 0; i < RATIO; ++i) begin : gen_adders
            logic carry_o;
            if (i == 0) begin
                part_adder #(.WIDTH(MIN_WIDTH)) padder (
                    .carry_i    (carry[i]),
                    .opA        (opA[i*MIN_WIDTH +: MIN_WIDTH]),
                    .opB        (opB[i*MIN_WIDTH +: MIN_WIDTH]),
                    .result     (result[i*MIN_WIDTH +: MIN_WIDTH]),
                    .carry_o    (carry_o)
                );
            end else begin
                part_adder #(.WIDTH(MIN_WIDTH)) padder (
                    .carry_i    (stop_carry[i - 1] ? carry[i] : gen_adders[i - 1].carry_o),
                    .opA        (opA[i*MIN_WIDTH +: MIN_WIDTH]),
                    .opB        (opB[i*MIN_WIDTH +: MIN_WIDTH]),
                    .result     (result[i*MIN_WIDTH +: MIN_WIDTH]),
                    .carry_o    (carry_o)
                );
            end
        end
    endgenerate
endmodule

module part_adder #(
    parameter int WIDTH = 8
)(
    input   logic carry_i,
    input   logic [WIDTH-1:0] opA,
    input   logic [WIDTH-1:0] opB,
    output  logic [WIDTH-1:0] result,
    output  logic carry_o
);

    assign {carry_o, result} = opA + opB + carry_i;

endmodule