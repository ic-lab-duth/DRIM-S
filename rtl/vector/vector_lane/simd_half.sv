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

    logic [MAX_WIDTH - 1 : 0] opA_left, opA_right;
    assign {opA_left, opA_right} = opA;

    logic [MAX_WIDTH - 1 : 0] result_temp;
    assign result_temp = high ? opA_left : opA_right;

    logic [MAX_WIDTH/2 - 1 : 0] result_left, result_right;
    assign result = sew[0] ? result_temp : {result_left, result_right};


    logic internal_carry;
    generate
        if (RATIO == 1) begin
            assign {result_left, result_right} = high ? opA_left : opA_right;
        end else begin
            simd_half #(
                .MIN_WIDTH(MIN_WIDTH),
                .MAX_WIDTH(MAX_WIDTH/2))
            internal_right (
                .high       (high),
                .sew        (sew[SEW_WIDTH - 1:1]),
                .opA        (opA_right),
                .result     (result_right)
            );
            simd_half #(
                .MIN_WIDTH(MIN_WIDTH),
                .MAX_WIDTH(MAX_WIDTH/2))
            internal_left (
                .high       (high),
                .sew        (sew[SEW_WIDTH - 1:1]),
                .opA        (opA_left),
                .result     (result_left)
            );
        end
    endgenerate
endmodule
