module sew_register #(parameter int DATA_FROM_SCALAR=96,
                      parameter int INSTRUCTION_BITS=32
                    )(input logic clk,
                      input logic rst,
                      input logic valid_fifo,
                      input logic [DATA_FROM_SCALAR-1:0] instruction_in,
                      output logic [2:0] sew);

logic [INSTRUCTION_BITS-1:0] instruction;
logic vector_operation;
logic invalid;

assign instruction=instruction_in[DATA_FROM_SCALAR-INSTRUCTION_BITS+:INSTRUCTION_BITS];
assign vector_operation=(instruction[6:0]==7'b1010111);
assign invalid=(instruction[14:12]==3'b111);

always_ff @(posedge clk or posedge rst) begin
    if(rst)
        sew<=0;
    else begin
        if(vector_operation && invalid && valid_fifo)
            sew<=instruction[25:23];
    end
end

endmodule