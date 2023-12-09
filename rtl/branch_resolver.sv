/*
* @info Branch Resolve Functional Unit
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief Instructions assigned: Branches, Shifts, Compares
*
* @note  Check structs_ex.sv for the structs used.
*
*/
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module branch_resolver #(
	parameter INSTR_BITS     = 32,
	parameter DATA_WIDTH     = 32,
	parameter CSR_ADDR_WIDTH = 20
) (
	input  logic                      clk        ,
	input  logic                      rst_n      ,
	//Input Port
	input  logic                      valid      ,
	input  to_execution               input_data ,
	//Output Port
	output ex_update                  fu_update  ,
	output predictor_update           pr_update  ,
	output logic                      busy_fu    ,
	//CSR R/W Ports
	output logic [CSR_ADDR_WIDTH-1:0] csr_address,
	input  logic [    DATA_WIDTH-1:0] csr_data   ,
	output logic                      csr_wr_en  ,
	output logic [    DATA_WIDTH-1:0] csr_wr_data
);

	logic unsigned [DATA_WIDTH-1 : 0] data_1_u, data_2_u, immediate_u;
	logic signed   [DATA_WIDTH-1 : 0] data_1_s, data_2_s, immediate_s;
	logic          [DATA_WIDTH-1 : 0] result, dummy_jump_address, jump_address;
	logic          [DATA_WIDTH-1 : 0] csri_imm      ;
	logic          [           4 : 0] microoperation, exc_cause;
	logic                             exc_valid, jump_taken, valid_jump, is_comp;
	//Create dummy signals
    assign data_1_u       = $unsigned(input_data.data1);
    assign data_2_u       = $unsigned(input_data.data2);
    assign data_1_s       = $signed(input_data.data1);
    assign data_2_s       = $signed(input_data.data2);
    assign immediate_s    = $signed(input_data.immediate);
    assign immediate_u    = $unsigned(input_data.immediate);
    assign microoperation = input_data.microoperation;
	//Create the output
	assign fu_update.valid           = valid & input_data.valid;
	assign fu_update.destination     = input_data.destination;
	assign fu_update.ticket          = input_data.ticket;
	assign fu_update.data            = result;
	assign fu_update.valid_exception = exc_valid;
	assign fu_update.cause           = exc_cause;
	// Create the Busy Signal for the FU
	assign busy_fu = 'b0;
	//Create the Output for the Predictors' Update
	assign pr_update.valid_jump   = valid & input_data.valid & valid_jump;
	assign pr_update.jump_taken   = jump_taken;
	assign pr_update.is_comp      = is_comp;
	assign pr_update.orig_pc      = input_data.pc;
	assign pr_update.jump_address = jump_address;		//next PC
	assign pr_update.ticket       = input_data.ticket;
	assign pr_update.rat_id       = input_data.rat_id;

	//CSR Signals
	assign csr_address        = input_data.immediate[0+:CSR_ADDR_WIDTH];
	assign csri_imm           = {{27{input_data.immediate[4]}},input_data.immediate};

	assign dummy_jump_address = data_1_u + data_2_u + input_data.pc;
	assign is_comp            = (microoperation==5'b10010) | (microoperation==5'b10011)
	| (microoperation==5'b10100) | (microoperation==5'b10101 );
	// Create the Output based on the desired Operation
	always_comb begin : Operations
		case (microoperation)
			5'b00000: begin
				//SLT
				if(data_1_s<data_2_s) result = 1;
				else 				  result = 0;
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b00001: begin
				//SLTU
				if(data_1_u<data_2_u) result = 1;
				else 				  result = 0;
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b00010: begin
				//SLTI
				if(data_1_s<immediate_s) result = 1;
				else 				     result = 0;
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b00011: begin
				//SLTIU
				if(data_1_u<immediate_u) result = 1;
				else 				     result = 0;
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b00100: begin
				//SLL
				result       = data_1_u << data_2_u[4:0];
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b00101: begin
				//SRL
				result       = data_1_u >> data_2_u[4:0];
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b00110: begin
				//SRA
				result       = data_1_s >>> data_2_u[4:0];
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b00111: begin
				//SLLI/C.SLLI
				result       = data_1_s << immediate_u[4:0];
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b01000: begin
				//SRLI/C.SRLI
				result       = data_1_s >> immediate_u[4:0];
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b01001: begin
				//SRAI/C.SRAI
				result       = data_1_s >>> immediate_u[4:0];
				jump_taken   = 0;
				valid_jump   = 0;
				jump_address = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b01010: begin										// can generate exception
				// JAL
				jump_address = immediate_u + input_data.pc;
				result       = input_data.pc + 4;
				valid_jump   = 1;
				jump_taken   = 1;
				exc_valid    = jump_address[0];
				exc_cause    = 1;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
			5'b01011: begin										// can generate exception
				//JALR
				jump_address    = data_1_u + immediate_u;
				jump_address[0] = 1'b0;
				result          = input_data.pc + 4;
				valid_jump      = 1;
				jump_taken      = 1;
				exc_valid       = jump_address[0];
				exc_cause       = 1;
				csr_wr_en       = 0;
				csr_wr_data     = csri_imm;
			end
			5'b01100: begin
				//BEQ/C.BEQZ
				jump_address = immediate_u + input_data.pc;
				valid_jump   = 1;
				result       = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data     = csri_imm;
				if(data_1_u == data_2_u) jump_taken = 1;
				else 					 jump_taken = 0;
			end
			5'b01101: begin
				//BNE/C.BNEZ
				jump_address = immediate_u + input_data.pc;
				valid_jump   = 1;
				result       = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data     = csri_imm;
				if(data_1_u != data_2_u) jump_taken = 1;
				else 					 jump_taken = 0;
			end
			5'b01110: begin
				//BLT
				jump_address = immediate_u + input_data.pc;
				valid_jump   = 1;
				result       = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data     = csri_imm;
				if(data_1_s < data_2_s) jump_taken = 1;
				else 					jump_taken = 0;
			end
			5'b01111: begin
				//BLTU
				jump_address = immediate_u + input_data.pc;
				valid_jump   = 1;
				result       = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data     = csri_imm;
				if(data_1_u < data_2_u) jump_taken = 1;
				else 					jump_taken = 0;
			end
			5'b10000: begin
				//BGE
				jump_address = immediate_u + input_data.pc;
				valid_jump   = 1;
				result       = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data     = csri_imm;
				if(data_1_s >= data_2_s) jump_taken = 1;
				else 					 jump_taken = 0;
			end
			5'b10001: begin
				//BGEU
				jump_address = immediate_u + input_data.pc;
				valid_jump   = 1;
				result       = 0;
				exc_valid    = 0;
				exc_cause    = 0;
				csr_wr_en    = 0;
				csr_wr_data     = csri_imm;
				if(data_1_u >= data_2_u) jump_taken = 1;
				else 					 jump_taken = 0;
			end
			5'b10010: begin
				//C.JR/C.JALR
				jump_address    = data_1_u;
				result          = input_data.pc + 2;
				valid_jump      = 1;
				jump_taken      = 1;
				exc_valid       = 0;
				exc_cause       = 0;
				csr_wr_en       = 0;
				csr_wr_data     = csri_imm;
			end
			5'b10011: begin
				//C.J/C.JAL
				jump_address    = immediate_u + input_data.pc;
				result          = input_data.pc + 2;
				valid_jump      = 1;
				jump_taken      = 1;
				exc_valid       = 0;
				exc_cause       = 0;
				csr_wr_en       = 0;
				csr_wr_data     = csri_imm;
			end
			5'b10100: begin
				//C.BEQZ
				jump_address    = immediate_u + input_data.pc;
				result          = 0;
				valid_jump      = 1;
				exc_valid       = 0;
				exc_cause       = 0;
				csr_wr_en       = 0;
				csr_wr_data     = csri_imm;
				if(|data_1_u) jump_taken = 0;
				else 		  jump_taken = 1;
			end
			5'b10101: begin
				//C.BNEZ
				jump_address    = immediate_u + input_data.pc;
				result          = 0;
				valid_jump      = 1;
				exc_valid       = 0;
				exc_cause       = 0;
				csr_wr_en       = 0;
				csr_wr_data     = csri_imm;
				if(|data_1_u) jump_taken = 1;
				else 		  jump_taken = 0;
			end
			5'b11000: begin
				//CSRRW
				result          = csr_data; //zero extend?
				jump_address    = 0;
				valid_jump      = 0;
				exc_valid       = 0;
				exc_cause       = 0;
				jump_taken      = 0;
				csr_wr_en       = 1;
				csr_wr_data     = input_data.data1;
			end
			5'b11001: begin
				//CSRRS
				result          = csr_data; //zero extend?
				jump_address    = 0;
				valid_jump      = 0;
				exc_valid       = 0;
				exc_cause       = 0;
				jump_taken      = 0;
				csr_wr_en       = |input_data.data1;
				csr_wr_data     = input_data.data1 | csr_data; //rs1 is mask -> set bits
			end
			5'b11010: begin
				//CSRRC
				result          = csr_data; //zero extend?
				jump_address    = 0;
				valid_jump      = 0;
				exc_valid       = 0;
				exc_cause       = 0;
				jump_taken      = 0;
				csr_wr_en       = |input_data.data1;
				csr_wr_data     = ~input_data.data1 & csr_data; //rs1 is mask -> clear bits
			end
			5'b11011: begin
				//CSRRWI
				result          = csr_data; //zero extend?
				jump_address    = 0;
				valid_jump      = 0;
				exc_valid       = 0;
				exc_cause       = 0;
				jump_taken      = 0;
				csr_wr_en       = 1;
				csr_wr_data     = csri_imm;
			end
			5'b11100: begin
				//CSRRSI
				result          = csr_data; //zero extend?
				jump_address    = 0;
				valid_jump      = 0;
				exc_valid       = 0;
				exc_cause       = 0;
				jump_taken      = 0;
				csr_wr_en       = |csri_imm;
				csr_wr_data     = csri_imm | csr_data; //rs1 is mask -> set bits
			end
			5'b11101: begin
				//CSRRCI
				result          = csr_data; //zero extend?
				jump_address    = 0;
				valid_jump      = 0;
				exc_valid       = 0;
				exc_cause       = 0;
				jump_taken      = 0;
				csr_wr_en       = |csri_imm;
				csr_wr_data     = ~csri_imm & csr_data; //rs1 is mask -> clear bits
			end
			default : begin
				jump_address = 0;
				jump_taken   = 0;
				valid_jump   = 0;
				result       = 0;
				exc_valid    = 1;
				exc_cause    = 2;
				csr_wr_en    = 0;
				csr_wr_data  = csri_imm;
			end
		endcase
	end

endmodule