module requestor #(parameter int ADDR_RANGE=32768,
				   parameter int LENGTH_RANGE=32,
				   parameter int BUS_WIDTH=32,
                   parameter int LANES_DATA_WIDTH=64,
				   parameter int VREG_BITS=256,
				   parameter int NUMBER_VECTOR_LANES=4
				 )(input logic clk,
                   input logic rst,
                   //inputs from processor
                   input logic memory_enable,
				   input logic operation,
				   input logic [1:0] mode_in,
				   input logic [2:0] sew_in,
				   input logic [2:0] indexed_sew,
				   input logic [VREG_BITS-1:0] indexed_in,
				   input logic [LANES_DATA_WIDTH-1:0] wrdata_in [0:NUMBER_VECTOR_LANES-1],
				   input logic [$clog2(ADDR_RANGE)-1:0] stride_in,
				   input logic [$clog2(ADDR_RANGE)-1:0] addr_in,
                    //inputs from completer
				   input logic ready,
				   input logic [BUS_WIDTH-1:0] rddata,
				   input logic rddatavalid,
                   	//outputs to completer
				   output logic [BUS_WIDTH-1:0] wrdata,
				   output logic [$clog2(ADDR_RANGE)-1:0] addr,
				   output logic [$clog2(LENGTH_RANGE):0] length,
				   output logic [1:0] mode,
				   output logic wr,
				   output logic rd,
				   output logic rddataready,
                   //outputs to processor
                   output logic [LANES_DATA_WIDTH-1:0] rddata_out [0:NUMBER_VECTOR_LANES-1],
				   output logic [NUMBER_VECTOR_LANES-1:0] valid_read,
				   output logic store_done,

				   input logic mem_ready);

logic [VREG_BITS-1:0] wrdata_inserted;
logic [VREG_BITS-1:0] wrdata_temp;
logic [VREG_BITS-1:0] rddata_temp;
logic [VREG_BITS-1:0] indexed_value;
logic [$clog2(ADDR_RANGE)-1:0] strided_value;
logic [$clog2(ADDR_RANGE)-1:0] addr_temp;
logic [1:0] mode_temp;
logic [2:0] sew_temp;
logic [2:0] indexed_sew_choice;
logic flag;

logic sew_64;
logic part_of_the_same_word;
assign sew_64=sew_temp[0] & sew_temp[1];
assign part_of_the_same_word=(flag==0);


always_comb begin
	for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
		wrdata_inserted[LANES_DATA_WIDTH*i+:LANES_DATA_WIDTH]=wrdata_in[i];
	end
end

