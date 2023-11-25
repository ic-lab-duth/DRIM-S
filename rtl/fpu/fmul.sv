module fmul #(
                parameter int FW = 23,
                parameter int EW = 8
            )(
                input logic clk,

                input logic [EW - 1 : 0]    exponentA,
                input logic [FW : 0]        significantA,
                input logic signA,
                input logic infA,
                input logic nanA,
                input logic zeroA,

                input logic [EW - 1 : 0]    exponentB,
                input logic [FW : 0]        significantB,
                input logic signB,
                input logic infB,
                input logic nanB,
                input logic zeroB,

                output logic [EW + 1 : 0]    exponentR,
                output logic [2*FW + 1 : 0]  significantR,
                output logic signR,
                output logic infR,
                output logic nanR,
                output logic zeroR
            );

    localparam BIAS = 2**(EW - 1) - 1;

    logic [EW + 1 : 0]    exponent_temp;
    logic [2*FW + 1 : 0]  significant_temp;

    assign exponent_temp = {2'b0, exponentA} + {2'b0, exponentB} - {2'b0, (EW)'(BIAS)};
    assign significant_temp = significantA*significantB;

    always_ff @( posedge clk ) begin
        nanR <= nanA | nanB | (zeroA & infB) | (infA & zeroB);
        infR <= (infA & ~(zeroB | nanB)) | (infB & ~(zeroA | nanA));
        zeroR <= (zeroA & ~(infB | nanB)) | (zeroB & ~(infA | nanA));

        signR <= signA ^ signB;

        exponentR <= exponent_temp + significant_temp[2*FW + 1];

        significantR <= significant_temp[2*FW + 1] ? significant_temp : {significant_temp[2*FW : 0], 1'b0};
    end


endmodule