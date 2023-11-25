module fpost #(
                parameter int FW   = 23,
                parameter int EW   = 8
            )(

                input logic [EW - 1 : 0]   exponentA,
                input logic [FW : 0]       significantA,
                input logic signA,
                input logic infA,
                input logic nanA,
                input logic zeroA,

                output logic [EW + FW : 0]  result
            );

    assign result = nanA    ? {signA, {EW + FW{1'b1}}} :
                    infA    ? {signA, {EW{1'b1}}, {FW{1'b0}}} :
                    zeroA   ? {signA, {EW + FW{1'b0}}} :
                    {signA,  exponentA, significantA[FW - 1 : 0]};

endmodule