typedef enum logic [3:0] {IDLE=4'b0001,
						  READ=4'b0010,
						  WRITE=4'b0100,
						  WORKING_READ=4'b1000} fsm_state;

fsm_state state,previous_state;

//save states
always_ff @(posedge clk or posedge rst) begin
	if(rst) begin
		addr_temp<=0;
		mode_temp<=0;
		sew_temp<=0;
		indexed_value<=0;
		strided_value<=0;
		wrdata_temp<=0;
		indexed_sew_choice<=0;
	end
	else begin
		if(state==IDLE & memory_enable) begin
			addr_temp<=addr_in;
			mode_temp<=mode_in;
			sew_temp<=(mode_in!=3)?sew_in:indexed_sew;
			indexed_value<=indexed_in;
			strided_value<=stride_in;
			wrdata_temp<=wrdata_inserted;
			indexed_sew_choice<=sew_in;
		end
	end
end
//

//setting length for burst
logic [$clog2(LENGTH_RANGE):0] length_temp;

logic [4:0] length_choice;
assign length_choice={mode_temp,sew_temp};

always_comb begin
	casez(length_choice)
		5'b01???:length_temp=VREG_BITS/BUS_WIDTH;
		5'b1?000:length_temp=4*VREG_BITS/BUS_WIDTH;
		5'b1?001:length_temp=2*VREG_BITS/BUS_WIDTH;
		5'b1?01?:length_temp=VREG_BITS/BUS_WIDTH;
		default:length_temp=0;
	endcase
end
//

//counter
logic [$clog2(LENGTH_RANGE)-1:0] counter;

logic [1:0] counter_choice;

logic comp;
logic increase;

assign increase=((wr & ready) | (rddataready & rddatavalid));
assign comp=(counter==length-1);
assign counter_choice={comp,increase};

always_ff @(posedge clk or posedge rst) begin
	if(rst)
		counter<=0;
	else begin
		case(counter_choice)
			2'b01:counter<=counter+1'b1;
			2'b11:counter<=0;
			default:counter<=counter;
		endcase
	end
end
//


//fsm for setting signals between requestor or completer
logic [1:0] input_choice;

assign input_choice={memory_enable,operation};

always_ff @(posedge clk or posedge rst) begin
	if(rst)
		state<=IDLE;
	else begin
		case(state)
			IDLE: begin
				casez(input_choice)
					2'b10:state<=READ;
					2'b11:state<=WRITE;
					default:state<=IDLE;
				endcase
			end
			READ: begin
				if(ready)
					state<=WORKING_READ;
			end
			WRITE: begin
				if(comp && wr && ready)
					state<=IDLE;
			end
			WORKING_READ: begin
				if(comp && rddataready && rddatavalid)
					state<=IDLE;
			end
		endcase
	end
end
//

//previous_state
always_ff @(posedge clk or posedge rst) begin
    if(rst)
        previous_state<=IDLE;
    else
        previous_state<=state;
end
//

//flag for 64 bits words so stride doesnt increase
always_ff @(posedge clk or posedge rst) begin
	if(rst)
		flag<=0;
	else begin
		case(counter_choice)
			2'b11:flag<=0;
			2'b01:flag<=flag+1;
		endcase
	end
end
//

//calculating index offset
logic [$clog2(ADDR_RANGE)-1:0] indexed_offset;
logic [$clog2(ADDR_RANGE)-1:0] indexed_final;

always_comb begin
    case(indexed_sew_choice)
        3'b000:indexed_offset=(indexed_value[8*counter+:8]>>2);
        3'b001:indexed_offset=(indexed_value[16*counter+:16]>>2);
        3'b010:indexed_offset=((indexed_value[32*counter+:32])>>2);
        3'b011:indexed_offset=((indexed_value[64*(counter>>2)+:64])>>2);
        default:indexed_offset=0;
    endcase
end

assign indexed_final=(part_of_the_same_word && sew_64)?indexed_offset+1:indexed_offset;
//

//calculating stride offset
logic [$clog2(ADDR_RANGE)-1:0] stride_offset;

logic [3:0] stride_choice;
assign stride_choice={part_of_the_same_word,sew_64,increase,comp};

always_ff @(posedge clk or posedge rst) begin
	if(rst)
		stride_offset<=0;
	else begin
		casez(stride_choice)
			4'b??11:stride_offset<=0;
			4'b?010:stride_offset<=stride_offset+strided_value;
			4'b0110:stride_offset<=stride_offset+strided_value-1;
			4'b1110:stride_offset<=stride_offset+1;
			default:stride_offset<=stride_offset;
		endcase
	end
end
//


//rddata_temp
always_ff @(posedge clk or posedge rst) begin
	if(rst)
		rddata_temp<=0;
	else begin
		casez(length_choice)
			5'b01???: begin
				if(rddataready && rddatavalid)
					rddata_temp[BUS_WIDTH*counter+:BUS_WIDTH]<=rddata;
			end
			5'b1?000: begin
				if(rddataready && rddatavalid)
					rddata_temp[8*counter+:8]<=rddata[7:0];
			end
			5'b1?001: begin
				if(rddataready && rddatavalid)
					rddata_temp[16*counter+:16]<=rddata[15:0];
			end
			5'b1?01?: begin
				if(rddataready && rddatavalid)
					rddata_temp[32*counter+:32]<=rddata[31:0];
			end
			default:rddata_temp<=rddata_temp;
		endcase
	end
end
//
//////////////////////////////////////////////////////////////
/////             Setting outputs to completer           /////
/////                                                    /////
//////////////////////////////////////////////////////////////

//set wrdata that we will push to completer
always_comb begin
	casez(length_choice)
		5'b01???:wrdata=wrdata_temp[BUS_WIDTH*counter+:BUS_WIDTH];
		5'b1?000:wrdata={{(BUS_WIDTH-8){1'b0}},wrdata_temp[8*counter+:8]};
		5'b1?001:wrdata={{(BUS_WIDTH-16){1'b0}},wrdata_temp[16*counter+:16]};
		5'b1?01?:wrdata=wrdata_temp[BUS_WIDTH*counter+:BUS_WIDTH];
		default:wrdata=0;
	endcase
end
//

always_comb begin
	case(mode_temp)
		2'b10:addr=addr_temp+stride_offset;
		2'b11:addr=addr_temp+indexed_final;
		default:addr=addr_temp;
	endcase
end


assign rd=(state==READ);
assign wr=(state==WRITE);
assign rddataready=(state==WORKING_READ);
assign mode=mode_temp;
assign length=length_temp;

//////////////////////////////////////////////////////////////
/////             Setting outputs to processor           /////
/////                                                    /////
//////////////////////////////////////////////////////////////

//rddata_out
always_comb begin
	for(int i=0;i<NUMBER_VECTOR_LANES;i++) begin
		rddata_out[i]=rddata_temp[LANES_DATA_WIDTH*i+:LANES_DATA_WIDTH];
	end
end
//

//valid_read
always_ff @(posedge clk or posedge rst) begin
	if(rst)
		valid_read<=0;
	else begin
		if(state==IDLE && previous_state==WORKING_READ)
			valid_read<={NUMBER_VECTOR_LANES{1'b1}};
		else
			valid_read<=0;
	end
end
//

//store_done
always_ff @(posedge clk or posedge rst) begin
	if(rst)
		store_done<=0;
	else begin
		if(state==IDLE && previous_state==WRITE)
			store_done<=1;
		else
			store_done<=0;
	end
end
//


endmodule