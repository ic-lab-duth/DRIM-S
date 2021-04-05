/*
* @info Vector Unit Pipeline
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @param VECTOR_ELEM      : # of Instruction Bits (default==32)
* @param VECTOR_ACTIVE_EL : # of Instruction Bits (default==32)
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module vector_top #(
    parameter VECTOR_ELEM      = 4,
    parameter VECTOR_ACTIVE_EL = 4
) (
    input  logic     clk     ,
    input  logic     rst_n   ,
    //Instruction In
    input  logic     valid_in,
    input  to_vector instr_in,
    output logic     pop
    //Memory Interface
);



endmodule