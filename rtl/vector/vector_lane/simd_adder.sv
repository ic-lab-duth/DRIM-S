module simd_adder #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input   logic sub,
    input   logic rev,
    input   logic carry,
    input   logic [SEW_WIDTH - 1 : 0]   sew,
    input   logic [MAX_WIDTH/8 - 1 : 0] mask,
    input   logic [MAX_WIDTH - 1 : 0]   opA,
    input   logic [MAX_WIDTH - 1 : 0]   opB,
    output  logic [MAX_WIDTH - 1 : 0]   result
);

    logic [MAX_WIDTH - 1 : 0] correct_opA, correct_opB;
    assign correct_opA = rev ? opB : opA;
    assign correct_opB = rev ? opA : opB;

    logic [MAX_WIDTH - 1 : 0] opB_real;
    assign opB_real = sub ? ~correct_opB : correct_opB;

    logic [MAX_WIDTH/8 - 1 : 0] carries;
    assign carries =    carry   ? mask :
                        sub     ? {MAX_WIDTH/8{1'b1}} : {MAX_WIDTH/8{1'b0}};

    simd_internal_add #(
        .MIN_WIDTH(MIN_WIDTH),
        .MAX_WIDTH(MAX_WIDTH))
    internal_adder (
        .carry_i    (1'b0),
        .sew        (sew),
        .carries    (carries),
        .opA        (correct_opA),
        .opB        (opB_real),
        .result     (result),
        .carry_o    ()
    );

endmodule
module simd_internal_add #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input   logic carry_i,
    input   logic [SEW_WIDTH - 1 : 0]   sew,
    input   logic [MAX_WIDTH/8 - 1 : 0] carries,
    input   logic [MAX_WIDTH - 1 : 0]   opA,
    input   logic [MAX_WIDTH - 1 : 0]   opB,
    output  logic [MAX_WIDTH - 1 : 0]   result,
    output  logic carry_o
);

    localparam int RATIO = MAX_WIDTH/MIN_WIDTH;

    logic [MAX_WIDTH/2 - 1 : 0] result_left, result_right;
    assign result = {result_left, result_right};

    logic [MAX_WIDTH/2 - 1 : 0] opA_left, opA_right;
    assign {opA_left, opA_right} = opA;

    logic [MAX_WIDTH/2 - 1 : 0] opB_left, opB_right;
    assign {opB_left, opB_right} = opB;

    logic [MAX_WIDTH/16 - 1 : 0] carries_left, carries_right;
    assign {carries_left, carries_right} = carries;

    logic true_carry;
    assign true_carry = sew[0] ? carries[0] : carry_i;

    logic internal_carry;
    generate
        if (RATIO == 1) begin
            assign {carry_o, result_left, result_right} = opA + opB + true_carry;
        end else begin
            simd_internal_add #(
                .MIN_WIDTH(MIN_WIDTH),
                .MAX_WIDTH(MAX_WIDTH/2))
            internal_right (
                .carry_i    (true_carry),
                .sew        (sew[SEW_WIDTH - 1:1]),
                .carries    (carries_right),
                .opA        (opA_right),
                .opB        (opB_right),
                .result     (result_right),
                .carry_o    (internal_carry)
            );
            simd_internal_add #(
                .MIN_WIDTH(MIN_WIDTH),
                .MAX_WIDTH(MAX_WIDTH/2))
            internal_left (
                .carry_i    (internal_carry),
                .sew        (sew[SEW_WIDTH - 1:1]),
                .carries    (carries_left),
                .opA        (opA_left),
                .opB        (opB_left),
                .result     (result_left),
                .carry_o    (carry_o)
            );
        end
    endgenerate
endmodule