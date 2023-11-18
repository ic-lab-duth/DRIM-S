/*
 * @info LRU Top Module
 * @info Top-Module: LRU2.sv, LRUMORE.sv
 *
 * @author VLSI Lab, EE dept., Democritus University of Thrace
 *
 * @param ASSOCIATIVITY: The cache assosiativity
 * @param ENTRIES      : The total addressable entries.
 * @param INDEX_BITS   : The address width
 * @param OUTPUT_BITS  : The Output width
 */
module lru #(ASSOCIATIVITY=2,ENTRIES=256,INDEX_BITS=8,OUTPUT_BITS=2) (
    input  logic                   clk           ,
    input  logic                   rst_n         ,
    input  logic [ INDEX_BITS-1:0] line_selector ,
    input  logic [OUTPUT_BITS-1:0] referenced_set,
    input  logic                   lru_update    ,
    output logic [OUTPUT_BITS-1:0] lru_way
);
	generate
		if(ASSOCIATIVITY==2) begin
			//instantiate the 2-way LRU module
			lru2 #(ENTRIES,INDEX_BITS)
			LRU2(.clk            (clk),
				 .rst_n          (rst_n),
				 .line_selector  (line_selector),
				 .referenced_set (referenced_set),
				 .lru_update     (lru_update),
				 .lru_way        (lru_way));
		end else if(ASSOCIATIVITY>2) begin
			//instantiate the >2-way LRU module
			lrumore #(ASSOCIATIVITY,ENTRIES,INDEX_BITS,OUTPUT_BITS)
			LRUMORE(.clk            (clk),
				 	.rst_n          (rst_n),
				 	.line_selector  (line_selector),
				 	.referenced_set (referenced_set),
				 	.lru_update     (lru_update),
				 	.lru_way        (lru_way));
		end
	endgenerate

endmodule


// module mylru #(ASSOCIATIVITY=2,ENTRIES=256,INDEX_BITS=8,OUTPUT_BITS=2) (
//     input  logic                   clk           ,
//     input  logic                   rst_n         ,
//     input  logic [ INDEX_BITS-1:0] line_selector ,
//     input  logic [OUTPUT_BITS-1:0] referenced_set,
//     input  logic                   lru_update    ,
//     output logic [OUTPUT_BITS-1:0] lru_way
// );
// 	localparam COUNTER_BITS = $clog2(ASSOCIATIVITY);

// 	logic [ENTRIES-1 : 0][ASSOCIATIVITY-1 : 0][COUNTER_BITS-1 : 0] stored_stats, next_stats;


// 	always_ff @(posedge clk or negedge rst_n) begin : Update
// 		if(!rst_n) begin
// 			for (int i = 0; i < ENTRIES; i++) begin
// 				for (int j = 0; j < ASSOCIATIVITY; j++) begin
// 					stored_stats[i][j] = j;
// 				end
// 			end
// 		end else begin
// 			if(lru_update) begin
// 				stored_stats <= next_stats;
// 			end
// 		end
// 	end

// 	logic [COUNTER_BITS-1 : 0] saved_stat;
// 	always_comb begin
// 		next_stats = stored_stats;
// 		saved_stat = stored_stats[line_selector][referenced_set];
// 		for (int i = 0; i < ASSOCIATIVITY; i++) begin
// 			if (stored_stats[line_selector][i] == saved_stat)
// 				next_stats[line_selector][i] = ASSOCIATIVITY - 1;
// 			else if (stored_stats[line_selector][i] > saved_stat)
// 				next_stats[line_selector][i] = stored_stats[line_selector][i] - 1;
// 		end
// 	end

// 	always_comb begin
// 		lru_way = 0;
// 		if (lru_update) begin
// 			for (int i = 0; i < ASSOCIATIVITY; i++) begin
// 				if (stored_stats[line_selector][i] == 0) begin
// 					lru_way = i;
// 				end
// 			end
// 		end else begin
// 			for (int i = 0; i < ASSOCIATIVITY; i++) begin
// 				if (stored_stats[line_selector][i] == 0) begin
// 					lru_way = i;
// 				end
// 			end
// 		end
// 	end
// endmodule