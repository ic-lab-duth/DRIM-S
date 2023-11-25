module delay    #(
                    parameter int DATA_WIDTH    = 32,
                    parameter int DELAY         = 1
                )(
                    input logic clk,
                    input logic [DATA_WIDTH - 1 : 0] data_i,
                    output logic [DATA_WIDTH - 1 : 0] data_o
                );

    logic [DELAY : 0][DATA_WIDTH - 1 : 0] data;


    genvar i;
    generate
        assign data_o = data[DELAY];
        assign data[0] = data_i;
        if (DELAY > 0) begin
            for (i = 0; i < DELAY; ++i) begin
                flop #(.DATA_WIDTH(DATA_WIDTH)) flop (.clk(clk), .data_i(data[i]), .data_o(data[i + 1]));
            end
        end else begin
            assign data_o = data_i;
        end
    endgenerate

endmodule