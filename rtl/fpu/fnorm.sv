module fnorm #(
                parameter int FW1   = 26,
                parameter int FW2   = 23,
                parameter int EW1    = 10,
                parameter int EW2    = 8
            )(
                input logic clk,

                input logic [2 : 0] rm,

                input logic [EW1 - 1 : 0]   exponentA,
                input logic [FW1 : 0]       significantA,
                input logic signA,
                input logic infA,
                input logic nanA,
                input logic zeroA,

                output logic [EW2 - 1 : 0]   exponentR,
                output logic [FW2 : 0]       significantR,
                output logic signR,
                output logic infR,
                output logic nanR,
                output logic zeroR
            );

    logic [FW1 : 0] norm_significant;
    logic [EW1 : 0] exponent_temp;
    always_comb begin : arbiter
        exponent_temp       = exponentA;
        norm_significant    = significantA;
        for (int i = 0; i < FW1 + 1; i++) begin
            if (!norm_significant[FW1] && exponentR != 0) begin
                exponent_temp       -= 1;
                norm_significant    <<= 1;
            end
        end
    end

    logic [FW1 - FW2 - 3 : 0] sticky_temp;
    logic [FW2 : 0] significant_temp;
    logic guard;
    logic round;
    logic sticky;

    assign {significant_temp, guard, round, sticky_temp} = norm_significant;
    assign sticky = |sticky_temp;

    //TODO ROUNDING

    always_ff @( posedge clk ) begin
        significantR    <= significant_temp;
        exponentR       <= exponent_temp[EW2 - 1:0];
        signR           <= signA;
        infR            <= infA;
        nanR            <= nanA;
        zeroR           <= zeroA;
    end
endmodule