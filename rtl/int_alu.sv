/*
 * @info Functional Unit: Integer ALU
 * @info Sub-Modules: division.sv, multiply.sv
 *
 * @author VLSI Lab, EE dept., Democritus University of Thrace
 *
 * @note Check structs_ex.sv for the structs used.
 *
 * @param INSTR_BITS    : # of Instruction Bits (default 32 bits)
 * @param DATA_WIDTH    : # of Data Bits (default 32 bits)
*  @param R_ADDR        : # of Register Bits (default 6 bits)
 * @param ROB_INDEX_BITS: # of ROB Ticket Bits (default 3 bits)
 */
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module int_alu #(
    parameter INSTR_BITS     = 32,
    parameter DATA_WIDTH     = 32,
    parameter R_ADDR         = 6 ,
    parameter ROB_INDEX_BITS = 3
) (
    input  logic        clk       ,
    input  logic        rst_n     ,
    // Input Port
    input  logic        valid     ,
    input  to_execution input_data,
    //Output Port
    output ex_update    fu_update ,
    output logic        busy_fu
);
    localparam DIV_CYCLES = 16;
//---------------------------------------------------------------------------------------
    typedef enum logic[1:0] {NORMAL, MUL, DIV} alu_state;
    logic unsigned [DATA_WIDTH-1 : 0] data_1_u,data_2_u;
    logic signed [DATA_WIDTH-1 : 0]   data_1_s,data_2_s;
    logic [DIV_CYCLES-1:0][ROB_INDEX_BITS-1:0]  storage_ticket;
    logic [DATA_WIDTH-1 : 0]           result_comb;
    logic [DIV_CYCLES-1:0][R_ADDR-1:0] storage_destination;
    logic [DIV_CYCLES-1:0][4 : 0]      storage_microop;
	logic [4 : 0]                      microoperation;
    logic [DIV_CYCLES:0]               busy_vector;
    alu_state                          next_state;
    logic                              operation_enable;
//---------------------------------------------------------------------------------------
    logic [2*DATA_WIDTH-1 : 0] result_div, result_mul;
    logic [DATA_WIDTH-1 : 0]   remainder;
    logic                      sign, diff_type, enable_div, enable_mul;
    logic                      div_ready, mul_ready, exc_valid;

    division #(DATA_WIDTH,DIV_CYCLES)
    division(.clk      (clk),
             .rst_n    (rst_n),
             //Inputs
             .enable   (enable_div),
             .sign     (sign),
             .dividend (input_data.data1),
             .divider  (input_data.data2),
             //Outputs
             .ready         (div_ready),
             .result        (result_div),
             .remainder_out (remainder));

    multiply #(DATA_WIDTH)
    multiply(.clk      (clk),
             .rst_n    (rst_n),
             //Inputs
             .enable   (enable_mul),
             .sign     (sign),
             .diff_type(diff_type),
             .data_1   (input_data.data1),
             .data_2   (input_data.data2),
             //Outputs
             .ready     (mul_ready),
             .result    (result_mul));
