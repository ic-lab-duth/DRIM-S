/*-------------------------------------------------------------------------------	
	Decription: 
	This is a template class which returns random instructions for RISC-V ISA

	It contains also an implementation for a checker for the register file and the
	memory containing the data. 
	When we receive an instruction that writes back to a destination register,
	we update the expected register file.
	When we receive an instruction that is either load or store, 
	we update the expected memory_file 

	Functions:
	get_string_instruction()      : returns a string representation of the assembly instruction
	get_rd_used()                 : returns a logic that indicates if we used the destination register
	get_register_file_expected()  : returns the regiter file array
	set_rf_zero()                 : void, sets rf[0]=0
	initialize_memory()           : void, creates the data memory
	get_memory_final()            : returns the memory array
	get_rs1_value()               : returns rf[rs1]
	get_rs2_value()               : returns rf[rs2]

--------------------------------------------------------------------------------*/

import type_definitions_pkg::*;
import tb_util_pkg::*;
import simulation_parameters_pkg::*;

class instruction;


	
	typedef logic [511:0] mem[21];
	R_type_instruction R_instr;
	I_type_instruction I_instr;
	S_type_instruction S_instr;
	SB_type_instruction SB_instr;
	U_type_instruction U_instr;
	UJ_type_instruction UJ_instr;

	int data_memory_line;

	randc instructions instruction; // instruction's identifier
	logic [31:0] instruction_out; // outputed 32 bit instruction
	string string_instruction; // assembly format of the returned instrruction

	logic [31:0] immediate; // expected immediate 
	logic [63:0] mult_result;
	logic [31:0] unsigned_data;
	logic [31:0] unsigned_immediate;

	static rf_array register_file_expected; // array to store expected register file
	static mem data_memory; // array to store the data memory

	/*---------------------------------------------------------------------	
		Variables for calculation of memory address for loads/stores
	----------------------------------------------------------------------*/
    logic [31:0] calculated_load_store_address;
    int line_address;
    int memory_address_position;
    int starting_bit;
    //---------------------------------------------------------------------	

    logic [15:0] l_h;
    logic [7:0] l_b;

	logic rd_used = 0; // rd_used=1 if we use a destinaion register for writeback


	/*---------------------------------------------------------------------	
							Identifiers to randomize
	----------------------------------------------------------------------*/
	logic [5:0] rs1; // source operand 1
	logic [5:0] rs2; // source operand 2
	rand logic [4:0] rd; // destination register
	rand logic [11:0] imm12; // 12-bit immediate
	rand logic [19:0] imm20; // 20-bit immediate
	rand bit[11:0] immed_12;
	rand bit[11:0] rs1_value;
	int immed_s;
	//---------------------------------------------------------------------	

	constraint rd_not_zero{
		rd != 0; 
	}

	// Distribution of the instruction's identifier. From here we can choose the 
	// weight and which instructions will be returned. 
	int DATA_MEMORY_LOWER, DATA_MEMORY_UPPER;

	constraint instructions_distribution {
		instruction dist {
			SLL    := SHIFTS_DIST,
			SRL    := SHIFTS_DIST,
			SRA    := SHIFTS_DIST,
			SLLI   := SHIFTS_DIST,
			SRLI   := SHIFTS_DIST,
			SRAI   := SHIFTS_DIST,
			ADD    := OPERATIONS_DIST,
			SUB    := OPERATIONS_DIST,
			XOR    := OPERATIONS_DIST,
			OR     := OPERATIONS_DIST,
			AND    := OPERATIONS_DIST,
			ADDI   := OPERATIONS_DIST,
			XORI   := OPERATIONS_DIST,
			ORI    := OPERATIONS_DIST,
			ANDI   := OPERATIONS_DIST,
			MUL    := OPERATIONS_DIST,
			MULH   := OPERATIONS_DIST,
			MULHU  := OPERATIONS_DIST,
			MULHSU := OPERATIONS_DIST,
			DIV    := DIV_DIST,
			DIVU   := DIV_DIST,
			SLT    := COMPARES_DIST,
			SLTU   := COMPARES_DIST,
			SLTI   := COMPARES_DIST,
			SLTIU  := COMPARES_DIST,
			LB     := LOADS_DIST,
			LH     := LOADS_DIST,
			LW     := LOADS_DIST,
			LBU    := LOADS_DIST,
			LHU    := LOADS_DIST,
			SB     := STORES_DIST,
			SH     := STORES_DIST,
			SW     := STORES_DIST
		};
	}
	

	
	function new();
		data_memory_line = 21;
	endfunction : new


	/*---------------------------------------------------------------------	
		function get_instruction();

		Description: 
		According to the instruction operand (which is a rand data member
		of this class) we:
		1) create the 32-bit instruction 
		2) we create the string format of the assembly of the instruction
		3) We update the expected register file and memory file

		Returns: A 32-bit instruction	
	----------------------------------------------------------------------*/
	function logic [31:0] get_instruction();
		

		case (instruction)

		/*---------------------------------------------------------------------
					R-type integer unit			
		----------------------------------------------------------------------*/		
			ADD: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 0;
				R_instr.funct7 = 0;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"ADD"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) + $unsigned(register_file_expected[rs2]);
			end

			SUB: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 0;
				R_instr.funct7 = 7'b0100000;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"SUB"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) - $unsigned(register_file_expected[rs2]);
			end

			XOR: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b100;
				R_instr.funct7 = 0;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"XOR"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) ^ $unsigned(register_file_expected[rs2]);
			end

			OR: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b110;
				R_instr.funct7 = 0;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"OR"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) | $unsigned(register_file_expected[rs2]);
			end

			AND: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b111;
				R_instr.funct7 = 0;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"AND"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) & $unsigned(register_file_expected[rs2]);
			end

			MUL: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b000;
				R_instr.funct7 = 7'b0000001;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"MUL"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				mult_result = $signed(register_file_expected[rs1]) * $signed(register_file_expected[rs2]);
				register_file_expected[rd] = mult_result[31:0];
			end

			MULH: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b001;
				R_instr.funct7 = 7'b0000001;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"MULH"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				mult_result = $signed(register_file_expected[rs1]) * $signed(register_file_expected[rs2]);
				register_file_expected[rd] = mult_result[63:32];
			end

			MULHU: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b011;
				R_instr.funct7 = 7'b0000001;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"MULHU"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				mult_result = $unsigned(register_file_expected[rs1]) * $unsigned(register_file_expected[rs2]);
				register_file_expected[rd] = mult_result[63:32];
			end

			MULHSU: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b010;
				R_instr.funct7 = 7'b0000001;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"MULHSU"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				mult_result = $signed(register_file_expected[rs1]) * $unsigned(register_file_expected[rs2]);
				register_file_expected[rd] = mult_result[63:32];
			end

			DIV: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b100;
				R_instr.funct7 = 7'b0000001;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"DIV"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				if(register_file_expected[rs2] != 0) begin
					register_file_expected[rd] = $signed(register_file_expected[rs1]) / $signed(register_file_expected[rs2]);
				end
			end

			DIVU: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b101;
				R_instr.funct7 = 7'b0000001;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"DIVU"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				if(register_file_expected[rs2] != 0) begin
					register_file_expected[rd] = $unsigned(register_file_expected[rs1]) / $unsigned(register_file_expected[rs2]);
				end
			end

			REM: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b110;
				R_instr.funct7 = 7'b0000001;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"REM"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				if(register_file_expected[rs2] != 0) begin
					register_file_expected[rd] = $signed(register_file_expected[rs1]) % $signed(register_file_expected[rs2]);
				end
			end

			REMU: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b111;
				R_instr.funct7 = 7'b0000001;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"REMU"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				if(register_file_expected[rs2] != 0) begin
					register_file_expected[rd] = $unsigned(register_file_expected[rs1]) % $unsigned(register_file_expected[rs2]);
				end
			end

			

		//---------------------------------------------------------------------	



		/*---------------------------------------------------------------------
					R-type branches unit			
		----------------------------------------------------------------------*/
			SLL: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b001;
				R_instr.funct7 = 0;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"SLL"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				unsigned_data = $unsigned(register_file_expected[rs2]);
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) << unsigned_data[4:0]; 
			end

			SRL: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b101;
				R_instr.funct7 = 0;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"SRL"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				unsigned_data = $unsigned(register_file_expected[rs2]);
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) >> unsigned_data[4:0];
			end

			SRA: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b101;
				R_instr.funct7 = 7'b0100000;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"SRA"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				unsigned_data = $unsigned(register_file_expected[rs2]);
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) >>> unsigned_data[4:0];
			end

			SLT: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b010;
				R_instr.funct7 = 0;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"SLT"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				if( $signed(register_file_expected[rs1]) < $signed(register_file_expected[rs2]) ) begin
					register_file_expected[rd] = 1;
				end
				else begin
					register_file_expected[rd] = 0;
				end
			end

			SLTU: begin

				R_instr.rs1 = rs1;
				R_instr.rd = rd;
				R_instr.rs2 = rs2;
				R_instr.funct3 = 3'b011;
				R_instr.funct7 = 0;
				R_instr.opcode = 7'b0110011;
				instruction_out = R_instr;
				string_instruction = {"SLTU"," ",$sformatf("%0d",R_instr.rd),",",$sformatf("%0d",R_instr.rs1),",",$sformatf("%0d",R_instr.rs2)};
				rd_used = 1;
				if( $unsigned(register_file_expected[rs1]) < $unsigned(register_file_expected[rs2]) ) begin
					register_file_expected[rd] = 1;
				end
				else begin
					register_file_expected[rd] = 0;
				end
			end

			
		//---------------------------------------------------------------------	


		/*---------------------------------------------------------------------
					I-type load/store unit			
		----------------------------------------------------------------------*/
			LB: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = immed_12;
				I_instr.funct3 = 3'b000;
				I_instr.opcode = 7'b0000011;
				instruction_out = I_instr;
				immediate = {{20{immed_12[11]}},immed_12};
				immed_s = immed_12;
				string_instruction = {"LB"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immed_s)};
				rd_used = 1;
				calculated_load_store_address = register_file_expected[rs1] + immediate;
				line_address = (calculated_load_store_address / 64)+1;
				//if((calculated_load_store_address % 64) == 0)	 line_address--;
				memory_address_position = (64*line_address-4) - calculated_load_store_address;
				starting_bit = 511-((memory_address_position/4)*32);
				 l_b = data_memory[line_address-1][(starting_bit-24) -: 8];
				 register_file_expected[rd] = {{24{l_b[7]}},l_b};
				
			end

			LH: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = immed_12;
				I_instr.funct3 = 3'b001;
				I_instr.opcode = 7'b0000011;
				instruction_out = I_instr;
				immediate = {{20{immed_12[11]}},immed_12};
				immed_s = immed_12;
				string_instruction = {"LH"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immed_s)};
				rd_used = 1;
				calculated_load_store_address = register_file_expected[rs1] + immediate;
				line_address = (calculated_load_store_address / 64)+1;
				//if((calculated_load_store_address % 64) == 0)	 line_address--;
				memory_address_position = (64*line_address-4) - calculated_load_store_address;
				starting_bit = 511-((memory_address_position/4)*32);
				 l_h = data_memory[line_address-1][(starting_bit-16) -: 16];
				 register_file_expected[rd] = {{16{l_h[15]}},l_h};
				
			end

			LW: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = immed_12;
				I_instr.funct3 = 3'b010;
				I_instr.opcode = 7'b0000011;
				instruction_out = I_instr;
				immediate = {{20{immed_12[11]}},immed_12};
				immed_s = immed_12;
				string_instruction = {"LW"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immed_s)};
				// string_instruction = {"LW"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",I_instr.imm_11to0)};
				rd_used = 1;
				calculated_load_store_address = register_file_expected[rs1] + immediate;
				line_address = (calculated_load_store_address / 64)+1;
				//if((calculated_load_store_address % 64) == 0)	 line_address--;
				memory_address_position = (64*line_address-4) - calculated_load_store_address;
				starting_bit = 511-((memory_address_position/4)*32);
				register_file_expected[rd] = data_memory[line_address-1][starting_bit -: 32];
			end

			LBU: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = immed_12;
				I_instr.funct3 = 3'b100;
				I_instr.opcode = 7'b0000011;
				instruction_out = I_instr;
				immediate = {{20{immed_12[11]}},immed_12};
				immed_s = immed_12;
				string_instruction = {"LBU"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immed_s)};
				rd_used = 1;
				calculated_load_store_address = register_file_expected[rs1] + immediate;
				line_address = (calculated_load_store_address / 64)+1;
				//if((calculated_load_store_address % 64) == 0)	 line_address--;
				memory_address_position = (64*line_address-4) - calculated_load_store_address;
				starting_bit = 511-((memory_address_position/4)*32);
				 l_b = data_memory[line_address-1][(starting_bit-24) -: 8];
				 register_file_expected[rd] = {{24{1'b0}},l_b};
				
			end

			LHU: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = immed_12;
				I_instr.funct3 = 3'b101;
				I_instr.opcode = 7'b0000011;
				instruction_out = I_instr;
				immediate = {{20{immed_12[11]}},immed_12};
				immed_s = immed_12;
				string_instruction = {"LHU"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immed_s)};
				rd_used = 1;
				calculated_load_store_address = register_file_expected[rs1] + immediate;
				line_address = (calculated_load_store_address / 64)+1;
				//if((calculated_load_store_address % 64) == 0)	 line_address--;
				memory_address_position = (64*line_address-4) - calculated_load_store_address;
				starting_bit = 511-((memory_address_position/4)*32);
				 l_h = data_memory[line_address-1][(starting_bit-16) -: 16];
				 register_file_expected[rd] = {{16{1'b0}},l_h};
				
			end

		//---------------------------------------------------------------------	



		/*---------------------------------------------------------------------
					I-type Integer unit			
		----------------------------------------------------------------------*/
			ADDI: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = imm12;
				I_instr.funct3 = 3'b000;
				I_instr.opcode = 7'b0010011;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"ADDI"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate)};
				rd_used = 1;
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) + $unsigned(immediate);
				
			end

			XORI: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = imm12;
				I_instr.funct3 = 3'b100;
				I_instr.opcode = 7'b0010011;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"XORI"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate)};
				rd_used = 1;
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) ^ $unsigned(immediate);
				
			end

			ORI: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = imm12;
				I_instr.funct3 = 3'b110;
				I_instr.opcode = 7'b0010011;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"ORI"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate)};
				rd_used = 1;
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) | $unsigned(immediate);
				
			end

			ANDI: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = imm12;
				I_instr.funct3 = 3'b111;
				I_instr.opcode = 7'b0010011;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"ANDI"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate)};
				rd_used = 1;
				register_file_expected[rd] = $unsigned(register_file_expected[rs1]) & $unsigned({{20{imm12[11]}},imm12});
				
			end


		/*---------------------------------------------------------------------
					I-type branches unit			
		----------------------------------------------------------------------*/

			

			SLLI: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = {{7'b0000000},imm12[4:0]};
				I_instr.funct3 = 3'b001;
				I_instr.opcode = 7'b0010011;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"SLLI"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate[4:0])};
				rd_used = 1;
				unsigned_immediate = $unsigned(immediate);
				register_file_expected[rd] = $signed(register_file_expected[rs1]) << imm12[4:0];
				
			end

			SRLI: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = {{7'b0000000},imm12[4:0]};
				I_instr.funct3 = 3'b101;
				I_instr.opcode = 7'b0010011;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"SRLI"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate[4:0])};
				rd_used = 1;
				unsigned_immediate = $unsigned(immediate);
				register_file_expected[rd] = $signed(register_file_expected[rs1]) >> imm12[4:0];
				
			end


			SRAI: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = {{7'b0100000},imm12[4:0]};
				I_instr.funct3 = 3'b101;
				I_instr.opcode = 7'b0010011;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"SRAI"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate[4:0])};
				rd_used = 1;
				unsigned_immediate = $unsigned(immediate);
				register_file_expected[rd] = $signed(register_file_expected[rs1]) >>> imm12[4:0];
				
			end

			SLTI: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = imm12;
				I_instr.funct3 = 3'b010;
				I_instr.opcode = 7'b0010011;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"SLTI"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate)};
				rd_used = 1;
				if( $signed(register_file_expected[rs1]) < $signed(immediate) ) begin
					register_file_expected[rd] = 1;
				end
				else begin
					register_file_expected[rd] = 0;
				end
				
			end

			SLTIU: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = imm12;
				I_instr.funct3 = 3'b011;
				I_instr.opcode = 7'b0010011;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"SLTIU"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate)};
				rd_used = 1;
				if( $unsigned(register_file_expected[rs1]) < $unsigned(immediate) ) begin
					register_file_expected[rd] = 1;
				end
				else begin
					register_file_expected[rd] = 0;
				end
				
			end

			JALR: begin

				I_instr.rs1 = rs1;
				I_instr.rd = rd;
				I_instr.imm_11to0 = imm12;
				I_instr.funct3 = 3'b000;
				I_instr.opcode = 7'b1100111;
				instruction_out = I_instr;
				immediate = {{20{imm12[11]}},imm12};
				string_instruction = {"JALR"," ",$sformatf("%0d",I_instr.rd),",",$sformatf("%0d",I_instr.rs1),",",$sformatf("%0d",immediate)};
				rd_used = 1;
				
			end
		//---------------------------------------------------------------------	


		/*---------------------------------------------------------------------
					S-type load/store unit			
		----------------------------------------------------------------------*/
			SB: begin

				S_instr.imm_11to5 = immed_12[11:5];
				S_instr.rs2 = rs2;				
				S_instr.rs1 = rs1;
				S_instr.funct3 = 3'b000;
				S_instr.imm_4to0 = immed_12[4:0];				
				S_instr.opcode = 7'b0100011;
				instruction_out = S_instr;
				immediate = {{20{immed_12[11]}},immed_12};
				immed_s = immed_12;
				string_instruction = {"SB"," ",$sformatf("%0d",S_instr.rs1),",",$sformatf("%0d",S_instr.rs2),",",$sformatf("%0d",immed_s)};
				calculated_load_store_address = register_file_expected[rs1] + immediate;
				line_address = (calculated_load_store_address / 64)+1;
				//if((calculated_load_store_address % 64) == 0)	 line_address--;
				memory_address_position = (64*line_address-4) - calculated_load_store_address;
				starting_bit = 511-((memory_address_position/4)*32);
				data_memory[line_address-1][(starting_bit-24) -: 8] = register_file_expected[rs2][7:0]; 
				
				
			end

			SH: begin

				S_instr.imm_11to5 = immed_12[11:5];
				S_instr.rs2 = rs2;				
				S_instr.rs1 = rs1;
				S_instr.funct3 = 3'b001;
				S_instr.imm_4to0 = immed_12[4:0];				
				S_instr.opcode = 7'b0100011;
				instruction_out = S_instr;
				immediate = {{20{immed_12[11]}},immed_12};
				immed_s = immed_12;
				string_instruction = {"SH"," ",$sformatf("%0d",S_instr.rs1),",",$sformatf("%0d",S_instr.rs2),",",$sformatf("%0d",immed_s)};
				calculated_load_store_address = register_file_expected[rs1] + immediate;
				line_address = (calculated_load_store_address / 64)+1;
				//if((calculated_load_store_address % 64) == 0)	 line_address--;
				memory_address_position = (64*line_address-4) - calculated_load_store_address;
				starting_bit = 511-((memory_address_position/4)*32);
				data_memory[line_address-1][(starting_bit-16) -: 16] = register_file_expected[rs2][15:0]; 

				
				
			end

			SW: begin

				S_instr.imm_11to5 = immed_12[11:5];
				S_instr.rs2 = rs2;				
				S_instr.rs1 = rs1;
				S_instr.funct3 = 3'b010;
				S_instr.imm_4to0 = immed_12[4:0];				
				S_instr.opcode = 7'b0100011;
				instruction_out = S_instr;
				immediate = {{20{immed_12[11]}},immed_12};
				immed_s = immed_12;
				string_instruction = {"SW"," ",$sformatf("%0d",S_instr.rs1),",",$sformatf("%0d",S_instr.rs2),",",$sformatf("%0d",immed_s)};
				calculated_load_store_address = register_file_expected[rs1] + immediate;
				line_address = (calculated_load_store_address / 64)+1;
				//if((calculated_load_store_address % 64) == 0)	 line_address--;
				memory_address_position = (64*line_address-4) - calculated_load_store_address;
				starting_bit = 511-((memory_address_position/4)*32);
				data_memory[line_address-1][starting_bit -: 32] = register_file_expected[rs2];
				
			end

		//---------------------------------------------------------------------	



		/*---------------------------------------------------------------------
					SB-type branches unit			
		----------------------------------------------------------------------*/

			BEQ: begin

				SB_instr.imm_12 = imm12[11];
				SB_instr.imm_10to5 = imm12[9:4];								
				SB_instr.rs2 = rs2;				
				SB_instr.rs1 = rs1;
				SB_instr.funct3 = 3'b000;
				SB_instr.imm_4to1 = imm12[3:0];	
				SB_instr.imm_11 = imm12[10];							
				SB_instr.opcode = 7'b1100011;
				instruction_out = SB_instr;
				string_instruction = {"BEQ"," ",$sformatf("%0d",SB_instr.rs1),",",$sformatf("%0d",SB_instr.rs2),",",$sformatf("%0d",{{19{imm12[11]}},imm12,1'b0})};
				
			end

			BNE: begin

				SB_instr.imm_12 = imm12[11];
				SB_instr.imm_10to5 = imm12[9:4];								
				SB_instr.rs2 = rs2;				
				SB_instr.rs1 = rs1;
				SB_instr.funct3 = 3'b001;
				SB_instr.imm_4to1 = imm12[3:0];	
				SB_instr.imm_11 = imm12[10];							
				SB_instr.opcode = 7'b1100011;
				instruction_out = SB_instr;
				string_instruction = {"BNE"," ",$sformatf("%0d",SB_instr.rs1),",",$sformatf("%0d",SB_instr.rs2),",",$sformatf("%0d",{{19{imm12[11]}},imm12,1'b0})};
				
			end

			BLT: begin

				SB_instr.imm_12 = imm12[11];
				SB_instr.imm_10to5 = imm12[9:4];								
				SB_instr.rs2 = rs2;				
				SB_instr.rs1 = rs1;
				SB_instr.funct3 = 3'b100;
				SB_instr.imm_4to1 = imm12[3:0];	
				SB_instr.imm_11 = imm12[10];							
				SB_instr.opcode = 7'b1100011;
				instruction_out = SB_instr;
				string_instruction = {"BLT"," ",$sformatf("%0d",SB_instr.rs1),",",$sformatf("%0d",SB_instr.rs2),",",$sformatf("%0d",{{19{imm12[11]}},imm12,1'b0})};
				
			end

			BGE: begin

				SB_instr.imm_12 = imm12[11];
				SB_instr.imm_10to5 = imm12[9:4];								
				SB_instr.rs2 = rs2;				
				SB_instr.rs1 = rs1;
				SB_instr.funct3 = 3'b101;
				SB_instr.imm_4to1 = imm12[3:0];	
				SB_instr.imm_11 = imm12[10];							
				SB_instr.opcode = 7'b1100011;
				instruction_out = SB_instr;
				string_instruction = {"BGE"," ",$sformatf("%0d",SB_instr.rs1),",",$sformatf("%0d",SB_instr.rs2),",",$sformatf("%0d",{{19{imm12[11]}},imm12,1'b0})};
				
			end

			BLTU: begin

				SB_instr.imm_12 = imm12[11];
				SB_instr.imm_10to5 = imm12[9:4];								
				SB_instr.rs2 = rs2;				
				SB_instr.rs1 = rs1;
				SB_instr.funct3 = 3'b110;
				SB_instr.imm_4to1 = imm12[3:0];	
				SB_instr.imm_11 = imm12[10];							
				SB_instr.opcode = 7'b1100011;
				instruction_out = SB_instr;
				string_instruction = {"BLTU"," ",$sformatf("%0d",SB_instr.rs1),",",$sformatf("%0d",SB_instr.rs2),",",$sformatf("%0d",{{19{imm12[11]}},imm12,1'b0})};
				
			end

			BGEU: begin

				SB_instr.imm_12 = imm12[11];
				SB_instr.imm_10to5 = imm12[9:4];								
				SB_instr.rs2 = rs2;				
				SB_instr.rs1 = rs1;
				SB_instr.funct3 = 3'b111;
				SB_instr.imm_4to1 = imm12[3:0];	
				SB_instr.imm_11 = imm12[10];							
				SB_instr.opcode = 7'b1100011;
				instruction_out = SB_instr;
				string_instruction = {"BGEU"," ",$sformatf("%0d",SB_instr.rs1),",",$sformatf("%0d",SB_instr.rs2),",",$sformatf("%0d",{{19{imm12[11]}},imm12,1'b0})};
				
			end

		//---------------------------------------------------------------------	


		/*---------------------------------------------------------------------
					U-type integer unit			
		----------------------------------------------------------------------*/

			LUI: begin

				U_instr.imm_31to12 = imm20;	
				U_instr.rd = rd;							
				U_instr.opcode = 7'b0110111;
				instruction_out = U_instr;
				string_instruction = {"LUI"," ",$sformatf("%0d",U_instr.rd),",",$sformatf("%0d",imm20)};
				rd_used = 1;
				
			end	

			AUIPC: begin

				U_instr.imm_31to12 = imm20;	
				U_instr.rd = rd;							
				U_instr.opcode = 7'b0010111;
				instruction_out = U_instr;
				string_instruction = {"AUIPC"," ",$sformatf("%0d",U_instr.rd),",",$sformatf("%0d",{imm20,12'b000000000000})};
				rd_used = 1;
				
			end		
	


		//---------------------------------------------------------------------	



		/*---------------------------------------------------------------------
					UJ-type integer unit			
		----------------------------------------------------------------------*/

			JAL: begin

				UJ_instr.imm_20 = imm20[19];
				UJ_instr.imm_10to1 = imm20[9:0];
				UJ_instr.imm_11 = imm20[10];
				UJ_instr.imm_19to12 = imm20[18:11];
				UJ_instr.rd = rd;							
				UJ_instr.opcode = 7'b1101111;
				instruction_out = UJ_instr;
				string_instruction = {"JAL"," ",$sformatf("%0d",UJ_instr.rd),",",$sformatf("%0d",{{12{imm20[19]}},imm20,1'b0})};
				rd_used = 1;
				
			end	
		//---------------------------------------------------------------------	

		endcase

		


/*$display("
	calculated_load_store_address= %0d,
	line_address= %0d,
	memory_address_position=%0d,
	starting_bit=%0d,
	data_memory[line_address-1][(starting_bit-16) -: 16]=%b,
	data_memory[19][15:0]=%b,
	register_file_expected[rs2][15:0]
	",calculated_load_store_address,line_address,memory_address_position,starting_bit,data_memory[line_address-1][(starting_bit-16) -: 16],data_memory[19][15:0],register_file_expected[rs2][15:0]);

		$display("rf[rd]=%0d",register_file_expected[rd]); */


		return instruction_out;

	endfunction : get_instruction





	//debugging
	function void display_fields();
		//$display("rd=%0d,rs1= %0d,rs2=%0d,imm12=%0d,imm20=%0d",rd,rs1,rs2,imm12,imm20);
	endfunction : display_fields

	/*-----------------------------------------------------------------------------------	
		function get_string_instruction();

		Description: This function returnes the string format of the assembly instruction
	-----------------------------------------------------------------------------------*/
	function string get_string_instruction();
		return string_instruction;
	endfunction : get_string_instruction
	
	/*-----------------------------------------------------------------------------------	
		function get_rd_used();

		Description: This function returnes a boolean which indicates if we have used the
		destination register
	-----------------------------------------------------------------------------------*/
	function logic get_rd_used();
		return rd_used;
	endfunction : get_rd_used
	
	/*-----------------------------------------------------------------------------------	
		function get_register_file_expected();

		Description: This function returnes the register file
	-----------------------------------------------------------------------------------*/
	function rf_array get_register_file_expected();
		return register_file_expected;
	endfunction : get_register_file_expected

	/*-----------------------------------------------------------------------------------	
		function set_rf_zero();

		Description: This function sets rf[0]=0
	-----------------------------------------------------------------------------------*/
	function void set_rf_zero();
		register_file_expected[0] = 0;
	endfunction : set_rf_zero
	
	/*-----------------------------------------------------------------------------------	
		function initialize_memory();

		Description: This function creates an instance of the memory that holds the data
	-----------------------------------------------------------------------------------*/
	function void initialize_memory();
		for (int i = 0; i < (data_memory_line-1); i++) begin
			data_memory[i] = 'b0;
		end
		data_memory[data_memory_line] = 512'h000000100000000F0000000E0000000D0000000C0000000B0000000A000000090000000800000007000000060000000500000004000000030000000200000001;
		data_memory[data_memory_line+1] = 512'h0000001F0000001E0000001D0000001C0000001B0000001A00000019000000180000001700000016000000150000001400000013000000120000001100000010;
	endfunction : initialize_memory

	/*-----------------------------------------------------------------------------------	
		function get_memory_final();

		Description: This function returnes the data memory array
	-----------------------------------------------------------------------------------*/
	function mem get_memory_final();
		return data_memory;	
	endfunction : get_memory_final

	/*-----------------------------------------------------------------------------------	
		function get_rs1_value();

		Description: This function returnes a value stored in the register file. The position
		is specified by the source operand 1
	-----------------------------------------------------------------------------------*/
	function logic [31:0] get_rs1_value();
		return register_file_expected[rs1];
	endfunction : get_rs1_value

	/*-----------------------------------------------------------------------------------	
		function get_rs2_value();

		Description: This function returnes a value stored in the register file. The position
		is specified by the source operand 1
	-----------------------------------------------------------------------------------*/
	function logic [31:0] get_rs2_value();
		return  register_file_expected[rs2];
	endfunction : get_rs2_value


	function bit[31:0] get_jump_hang(output string jump_hang_instruction_string);
		bit[31:0] jump_hang_instruction;
		jump_hang_instruction = 32'h0000006f;
		jump_hang_instruction_string = $sformatf("%h",jump_hang_instruction);
		return jump_hang_instruction;
	endfunction

	function bit[31:0] get_zero(output string zero_instruction_string);
		bit[31:0] zero_instruction;
		zero_instruction = 32'h00000000;
		zero_instruction_string = $sformatf("%h",zero_instruction);
		return zero_instruction;
	endfunction

	function bit[31:0] get_number(input int number,output string number_string);
		number_string = $sformatf("%h",number);
		return number;
	endfunction

	
	function bit[31:0] get_lui(input int destination, output string lui_instruction_string);
		U_type_instruction lui_instruction;
		bit[31:0] lui_instruction_out;
		// $display("base_address=%0d, rs1_value=%0d, immed_12=%0d",rs1_value+immed_12,rs1_value,immed_12);
		lui_instruction.imm_31to12 = rs1_value;	
		lui_instruction.rd = destination;							
		lui_instruction.opcode = 7'b0110111;
		lui_instruction_out = lui_instruction;
		lui_instruction_string = {"LUI"," ",$sformatf("%0d",lui_instruction.rd),",",$sformatf("%0d",rs1_value)};
		
		return lui_instruction_out;
	endfunction
	constraint valid_data_memory_location {
		(rs1_value + immed_12) >= DATA_MEMORY_LOWER;
		(rs1_value + immed_12) <= DATA_MEMORY_UPPER;
		((rs1_value + immed_12)%4) == 0;
		immed_12[11]==0;
		rs1_value[11]==0;
	}


	function bit[31:0] get_lui_immed(input int destination, input bit[19:0] immed_20, output string lui_instruction_string);
		U_type_instruction lui_instruction;
		bit[31:0] lui_instruction_out;
		lui_instruction.imm_31to12 = immed_20;	
		lui_instruction.rd = destination;							
		lui_instruction.opcode = 7'b0110111;
		lui_instruction_out = lui_instruction;
		lui_instruction_string = {"LUI"," ",$sformatf("%0d",lui_instruction.rd),",",$sformatf("%0d",immed_20)};
		
		return lui_instruction_out;
	endfunction

	function bit[31:0] get_addi(input int destination, input int rs1, input bit[11:0] immed_12, output string addi_instruction_string);
		I_type_instruction addi_instruction;
		bit[31:0] addi_instruction_out;

		addi_instruction.rs1 = rs1;
		addi_instruction.rd = destination;
		addi_instruction.imm_11to0 = immed_12;
		addi_instruction.funct3 = 3'b000;
		addi_instruction.opcode = 7'b0010011;
		addi_instruction_out = addi_instruction;
		addi_instruction_string = $sformatf("ADDI %0d %0d %0d",addi_instruction.rd,addi_instruction.rs1,addi_instruction.imm_11to0);
		
		register_file_expected[destination] = $unsigned(register_file_expected[rs1]) + $unsigned(immed_12);	
		return addi_instruction_out;
	endfunction

	function bit[31:0] get_sltiu(input int destination, input int rs1, input bit[11:0] immed_12, output string sltiu_instruction_string);
		I_type_instruction sltiu_instruction;
		bit[31:0] sltiu_instruction_out;

		sltiu_instruction.rs1 = rs1;
		sltiu_instruction.rd = destination;
		sltiu_instruction.imm_11to0 = immed_12;
		sltiu_instruction.funct3 = 3'b011;
		sltiu_instruction.opcode = 7'b0010011;
		sltiu_instruction_out = sltiu_instruction;
		sltiu_instruction_string = $sformatf("SLTIU %0d %0d %0d",sltiu_instruction.rd,sltiu_instruction.rs1,sltiu_instruction.imm_11to0);
		
		return sltiu_instruction_out;
	endfunction

	function bit[31:0] get_bne(input int rs1, input int rs2, input bit[11:0] immed_12, output string bne_instruction_string);
		SB_type_instruction bne_instruction;
		bit[31:0] bne_instruction_out;

		bne_instruction.imm_12 = immed_12[11];
		bne_instruction.imm_10to5 = immed_12[9:4];								
		bne_instruction.rs2 = rs2;				
		bne_instruction.rs1 = rs1;
		bne_instruction.funct3 = 3'b001;
		bne_instruction.imm_4to1 = immed_12[3:0];	
		bne_instruction.imm_11 = immed_12[10];							
		bne_instruction.opcode = 7'b1100011;
		bne_instruction_out = bne_instruction;
		bne_instruction_string = $sformatf("BNE %0d %0d %0d",bne_instruction.rs1,bne_instruction.rs2,{{19{immed_12[11]}},immed_12,1'b0});
				
		
		return bne_instruction_out;
	endfunction

	function bit[31:0] get_jal(input int pc, input bit[19:0] immed, output string jal_instruction_string);
		UJ_type_instruction jal_instruction;
		bit[31:0] jal_instruction_out;

		jal_instruction.imm_20 = immed[19];
		jal_instruction.imm_10to1 = immed[9:0];
		jal_instruction.imm_11 = immed[10];
		jal_instruction.imm_19to12 = immed[18:11];
		jal_instruction.rd = 1;							
		jal_instruction.opcode = 7'b1101111;
		jal_instruction_out = jal_instruction;
		jal_instruction_string = $sformatf("JAL %0h",$signed(pc+(immed*2)));

		return jal_instruction_out;
	endfunction

	function bit[31:0] get_fnc_return(input int rs1, output string jalr_instruction_string);
		I_type_instruction jalr_instruction;
		bit[31:0] jalr_instruction_out;

		jalr_instruction.rs1 = rs1;
		jalr_instruction.rd = 0;
		jalr_instruction.imm_11to0 = 0;
		jalr_instruction.funct3 = 3'b000;
		jalr_instruction.opcode = 7'b1100111;
		jalr_instruction_out = jalr_instruction;
		jalr_instruction_string = $sformatf("JALR rd=%0d rs1=%0d",jalr_instruction.rd,jalr_instruction.rs1);

		return jalr_instruction_out;
	endfunction

	function bit[31:0] get_load(input int dest,input int rs1, output string load_instruction_string);
		I_type_instruction load_instr;
		bit[31:0] load_instruction_out;
		int load_funct3;

		load_funct3 = $urandom_range(1,5);
		if(load_funct3==1) begin
			load_instr.funct3 = 3'b000; // LB
		end else if(load_funct3==2) begin
			load_instr.funct3 = 3'b001; // LH
		end else if(load_funct3==3) begin
			load_instr.funct3 = 3'b010; // LW
		end else if(load_funct3==4) begin
			load_instr.funct3 = 3'b100; // LBU
		end else if(load_funct3==5) begin
			load_instr.funct3 = 3'b101; // LHU
		end 

		load_instr.rs1 = rs1;
		load_instr.rd = dest;
		load_instr.imm_11to0 = immed_12;
		load_instr.opcode = 7'b0000011;
		load_instruction_out = load_instr;
		load_instruction_string = {"LW"," ",$sformatf("%0d",load_instr.rd),",",$sformatf("%0d",load_instr.rs1),",",$sformatf("%0d",immed_12)};
		return load_instruction_out;
	endfunction

	function bit[31:0] get_store(input int rs1, input int rs2,  output string store_instruction_string);
		S_type_instruction store_instr;
		bit[31:0] store_instruction_out;

		int store_funct3;

		store_funct3 = $urandom_range(1,3);
		if(store_funct3==1) begin
			store_instr.funct3 = 3'b000; // SB
		end else if(store_funct3==2) begin
			store_instr.funct3 = 3'b001; // SH
		end else if(store_funct3==3) begin
			store_instr.funct3 = 3'b010; // SW
		end

		store_instr.imm_11to5 = immed_12[11:5];
		store_instr.rs2 = rs2;				
		store_instr.rs1 = rs1;
		store_instr.imm_4to0 = immed_12[4:0];				
		store_instr.opcode = 7'b0100011;
		store_instruction_out = store_instr;
		store_instruction_string = {"SW"," ",$sformatf("%0d",store_instr.rs1),",",$sformatf("%0d",store_instr.rs2),",",$sformatf("%0d",immed_12)};
		return store_instruction_out;
	endfunction


	function bit[31:0] get_beq(input int rs1, input int rs2, input bit[11:0] immed_12, output string beq_instruction_string);
		SB_type_instruction beq_instruction;
		bit[31:0] beq_instruction_out;

		beq_instruction.imm_12 = immed_12[11];
		beq_instruction.imm_10to5 = immed_12[9:4];								
		beq_instruction.rs2 = rs2;				
		beq_instruction.rs1 = rs1;
		beq_instruction.funct3 = 3'b000;
		beq_instruction.imm_4to1 = immed_12[3:0];	
		beq_instruction.imm_11 = immed_12[10];							
		beq_instruction.opcode = 7'b1100011;
		beq_instruction_out = beq_instruction;
		beq_instruction_string = $sformatf("beq %0d %0d %0d",beq_instruction.rs1,beq_instruction.rs2,{{19{immed_12[11]}},immed_12,1'b0});
				
		
		return beq_instruction_out;
	endfunction


	function bit[31:0] get_auipc(input int rd, input bit[11:0] immed, output string auipc_instruction_string);
		U_type_instruction auipc_instruction;
		bit[31:0] auipc_instruction_out;

		auipc_instruction.imm_31to12 = immed;	
		auipc_instruction.rd = rd;							
		auipc_instruction.opcode = 7'b0010111;
		auipc_instruction_out = auipc_instruction;
		auipc_instruction_string = $sformatf("AUIPC rd:%0d immed:%0d",rd,immed);

		return auipc_instruction_out;
	endfunction

endclass 