`ifndef INSTRUCTION_DRIVER_SV
`define INSTRUCTION_DRIVER_SV

import dut_parameters_pkg::*;
import tb_util_pkg::*;

class instruction_driver extends uvm_component;
	`uvm_component_utils(instruction_driver)

	virtual IF_if if_vif;
	instruction_generator Rig;	

	task run_phase(uvm_phase phase);
		phase.raise_objection(this);

		// Initial phase to fill register file with random numbers
		reset_low();
		Rig = new(0);
		Rig.generate_instructions_initial_phase();
		
		// Generate random instructions based on the simulation parameters
		Rig.generate_instructions();
		$root.top_tb.th.uut.main_memory.update_ram();
		reset_high();
        wait_test_till_completion();

		phase.drop_objection(this);
	endtask

	task wait_test_till_completion();
		int last_pc, counter, total_cycles;
		counter = 0;
		while(counter<TIME_OUT_CYCLES) begin 
			if((if_vif.current_PC==last_pc) && if_vif.Hit_cache) begin 
				counter++;
			end else begin 
				counter = 0;
			end
			last_pc = if_vif.current_PC;
			total_cycles++;
			@(posedge if_vif.clk);
		end
		$display("Test needed %0d cycles to complete",total_cycles);
	endtask 

	task reset_low();
		force $root.top_tb.th.uut.rst_n = 1'b0;
		repeat(2) @(posedge if_vif.clk);
	endtask

	task reset_high();
		force $root.top_tb.th.uut.rst_n = 1'b1;
		repeat(2) @(posedge if_vif.clk);
	endtask

	function new(string name, uvm_component parent);
		super.new(name,parent);
	endfunction 

endclass
`endif