//---------------------------------------------------------------------------------------
	//create dummy signals
	assign microoperation = input_data.microoperation;
    assign data_1_u = $unsigned(input_data.data1);
    assign data_2_u = $unsigned(input_data.data2);
    assign data_1_s = $signed(input_data.data1);
    assign data_2_s = $signed(input_data.data2);

    assign operation_enable = valid & input_data.valid;
	//create the output
	assign fu_update.valid_exception = (mul_ready | div_ready)? 1'b0 : exc_valid; //Exceptions used for debugging atm
	assign fu_update.cause           = 2;					                      //Exceptions used for debugging atm
    assign fu_update.valid           = (valid & input_data.valid & (next_state==NORMAL)) | mul_ready | div_ready;

    // Push the correct data to the Output
    always_comb begin : Outputs
        if(mul_ready) begin
            fu_update.destination = storage_destination[2];
            fu_update.ticket      = storage_ticket[2];
            if(storage_microop[2]==5'b00010) begin
                //MUL (lower 32bits)
                fu_update.data        = result_mul[DATA_WIDTH-1:0];
            end else begin
                //MULH/MULHU/MULHSU
                fu_update.data        = result_mul[2*DATA_WIDTH-1:DATA_WIDTH];
            end
        end else if(div_ready) begin
            fu_update.destination = storage_destination[DIV_CYCLES-1];
            fu_update.ticket      = storage_ticket[DIV_CYCLES-1];
            if(storage_microop[DIV_CYCLES-1]==5'b00110 || storage_microop[DIV_CYCLES-1]==5'b00111) begin
                //DIV/DIVU
                fu_update.data        = result_div[DATA_WIDTH-1:0];
            end else if(storage_microop[DIV_CYCLES-1]==5'b01000 || storage_microop[DIV_CYCLES-1]==5'b01001) begin
                //REM/REMU
                fu_update.data        = remainder[DATA_WIDTH-1:0];
            end else begin
                fu_update.data        = result_div[DATA_WIDTH-1:0];
            end
        end else begin
            fu_update.destination = input_data.destination;
            fu_update.ticket      = input_data.ticket;
            fu_update.data        = result_comb;
        end
    end

// Create the Output based on the desired Operation
always_comb begin : Operations
    case (microoperation)
        5'b00000: begin
            //ADD
            enable_mul = 0;
            enable_div = 0;
            sign       = 0;
            diff_type  = 0;
            next_state = NORMAL;
            result_comb = data_1_u + data_2_u;
            exc_valid  = 0;
        end
        5'b00001: begin
            //SUB
            enable_mul = 0;
            enable_div = 0;
            sign       = 0;
            diff_type  = 0;
            next_state = NORMAL;
            result_comb = data_1_u - data_2_u;
            exc_valid  = 0;
        end
        5'b00010: begin
            //MUL (lower 32bits)
            sign       = 1;
            enable_mul = operation_enable;
            enable_div = 0;
            diff_type  = 0;
            next_state = MUL;
            result_comb = 0;
            exc_valid  = 0;
        end
        5'b00011: begin
            //MULH (upper 32bits)
            sign       = 1;
            enable_mul = operation_enable;
            enable_div = 0;
            diff_type  = 0;
            next_state = MUL;
            result_comb = 0;
            exc_valid  = 0;
        end
        5'b00100: begin
            //MULHU (upper 32bits)
            sign       = 0;
            enable_mul = operation_enable;
            enable_div = 0;
            diff_type  = 0;
            next_state = MUL;
            result_comb = 0;
            exc_valid  = 0;
        end
        5'b00101: begin
            //MULHSU (upper 32bits) (signed*unsigned)
            sign       = 1;
            enable_mul = operation_enable;
            enable_div = 0;
            diff_type  = 1;
            next_state = MUL;
            result_comb = 0;
            exc_valid  = 0;
        end
        5'b00110: begin
            //DIV
            if(input_data.data2==0) begin            //Division by zero
                next_state = NORMAL;
                result_comb = -1;
                enable_div = 0;
            end else if(input_data.data1=='b1 && input_data.data2==-1) begin //OverFlow
                next_state = NORMAL;
                result_comb = input_data.data1;
                enable_div = 0;
            end else begin
                next_state = DIV;
                enable_div = operation_enable;
                result_comb = 0;
            end
            sign       = 1;
            enable_mul = 0;
            diff_type  = 0;
            exc_valid  = 0;
        end
        5'b00111: begin
            //DIVU
            if(input_data.data2==0) begin            //Division by zero
                next_state = NORMAL;
                enable_div = 0;
                result_comb = 'b1;
            end else begin
                next_state = DIV;
                enable_div = operation_enable;
                result_comb = 0;
            end
            sign       = 0;
            enable_mul = 0;
            diff_type  = 0;
            exc_valid  = 0;
        end
        5'b01000: begin
            //REM
            if(input_data.data2==0) begin            //Division by zero
                next_state = NORMAL;
                enable_div = 0;
                result_comb = input_data.data1;
            end else if(input_data.data1=='b1 && input_data.data2==-1) begin //OverFlow
                next_state = NORMAL;
                result_comb = 'b0;
                enable_div = 0;
            end else begin
                next_state = DIV;
                enable_div = operation_enable;
                result_comb = 0;
            end
            sign       = 1;
            enable_mul = 0;
            diff_type  = 0;
            exc_valid  = 0;
        end
        5'b01001: begin
            //REMU
            if(input_data.data2==0) begin            //Division by zero
                next_state = NORMAL;
                enable_div = 0;
                result_comb = input_data.data1;
            end else begin
                next_state = DIV;
                enable_div = operation_enable;
                result_comb = 0;
            end
            sign       = 0;
            enable_mul = 0;
            diff_type  = 0;
            exc_valid  = 0;
        end
        5'b01010: begin
            //AND/ANDI/C.ANDI/C.AND
            enable_mul = 0;
            enable_div = 0;
            sign       = 0;
            diff_type  = 0;
            next_state = NORMAL;
            result_comb = data_1_u & data_2_u;
            exc_valid  = 0;
        end
        5'b01011: begin
            //OR/ORI/C.OR
            enable_mul = 0;
            enable_div = 0;
            sign       = 0;
            diff_type  = 0;
            next_state = NORMAL;
            result_comb = data_1_u | data_2_u;
            exc_valid  = 0;
        end
        5'b01100: begin
            //XOR/XORI/C.XOR
            enable_mul = 0;
            enable_div = 0;
            sign       = 0;
            diff_type  = 0;
            next_state = NORMAL;
            result_comb = data_1_u ^ data_2_u;
            exc_valid  = 0;
        end
        default: begin
            sign       = 0;
            enable_mul = 0;
            enable_div = 0;
            result_comb = 0;
            diff_type  = 0;
            next_state = NORMAL;
            exc_valid  = 1;
        end
    endcase
end


//Maintain Busy Bit Vector
logic [DIV_CYCLES:0] busy_vector_shifted;
logic [DIV_CYCLES:0] nxt_busy_vector;
assign busy_vector_shifted = busy_vector <<1;
assign nxt_busy_vector = (next_state==MUL & operation_enable) ? busy_vector_shifted | 17'b00100000000000000 :
                         (next_state==DIV & operation_enable) ? busy_vector_shifted | 17'b01111111111111110 :
                                                                busy_vector_shifted;
always_ff @(posedge clk or negedge rst_n) begin : BusyVector
    if(!rst_n) begin
        busy_vector <= 'b0;
    end else begin
        busy_vector <= nxt_busy_vector;
    end
end
//Create the Busy Output
assign busy_fu = busy_vector[DIV_CYCLES-1] | (next_state == DIV & operation_enable);

//Store some Bookkeeping for later completion
always_ff @(posedge clk) begin : Storage
    for (int i = DIV_CYCLES-1; i > 0; i--) begin
        storage_destination[i] <= storage_destination[i-1];
        storage_ticket[i]      <= storage_ticket[i-1];
        storage_microop[i]     <= storage_microop[i-1];
    end
    storage_destination[0] <= input_data.destination;
    storage_ticket[0]      <= input_data.ticket;
    storage_microop[0]     <= input_data.microoperation;
end

endmodule