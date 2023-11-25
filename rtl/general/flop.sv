module flop #(
                parameter int DATA_WIDTH = 32
            )(
                input logic clk,
                input logic [DATA_WIDTH - 1 : 0] data_i,
                output logic [DATA_WIDTH - 1 : 0] data_o
            );

            always_ff @(posedge clk) data_o <= data_i;

endmodule