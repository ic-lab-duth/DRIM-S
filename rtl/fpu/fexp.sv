module fexp #(
                parameter int FW1   = 23,
                parameter int FW2   = 40,
                parameter int EW1    = 8,
                parameter int EW2    = 10
            )(
                input logic clk,

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


    always_ff @( posedge clk ) begin
        significantR    <= {significantA, {FW2 - FW1{1'b0}}};
        exponentR       <= {{EW2 - EW1{1'b0}}, exponentA};
        signR           <= signA;
        infR            <= infA;
        nanR            <= nanA;
        zeroR           <= zeroA;
    end
endmodule