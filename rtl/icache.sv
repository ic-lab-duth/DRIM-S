/*
* @info Instruction Cache (Blocking)
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @note Cache configuration: {Valid} [Tag] [Data]
*
* @param ADDRESS_BITS : # of Address Bits (default==32)
* @param ENTRIES      : # of addressable entries (lines) in each bank
* @param ASSOCIATIVITY: Cache Associativity (default 2-way)
* @param BLOCK_WIDTH  : Block Width
* @param INSTR_BITS   : Stored data width that are returned (data saved per entry)
* @param DATA_BUS_WIDTH : Size of available data bus
*/
//DEFAULT: 256 entries * 256 bits * 2 sets = 16KB Cache size
module icache #(ADDRESS_BITS=32,ENTRIES=256,ASSOCIATIVITY=2,BLOCK_WIDTH=256,INSTR_BITS=32, DATA_BUS_WIDTH = 64) (
	input  logic                      clk            ,
	input  logic                      rst_n          ,
	//ICache Access Interface
	input  logic [  ADDRESS_BITS-1:0] address        ,
	output logic                      hit            ,
	output logic                      miss           ,
	output logic                      partial_access ,
	output logic [               1:0] partial_type   ,
	output logic [DATA_BUS_WIDTH-1:0] fetched_data,
	//Interface to L2 Cache
	output logic                      valid_o        ,
	input  logic                      ready_in       ,
	output logic [  ADDRESS_BITS-1:0] address_out    ,
	input  logic [   BLOCK_WIDTH-1:0] data_in
);
	localparam INDEX_BITS = $clog2(ENTRIES);
	localparam OFFSET_BITS = $clog2(BLOCK_WIDTH/INSTR_BITS)+2;
	localparam TAG_BITS = ADDRESS_BITS-OFFSET_BITS-INDEX_BITS;
	localparam OUTPUT_BITS = $clog2(ASSOCIATIVITY);

	// #Internal Signals#
	logic [ASSOCIATIVITY-1 : 0][BLOCK_WIDTH-1 : 0]  data;
	logic [ASSOCIATIVITY-1 : 0][TAG_BITS-1 : 0] 	tag;
	logic [ASSOCIATIVITY-1 : 0][ENTRIES-1:0]		validity;
	logic [      ASSOCIATIVITY-1 : 0] write_enable   ;
	logic [           TAG_BITS-1 : 0] new_tag,tag_usearch,saved_tag;
	logic [         INDEX_BITS-1 : 0] line_selector  ;
	logic [      ASSOCIATIVITY-1 : 0] entry_found    ;
	logic [        OFFSET_BITS-2 : 0] offset_selector;
	logic [        BLOCK_WIDTH-1 : 0] data_bus       ;
	logic [       ADDRESS_BITS-1 : 0] saved_address  ;
	logic [        BLOCK_WIDTH-1 : 0] new_data,saved_data;
	logic [        OUTPUT_BITS-1 : 0] referenced_read,referenced_set,lru_way,new_valid_entry;
	logic [      ASSOCIATIVITY-1 : 0] all_valid_temp ;
	logic [                    1 : 0] miss_fsm       ;
	logic [$clog2(BLOCK_WIDTH)-1 : 0] starting_bit   ;
	logic                             all_valid,nvalid_used,lru_used,lru_update;

	//use the offset_selector to choose the correct instruction from the block
	assign offset_selector = (miss_fsm==2) ? saved_address[OFFSET_BITS-1 : 1] : address[OFFSET_BITS-1 : 1];
	//use the line selector to index the cache banks
	assign line_selector   = (miss_fsm==2) ? saved_address[OFFSET_BITS+INDEX_BITS-1 : OFFSET_BITS] : address[OFFSET_BITS+INDEX_BITS-1 : OFFSET_BITS];
	//use the tag_usearch to find the match in the Tag Bank
	assign tag_usearch     = (miss_fsm==2) ? saved_address[OFFSET_BITS+INDEX_BITS+TAG_BITS-1 : OFFSET_BITS+INDEX_BITS] : address[OFFSET_BITS+INDEX_BITS+TAG_BITS-1 : OFFSET_BITS+INDEX_BITS];
	assign partial_access  = |partial_type;
	always_comb begin : partialType
		if(offset_selector[1:0]==2'b11 && &offset_selector[OFFSET_BITS -2:2]) begin
			partial_type = 1;
		end else if(offset_selector[1:0]==2'b10 && &offset_selector[OFFSET_BITS -2:2]) begin
			partial_type = 2;
		end else if(offset_selector[1:0]==2'b01 && &offset_selector[OFFSET_BITS -2:2]) begin
			partial_type = 3;
		end else begin
			partial_type = 0;
		end
	end
	//values used for cache update
	assign new_tag       = saved_tag;
	assign new_data      = saved_data;

	//SRAM TAG-DATA BANKS
	//Generate the Cache Banks(accessed in parallel) : ( 1 Bank for Tags and 1 Bank for Data ) per way
	genvar i;
	generate
	for (i = 0; i < ASSOCIATIVITY ; i = i + 1) begin: gen_sram
		// Initialize the Tag Banks for each Set 	-> Outputs the saved Tags
		sram #(.SIZE        (ENTRIES),
               .DATA_WIDTH  (TAG_BITS),
               .RD_PORTS    (1),
               .WR_PORTS    (1),
               .RESETABLE   (0))
        SRAM_TAG(.clk                  (clk),
        		 .rst_n 			   (rst_n),
                 .wr_en                (write_enable[i]),
                 .read_address         (line_selector),
                 .data_out             (tag[i]),
                 .write_address        (line_selector),
                 .new_data             (new_tag));
		// Initialize the Data Banks for each Set 	-> Outputs the saved Data
	    sram #(.SIZE        (ENTRIES),
               .DATA_WIDTH  (BLOCK_WIDTH),
               .RD_PORTS    (1),
               .WR_PORTS    (1),
               .RESETABLE   (0))
        SRAM_DATA(.clk                  (clk),
        		  .rst_n 			    (rst_n),
                  .wr_en                (write_enable[i]),
                  .read_address         (line_selector),
                  .data_out             (data[i]),
                  .write_address        (line_selector),
                  .new_data             (new_data));
	end
	endgenerate
	//Replacement Policy Modules
	lru #(ASSOCIATIVITY,ENTRIES,INDEX_BITS,OUTPUT_BITS)
	LRU(.clk            (clk),
		.rst_n          (rst_n),
		.line_selector  (line_selector),
		.referenced_set (referenced_set),
		.lru_update     (lru_update),
		.lru_way        (lru_way));
	//1-bit Wr_En for the LRU modules
	assign lru_update = hit;

	//Read & Output

	//If bypasssing is needed swap the lines for the hit assignment!!!
	assign hit  = (miss_fsm==1)? 1 : |entry_found;
	assign miss = ~(|entry_found);
	//address passed to the main memory, for the data request
	assign address_out = address;
	//begin a new request whenever we get a miss
	assign valid_o = miss & (miss_fsm==0) ;

	//Assert the Individul hit Lines for Each Way
	always_comb begin : FindEntry
		for (int i = 0; i < ASSOCIATIVITY; i++) begin
			if((tag[i]==tag_usearch) && validity[i][line_selector]) begin
				entry_found[i] = 'd1;
			end else begin
				entry_found[i] = 'd0;
			end
		end
	end

	//Push the Correct Data Block to the data Bus
	always_comb begin : OutputBus
		//Use the Data from next Memory level as default case, so you can bypass them if needed
		//also check on the hit signal assignment for more info on bypass
		data_bus = saved_data;
		referenced_read = 'd1;
		for (int i = 0; i < ASSOCIATIVITY; i++) begin
			if(entry_found[i]) begin
				data_bus = data[i];
				referenced_read = i;
			end
		end
	end
	//Choose the Correct Instruction and Output It
	assign  starting_bit    = offset_selector << 4;
	// assign	fetched_data = partial_access? {{16{1'b0}},data_bus[starting_bit +: DATA_BUS_WIDTH/2]} : data_bus[starting_bit +: DATA_BUS_WIDTH];
	always_comb begin : DATA_OUT
		if(partial_type==3) begin
			fetched_data = {{48{1'b0}},data_bus[starting_bit +: DATA_BUS_WIDTH/4]};
		end else if(partial_type==2) begin
			fetched_data = {{32{1'b0}},data_bus[starting_bit +: DATA_BUS_WIDTH/2]};
		end else if(partial_type==1) begin
			fetched_data = {{16{1'b0}},data_bus[starting_bit +: 3*DATA_BUS_WIDTH/4]};
		end else begin
			fetched_data = data_bus[starting_bit +: DATA_BUS_WIDTH];
		end
	end
	//Pick the correct Referenced Set
	always_comb begin : referencedSet
		if((miss_fsm==1)) begin
			if(nvalid_used) begin
				referenced_set = new_valid_entry;
			end else begin
				referenced_set = lru_way;
			end
		end else begin
			referenced_set = referenced_read;
		end
	end
	//Assert all_valid lines -> indicates if all the selected entries are all valid
	always_comb begin : IsAllValid
		for (int i = 0; i < ASSOCIATIVITY; i++) begin
			all_valid_temp[i] = validity[i][line_selector];
		end
	end
	assign all_valid = &all_valid_temp;

	//FSM state - Block Cache!
	always_ff @(posedge clk or negedge rst_n) begin : FSM
		if(!rst_n) begin
			miss_fsm      <= 0;
			saved_address <= 'b0;
			saved_tag     <= 'b0;
			saved_data    <= 'b0;
		end else begin
			//Block Cache when miss appears
			if(miss && (miss_fsm==0) && (!ready_in)) begin
				miss_fsm      <= 2;
				saved_address <= address;
				saved_tag     <= tag_usearch;
			//Bypass FSM stage 2 if data are already ready and go to 1
			end else if(miss && (miss_fsm==0) && ready_in) begin
				miss_fsm      <= 1;
				saved_address <= address;
				saved_tag     <= tag_usearch;
				saved_data    <= data_in;
			//go to FSM stage 1 when data are ready
			end else if(miss_fsm==2 && ready_in) begin
				miss_fsm   <= 1;
				saved_data <= data_in;
			//disable blocking after the Write
			end else if(miss_fsm==1) begin
				miss_fsm <= 0;
			end
		end
	end

	//REPLACEMENT
	//Assert the Write Signals
	generate
		if(ASSOCIATIVITY>1) begin
			always_comb begin : WriteSignals
				if(miss_fsm==1) begin
                    write_enable    = 0;
                    new_valid_entry = 0;
					//Check if invalid entries exist
					if(!all_valid) begin
						lru_used    = 1'b0;								//lru_way not used
						nvalid_used = 1'b1;								//new valid is used
						for (int i = 0; i < ASSOCIATIVITY; i++) begin
							if(!validity[i][line_selector]) begin
								new_valid_entry = i;
								write_enable[i] = 1'b1;
								break;
							end
						end
					end else begin
					   //no invalid entries, evict LRU
						write_enable[lru_way]= 1'b1;
						lru_used             = 1'b1;
						nvalid_used          = 1'b0;
                        new_valid_entry      = 0;
					end
				end else begin
					nvalid_used     = 1'b0;
					lru_used        = 1'b0;
					new_valid_entry = 0;
                    write_enable    = 0;
				end
			end
		end else if(ASSOCIATIVITY==1) begin
			//Assert the Write Signals
			always_comb begin : WriteBack
				if(miss_fsm==1) begin
					write_enable = 'b1;
				end else begin
					write_enable = 'b0;
				end
			end
		end
	endgenerate
	//Assert the Validities
	generate
		if(ASSOCIATIVITY>1) begin
			//Update the Validity Bits
			always_ff @(posedge clk or negedge rst_n) begin : UValBits
				if(!rst_n) begin
					for (int i = 0; i < ASSOCIATIVITY; i++) begin
						validity[i] <= 'b0;
					end
				end else begin
					if(lru_used) begin
						validity[lru_way][line_selector] <= 'd1;
					end
					if(nvalid_used) begin
						validity[new_valid_entry][line_selector] <= 'd1;
					end
				end
			end
		end else if(ASSOCIATIVITY==1) begin
			//Update the Validity Bits
			always_ff @(posedge clk or negedge rst_n) begin : UValBits
				if(!rst_n) begin
					validity <= 'b0;
				end else begin
					if(miss_fsm==1) begin
						validity[line_selector] <= 'b1;
					end
				end
			end
		end
	endgenerate


`ifdef INCLUDE_SVAS
    `include "icache_sva.sv"
`endif

endmodule