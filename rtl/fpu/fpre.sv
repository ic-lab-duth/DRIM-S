module fpre #(
                parameter int FW = 23,
                parameter int EW = 8
            )(
                input logic clk,

                input logic [EW + FW : 0]  opA,
                input logic [EW + FW : 0]  opB,
                input logic [EW + FW : 0]  opC,

                input logic [3:0] op,

                output logic sign1,
                output logic sign2,
                output logic sign3,

                output logic [EW - 1 : 0] exponent1,
                output logic [EW - 1 : 0] exponent2,
                output logic [EW - 1 : 0] exponent3,

                output logic [FW : 0] significant1,
                output logic [FW : 0] significant2,
                output logic [FW : 0] significant3,

                output logic inf1,
                output logic inf2,
                output logic inf3,

                output logic nan1,
                output logic nan2,
                output logic nan3,

                output logic zero1,
                output logic zero2,
                output logic zero3
            );

    localparam BIAS = 2**(EW - 1) - 1;

    logic [EW + FW : 0] op1; // in multiplier
    logic [EW + FW : 0] op2; // in multiplier
    logic [EW + FW : 0] op3; // in adder

    // op bits | sub | negate product | use adder | use multiplier |
    always_comb begin
        case (op[1:0])
            2'b01: begin
                op1 = opA;
                op2 = op[2] ? {~opB[EW + FW], opB[EW + FW - 1:0]} : opB;
                op3 = 0;
            end
            2'b10: begin
                op1 = $shortrealtobits(1.0);
                op2 = opA;
                op3 = op[3] ? {~opB[EW + FW], opB[EW + FW - 1:0]} : opB;
            end
            2'b11: begin
                op1 = opA;
                op2 = op[2] ? {~opB[EW + FW], opB[EW + FW - 1:0]} : opB;
                op3 = op[3] ? {~opC[EW + FW], opC[EW + FW - 1:0]} : opC;
            end
            default: begin
                op1 = 0;
                op2 = 0;
                op3 = 0;
            end
        endcase
    end



    logic sign1_temp;
    logic sign2_temp;
    logic sign3_temp;

    logic [EW - 1 : 0] exponent1_temp;
    logic [EW - 1 : 0] exponent2_temp;
    logic [EW - 1 : 0] exponent3_temp;

    logic [FW - 1 : 0] fraction1;
    logic [FW - 1 : 0] fraction2;
    logic [FW - 1 : 0] fraction3;

    assign {sign1_temp, exponent1_temp, fraction1} = op1;
    assign {sign2_temp, exponent2_temp, fraction2} = op2;
    assign {sign3_temp, exponent3_temp, fraction3} = op3;


    always_comb begin
        sign1 = sign1_temp;
        sign2 = sign2_temp;
        sign3 = sign3_temp;

        exponent1 = exponent1_temp;
        exponent2 = exponent2_temp;
        exponent3 = exponent3_temp;

        significant1 = {|exponent1_temp, fraction1};
        significant2 = {|exponent2_temp, fraction2};
        significant3 = {|exponent3_temp, fraction3};

        inf1 = &exponent1_temp & ~|fraction1;
        inf2 = &exponent2_temp & ~|fraction2;
        inf3 = &exponent3_temp & ~|fraction3;

        nan1 = &exponent1_temp & |fraction1;
        nan2 = &exponent2_temp & |fraction2;
        nan3 = &exponent3_temp & |fraction3;

        zero1 = ~|exponent1_temp & ~|fraction1;
        zero2 = ~|exponent2_temp & ~|fraction2;
        zero3 = ~|exponent3_temp & ~|fraction3;
    end
    // always_ff @( posedge clk ) begin
    //     sign1 <= sign1_temp;
    //     sign2 <= sign2_temp;
    //     sign3 <= sign3_temp;

    //     exponent1 <= exponent1_temp;
    //     exponent2 <= exponent2_temp;
    //     exponent3 <= exponent3_temp;

    //     significant1 <= {|exponent1_temp, fraction1};
    //     significant2 <= {|exponent2_temp, fraction2};
    //     significant3 <= {|exponent3_temp, fraction3};

    //     inf1 <= &exponent1_temp & ~|fraction1;
    //     inf2 <= &exponent2_temp & ~|fraction2;
    //     inf3 <= &exponent3_temp & ~|fraction3;

    //     nan1 <= &exponent1_temp & |fraction1;
    //     nan2 <= &exponent2_temp & |fraction2;
    //     nan3 <= &exponent3_temp & |fraction3;

    //     zero1 <= ~|exponent1_temp & ~|fraction1;
    //     zero2 <= ~|exponent2_temp & ~|fraction2;
    //     zero3 <= ~|exponent3_temp & ~|fraction3;
    // end




endmodule