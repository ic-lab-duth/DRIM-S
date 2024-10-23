module crossbar  #(
    DW = 32,
    N = 8
)(
    input  logic inverse,
    input  logic [N-1:0][DW-1:0] perm,
    input  logic [N-1:0][DW-1:0] data_i,
    output logic [N-1:0][DW-1:0] data_o

);

logic [N-1:0][N-1:0] matrix;

always_comb for (int i = 0; i < N; ++i) matrix[i] = 1 << perm[i];

always_comb begin
        for (int i = 0; i < N; i++) begin
            data_o[i] = 0;
            for (int j = 0; j < N; j++) begin
                for (int k = 0; k < DW; k++) begin
                    data_o[i][k] |= ((inverse & matrix[j][i]) | (~inverse & matrix[i][j])) & data_i[j][k];
                end
            end
        end
    end

endmodule : crossbar
