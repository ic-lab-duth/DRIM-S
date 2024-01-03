module simd_unsigned #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input   logic carry_i,
    input   logic [SEW_WIDTH - 1 : 0] sew,
    input   logic [MAX_WIDTH - 1 : 0] opA,
    output  logic [MAX_WIDTH - 1 : 0] result,
    output  logic carry_o
);
    localparam int RATIO = MAX_WIDTH/MIN_WIDTH;

    logic [MAX_WIDTH - 1 : 0] tempA;
    assign tempA = opA[MAX_WIDTH - 1] ? ~opA : opA;

    logic [MAX_WIDTH/2 - 1 : 0] result_left, result_right;
    assign result = {result_left, result_right};

    logic [MAX_WIDTH/2 - 1 : 0] opA_left, opA_right;
    assign {opA_left, opA_right} = sew[0] ? tempA : opA;

    logic internal_carry;
    generate
        if (RATIO == 1) begin
            assign {carry_o, result_left, result_right} = sew[0] ? tempA + opA[MAX_WIDTH - 1] : opA + carry_i;
        end else begin
            simd_unsigned #(
                .MIN_WIDTH(MIN_WIDTH),
                .MAX_WIDTH(MAX_WIDTH/2))
            internal_right (
                .carry_i    (sew[0] ? opA[MAX_WIDTH - 1] : carry_i),
                .sew        (sew[SEW_WIDTH - 1:1]),
                .opA        (opA_right),
                .result     (result_right),
                .carry_o    (internal_carry)
            );
            simd_unsigned #(
                .MIN_WIDTH(MIN_WIDTH),
                .MAX_WIDTH(MAX_WIDTH/2))
            internal_left (
                .carry_i    (internal_carry),
                .sew        (sew[SEW_WIDTH - 1:1]),
                .opA        (opA_left),
                .result     (result_left),
                .carry_o    (carry_o)
            );
        end
    endgenerate
endmodule
