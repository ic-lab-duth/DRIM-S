module fadd #(
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

                output logic [EW - 1 : 0]   exponentR,
                output logic [FW  : 0]      significantR,
                output logic signR,
                output logic infR,
                output logic nanR,
                output logic zeroR
            );




    logic comp;
    assign comp = exponentA > exponentB;

    logic [EW : 0] shamt;
    assign shamt = comp ? exponentA - exponentB : exponentB - exponentA;


    logic [FW : 0] shifted_signigicantA;
    logic [FW : 0] shifted_signigicantB;

    assign shifted_signigicantA = comp ? significantA : significantA >> shamt;
    assign shifted_signigicantB = comp ? significantB >> shamt : significantB;

    logic [FW + 1 : 0] add_signigicant;
    logic [FW + 1 : 0] sub_signigicant;

    assign add_signigicant = shifted_signigicantA + shifted_signigicantB;
    assign sub_signigicant = comp ? shifted_signigicantA - shifted_signigicantB : shifted_signigicantB - shifted_signigicantA;

    logic [FW + 1: 0] significant_temp;
    logic [EW - 1 : 0] exponent_temp;

    assign significant_temp = signA ^ signB ? sub_signigicant : add_signigicant;
    assign exponent_temp = comp ? exponentA : exponentB;

    always_ff @( posedge clk ) begin
        nanR            <= nanA | nanB | (infA & infB & (signA ^ signB));
        infR            <= (infA | infB) & ~nanR;
        zeroR           <= (zeroA & zeroB) | (~|significant_temp & ~(nanA | nanB));
        signR           <= comp ? signA : signB;

        exponentR <= exponent_temp + significant_temp[FW + 1];

        significantR <= significant_temp[FW + 1] ? significant_temp[FW + 1:1] : significant_temp[FW:0];
    end




endmodule