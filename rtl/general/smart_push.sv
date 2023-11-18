module smart_push   #(
                        parameter int INPUT_PORTS   = 1,
                        parameter int OUTPUT_PORTS  = 1,
                        parameter int DATA_WIDTH    = 32
                    )(
                        // input port
                        output  logic [INPUT_PORTS - 1 : 0]                        ready_out,
                        input   logic [INPUT_PORTS - 1 : 0]                        valid_in,
                        input   logic [INPUT_PORTS - 1 : 0][DATA_WIDTH - 1 : 0]    data_in,

                        // output port
                        output  logic [OUTPUT_PORTS - 1 : 0]                       push,
                        input   logic [OUTPUT_PORTS - 1 : 0]                       ready_in,
                        output  logic [OUTPUT_PORTS - 1 : 0][DATA_WIDTH - 1 : 0]   data_out
                    );

    logic [OUTPUT_PORTS - 1 : 0]    temp_valid;
    logic [INPUT_PORTS - 1 : 0]     temp_ready;

    logic [$clog2(OUTPUT_PORTS) : 0] indexA;
    always_comb begin : create_temp_valid
        indexA      = 0;
        temp_valid  = 0;
        data_out   = 0;
        for (int i = 0; i < INPUT_PORTS; i += 1) begin
            if (valid_in[i] && indexA < OUTPUT_PORTS) begin
                temp_valid[indexA]  = 1'b1;
                data_out[indexA]    = data_in[i];
                indexA += 1;
            end
        end
    end

    assign push = temp_valid & ready_in;

    logic [$clog2(OUTPUT_PORTS): 0] indexB;
    always_comb begin : create_temp_ready
        indexB      = 0;
        ready_out   = 0;
        for (int i = 0; i < INPUT_PORTS; i += 1) begin
            if (valid_in[i] && indexB < OUTPUT_PORTS) begin
                ready_out[i] = push[indexB];
                indexB += 1;
            end
        end
    end

endmodule