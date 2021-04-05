/*
* @info Brach Target Buffer
* @info Top Modules: Predictor.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief A target predictor, addressable with the PC address, for use in dynamic predictors
*
* @note The SRAM Stores in each entry: [OriginatingPC/TargetPC]
*
*/
module btb #(PC_BITS=32,SIZE=1024) (
    input  logic               clk       ,
    input  logic               rst_n     ,
    //Update Interface
    input  logic               wr_en     ,
    input  logic [PC_BITS-1:0] orig_pc   ,
    input  logic [PC_BITS-1:0] target_pc ,
    //Invalidation Interface
    input  logic               invalidate,
    input  logic [PC_BITS-1:0] pc_invalid,
    //Access Interface
    input  logic [PC_BITS-1:0] pc_in_a   ,
    input  logic [PC_BITS-1:0] pc_in_b   ,
    //Output Ports
    output logic               hit_a     ,
    output logic [PC_BITS-1:0] next_pc_a ,
    output logic               hit_b     ,
    output logic [PC_BITS-1:0] next_pc_b
);
    localparam SEL_BITS = $clog2(SIZE);
	// #Internal Signals#
    logic [1:0][ 2*PC_BITS-1:0] data_out;
    logic [1:0][SEL_BITS-1:0]   read_addresses;
    logic [SEL_BITS-1 : 0]      line_selector_a, line_selector_b, line_write_selector, line_inv_selector;
    logic [ 2*PC_BITS-1:0]      retrieved_data_a, retrieved_data_b, new_data;
    logic [      SIZE-1:0]      validity        ;
    logic                       masked_wr_en    ;

    localparam int BTB_SIZE = SIZE*2*PC_BITS + $bits(validity); //dummy for debugging
	//create the line selector from the pc_in_a bits k-2
    assign line_selector_a = pc_in_a[SEL_BITS : 1];
    assign line_selector_b = pc_in_b[SEL_BITS : 1];
    //Create the line selector for the write operation
    assign line_write_selector = orig_pc[SEL_BITS : 1];
	//Create the new Data to be stored ([orig_pc/target_pc])
	assign new_data            = { orig_pc,target_pc };
	//Create the Invalidation line selector
	assign line_inv_selector   = pc_invalid[SEL_BITS : 1];

    assign read_addresses[0] = line_selector_a;
    assign read_addresses[1] = line_selector_b;
    sram #(.SIZE        (SIZE),
           .DATA_WIDTH  (2*PC_BITS),
           .RD_PORTS    (2),
           .WR_PORTS    (1),
           .RESETABLE   (0))
    SRAM (.clk                 (clk),
          .rst_n               (rst_n),
          .wr_en               (wr_en),
          .read_address        (read_addresses),
          .data_out            (data_out),
          .write_address       (line_write_selector),
          .new_data            (new_data));

    //always output the target PC
    assign retrieved_data_a = data_out[0];
    assign retrieved_data_b = data_out[1];
    assign next_pc_a        = retrieved_data_a[0 +: PC_BITS];
    assign next_pc_b        = retrieved_data_b[0 +: PC_BITS];

	always_comb begin : HitOutputA
		//Calculate hit_a signal
		if (retrieved_data_a[PC_BITS +: PC_BITS]==pc_in_a) begin
			hit_a = validity[line_selector_a];
		end else begin
			hit_a = 0;
		end
	end
    always_comb begin : HitOutputB
        //Calculate hit_a signal
        if (retrieved_data_b[PC_BITS +: PC_BITS]==pc_in_b) begin
            hit_b = validity[line_selector_b];
        end else begin
            hit_b = 0;
        end
    end

    assign masked_wr_en = invalidate ? wr_en & (line_inv_selector!=line_write_selector) : wr_en;
	always_ff @(posedge clk or negedge rst_n) begin : ValidityBits
		if(!rst_n) begin
			 validity[SIZE-1:0] <= 'd0;
		end else begin
			 if(invalidate) begin
			 	validity[line_inv_selector] <= 0;
			 end
             if(masked_wr_en) begin
			 	validity[line_write_selector] <= 1;
			 end
		end
	end

endmodule