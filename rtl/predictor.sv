/*
 * @info Predictor Top-Module
 * @info Sub Modules: RAS.sv  Gshare.sv, BTB.sv
 *
 * @author VLSI Lab, EE dept., Democritus University of Thrace
 * 
 * @brief A dynamic Predictor, containing a gshare predictor for the direction prediction,
 * 		  a branch target buffer for the target prediction, and a return address stack
 *
 * @param PC_BITS : # of PC Bits
 */
module predictor
	//Parameter List
	#(parameter int PC_BITS          = 32,
	  parameter int RAS_DEPTH        = 8,
	  parameter int GSH_HISTORY_BITS = 2,
	  parameter int GSH_SIZE         = 256,
	  parameter int BTB_SIZE         = 256,
	  parameter int FETCH_WIDTH      = 64)									
	//Input List
	(input logic clk,
	 input logic rst_n,
	 //Control Interface
	 input logic 				  must_flush,
	 input logic 				  is_branch,
	 input logic 				  branch_resolved,
	 //Update Interface
	 input logic                  new_entry,
	 input logic [PC_BITS-1 : 0]  pc_orig,
	 input logic [PC_BITS-1 : 0]  target_pc,
	 input logic                  is_taken,
	 //RAS Interface
	 input logic                  is_return,
	 input logic                  is_jumpl,
	 input logic 			      invalidate,
	 input logic [PC_BITS-1 : 0]  old_pc,
	 //Access Interface
	 input logic [PC_BITS-1 : 0]  pc_in,
	 output logic				  taken_branch_a,
	 output logic [PC_BITS-1 : 0] next_pc_a,
	 output logic				  taken_branch_b,
	 output logic [PC_BITS-1 : 0] next_pc_b);


	// #Internal Signals#
	logic [PC_BITS-1 : 0] pc_in_2, next_pc_btb_a, next_pc_btb_b, pc_out_ras, new_entry_ras;
	logic hit_btb_a, hit_btb_b, pop, push, is_empty_ras, is_taken_out_a, is_taken_out_b;

	assign pc_in_2        = pc_in + 4;
	assign taken_branch_a = (hit_btb_a & is_taken_out_a);
	assign taken_branch_b = (hit_btb_b & is_taken_out_b);
	//Initialize the GShare
	gshare #(
		.PC_BITS     (PC_BITS         ),
		.HISTORY_BITS(GSH_HISTORY_BITS),
		.SIZE        (GSH_SIZE        )
	) gshare (
		.clk           (clk           ),
		.rst_n         (rst_n         ),
		.pc_in_a       (pc_in         ),
		.pc_in_b       (pc_in_2       ),
		.is_taken_out_a(is_taken_out_a),
		.is_taken_out_b(is_taken_out_b),
		
		.wr_en         (new_entry     ),
		.is_taken      (is_taken      ),
		.orig_pc       (pc_orig       )
	);
	//Initialize the BTB
	btb #(
		.PC_BITS(PC_BITS ),
		.SIZE   (BTB_SIZE)
	) btb (
		.clk       (clk          ),
		.rst_n     (rst_n        ),
		
		.pc_in_a   (pc_in        ),
		.pc_in_b   (pc_in_2      ),
		
		.wr_en     (new_entry    ),
		.orig_pc   (pc_orig      ),
		.target_pc (target_pc    ),
		
		.invalidate(invalidate   ),
		.pc_invalid(old_pc       ),
		
		.hit_a     (hit_btb_a    ),
		.next_pc_a (next_pc_btb_a),
		.hit_b     (hit_btb_b    ),
		.next_pc_b (next_pc_btb_b)
	);
	//Initialize the RAS
	ras #(
		.PC_BITS(PC_BITS  ),
		.SIZE   (RAS_DEPTH)
	) ras (
		.clk            (clk                  ),
		.rst_n          (rst_n                ),
		
		.must_flush     (must_flush           ),
		.is_branch      (is_branch & ~is_jumpl),
		.branch_resolved(branch_resolved      ),
		
		.pop            (pop                  ),
		.push           (push                 ),
		.new_entry      (new_entry_ras        ),
		.pc_out         (pc_out_ras           ),
		.is_empty       (is_empty_ras         )
	);

	//RAS Drive Signals
	assign pop  = (is_return & ~is_empty_ras);					
	assign push = is_jumpl;
	assign new_entry_ras = old_pc +4;

	//push the Correct PC to the Output
	always_comb begin : PushOutputA
		if(pop) begin
			next_pc_a = pc_out_ras;
		end else if(hit_btb_a && is_taken_out_a) begin
			next_pc_a = next_pc_btb_a;
		end else begin
			next_pc_a = pc_in+(FETCH_WIDTH/32)*4;
		end
	end
	always_comb begin : PushOutputB
		if(pop) begin
			next_pc_b = pc_out_ras;
		end else if(hit_btb_b && is_taken_out_b) begin
			next_pc_b = next_pc_btb_b;
		end else begin
			next_pc_b = pc_in_2+(FETCH_WIDTH/32)*4;
		end
	end

endmodule