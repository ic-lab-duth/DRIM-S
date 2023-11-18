module smart_pop    #(
                        parameter int INPUT_PORTS = 1
                    )(
                        input   logic                       clk,
                        input   logic                       rst,

                        // flush port
                        input   logic                       flush,

                        // output port
                        input   logic [INPUT_PORTS - 1 : 0]  ready_in,
                        output  logic [INPUT_PORTS - 1 : 0]  valid_out,

                        // input port
                        input   logic [INPUT_PORTS - 1 : 0]  valid_in,
                        output  logic [INPUT_PORTS - 1 : 0]  pop
                    );

    logic [INPUT_PORTS - 1 : 0] valid;
    logic [INPUT_PORTS - 1 : 0] future_valid;
    logic [INPUT_PORTS - 1 : 0] next_valid;

    assign future_valid = valid & ~ready_in;
    assign valid_out    = valid_in & valid;
    always_ff @( posedge clk ) begin
        if (rst) begin
            valid <= {INPUT_PORTS{1'b1}};
        end else if (flush) begin
            valid <= {INPUT_PORTS{1'b1}};
        end else begin
            valid <= next_valid;
        end
    end

    always_comb begin : create_next_valid
        next_valid = future_valid;
        for (int i = 0; i < INPUT_PORTS; i++) begin
            if (pop[i]) begin
                next_valid = {1'b1, next_valid[INPUT_PORTS - 1 : 1]};
            end
        end
    end

    always_comb begin : create_pop
        pop[0] = ~future_valid[0];
        for (int i = 1; i < INPUT_PORTS; i++) begin
            pop[i] = ~future_valid[i] & pop[i - 1] & valid_in[i];
        end
    end

endmodule