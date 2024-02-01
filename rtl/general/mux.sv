module mux #(
    parameter int INPUTS    = 4,
    parameter int WIDTH     = 16
)(
    input  logic [INPUTS-1:0]               sel,
    input  logic [INPUTS-1:0][WIDTH-1:0]    data_i,
    output logic [WIDTH-1:0]                data_o
);


logic [INPUTS - 1 : 0][WIDTH - 1 : 0] data_temp;
always_comb for (int i = 0; i < INPUTS; ++i) for (int j = 0; j < WIDTH; ++j) data_temp[i][j] = data_i[i][j] & sel[i];

always_comb begin
    data_o = data_temp[0];
    for (int i = 1; i < INPUTS; ++i) data_o |= data_temp[i];
end

endmodule