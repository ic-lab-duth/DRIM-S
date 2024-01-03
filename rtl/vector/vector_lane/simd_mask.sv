module simd_mask #(
    parameter int MIN_WIDTH = 8,
    parameter int MAX_WIDTH = 64,
    parameter int ID        = 0,
    parameter int TARGET    = 0,
    parameter int SEW_WIDTH = $clog2(MAX_WIDTH/MIN_WIDTH) + 1
)(
    input   logic [SEW_WIDTH - 1 : 0] sew,
    output  logic [MAX_WIDTH - 1 : 0] result
);
    localparam int RATIO = MAX_WIDTH/MIN_WIDTH;

    logic [MAX_WIDTH/2 - 1 : 0] result_left, result_right;
    generate
        if (TARGET >= ID && TARGET < ID + RATIO) assign result = sew[0] ? {MAX_WIDTH{1'b1}} : {result_left, result_right};
        else assign result = 0;
    endgenerate

    generate
        if (RATIO == 1) begin
            assign {result_left, result_right} = ID == TARGET ? {MAX_WIDTH{1'b1}} : {MAX_WIDTH{1'b0}};
        end else begin
            simd_mask #(
                .MIN_WIDTH  (MIN_WIDTH),
                .MAX_WIDTH  (MAX_WIDTH/2),
                .ID         (ID),
                .TARGET     (TARGET))
            internal_right (
                .sew        (sew[SEW_WIDTH - 1:1]),
                .result     (result_right)
            );
            simd_mask #(
                .MIN_WIDTH(MIN_WIDTH),
                .MAX_WIDTH(MAX_WIDTH/2),
                .ID       (ID + RATIO/2),
                .TARGET   (TARGET))
            internal_left (
                .sew        (sew[SEW_WIDTH - 1:1]),
                .result     (result_left)
            );
        end
    endgenerate
endmodule
