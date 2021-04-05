/*
* @info Integer Division Module
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief Integer Division Module (signed/unsigned) : returns the quotient and the remainder
*
* @param DATA_WIDTH  : # of Data Bits (default 32 bits)
* @param CALC_CYCLES : # of clocks needed for the calculation is also parameterized (only powers of 2)
*/
module division #(
    parameter DATA_WIDTH  = 32,
    parameter CALC_CYCLES = 4
) (
    input  logic                    clk          ,
    input  logic                    rst_n        ,
    //Input Port
    input  logic                    enable       ,
    input  logic                    sign         ,
    input  logic [  DATA_WIDTH-1:0] dividend     ,
    input  logic [  DATA_WIDTH-1:0] divider      ,
    //Output Port
    output logic                    ready        ,
    output logic [2*DATA_WIDTH-1:0] result       ,
    output logic [  DATA_WIDTH-1:0] remainder_out
);

    localparam BIT_GROUPS = DATA_WIDTH/CALC_CYCLES;
    // #Internal variables#
    logic [$clog2(CALC_CYCLES)-1:0] counter        ;
    logic [         DATA_WIDTH-1:0] remainder_saved, quotient_saved;
    logic [         DATA_WIDTH-1:0] quotient,divider_copy, remainder;
    logic [           DATA_WIDTH:0] diff           ;
    logic                           result_sign, saved_sign;

    always_comb begin : Division
        remainder = {remainder_saved[DATA_WIDTH-2:0],quotient_saved[DATA_WIDTH-1]};
        quotient  = quotient_saved << 1 ;
        diff      = remainder - divider_copy;
        if(diff[DATA_WIDTH]) begin
            quotient[0] = 1'b0;
        end else begin
            quotient[0] = 1'b1;
            remainder   = remainder - divider_copy;
        end
        for(int i = 0; i < BIT_GROUPS-1; i++)    begin
            remainder = {remainder[DATA_WIDTH-2:0],quotient[DATA_WIDTH-1]};
            quotient  = quotient << 1 ;
            diff      = remainder - divider_copy;
            if(diff[DATA_WIDTH]) begin
                quotient[0] = 1'b0;
            end else begin
                quotient[0] = 1'b1;
                remainder   = remainder - divider_copy;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : CaptureData
        if(!rst_n) begin
            counter <= 0;
        end else begin
            if(enable && counter==0) begin
                counter        <= CALC_CYCLES-1;
                result_sign    <= sign & dividend[31]^divider[31];
                saved_sign     <= sign & dividend[31];
                quotient_saved <= (!sign || !dividend[31]) ? dividend : ~dividend + 1'b1;
                divider_copy   <= (!sign || !divider[31]) ? divider : ~divider + 1'b1;
                remainder_saved    <= 0;
            end else if(counter!=0) begin
                counter         <= counter -1;
                remainder_saved <= remainder;
                quotient_saved  <= quotient;
            end
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin : Ready
        if(!rst_n) begin
            ready <= 0;
        end else begin
            if(counter==1 && !ready) begin
                ready <= 1;
            end else if(ready) begin
                ready <= 0;
            end
        end
    end
    assign remainder_out = (!saved_sign) ? remainder : ~remainder + 1'b1;
    assign result        = (!result_sign) ? quotient : ~quotient + 1'b1;

`ifdef INCLUDE_SVAS
    `include "division_sva.sv"
`endif

endmodule