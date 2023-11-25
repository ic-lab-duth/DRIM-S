module fma #(
                parameter int FW = 23,
                parameter int EW = 8
            )(
                input logic clk,

                input logic [2 : 0] rm,
                input logic [3:0] op,

                input logic [EW + FW : 0]  opA,
                input logic [EW + FW : 0]  opB,
                input logic [EW + FW : 0]  opC,

                output logic [EW + FW : 0]  result
            );

    logic sign1_pre;
    logic sign2_pre;
    logic sign3_pre;
    logic [EW - 1 : 0] exponent1_pre;
    logic [EW - 1 : 0] exponent2_pre;
    logic [EW - 1 : 0] exponent3_pre;
    logic [FW : 0] significant1_pre;
    logic [FW : 0] significant2_pre;
    logic [FW : 0] significant3_pre;
    logic inf1_pre;
    logic inf2_pre;
    logic inf3_pre;
    logic nan1_pre;
    logic nan2_pre;
    logic nan3_pre;
    logic zero1_pre;
    logic zero2_pre;
    logic zero3_pre;

    fpre #(.FW(FW),.EW(EW)) fpre    (
                                        .clk            (clk),
                                        .opA            (opA),
                                        .opB            (opB),
                                        .opC            (opC),
                                        .op             (op),
                                        .sign1          (sign1_pre),
                                        .sign2          (sign2_pre),
                                        .sign3          (sign3_pre),
                                        .exponent1      (exponent1_pre),
                                        .exponent2      (exponent2_pre),
                                        .exponent3      (exponent3_pre),
                                        .significant1   (significant1_pre),
                                        .significant2   (significant2_pre),
                                        .significant3   (significant3_pre),
                                        .inf1           (inf1_pre),
                                        .inf2           (inf2_pre),
                                        .inf3           (inf3_pre),
                                        .nan1           (nan1_pre),
                                        .nan2           (nan2_pre),
                                        .nan3           (nan3_pre),
                                        .zero1          (zero1_pre),
                                        .zero2          (zero2_pre),
                                        .zero3          (zero3_pre)
                                    );

    logic [EW + 1 : 0]    exponent_mul;
    logic [2*FW + 1 : 0]  significant_mul;
    logic sign_mul;
    logic inf_mul;
    logic nan_mul;
    logic zero_mul;

    fmul #(.FW(FW),.EW(EW)) fmul    (
                                        .clk            (clk),
                                        .exponentA      (exponent1_pre),
                                        .significantA   (significant1_pre),
                                        .signA          (sign1_pre),
                                        .infA           (inf1_pre),
                                        .nanA           (nan1_pre),
                                        .zeroA          (zero1_pre),
                                        .exponentB      (exponent2_pre),
                                        .significantB   (significant2_pre),
                                        .signB          (sign2_pre),
                                        .infB           (inf2_pre),
                                        .nanB           (nan2_pre),
                                        .zeroB          (zero2_pre),
                                        .exponentR      (exponent_mul),
                                        .significantR   (significant_mul),
                                        .signR          (sign_mul),
                                        .infR           (inf_mul),
                                        .nanR           (nan_mul),
                                        .zeroR          (zero_mul)
                                    );

    logic [EW + 1 : 0]    exponent_exp;
    logic [2*FW + 1 : 0]  significant_exp;
    logic sign_exp;
    logic inf_exp;
    logic nan_exp;
    logic zero_exp;

    fexp #(.FW1(FW),.FW2(2*FW + 1),.EW1(EW),.EW2(EW + 2)) fexp  (
                                                                    .clk            (clk),
                                                                    .exponentA      (exponent3_pre),
                                                                    .significantA   (significant3_pre),
                                                                    .signA          (sign3_pre),
                                                                    .infA           (inf3_pre),
                                                                    .nanA           (nan3_pre),
                                                                    .zeroA          (zero3_pre),
                                                                    .exponentR      (exponent_exp),
                                                                    .significantR   (significant_exp),
                                                                    .signR          (sign_exp),
                                                                    .infR           (inf_exp),
                                                                    .nanR           (nan_exp),
                                                                    .zeroR          (zero_exp)
                                                                );

    logic [EW + 1 : 0]      exponent_add;
    logic [2*FW + 1: 0]     significant_add;
    logic sign_add;
    logic inf_add;
    logic nan_add;
    logic zero_add;

    fadd #(.FW(2*FW + 1),.EW(EW + 2)) fadd  (
                                                .clk            (clk),
                                                .exponentA      (exponent_mul),
                                                .significantA   (significant_mul),
                                                .signA          (sign_mul),
                                                .infA           (inf_mul),
                                                .nanA           (nan_mul),
                                                .zeroA          (zero_mul),
                                                .exponentB      (exponent_exp),
                                                .significantB   (significant_exp),
                                                .signB          (sign_exp),
                                                .infB           (inf_exp),
                                                .nanB           (nan_exp),
                                                .zeroB          (zero_exp),
                                                .exponentR      (exponent_add),
                                                .significantR   (significant_add),
                                                .signR          (sign_add),
                                                .infR           (inf_add),
                                                .nanR           (nan_add),
                                                .zeroR          (zero_add)
                                            );

    logic sign_norm;
    logic [EW - 1 : 0] exponent_norm;
    logic [FW : 0] significant_norm;
    logic inf_norm;
    logic nan_norm;
    logic zero_norm;

    fnorm #(.FW1(2*FW + 1),.FW2(FW),.EW1(EW + 2),.EW2(EW)) fnorm    (
                                                                                .clk            (clk),
                                                                                .rm             (rm),
                                                                                .exponentA      (exponent_add),
                                                                                .significantA   (significant_add),
                                                                                .signA          (sign_add),
                                                                                .infA           (inf_add),
                                                                                .nanA           (nan_add),
                                                                                .zeroA          (zero_add),
                                                                                .exponentR      (exponent_norm),
                                                                                .significantR   (significant_norm),
                                                                                .signR          (sign_norm),
                                                                                .infR           (inf_norm),
                                                                                .nanR           (nan_norm),
                                                                                .zeroR          (zero_norm)
                                                                            );

fpost #(.FW(FW),.EW(EW)) fpost  (
                                    .exponentA      (exponent_norm),
                                    .significantA   (significant_norm),
                                    .signA          (sign_norm),
                                    .infA           (inf_norm),
                                    .nanA           (nan_norm),
                                    .zeroA          (zero_norm),
                                    .result         (result)
                                );


endmodule