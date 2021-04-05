/*
 * @info Return Address Stack
 * @info Sub-Modules: fifo_flush.sv
 *
 * @author VLSI Lab, EE dept., Democritus University of Thrace
 *
 * @note buffer only saves 31/32 bits of the PC -> Lower 1 bit not needed,
 *
 * @param PC_BITS : # of PC Bits (default 32 bits)
 * @param SIZE    : # of entries (lines) in the buffer
 */
module ras #(PC_BITS=32,SIZE=32) (
    input  logic               clk            ,
    input  logic               rst_n          ,
    input  logic               must_flush     ,
    input  logic               is_branch      ,
    input  logic               branch_resolved,
    input  logic               pop            ,
    input  logic               push           ,
    input  logic [PC_BITS-1:0] new_entry      ,
    output logic [PC_BITS-1:0] pc_out         ,
    output logic               is_empty
);

	localparam CON_BITS = $clog2(SIZE);
    // #Internal Signals#
    //-2 to create the 31bits space instead of 32bits for the Address
    logic [SIZE-1:0][PC_BITS-2:0] buffer;
    logic [CON_BITS-1 : 0] head, tail, data_pointer, checkpointed_tos;
    logic [CON_BITS   : 0] checkpoint_pushed, checkpoint_out;
    logic [ PC_BITS-2 : 0] data_out         ;
    logic                  lastpush,  checkpoint_valid, checkpointed_lastpush;

    localparam int RAS_SIZE = $bits(buffer) + 2*$bits(head) + 4*(CON_BITS+1);
	//Create the empty stat output
	assign is_empty = (head == tail) & ~lastpush;
	//extend t he stored 31 bits to 32 and output them
	assign data_pointer = head-1;
	assign data_out = buffer[data_pointer];
	assign pc_out   = {data_out,1'b0};

    assign checkpoint_pushed = {head,lastpush};
    //Initialize the fifo for the TOS checkpointing
    fifo_overflow #(
        .DW     (CON_BITS+1),
        .DEPTH  (4))
    fifo_overflow  (
        .clk        (clk),
        .rst        (~rst_n),
        .flush      (must_flush),

        .push_data  (checkpoint_pushed),
        .push       (is_branch),

        .pop_data   (checkpoint_out),
        .valid      (checkpoint_valid),
        .pop        (branch_resolved & checkpoint_valid)
        );

    assign checkpointed_lastpush = checkpoint_out[0];
    assign checkpointed_tos      = checkpoint_out[CON_BITS:1];
	always_ff @(posedge clk) begin : MemoryManagement
		if(push) begin
			buffer[head] <= new_entry[PC_BITS-1:1];
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin : PointerManagement
		if(!rst_n) begin
			head     <= 0;
			tail     <= 0;
			lastpush <= 0;
		end else begin
            if(must_flush && checkpoint_valid) begin
                //Restore Checkpoint
                head <= checkpointed_tos;
                lastpush <= checkpointed_lastpush;
            end else if(push) begin
                //push new Values
				lastpush <= 1;
				head     <= head + 1;
				//Override the oldest value when buffer Full
				if(head==tail && lastpush) begin
					tail <= tail+1;
				end
			end else if(pop) begin
                //pop Values when not Empty
				head <= head-1;
				lastpush <= 0;
			end
		end
	end

`ifdef INCLUDE_SVAS
    `include "ras_sva.sv"
`endif

endmodule