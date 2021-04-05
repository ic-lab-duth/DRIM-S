import simulation_parameters_pkg::*;
import simulation_parameters_pkg::*;

class instruction_generator;
	// Structural parameters
	// structure variables
	int ARM_ID;
	int MEMORY_START_LINE;
	int NO_OF_MEM_LINES=5;
	int NO_OF_DATA_LINES=10;
	int NO_OF_FUNCTIONS = 10; // always NO_OF_FUNCTIONS>NO_OF_FUNCTIONS_LVL_2
	int NO_OF_FUNCTIONS_LVL_2 = 2;
	int BLOCK_WIDTH=512;
	int BYTES_PER_LINE = BLOCK_WIDTH/8;
	int DATA_MEMORY_START_LINE;
	int DATA_MEMORY_LOWER;
	int DATA_MEMORY_UPPER;
	int FUNCTION_START_LINE;
	int FUNCTION_START_LINE_LVL2;
	int MIN_FNC_INSTR = 9;
	int MAX_FNC_INSTR = 9; // max 9
	int LOOP_ITERATIONS;
	int INSTRUCTIONS_INSIDE_LOOP = 10;
	int NESTED_FNC_RATE = 0;
	// Parameters
	int FNC_CALL_RATE;
	int MEMORY_LOCATION_DEPENDENCY_RATE;

	instruction instruction_h;
	bit [31:0] instruction;
	string instruction_string, instruction_hex, instruction_line_to_memory;
	
	int ins_counter, memory_position, memory_line, pc, currently_in_use_regs_q[$], instructions_to_generate, fnc_ins_counter, function_to_call;
	int last_dest, last_rs1;
	rand int index_reg, flag_reg, index_reg_2, flag_reg_2, start_loop_pc, start_loop_pc_2, jump_to_pc;
	rand bit [11:0] immed12;

	// file handles
	int prt_instructions, memory_file;

	

	function void generate_instructions_initial_phase();
		rf_array exp_register_file;
		int random_destination; 
		bit[19:0] immed_20;

		
		// Fill memory with data
		// repeat(NO_OF_DATA_LINES) begin
		// 	repeat((BYTES_PER_LINE-memory_position)/4) begin
		// 		instruction = instruction_h.get_number($urandom_range(0,10),instruction_string);
		// 		write_instruction_to_mem_file(instruction, instruction_string);
		// 	end
		// end

		// Generate instructions
		ins_counter = 0;
		while(ins_counter<200) begin 
			random_destination = $urandom_range(1,31);
			immed_20 = $urandom_range(1,20);
			instruction = instruction_h.get_addi(random_destination,0,immed_20,instruction_string);
			write_instruction_to_mem_file(instruction, instruction_string);
		end
		
		// //write "jump hang" to memory so that the PC stays the same when program finishes
		// instruction = instruction_h.get_jump_hang(instruction_string);
		// write_instruction_to_mem_file(instruction, instruction_string);

		// exp_register_file = instruction_h.get_register_file_expected();

		// // finish the line with zeros
		// repeat((BYTES_PER_LINE-memory_position)/4) begin
		// 	instruction = instruction_h.get_zero(instruction_string);
		// 	write_instruction_to_mem_file(instruction, instruction_string);
		// end

	endfunction


	

	function void generate_instructions();
		ins_counter = 0;
		currently_in_use_regs_q = {};
		// $display("MEMORY_START_LINE=%0d",MEMORY_START_LINE);
		// $display("FUNCTION_START_LINE=%0d",FUNCTION_START_LINE);
		// $display("DATA_MEMORY_START_LINE=%0d\n",DATA_MEMORY_START_LINE);

		// $display("DATA_MEMORY_LOWER=%0d",DATA_MEMORY_LOWER);
		// $display("DATA_MEMORY_UPPER=%0d",DATA_MEMORY_UPPER);

		// // Fill memory with data
		// repeat(NO_OF_DATA_LINES) begin
		// 	repeat((BYTES_PER_LINE-memory_position)/4) begin
		// 		instruction = instruction_h.get_number($urandom_range(0,10),instruction_string);
		// 		write_instruction_to_mem_file(instruction, instruction_string);
		// 	end
		// end

		// // fill in the memory txt with zeros till we reach the line where instructions are stored
		// for (int i = memory_line; i <MEMORY_START_LINE ; i++) begin
		// 	repeat((BYTES_PER_LINE-memory_position)/4) begin
		// 		instruction = instruction_h.get_zero(instruction_string);
		// 		write_instruction_to_mem_file(instruction, instruction_string);
		// 	end
		// end

		// ********************
		// Instructions section
		// ********************
		ins_counter = 0;
		while(ins_counter<NO_OF_INSTRUCTIONS) begin 
			if($urandom_range(0,99)<simulation_parameters_pkg::FOR_LOOP_RATE) begin
				currently_in_use_regs_q = {};

				// Select register for index, flag
				index_reg = get_free_reg();
				currently_in_use_regs_q.push_back(index_reg);
				flag_reg  = get_free_reg();
				currently_in_use_regs_q.push_back(flag_reg);
				// $display("index_reg=%0d",index_reg);
				// Initialize index to zero
				instruction = instruction_h.get_addi(index_reg,0,0,instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
				start_loop_pc = pc;
				// Generate random instructions inside
				repeat(INSTRUCTIONS_INSIDE_LOOP) begin 
					if($urandom_range(0,99)<simulation_parameters_pkg::FORWARD_BRANCH_RATE) begin
						instruction = instruction_h.get_beq(0,$urandom_range(1,31),2,instruction_string);
						write_instruction_to_mem_file(instruction, instruction_string);
					end else begin 
						instruction = get_random_instruction(instruction_string);
						write_instruction_to_mem_file(instruction, instruction_string);
					end
				end
				if($urandom_range(0,99)<simulation_parameters_pkg::NESTED_LOOP_RATE) begin
					index_reg_2 = get_free_reg();
					currently_in_use_regs_q.push_back(index_reg_2);
					flag_reg_2  = get_free_reg();
					currently_in_use_regs_q.push_back(flag_reg_2);
					instruction = instruction_h.get_addi(index_reg_2,0,0,instruction_string);
					write_instruction_to_mem_file(instruction, instruction_string);
					start_loop_pc_2 = pc;
					repeat(INSTRUCTIONS_INSIDE_LOOP) begin 
						if($urandom_range(0,99)<simulation_parameters_pkg::FORWARD_BRANCH_RATE) begin
							instruction = instruction_h.get_beq(0,$urandom_range(1,31),2,instruction_string);
							write_instruction_to_mem_file(instruction, instruction_string);
						end else begin 
							instruction = get_random_instruction(instruction_string);
							write_instruction_to_mem_file(instruction, instruction_string);
						end
					end
					instruction = instruction_h.get_addi(index_reg_2,index_reg_2,1,instruction_string); // index++
					write_instruction_to_mem_file(instruction, instruction_string);
					instruction = instruction_h.get_sltiu(flag_reg_2,index_reg_2,$urandom_range(LOOP_ITERATIONS,LOOP_ITERATIONS),instruction_string);
					write_instruction_to_mem_file(instruction, instruction_string);
					jump_to_pc = -((pc-start_loop_pc_2)/2);
					instruction = instruction_h.get_bne(flag_reg_2,0,jump_to_pc,instruction_string);
					write_instruction_to_mem_file(instruction, instruction_string);
				end
				// Increment index
				instruction = instruction_h.get_addi(index_reg,index_reg,1,instruction_string); // index++
				write_instruction_to_mem_file(instruction, instruction_string);
				// Set flag
				instruction = instruction_h.get_sltiu(flag_reg,index_reg,$urandom_range(LOOP_ITERATIONS,LOOP_ITERATIONS),instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
				// Branch back if flag is not set
				jump_to_pc = -((pc-start_loop_pc)/2);
				instruction = instruction_h.get_bne(flag_reg,0,jump_to_pc,instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);

				currently_in_use_regs_q = {};
			end else if($urandom_range(0,99)<FNC_CALL_RATE && NO_OF_FUNCTIONS>0) begin
				// Save the return address to reg x1
				instruction = instruction_h.get_addi(1,0,pc+8,instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
				// Make the function call
				function_to_call = $urandom_range(1,NO_OF_FUNCTIONS-NO_OF_FUNCTIONS_LVL_2)-1;
				jump_to_pc = (FUNCTION_START_LINE*BYTES_PER_LINE+(function_to_call)*BYTES_PER_LINE-pc)/2;
				instruction = instruction_h.get_jal(pc,jump_to_pc,instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end else begin 
				instruction = get_random_instruction(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
				
		end
		
		//write "jump hang" to memory so that the PC stays the same when program finishes
		instruction = instruction_h.get_jump_hang(instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);

		// // fill in the memory txt with zeros till we reach the line where the functions are stored
		// for (int i = memory_line; i <FUNCTION_START_LINE ; i++) begin
		// 	repeat((BYTES_PER_LINE-memory_position)/4) begin
		// 		instruction = instruction_h.get_zero(instruction_string);
		// 		write_instruction_to_mem_file(instruction, instruction_string);
		// 	end
		// end

		// // ********************
		// // Functions section
		// // ********************
		// // Level 1 (main functions)
		// // Be carefull, you dont want to ruin x1 reg which holds the return address
		// repeat(NO_OF_FUNCTIONS-NO_OF_FUNCTIONS_LVL_2) begin 
		// 	// Max 16 instructions per function
		// 	instructions_to_generate = $urandom_range(MIN_FNC_INSTR,MAX_FNC_INSTR);
		// 	fnc_ins_counter = 0;
		// 	while(fnc_ins_counter<instructions_to_generate) begin 
		// 		if($urandom_range(0,99)<NESTED_FNC_RATE) begin
		// 			function_to_call = $urandom_range(1,NO_OF_FUNCTIONS_LVL_2)-1;
		// 			jump_to_pc = (FUNCTION_START_LINE_LVL2*BYTES_PER_LINE+(function_to_call)*BYTES_PER_LINE-pc)/2;
		// 			instruction = instruction_h.get_jal(pc,jump_to_pc,instruction_string);
		// 			write_instruction_to_mem_file(instruction, instruction_string);
		// 			$display("FUNCTION_START_LINE_LVL2 addr=%0h pc=%0d jump_to_pc=%0d ",FUNCTION_START_LINE_LVL2*BYTES_PER_LINE,pc,jump_to_pc);
		// 			// $stop;
		// 		end else begin 
		// 			instruction = get_random_instruction(instruction_string);
		// 			write_instruction_to_mem_file(instruction, instruction_string);
		// 		end
					
		// 	end
		// 	// fnc return
		// 	instruction = instruction_h.get_fnc_return(1, instruction_string);
		// 	write_instruction_to_mem_file(instruction, instruction_string);
		// 	// Fill the rest line with zeros
		// 	if(memory_position!=0) begin
		// 		repeat((BYTES_PER_LINE-memory_position)/4) begin
		// 			instruction = instruction_h.get_zero(instruction_string);
		// 			write_instruction_to_mem_file(instruction, instruction_string);
		// 		end
		// 	end
		// end
		// // Level 2 (nested functions)
		// repeat(NO_OF_FUNCTIONS_LVL_2) begin 
		// 	// Max 16 instructions per function
		// 	instructions_to_generate = $urandom_range(MIN_FNC_INSTR,MAX_FNC_INSTR);
		// 	fnc_ins_counter = 0;
		// 	while(fnc_ins_counter<instructions_to_generate) begin 
		// 		instruction = get_random_instruction(instruction_string);
		// 		write_instruction_to_mem_file(instruction, instruction_string);
		// 	end
		// 	// fnc return
		// 	instruction = instruction_h.get_fnc_return(2, instruction_string);
		// 	write_instruction_to_mem_file(instruction, instruction_string);
		// 	// Fill the rest line with zeros
		// 	if(memory_position!=0) begin
		// 		repeat((BYTES_PER_LINE-memory_position)/4) begin
		// 			instruction = instruction_h.get_zero(instruction_string);
		// 			write_instruction_to_mem_file(instruction, instruction_string);
		// 		end
		// 	end
		// end
		repeat(10) begin 
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end
			
		
		
		$fclose(prt_instructions);
		$fclose(memory_file);
	endfunction

	function void direct_btb_full();
		prt_instructions = $fopen("prt_instructions_new.txt","w");
		memory_file = $fopen("memory.txt","w");

		pc = 0;
		memory_position = 0;
		memory_line = 0;

		// fill in the memory txt with zeros till we reach the line where instructions are stored
		for (int i = memory_line; i <MEMORY_START_LINE ; i++) begin
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		for (int i = 0; i < 150; i++) begin
			instruction = instruction_h.get_beq(0,$urandom_range(1,31),2,instruction_string);
			write_instruction_to_mem_file(instruction, instruction_string);
		end

		//write "jump hang" to memory so that the PC stays the same when program finishes
		instruction = instruction_h.get_jump_hang(instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);

		repeat(10) begin 
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		$fclose(prt_instructions);
		$fclose(memory_file);
	endfunction

	function void direct_ras();
		int nested_fnc_calls = 10;
		prt_instructions = $fopen("prt_instructions_new.txt","w");
		memory_file = $fopen("memory.txt","w");
		pc = 0;
		memory_position = 0;
		memory_line = 0;

		// fill in the memory txt with zeros till we reach the line where instructions are stored
		for (int i = memory_line; i <MEMORY_START_LINE ; i++) begin
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		// First call to function 1
		// Save the return address to reg x5
		instruction = instruction_h.get_auipc(5,0,instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);
		instruction = instruction_h.get_addi(5,5,12,instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);
		// Make the function call
		function_to_call = 1;
		jump_to_pc = ((MEMORY_START_LINE+function_to_call)*BYTES_PER_LINE-pc)/2;
		instruction = instruction_h.get_jal(pc,jump_to_pc,instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);

		//write "jump hang" to memory so that the PC stays the same when program finishes
		instruction = instruction_h.get_jump_hang(instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);

		repeat((BYTES_PER_LINE-memory_position)/4) begin
			instruction = instruction_h.get_zero(instruction_string);
			write_instruction_to_mem_file(instruction, instruction_string);
		end

		// Create nested function calls
		for (int i = 1; i <= nested_fnc_calls; i++) begin
			// Save the return address to reg x5+i
			instruction = instruction_h.get_auipc(i+5,0,instruction_string);
			write_instruction_to_mem_file(instruction, instruction_string);
			instruction = instruction_h.get_addi(i+5,i+5,12,instruction_string);
			write_instruction_to_mem_file(instruction, instruction_string);
			// Make the function call
			function_to_call = i+1;
			jump_to_pc = ((MEMORY_START_LINE+function_to_call)*BYTES_PER_LINE-pc)/2;
			instruction = instruction_h.get_jal(pc,jump_to_pc,instruction_string);
			write_instruction_to_mem_file(instruction, instruction_string);
			// Make the function return
			instruction = instruction_h.get_fnc_return((i+5)-1, instruction_string);
			write_instruction_to_mem_file(instruction, instruction_string);

			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		// Create last function
		// Make the function return
		instruction = instruction_h.get_fnc_return(nested_fnc_calls+5, instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);
		repeat((BYTES_PER_LINE-memory_position)/4) begin
			instruction = instruction_h.get_zero(instruction_string);
			write_instruction_to_mem_file(instruction, instruction_string);
		end



		repeat(10) begin 
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end
		$fclose(prt_instructions);
		$fclose(memory_file);
	endfunction


	function void direct_load_store();
		NO_OF_DATA_LINES = 50;
		MEMORY_START_LINE = ARM_ID * NO_OF_MEM_LINES + NO_OF_DATA_LINES;
		DATA_MEMORY_LOWER = 0;
		DATA_MEMORY_UPPER = NO_OF_DATA_LINES*BYTES_PER_LINE + BYTES_PER_LINE - 4;
		// instruction_h.set_parameters(simulation_parameters_pkg::SHIFTS_DIST,simulation_parameters_pkg::OPERATIONS_DIST,simulation_parameters_pkg::COMPARES_DIST,simulation_parameters_pkg::LOADS_DIST,simulation_parameters_pkg::STORES_DIST,simulation_parameters_pkg::DIV_DIST,DATA_MEMORY_LOWER,DATA_MEMORY_UPPER);

		prt_instructions = $fopen("prt_instructions_new.txt","w");
		memory_file = $fopen("memory.txt","w");

		pc = 0;
		memory_position = 0;
		memory_line = 0;

		// Fill memory with data
		repeat(NO_OF_DATA_LINES) begin
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_number($urandom_range(0,10),instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		// fill in the memory txt with zeros till we reach the line where instructions are stored
		for (int i = memory_line; i <MEMORY_START_LINE ; i++) begin
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		for (int i = 0; i < 30; i++) begin
			if (!instruction_h.randomize()) $fatal("failed to randomize");
			instruction_h.rd = get_free_reg();
			instruction_h.rs1 = $urandom_range(1,31);
			// get a addi instruction, to setup rs1 data
			instruction = instruction_h.get_addi(instruction_h.rs1,0,instruction_h.rs1_value,instruction_string);
			write_instruction_to_mem_file(instruction, instruction_string);
			if($urandom_range(0,1)) begin
				instruction = instruction_h.get_load(instruction_h.rd,instruction_h.rs1,instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end else begin 
				instruction = instruction_h.get_store(instruction_h.rs1,$urandom_range(0,31),instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		//write "jump hang" to memory so that the PC stays the same when program finishes
		instruction = instruction_h.get_jump_hang(instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);

		repeat(10) begin 
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		$fclose(prt_instructions);
		$fclose(memory_file);
	endfunction 

	function void direct_wait_buffer_full();
		NO_OF_DATA_LINES = 50;
		MEMORY_START_LINE = ARM_ID * NO_OF_MEM_LINES + NO_OF_DATA_LINES;
		DATA_MEMORY_LOWER = 0;
		DATA_MEMORY_UPPER = NO_OF_DATA_LINES*BYTES_PER_LINE + BYTES_PER_LINE - 4;
		// instruction_h.set_parameters(simulation_parameters_pkg::SHIFTS_DIST,simulation_parameters_pkg::OPERATIONS_DIST,simulation_parameters_pkg::COMPARES_DIST,simulation_parameters_pkg::LOADS_DIST,simulation_parameters_pkg::STORES_DIST,simulation_parameters_pkg::DIV_DIST,DATA_MEMORY_LOWER,DATA_MEMORY_UPPER);

		prt_instructions = $fopen("prt_instructions_new.txt","w");
		memory_file = $fopen("memory.txt","w");

		pc = 0;
		memory_position = 0;
		memory_line = 0;

		// Fill memory with data
		repeat(NO_OF_DATA_LINES) begin
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_number($urandom_range(0,10),instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		// fill in the memory txt with zeros till we reach the line where instructions are stored
		for (int i = memory_line; i <MEMORY_START_LINE ; i++) begin
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end
		
		if (!instruction_h.randomize()) $fatal("failed to randomize");
		instruction_h.rd = get_free_reg();
		instruction_h.rs1 = $urandom_range(1,31);
		// get a addi instruction, to setup rs1 data
		instruction = instruction_h.get_addi(instruction_h.rs1,0,instruction_h.rs1_value,instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);
		for (int i = 0; i < 50; i++) begin
			if($urandom_range(0,1)) begin
				instruction = instruction_h.get_load($urandom_range(1,31),instruction_h.rs1,instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end else begin 
				instruction = instruction_h.get_store(instruction_h.rs1,$urandom_range(0,31),instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		//write "jump hang" to memory so that the PC stays the same when program finishes
		instruction = instruction_h.get_jump_hang(instruction_string);
		write_instruction_to_mem_file(instruction, instruction_string);

		repeat(10) begin 
			repeat((BYTES_PER_LINE-memory_position)/4) begin
				instruction = instruction_h.get_zero(instruction_string);
				write_instruction_to_mem_file(instruction, instruction_string);
			end
		end

		$fclose(prt_instructions);
		$fclose(memory_file);
	endfunction 

	function void direct_line_replacement();
		
	endfunction


	function bit[31:0] get_random_instruction(output string random_instruction_string);
		bit[31:0] random_instruction;
		bit[19:0] immediate_20;

		if (!instruction_h.randomize()) $fatal("failed to randomize");
		if($urandom_range(0,99)<simulation_parameters_pkg::WAW_HAZARD_RATE && !reg_in_use(last_dest)) begin
			if(last_dest!=1) begin
				// To not destroy reg in when it holds the ra of a function
				instruction_h.rd = last_dest;
			end else begin 
				instruction_h.rd = get_free_reg();
			end
		end else if($urandom_range(0,99)<simulation_parameters_pkg::WAR_HAZARD_RATE && !reg_in_use(last_rs1)) begin 
			if(last_rs1!=1) begin
				instruction_h.rd = last_rs1;
			end else begin 
				instruction_h.rd = get_free_reg();
			end
		end else begin 
			instruction_h.rd  = get_free_reg();
		end
		
		if($urandom_range(0,99)<simulation_parameters_pkg::RAW_HAZARD_RATE) begin
			instruction_h.rs1 = last_dest;
		end else begin 
			instruction_h.rs1 = $urandom_range(1,31);
		end
			

		instruction_h.rs2 = $urandom_range(0,31);
		// If instruction is load/store, we need an adititonal instruction to setup the memory address
		if(instruction_h.instruction == SW || instruction_h.instruction == SH || instruction_h.instruction == SB || instruction_h.instruction == LW || instruction_h.instruction == LH || instruction_h.instruction == LB || instruction_h.instruction == LHU || instruction_h.instruction == LBU ) begin 
			// get a addi instruction, to setup rs1 data
			instruction_h.rs1 = get_free_reg(); // we dont want setup of rs1 ruin our index register
			random_instruction = instruction_h.get_addi(instruction_h.rs1,0,instruction_h.rs1_value,random_instruction_string);
			write_instruction_to_mem_file(random_instruction, random_instruction_string);
			if($urandom_range(0,99)<MEMORY_LOCATION_DEPENDENCY_RATE) begin
				if(instruction_h.instruction == SW || instruction_h.instruction == SH || instruction_h.instruction == SB) begin
					random_instruction = instruction_h.get_load(instruction_h.rd,instruction_h.rs1,random_instruction_string);
					write_instruction_to_mem_file(random_instruction, random_instruction_string);
				end else begin 
					random_instruction = instruction_h.get_store(instruction_h.rs1,$urandom_range(0,31),random_instruction_string);
					write_instruction_to_mem_file(random_instruction, random_instruction_string);
				end
			end
			random_instruction = instruction_h.get_instruction();
			random_instruction_string = instruction_h.get_string_instruction();



			fnc_ins_counter += 2;
		end else begin 
			random_instruction = instruction_h.get_instruction();
			random_instruction_string = instruction_h.get_string_instruction();
			fnc_ins_counter++;
		end
			

		last_dest = instruction_h.rd;
		last_rs1 = instruction_h.rs1;
		return random_instruction;
	endfunction

	


	function void write_instruction_to_mem_file(input bit[31:0] instruction, input string instruction_string);
		instruction_hex = $sformatf("%h",instruction);
		instruction_line_to_memory = {instruction_hex,instruction_line_to_memory};
		$fwrite(prt_instructions,"address %h:%s \n",memory_line*BYTES_PER_LINE + memory_position,instruction_string);
		ins_counter++;
		// $display("memory_line=%0d, memory_position=%0d",memory_line,memory_position);
		pc+=4;
		memory_position += 4;
		if(memory_position == BYTES_PER_LINE) begin
			$fwrite(memory_file,"%s\n",instruction_line_to_memory);
			instruction_line_to_memory = "";
			memory_line++;
			memory_position = 0;
		end
	endfunction

	function new(int arm_id_i);
		instruction_h = new();
		ARM_ID = arm_id_i;
		MEMORY_START_LINE = ARM_ID * NO_OF_MEM_LINES + NO_OF_DATA_LINES;
		FUNCTION_START_LINE = MEMORY_START_LINE + NO_OF_MEM_LINES - NO_OF_FUNCTIONS;
		FUNCTION_START_LINE_LVL2 = NO_OF_MEM_LINES - NO_OF_FUNCTIONS_LVL_2;
		DATA_MEMORY_START_LINE = 0;
		DATA_MEMORY_LOWER = 0;
		DATA_MEMORY_UPPER = NO_OF_DATA_LINES*BYTES_PER_LINE + BYTES_PER_LINE - 4;

		prt_instructions = $fopen("instructions.txt","w");
		memory_file = $fopen("memory.txt","w");

	endfunction

	function int get_free_reg();
		int free_reg;
		do begin 
			// x1 reg is used to hold return address of functions
			if(FNC_CALL_RATE>0) begin
				free_reg = $urandom_range(2,31);
			end else begin 
				free_reg = $urandom_range(1,31);
			end
		end while(reg_in_use(free_reg)==1); // TODO add timeout mechanism if all regs in use
		// $display("free_reg=%0d",free_reg);
		return free_reg;
	endfunction


	function bit reg_in_use(input int id);
		bit found;
		found = 0;
		for (int i = 0; i <currently_in_use_regs_q.size() ; i++) begin
			if(currently_in_use_regs_q[i]==id) begin
				found = 1;
				break;
			end
		end
		return found;
	endfunction 

	constraint index_reg_constraint {
		index_reg inside{[1:31]};
	}

	// function void set_parameters(sim_parameters_s parameters, int arm);
	// 	simulation_parameters_pkg::SHIFTS_DIST      = parameters.simulation_parameters_pkg::SHIFTS_DIST;
	// 	simulation_parameters_pkg::OPERATIONS_DIST  = parameters.simulation_parameters_pkg::OPERATIONS_DIST;
	// 	simulation_parameters_pkg::COMPARES_DIST    = parameters.simulation_parameters_pkg::COMPARES_DIST;
	// 	simulation_parameters_pkg::LOADS_DIST       = parameters.simulation_parameters_pkg::LOADS_DIST;
	// 	simulation_parameters_pkg::STORES_DIST      = parameters.simulation_parameters_pkg::STORES_DIST;
	// 	simulation_parameters_pkg::DIV_DIST         = parameters.simulation_parameters_pkg::DIV_DIST;
	// 	simulation_parameters_pkg::FOR_LOOP_RATE    = parameters.simulation_parameters_pkg::FOR_LOOP_RATE;
	// 	simulation_parameters_pkg::NESTED_LOOP_RATE = parameters.simulation_parameters_pkg::NESTED_LOOP_RATE;
	// 	FNC_CALL_RATE    = parameters.FNC_CALL_RATE;
	// 	LOOP_ITERATIONS  = parameters.LOOP_ITERATIONS;
	// 	// MIN_LOOP_ITERATIONS = parameters.MIN_LOOP_ITERATIONS;
	// 	// MAX_LOOP_ITERATIONS = parameters.MAX_LOOP_ITERATIONS;
	// 	simulation_parameters_pkg::RAW_HAZARD_RATE = parameters.simulation_parameters_pkg::RAW_HAZARD_RATE;
	// 	simulation_parameters_pkg::WAR_HAZARD_RATE = parameters.simulation_parameters_pkg::WAR_HAZARD_RATE;
	// 	simulation_parameters_pkg::WAW_HAZARD_RATE = parameters.simulation_parameters_pkg::WAW_HAZARD_RATE;
	// 	MEMORY_LOCATION_DEPENDENCY_RATE = parameters.MEMORY_LOCATION_DEPENDENCY_RATE;
	// 	simulation_parameters_pkg::FORWARD_BRANCH_RATE = parameters.simulation_parameters_pkg::FORWARD_BRANCH_RATE;
	// 	instruction_h.set_parameters(simulation_parameters_pkg::SHIFTS_DIST,simulation_parameters_pkg::OPERATIONS_DIST,simulation_parameters_pkg::COMPARES_DIST,simulation_parameters_pkg::LOADS_DIST,simulation_parameters_pkg::STORES_DIST,simulation_parameters_pkg::DIV_DIST,DATA_MEMORY_LOWER,DATA_MEMORY_UPPER);
	// 	// $display("Arm %0d parameters",arm);
	// 	// $display("simulation_parameters_pkg::SHIFTS_DIST      = %0d",simulation_parameters_pkg::SHIFTS_DIST);
	// 	// $display("simulation_parameters_pkg::OPERATIONS_DIST  = %0d",simulation_parameters_pkg::OPERATIONS_DIST);
	// 	// $display("simulation_parameters_pkg::COMPARES_DIST    = %0d",simulation_parameters_pkg::COMPARES_DIST);
	// 	// $display("simulation_parameters_pkg::LOADS_DIST       = %0d",simulation_parameters_pkg::LOADS_DIST);
	// 	// $display("simulation_parameters_pkg::STORES_DIST      = %0d",simulation_parameters_pkg::STORES_DIST);
	// 	// $display("simulation_parameters_pkg::DIV_DIST      = %0d",simulation_parameters_pkg::DIV_DIST);
	// 	// $display("simulation_parameters_pkg::FOR_LOOP_RATE    = %0d",simulation_parameters_pkg::FOR_LOOP_RATE);
	// 	// $display("simulation_parameters_pkg::NESTED_LOOP_RATE = %0d",simulation_parameters_pkg::NESTED_LOOP_RATE);
	// 	// $display("FNC_CALL_RATE    = %0d\n",FNC_CALL_RATE);
	// 	// $display("MIN_LOOP_ITERATIONS = %0d",MIN_LOOP_ITERATIONS);
	// 	// $display("MAX_LOOP_ITERATIONS    = %0d\n",MAX_LOOP_ITERATIONS);
	// 	// $display("LOOP_ITERATIONS    = %0d\n",LOOP_ITERATIONS);
	// 	// $display("simulation_parameters_pkg::RAW_HAZARD_RATE = %0d",simulation_parameters_pkg::RAW_HAZARD_RATE);
	// 	// $display("simulation_parameters_pkg::WAR_HAZARD_RATE = %0d\n",simulation_parameters_pkg::WAR_HAZARD_RATE);
	// 	// $display("simulation_parameters_pkg::WAW_HAZARD_RATE = %0d",simulation_parameters_pkg::WAW_HAZARD_RATE);
	// 	// $display("MEMORY_LOCATION_DEPENDENCY_RATE = %0d\n",MEMORY_LOCATION_DEPENDENCY_RATE);
	// 	// $display("simulation_parameters_pkg::FORWARD_BRANCH_RATE = %0d\n",simulation_parameters_pkg::FORWARD_BRANCH_RATE);
	// endfunction 

	

endclass