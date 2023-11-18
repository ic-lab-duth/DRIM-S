/*
 * @info LRU Sub Module
 * @info Top Module: LRU.sv
 *
 * @author VLSI Lab, EE dept., Democritus University of Thrace
 *
 * @param ASSOCIATIVITY: The cache's associavity for which the LRU is intented.
 * @param ENTRIES      : The total addressable entries.
 * @param INDEX_BITS   : The address width
 * @param OUTPUT_BITS  : The output width
 */
module lrumore #(ASSOCIATIVITY=4,ENTRIES=256,INDEX_BITS=8,OUTPUT_BITS=2) (
	input  logic                   clk           ,
	input  logic                   rst_n         ,
	//Read Port
	input  logic [ INDEX_BITS-1:0] line_selector ,
	output logic [OUTPUT_BITS-1:0] lru_way       ,
	//Update Port
	input  logic                   lru_update    ,
	input  logic [OUTPUT_BITS-1:0] referenced_set
);
	// #Internal Signals
 	logic [ENTRIES-1 : 0] stored_stats;
 	logic 				  lru_update1,lru_update2,selected_bank,lru_way1,lru_way2;

	generate
		// ASSOCIATIVITY==4
		if(ASSOCIATIVITY==4) begin
			//Drive the Wr_En signals (Top Bit from reference indicates the bank)
			assign lru_update1 = ~referenced_set[1] & lru_update;
			assign lru_update2 = referenced_set[1] & lru_update;

			lru2 #(ENTRIES,INDEX_BITS)
			LRU1(.clk            (clk),
				 .rst_n          (rst_n),
				 .line_selector  (line_selector),
				 .referenced_set (referenced_set[0]),
				 .lru_update     (lru_update1),
				 .lru_way        (lru_way1));

			lru2 #(ENTRIES,INDEX_BITS)
			LRU2(.clk            (clk),
				 .rst_n          (rst_n),
				 .line_selector  (line_selector),
				 .referenced_set (referenced_set[0]),
				 .lru_update     (lru_update2),
				 .lru_way        (lru_way2));

			//Retrieve Stored Data
			assign selected_bank = stored_stats[line_selector];
			//Choose one bank based on the stored data
			assign lru_way       = selected_bank ? {1'b1,lru_way2} : {1'b0,lru_way1};
			//Save the data (which of the 2 banks were used)
			always_ff @(posedge clk or negedge rst_n) begin : Update
				if(!rst_n) begin
					stored_stats <= 'b0;
				end else begin
					if(lru_update) begin
						//Top Bit from reference indicates the bank
						stored_stats[line_selector] <= ~referenced_set[1];
					end
				end
			end
		 // ASSOCIATIVITY>4 (e.g. 8/16)
		end else if(ASSOCIATIVITY>4) begin

			assign lru_update1 = ~referenced_set[ASSOCIATIVITY -2] & lru_update;
			assign lru_update2 = referenced_set[ASSOCIATIVITY -2] & lru_update;

			lrumore #(ASSOCIATIVITY/2,ENTRIES,INDEX_BITS,OUTPUT_BITS-1)
			LRUMORE1(.clk            (clk),
				 	 .rst_n          (rst_n),
				 	 .line_selector  (line_selector),
				 	 .referenced_set (referenced_set[OUTPUT_BITS-2 : 0]),
				 	 .lru_update     (lru_update1),
				 	 .lru_way        (lru_way1));

			lrumore #(ASSOCIATIVITY/2,ENTRIES,INDEX_BITS,OUTPUT_BITS-1)
			LRUMORE2(.clk            (clk),
				 	 .rst_n          (rst_n),
				 	 .line_selector  (line_selector),
				 	 .referenced_set (referenced_set[OUTPUT_BITS-2 : 0]),
				 	 .lru_update     (lru_update2),
				 	 .lru_way        (lru_way2));

			//Retrieve Stored Data
			assign selected_bank = stored_stats[line_selector];
			//Choose one bank based on the stored data
			assign lru_way       = selected_bank ? {1'b0,lru_way1} : {1'b1,lru_way2}; //* bug was here
			//Save the data (which of the 2 banks were used)
			always_ff @(posedge clk or negedge rst_n) begin : Update
				if(!rst_n) begin
					stored_stats <= 'b0;
				end else begin
					if(lru_update) begin
						//Top Bit from reference indicates one of the banks
						stored_stats[line_selector] <= ~referenced_set[ASSOCIATIVITY -2];
					end
				end
			end
		end
	endgenerate

endmodule