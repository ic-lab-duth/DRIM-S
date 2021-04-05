/*
* @info CSR registers
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @param DATA_WIDTH   : # of Data Bits (default 32 bits)
* @param ADDR_WIDTH   : # of Address Bits (default 6 bits) (OH)
* @param CYCLE_PERIOD : # ms for a clock cycle
* @param CSR_DEPTH    : # CSR registers
*/

//++++   TEMPORARY PLACEHOLDER   ++++
//++++ PROBABLY MISSES FUNCTIONALITY ++++
module csr_registers #(
    parameter DATA_WIDTH   = 32 ,
    parameter ADDR_WIDTH   = 6  ,
    parameter CSR_DEPTH    = 256,
    parameter CYCLE_PERIOD = 1
) (
    input logic                  clk       ,
    input logic                  rst_n     ,
    // read side
    input logic [ADDR_WIDTH-1:0] read_addr ,
    input logic [DATA_WIDTH-1:0] data_out  ,
    // write side
    input logic                  write_en  ,
    input logic [ADDR_WIDTH-1:0] write_addr,
    input logic [DATA_WIDTH-1:0] write_data,
    //instruction commiting
    input logic                  valid_ret ,
    input logic                  dual_ret
);
// ------------------------------------------------------------------------------------------------ //
    logic [CSR_DEPTH-1:0][DATA_WIDTH-1:0] csr_registers;
    logic [2*DATA_WIDTH-1:0] time_counter, cycle_counter, instr_counter;
// ------------------------------------------------------------------------------------------------ //
    //Time Counter
    always_ff @(posedge clk or negedge rst_n) begin : TimeCounter
        if(!rst_n) begin
            time_counter <= 0;
        end else begin
            time_counter <= (cycle_counter+1)*CYCLE_PERIOD;
        end
    end
    //Cycle Counter
    always_ff @(posedge clk or negedge rst_n) begin : CycleCounter
        if(!rst_n) begin
            cycle_counter <= 0;
        end else begin
            cycle_counter <= cycle_counter +1;
        end
    end
    //Instruction Counter
    always_ff @(posedge clk or negedge rst_n) begin : InstrCounter
        if(!rst_n) begin
            instr_counter <= 0;
        end else begin
            if (valid_ret) begin
                if (dual_ret) begin
                    instr_counter <= instr_counter +2;
                end else begin
                    instr_counter <= instr_counter +1;
                end
            end
        end
    end
    //CSR registers
    always_ff @(posedge clk) begin : CSRregs
        if(write_en) begin
            csr_registers[write_addr] = write_data;
        end
    end
    //Pick the Outputs
    assign data_out = csr_registers[read_addr];

endmodule
