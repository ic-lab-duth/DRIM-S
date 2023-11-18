/*
 * @info Data Cache Top Module
 * @info Sub-Modules: SRAM.sv, data_operation.sv, ld_st_buffer.sv, wait_buffer.sv
 *
 * @author VLSI Lab, EE dept., Democritus University of Thrace
 *
 * @brief Non-Blocking Data Cache
 *
 * @note  Cache configuration: {Valid}{Dirty}[Tag][Data]
 *
 * @param DATA_WIDTH    : # of Data Bits
 * @param ADDR_BITS     : # of Address Bits
 * @param R_WIDTH       : # of Register Bits
 * @param MICROOP       : # of Microoperation Bits
 * @param ROB_TICKET    : # of Rob's ticket Bits
 * @param ASSOCIATIVITY : # of Ways in the DATA CACHE
 * @param ENTRIES       : # of Blocks per Way
 * @param BLOCK_WIDTH   : # of Block Bits
 * @param BUFFER_SIZES  : # of Entries in the Buffers (Load/Store/Wait) (affects miss_under_miss performance)
 */
`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module data_cache #(
    parameter DATA_WIDTH    = 32,
    parameter ADDR_BITS     = 32,
    parameter R_WIDTH       = 6,
    parameter MICROOP       = 5,
    parameter ROB_TICKET    = 3,
    parameter ASSOCIATIVITY = 4,
    parameter ENTRIES       = 256,
    parameter BLOCK_WIDTH   = 256,
    parameter BUFFER_SIZES  = 4
) (
    input  logic                   clk                ,
    input  logic                   rst_n              ,
    input  logic                   output_used        ,
    //Load Input Port
    input  logic                   load_valid         ,
    input  logic [  ADDR_BITS-1:0] load_address       ,
    input  logic [    R_WIDTH-1:0] load_dest          ,
    input  logic [    MICROOP-1:0] load_microop       ,
    input  logic [ ROB_TICKET-1:0] load_ticket        ,
    //Store Input Port
    input  logic                   store_valid        ,
    input  logic [  ADDR_BITS-1:0] store_address      ,
    input  logic [ DATA_WIDTH-1:0] store_data         ,
    input  logic [    MICROOP-1:0] store_microop      ,
    //Request Write Port to L2
    output logic                   write_l2_valid     ,
    output logic [  ADDR_BITS-1:0] write_l2_addr      ,
    output logic [BLOCK_WIDTH-1:0] write_l2_data      ,
    //Request Read Port to L2
    output logic                   request_l2_valid   ,
    output logic [  ADDR_BITS-1:0] request_l2_addr    ,
    //Update Port from L2
    input  logic                   update_l2_valid    ,
    input  logic [  ADDR_BITS-1:0] update_l2_addr     ,
    input  logic [BLOCK_WIDTH-1:0] update_l2_data     ,
    //Output Port
    output logic                 cache_load_blocked,
    output logic                 cache_store_blocked,
    output logic                 cache_will_block,
    output ex_update             served_output
);
    //Local Parameter
    localparam OUTPUT_BITS = $clog2(ASSOCIATIVITY);
    localparam INDEX_BITS  = $clog2(ENTRIES);
    localparam OFFSET_BITS = $clog2(BLOCK_WIDTH/DATA_WIDTH)+2;
    localparam TAG_BITS = ADDR_BITS - INDEX_BITS - OFFSET_BITS;

    // #Internal Signals#
    logic [ROB_TICKET-1:0] ld_head_ticket, wt_s_ticket, wt_w_ticket;
    logic [ ADDR_BITS-1:0] ld_head_addr, st_head_addr, wt_w_address, saved_search_addr, served_address, wt_search_addr, search_address_o;
    logic [DATA_WIDTH-1:0] st_head_data, wt_s_data, wt_s_frw_data, wt_w_data, st_s_data, served_data;
    logic [   MICROOP-1:0] ld_head_microop, st_head_microop, wt_s_microop, wt_w_microop,  served_microop;
    logic [   R_WIDTH-1:0] ld_head_dest, wt_s_dest, wt_w_dest;
    logic                  ld_ready, ld_valid, st_ready, st_valid, wt_ready, wt_valid, wt_in_walk;
    logic                  ld_pop, ld_push, st_pop, st_push, store_isfetched, wt_push;
    logic                  ld_head_isfetched, st_head_isfetched;
    logic                  wt_invalidate, wt_found_one, wt_s_frw_hit, wt_s_isstore, wt_w_isstore;
    logic                  ld_s_phit, st_s_vhit, st_s_phit, served_exc_v;

    logic [ASSOCIATIVITY-1 : 0][BLOCK_WIDTH-1 : 0]  data, overwritten_data;
    logic [ASSOCIATIVITY-1 : 0][TAG_BITS-1 : 0]     tag, overwritten_tag;
    logic [ASSOCIATIVITY-1 : 0][ENTRIES-1:0]        validity, dirty;
    logic [$clog2(ASSOCIATIVITY)-1 : 0]             entry_used;
    logic [   INDEX_BITS-1 : 0] read_line_select, write_line_select;
    logic [  OUTPUT_BITS-1 : 0] lru_way, new_valid_entry;
    logic [ASSOCIATIVITY-1 : 0] write_en_tag, write_en_data, all_valid_temp, entry_found;
    logic [     TAG_BITS-1 : 0] new_tag, update_l2_tag, new_modded_tag, tag_usearch, tag_picked;
    logic [  BLOCK_WIDTH-1 : 0] new_data, new_modded_block, block_picked;
    logic [   DATA_WIDTH-1 : 0] data_picked;
    logic [              3 : 0] served_exc;
    logic                       all_valid, lru_update, hit, served, must_wait;

    logic [       OFFSET_BITS-1 : 0]  offset_select;
    logic [1:0][   INDEX_BITS-1 : 0]  read_address;
    logic [ASSOCIATIVITY-1 : 0][1:0][TAG_BITS-1:0] read_tag;
    logic [ASSOCIATIVITY-1 : 0][1:0][BLOCK_WIDTH-1:0] read_data;
    //Serve FSM
    typedef enum logic [2:0] {IDLE, LD_IN, ST_IN, LD, ST, WT} serve_mode;
    serve_mode serve;

    //Create the Line selectors for the Data Banks Indexing
    assign read_line_select  = served_address[OFFSET_BITS+INDEX_BITS-1 : OFFSET_BITS];
    assign write_line_select = update_l2_valid ? update_l2_addr[OFFSET_BITS+INDEX_BITS-1 : OFFSET_BITS] : served_address[OFFSET_BITS+INDEX_BITS-1 : OFFSET_BITS];
    assign offset_select     = served_address[OFFSET_BITS-1 : 0];
    assign new_data          = update_l2_valid ? update_l2_data : new_modded_block;
    assign new_tag           = update_l2_valid ? update_l2_tag : new_modded_tag;                    //- same as the saved/read tag
    assign update_l2_tag     = update_l2_addr[OFFSET_BITS+INDEX_BITS +: TAG_BITS];
    assign tag_usearch       = served_address[OFFSET_BITS+INDEX_BITS +: TAG_BITS];
    //Create the Read Requests towards the L2
    assign request_l2_valid = (serve==LD_IN & ~served & ~ld_s_phit & ~st_s_phit) | (serve==ST_IN & ~served & ~st_s_phit & ~ld_s_phit & ~hit);
    assign request_l2_addr  = served_address;
    //Create the Write Requests towards the L2
    assign write_l2_valid = update_l2_valid & all_valid & dirty[lru_way][write_line_select];
    assign write_l2_addr  = {overwritten_tag[lru_way],write_line_select, {OFFSET_BITS{1'b0}}}; //* bug was here
    assign write_l2_data  = overwritten_data[lru_way];

    assign cache_will_block    = wt_invalidate;
    assign cache_load_blocked  = wt_in_walk | ~ld_ready | ~wt_ready;
    assign cache_store_blocked = wt_in_walk | (load_valid & ~cache_load_blocked) | ~st_ready | ~wt_ready;
    //Create the Output
    always_comb begin : CreateOutput
        if(serve==LD_IN) begin
            served_output.valid           = served;
            served_output.destination     = load_dest;
            served_output.ticket          = load_ticket;
            served_output.valid_exception = served_exc_v;
            served_output.cause           = served_exc;
        end else if(serve==ST_IN) begin
            served_output.valid           = 1'b0;
            served_output.destination     = load_dest;
            served_output.ticket          = load_ticket;
            served_output.valid_exception = served_exc_v;
            served_output.cause           = served_exc;
        end else if(serve==LD) begin
            served_output.valid           = 1'b1;
            served_output.destination     = ld_head_dest;
            served_output.ticket          = ld_head_ticket;
            served_output.valid_exception = served_exc_v;
            served_output.cause           = served_exc;
        end else if(serve==ST) begin
            served_output.valid           = 1'b0;
            served_output.destination     = load_dest;
            served_output.ticket          = load_ticket;
            served_output.valid_exception = served_exc_v;
            served_output.cause           = served_exc;
        end else if(serve==WT) begin
            served_output.valid           = ~wt_s_isstore;
            served_output.destination     = wt_s_dest;
            served_output.ticket          = wt_s_ticket;
            served_output.valid_exception = served_exc_v;
            served_output.cause           = served_exc;
        end else begin
            served_output.valid           = 1'b0;
            served_output.destination     = load_dest;
            served_output.ticket          = load_ticket;
            served_output.valid_exception = served_exc_v;
            served_output.cause           = served_exc;
        end
    end

    //SRAM TAG-DATA BANKS
    //Generate the Cache Banks(accessed in parallel) : ( 1 Bank for Tags and 1 Bank for Data ) per way
    genvar i;
    generate
        assign read_address[0] = read_line_select;
        assign read_address[1] = write_line_select;
        for (i = 0; i < ASSOCIATIVITY ; i = i + 1) begin
            assign tag[i]             = read_tag[i][0];
            assign overwritten_tag[i] = read_tag[i][1];
            assign data[i]            = read_data[i][0];
            assign overwritten_data[i]= read_data[i][1];
            // Initialize the Tag Banks for each Set    -> Outputs the saved Tags
            sram #(.SIZE        (ENTRIES),
                   .DATA_WIDTH  (TAG_BITS),
                   .RD_PORTS    (2),
                   .WR_PORTS    (1),
                   .RESETABLE   (0))
            SRAM_TAG(.clk                  (clk),
                     .rst_n                (rst_n),
                     .read_address         (read_address),
                     .data_out             (read_tag[i]),
                     .wr_en                (write_en_tag[i]),
                     .write_address        (write_line_select),
                     .new_data             (new_tag));
            // Initialize the Data Banks for each Set   -> Outputs the saved Data
            sram #(.SIZE        (ENTRIES),
                   .DATA_WIDTH  (BLOCK_WIDTH),
                   .RD_PORTS    (2),
                   .WR_PORTS    (1),
                   .RESETABLE   (0))
            SRAM_DATA(.clk                  (clk),
                      .rst_n                (rst_n),
                      .read_address         (read_address),
                      .data_out             (read_data[i]),
                      .wr_en                (write_en_data[i]),
                      .write_address        (write_line_select),
                      .new_data             (new_data));
        end
    endgenerate
    //Replacement Policy Modules
    generate
        if(ASSOCIATIVITY>1) begin

            lru #(ASSOCIATIVITY,ENTRIES,INDEX_BITS,OUTPUT_BITS)
            LRU(.clk            (clk),
                .rst_n          (rst_n),
                .line_selector  (update_l2_valid ? update_l2_addr[OFFSET_BITS+INDEX_BITS-1 : OFFSET_BITS] : read_line_select), //* bug was here
                .referenced_set (entry_used),
                .lru_update     (lru_update),
                .lru_way        (lru_way));
        end
    endgenerate

    //Assert the Individul Hit Lines for Each Way
    always_comb begin : FindEntry
        entry_used  = 0;
        block_picked = data[0];
        tag_picked  = tag[0];
        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            if((tag[i]==tag_usearch) && validity[i][read_line_select]) begin
                entry_found[i] = 1'd1;
                entry_used     = i;
                block_picked    = data[i];
                tag_picked     = tag[i];
            end else begin
                entry_found[i] = 1'd0;
            end
        end
    end
    assign hit = |entry_found;

    //Pick the correct Data and Serve
    always_comb begin : DataServe
        if(serve==LD_IN) begin
            if (load_dest == 0) begin //* bug was here
                served     = 1'b1;
                must_wait  = 1'b0;
                lru_update = 1'b0;
                served_output.data = 0;
            end else if(wt_s_frw_hit) begin
                //Forward from Wait Buffer
                served     = 1'b1;
                must_wait  = 1'b0;
                lru_update = 1'b0;
                served_output.data = wt_s_frw_data;
            end else if(st_s_vhit) begin
                //Forward from Store Buffer
                served     = 1'b1;
                must_wait  = 1'b0;
                lru_update = 1'b0;
                served_output.data = st_s_data;
            end else if(st_s_phit) begin //* bug was here
                //GO to wait buffer
                served     = 1'b0;
                must_wait  = 1'b1;
                lru_update = 1'b0;
                served_output.data = served_data;
            end else if(hit) begin
                //Grab from Cache
                served     = 1'b1;
                must_wait  = 1'b0;
                lru_update = 1'b1;
                served_output.data = served_data;
            end else begin
                //Can not Serve
                served     = 1'b0;
                lru_update = 1'b0;
                served_output.data = served_data;
                if(st_s_phit | ld_s_phit) begin
                //Store in Wait Buffer
                    must_wait = 1'b1;
                end else begin
                //Store in Load Buffer
                    must_wait = 1'b0;
                end
            end
        end else if(serve==ST_IN) begin
            served_output.data = served_data;
            if(update_l2_valid) begin
                //Write Conflict.. Store will wait in Buffers
                served     = 1'b0;
                lru_update = 1'b0;
                if(st_s_phit | ld_s_phit) begin
                    //Store in Wait Buffer
                    must_wait = 1'b1;
                end else begin
                    //Store in Store Buffer
                    must_wait = 1'b0;
                end
            end else begin
                //Serve the Store
                if(st_s_phit) begin
                    //Previous Store was in ST Buffer.. Must wait in Wait Buffer
                    served     = 1'b0;
                    must_wait  = 1'b1;
                    lru_update = 1'b0;
                end else if(ld_s_phit) begin //* bug was here
                    //If load in LD Buffer, store in Wait Buffer
                    served     = 1'b0;
                    must_wait  = 1'b1;
                    lru_update = 1'b0;
                end else if(hit) begin
                    //If hit Serve Normally
                    served     = 1'b1;
                    must_wait  = 1'b0;
                    lru_update = 1'b1;
                end else begin
                    //Store in Store Buffer
                    served     = 1'b0;
                    must_wait  = 1'b0;
                    lru_update = 1'b0;
                end
            end
        end else if(serve==LD) begin
            served     = 1'b1;
            must_wait  = 1'b0;
            lru_update = 1'b1;
            served_output.data = served_data;
        end else if(serve==ST) begin
            served     = 1'b1;
            must_wait  = 1'b0;
            lru_update = 1'b1;
            served_output.data = served_data;
        end else if (serve==WT) begin
            served     = 1'b1;
            must_wait  = 1'b0;
            lru_update = 1'b1;
            served_output.data = served_data;
        end else begin
            served     = 1'b0;
            must_wait  = 1'b0;
            lru_update = 1'b0;
            served_output.data = served_data;
        end
    end
    //Search for Validities
    always_comb begin : IsAllValid
        //all_valid<='d1;
        for (int i = 0; i < ASSOCIATIVITY; i++) begin
            all_valid_temp[i] = validity[i][write_line_select];
        end
    end
    //Indicates if all entries are valid
    assign all_valid = &all_valid_temp;

    //WRITE Enablers
    generate
        if(ASSOCIATIVITY>1) begin
            always_comb begin : WriteEnablers
                new_valid_entry = 0;
                write_en_data = 'b0;
                write_en_tag  = 'b0;
                if(update_l2_valid) begin
                    write_en_data = 'b0;
                    write_en_tag  = 'b0;
                    //Check if invalid entries exist
                    if(!all_valid) begin
                        for (int i = 0; i < ASSOCIATIVITY; i++) begin
                            if(!validity[i][write_line_select]) begin
                                new_valid_entry = i;
                                write_en_data[i] = 1'b1;
                                write_en_tag[i]  = 1'b1;
                                break;
                            end
                        end
                    end else begin
                        //no invalid entries, evict LRU
                        new_valid_entry = lru_way;
                        write_en_data[lru_way] = 1'b1;
                        write_en_tag[lru_way]  = 1'b1;
                    end
                end else if (serve==ST_IN && served) begin
                    write_en_data[entry_used] = 1'b1;
                    write_en_tag[entry_used]  = 1'b0;
                end else if (serve==ST) begin
                    write_en_data[entry_used] = 1'b1;
                    write_en_tag[entry_used]  = 1'b0;
                end else if(serve==WT && wt_s_isstore) begin
                    write_en_data[entry_used] = 1'b1;
                    write_en_tag[entry_used]  = 1'b0;
                end else begin
                    write_en_data = 'b0;
                    write_en_tag  = 'b0;
                end
            end
        end else if (ASSOCIATIVITY==1) begin
            assign write_en_data = update_l2_valid | (serve==ST_IN && served) | (serve==ST) | (serve==WT && wt_s_isstore);
            assign write_en_tag  = update_l2_valid;
        end
    endgenerate

    //VALIDITY Management
    generate
        if(ASSOCIATIVITY>1) begin
            always_ff @(posedge clk or negedge rst_n) begin : ValidityManagement
                if(!rst_n) begin
                    for (int i = 0; i < ASSOCIATIVITY; i++) begin
                        validity[i] <= 'b0;
                    end
                end else begin
                    if(update_l2_valid) begin
                        if(!all_valid) begin
                            //Store new Data into an invalid Entry
                            validity[new_valid_entry][write_line_select] <= 1'b1;
                        end else begin
                            //Store new Data into the LRU Entry
                            validity[lru_way][write_line_select] <= 1'b1;
                        end
                    end
                end
            end
        end else if (ASSOCIATIVITY==1) begin
            always_ff @(posedge clk or negedge rst_n) begin : ValidityManagement
                if(!rst_n) begin
                    validity <= 0;
                end else begin
                    if(update_l2_valid) begin
                        //Store new Data into the Entry
                        validity[write_line_select] <= 1'b1;
                    end
                end
            end
        end
    endgenerate

    //DIRTY Management
    generate
        if(ASSOCIATIVITY>1) begin
            always_ff @(posedge clk or negedge rst_n) begin : DirtyManagement
                if(!rst_n) begin
                    for (int i = 0; i < ASSOCIATIVITY; i++) begin
                        dirty[i] <= 'b0;
                    end
                end else begin
                    if(update_l2_valid) begin
                        if(!all_valid) begin
                            //Store new Data into an invalid Entry
                            dirty[new_valid_entry][write_line_select] <= 1'b0;
                        end else begin
                            //Store new Data into the LRU Entry
                            dirty[lru_way][write_line_select] <= 1'b0;
                        end
                    end else if(serve==ST_IN && served) begin
                        dirty[entry_used][write_line_select] <= 1'b1;
                    end else if(serve==ST) begin
                        dirty[entry_used][write_line_select] <= 1'b1;
                    end else if(serve==WT && wt_s_isstore) begin
                        dirty[entry_used][write_line_select] <= 1'b1;
                    end
                end
            end
        end else if (ASSOCIATIVITY==1) begin
            always_ff @(posedge clk or negedge rst_n) begin : DirtyManagement
                if(!rst_n) begin
                    dirty <= 'b0;
                end else begin
                    if(update_l2_valid) begin
                        dirty[write_line_select] <= 1'b0;
                    end else if(serve==ST_IN && served) begin
                        dirty[write_line_select] <= 1'b1;
                    end else if(serve==ST) begin
                        dirty[write_line_select] <= 1'b1;
                    end else if(serve==WT && wt_s_isstore) begin
                        dirty[write_line_select] <= 1'b1;
                    end
                end
            end
        end
    endgenerate

    //Pick what will be served (comb FSM) && Pick the address to be served this cycle
    always_comb begin : ServePriority
        if(wt_in_walk) begin
            serve          = WT;
            served_address = search_address_o;
            served_microop = wt_s_microop;
        end else if(load_valid && !output_used && ld_ready && wt_ready) begin
            serve          = LD_IN;
            served_address = load_address;
            served_microop = load_microop;
        end else if(store_valid && !output_used && st_ready && wt_ready) begin
            serve          = ST_IN;
            served_address = store_address;
            served_microop = store_microop;
        end else if(ld_valid && ld_head_isfetched && !output_used) begin
            serve          = LD;
            served_address = ld_head_addr;
            served_microop = ld_head_microop;
        end else if(st_valid && st_head_isfetched && !output_used && !update_l2_valid) begin
            serve          = ST;
            served_address = st_head_addr;
            served_microop = st_head_microop;
        end else begin
            serve          = IDLE;
            served_address = load_address;
            served_microop = load_microop;
        end
    end

    // New tag on hit stores is the same as the old one
    assign new_modded_tag = tag_picked;

    always_comb begin : DataPicked
        if(serve==ST_IN) begin
            data_picked = store_data;
        end else if(serve==ST) begin
            data_picked = st_head_data;
        end else begin
            data_picked = wt_s_data;
        end
    end
    //Initialize the Operations Module
    data_operation #(
        .ADDR_W     (OFFSET_BITS),
        .DATA_W     (DATA_WIDTH),
        .MICROOP    (MICROOP),
        .BLOCK_W    (BLOCK_WIDTH),
        .LOAD_ONLY  (0)
        )
    data_operation  (
        .input_address  (offset_select),
        .input_block    (block_picked),
        .input_data     (data_picked),
        .microop        (served_microop),

        .valid_exc      (served_exc_v),
        .exception      (served_exc),
        .output_block   (new_modded_block),
        .output_vector  (served_data)
        );

    assign ld_pop  = (serve==LD);
    assign ld_push = (serve==LD_IN) & ~served & ~must_wait & ~ld_s_phit;
    //Initialize the Load Buffer
    ld_st_buffer #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_BITS      (ADDR_BITS),
        .BLOCK_ID_START (OFFSET_BITS),
        .R_WIDTH        (R_WIDTH),
        .MICROOP        (MICROOP),
        .ROB_TICKET     (ROB_TICKET),
        .DEPTH          (BUFFER_SIZES))
    load_buffer (
        .clk                (clk),
        .rst_n              (rst_n),

        .push               (ld_push),
        .write_address      (load_address),
        .write_data         (),             //NC
        .write_microop      (load_microop),
        .write_dest         (load_dest),
        .write_ticket       (load_ticket),
        .write_isfetched    (1'b0),

        .search_address     (served_address),
        .search_microop_in  (),             //NC
        .search_data        (),             //NC
        .search_microop     (),             //NC
        .search_dest        (),             //NC
        .search_ticket      (),             //NC
        .search_valid_hit   (),             //NC
        .search_partial_hit (ld_s_phit),

        .valid_update       (update_l2_valid),
        .update_address     (update_l2_addr),

        .pop                (ld_pop),
        .head_isfetched     (ld_head_isfetched),
        .head_address       (ld_head_addr),
        .head_data          (),             //NC
        .head_microop       (ld_head_microop),
        .head_dest          (ld_head_dest),
        .head_ticket        (ld_head_ticket),

        .valid              (ld_valid),
        .ready              (ld_ready)
        );


    assign st_pop  = (serve==ST);
    assign st_push = (serve==ST_IN & ~served & ~must_wait & ~st_s_phit);
    //Initialize the Store Buffer
    ld_st_buffer #(
        .DATA_WIDTH     (DATA_WIDTH),
        .ADDR_BITS      (ADDR_BITS),
        .BLOCK_ID_START (OFFSET_BITS),
        .R_WIDTH        (R_WIDTH),
        .MICROOP        (MICROOP),
        .ROB_TICKET     (ROB_TICKET),
        .DEPTH          (BUFFER_SIZES))
    store_buffer (
        .clk                (clk),
        .rst_n              (rst_n),

        .push               (st_push),
        .write_address      (store_address),
        .write_data         (store_data),
        .write_microop      (store_microop),
        .write_dest         (),             //NC
        .write_ticket       (),             //NC
        .write_isfetched    (hit),

        .search_address     (served_address),
        .search_microop_in  (served_microop),
        .search_data        (st_s_data),
        .search_microop     (),             //NC
        .search_dest        (),             //NC
        .search_ticket      (),             //NC
        .search_valid_hit   (st_s_vhit),
        .search_partial_hit (st_s_phit),

        .valid_update       (update_l2_valid),
        .update_address     (update_l2_addr),

        .pop                (st_pop),
        .head_isfetched     (st_head_isfetched),
        .head_address       (st_head_addr),
        .head_data          (st_head_data),
        .head_microop       (st_head_microop),
        .head_dest          (),             //NC
        .head_ticket        (),             //NC

        .valid              (st_valid),
        .ready              (st_ready)
        );

    //Enter in WT Buffer Serve Mode
    assign wt_invalidate = (serve==LD | serve==ST) & wt_found_one;
    //Save the Search Address
    always_ff @(posedge clk) begin : SavedSearch
        if(serve==LD && wt_found_one) begin
                saved_search_addr <= ld_head_addr;
        end else if(serve==ST && wt_found_one) begin
            saved_search_addr <= st_head_addr;
        end
    end

    always_comb begin : WaitBufferInputs
        wt_w_dest   = load_dest;
        wt_w_ticket = load_ticket;
        wt_w_data   = store_data;
        if(serve==LD_IN) begin
            wt_w_address = load_address;
            wt_w_microop = load_microop;
        end else begin
            wt_w_address = store_address;
            wt_w_microop = store_microop;
        end
    end

    assign wt_w_isstore = (serve==ST_IN);
    assign wt_push = (serve==LD_IN & ~served & must_wait) | (serve==ST_IN & ~served & must_wait);
    assign wt_search_addr = (serve==WT) ? saved_search_addr: served_address;
    //Initialize the Wait Buffer
    wait_buffer #(
        .DATA_WIDTH         (DATA_WIDTH),
        .ADDR_BITS          (ADDR_BITS),
        .R_WIDTH            (R_WIDTH),
        .MICROOP            (MICROOP),
        .ROB_TICKET         (ROB_TICKET),
        .DEPTH              (2*BUFFER_SIZES)
        )
    wait_buffer  (
        .clk                (clk),
        .rst_n              (rst_n),

        .write_enable       (wt_push),
        .write_is_store     (wt_w_isstore),
        .write_address      (wt_w_address),
        .write_data         (wt_w_data),
        .write_microop      (wt_w_microop),
        .write_dest         (wt_w_dest),
        .write_ticket       (wt_w_ticket),

        .search_invalidate  (wt_invalidate),
        .search_address     (wt_search_addr),
        .search_microop_in  (served_microop),
        .search_address_o   (search_address_o),
        .search_is_store    (wt_s_isstore),
        .search_data        (wt_s_data),
        .search_frw_data    (wt_s_frw_data),
        .search_microop     (wt_s_microop),
        .search_dest        (wt_s_dest),
        .search_ticket      (wt_s_ticket),
        .search_valid_hit   (wt_s_frw_hit),

        .valid              (wt_valid),
        .ready              (wt_ready),
        .search_found_one   (wt_found_one),
        .search_found_multi (),             //NC
        .in_walk_mode       (wt_in_walk)
        );

`ifdef INCLUDE_SVAS
    `include "data_cache_sva.sv"
`endif

endmodule