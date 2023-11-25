/*
* @info Re-Order Buffer
* @info Sub Modules: arbiter.sv, and_or_mux.sv, SRAM.sv
*
* @author VLSI Lab, EE dept., Democritus University of Thrace
*
* @brief The Re-Order Buffer is used to maintain the in-order retirement of the instructions.
*
* @note  ROB Internal Configuration (per entry): [v|p|v_d|rd|data|v_exc|casue]
* @note:
* Functional Units:
* 00 : Load/Store Unit
* 01 : Floating Point Unit
* 10 : Integer Unit
* 11 : Branches
*
* @param ADDR_BITS     : # of Address Bits (default 32 bits)
* @param ROB_ENTRIES   : # of entries the ROB can hold
* @param FU_NUMBER     : # of Functional Units that can update ROB at the same cycle
* @param ROB_INDEX_BITS: # ROB's ticket Bits
* @param DATA_WIDTH    : # of Data Bits (default 32 bits)
*/

`ifdef MODEL_TECH
    `include "structs.sv"
`endif
module rob #(
    parameter ADDR_BITS      = 32,
    parameter ROB_ENTRIES    = 8 ,
    parameter FU_NUMBER      = 4 ,
    parameter ROB_INDEX_BITS = 3 ,
    parameter DATA_WIDTH     = 32
) (
    input  logic                                              clk                    ,
    input  logic                                              rst_n                  ,
    //Flush Port
    input  logic                                              flush_valid            ,
    input  logic     [ROB_INDEX_BITS-1:0]                     flush_ticket           ,
    output logic     [   ROB_ENTRIES-1:0]                     flush_vector_inv       ,
    //Forwarding Port
    input  logic     [               5:0][ROB_INDEX_BITS-1:0] read_address           ,
    output logic     [               5:0][              31:0] data_out               ,
    //Data Cache Interface (Search Interface)
    input  logic                                              cache_blocked          ,
    input  logic     [     ADDR_BITS-1:0]                     cache_addr             ,
    input  logic     [               4:0]                     cache_microop          ,
    output logic     [    DATA_WIDTH-1:0]                     cache_data             ,
    output logic                                              cache_valid            ,
    output logic                                              cache_stall            ,
    //STORE update from Data Cache (Input Interface)
    input  logic                                              store_valid            ,
    input  logic     [    DATA_WIDTH-1:0]                     store_data             ,
    input  logic     [ROB_INDEX_BITS-1:0]                     store_ticket           ,
    input  logic     [     ADDR_BITS-1:0]                     store_address          ,
    //writeback into Cache (Output Interface)
    output logic                                              cache_writeback_valid  ,
    output logic     [    DATA_WIDTH-1:0]                     cache_writeback_addr   ,
    output logic     [    DATA_WIDTH-1:0]                     cache_writeback_data   ,
    output logic     [               4:0]                     cache_writeback_microop,
    //Update from EX (Input Interface)
    input  ex_update [     FU_NUMBER-1:0]                     update                 ,
    //Interface with IS
    input  new_entries                                        new_requests           ,
    output to_issue                                           t_issue                ,
    output writeback_toARF                                    writeback_1            ,
    output writeback_toARF                                    writeback_2
);


    // #Internal Signals#
    rob_entry [   ROB_ENTRIES-1 : 0] rob;
    logic     [ROB_INDEX_BITS-1 : 0] tail, head, head_plus, tail_actual, tail_plus, flush_ticket_plus, flush_begin, temp;
    logic     [  ROB_INDEX_BITS : 0] counter, counter_actual;
    logic                            can_commit, can_commit_2, will_commit, will_commit_2, can_bypass, valid_1, valid_2, one_found, exact_match;

    logic [ROB_ENTRIES-1 : 0] main_match, secondary_match, match_picked;// difference;
    logic                     input_forward_match, input_forward_sec, microop_ok, input_forward_microop_ok;

    localparam int ROB_SIZE = $bits(rob);
    assign head_plus = head +1;
    //Create Status Output for the IS Stage
    assign t_issue.ticket    = tail_actual;
    assign t_issue.is_full   = (counter_actual==ROB_ENTRIES);
    assign t_issue.two_empty = (counter_actual<ROB_ENTRIES-1);

    //Create the most up-to-date status pointers
    always_comb begin
        if(new_requests.valid_request_1 && new_requests.valid_request_2) begin
            counter_actual = counter +2;
            tail_actual    = tail +2;
        end else if(new_requests.valid_request_1 || new_requests.valid_request_2) begin
            counter_actual = counter +1;
            tail_actual    = tail +1;
        end else begin
            counter_actual = counter;
            tail_actual    = tail;
        end
        if(will_commit) counter_actual = counter_actual - 1;
        if(will_commit_2) counter_actual = counter_actual - 2;
    end

    logic [FU_NUMBER : 0][ROB_INDEX_BITS-1 : 0]  upd_positions;
    logic [FU_NUMBER : 0][31 : 0]                new_data;
    logic [FU_NUMBER : 0]                        upd_en;

    logic [ROB_ENTRIES-1:0]                      tail_plus_oh, tail_oh, tail_oh_inverted, main_match_inv, match_picked_inv, flush_wr_en;

    logic [8:0][ROB_INDEX_BITS-1 : 0]            read_addr_rob;
    logic [8:0][31 : 0]                          data_out_rob;

    logic [ROB_INDEX_BITS-1 : 0]                 cache_forward_addr;
    logic [31 : 0]                               data_for_c, data_for_c_2;

    //Flushing Calculations
    assign flush_ticket_plus = flush_ticket+1;
    //Get the Entries for Invalidation/Flushing
    assign flush_wr_en      = diff_wr_en(flush_ticket_plus, head);
    assign flush_vector_inv = ~flush_wr_en;

    //Pick the Entries for Invalidation (creates an invalidate_en vector)
    function logic[ROB_ENTRIES-1:0] diff_wr_en(int ticket, int pointer);
        int counter, flag;
        logic [ROB_ENTRIES-1:0] result;
        logic [ROB_INDEX_BITS-1:0] i;
        flag    = 0;
        counter = 0;
        result  = 'b0;
        i       = ticket;
        while (counter < ROB_ENTRIES-1) begin
            if (!flag && i!=pointer) begin
                result[i] = 1'b1;
                counter   = counter + 1;
                i         = i + 1;
            end else begin
                if (i==pointer) flag = 1;
                counter = counter + 1;
            end
        end
        return result;
    endfunction

    //DATA CACHE SECTION
    //Search in the ROB for the same store Address
    assign input_forward_match = (store_address[31:2] == cache_addr[31:2]) & store_valid;
    assign input_forward_sec   = (store_address[1:0] == cache_addr[1:0]) & store_valid;
    always_comb begin : Compare
        for (int i = 0; i < ROB_ENTRIES; i++) begin
            main_match[i]      = rob[i].valid & rob[i].is_store ? (rob[i].address[31:2] == cache_addr[31:2]) : 1'b0;
            secondary_match[i] = rob[i].valid & rob[i].is_store ? (rob[i].address[1:0] == cache_addr[1:0]) : 1'b0;
        end
    end
    always_comb begin : invertPointers
        for (int i = 0; i < ROB_ENTRIES; i++) begin
            tail_oh_inverted[i] = tail_oh[ROB_ENTRIES-1-i];
            main_match_inv[i]   = main_match[ROB_ENTRIES-1-i];
            match_picked[i]     = match_picked_inv[ROB_ENTRIES-1-i];
        end
    end
    //Grant only one match to Forward the Data
    arbiter #(ROB_ENTRIES)
    arbiter(
        // .request_i      (main_match),
        .request_i      (main_match_inv),
        .priority_i     (tail_oh_inverted),
        .grant_o        (match_picked_inv),
        .anygnt_o       (one_found)
        );
    //Grab the secondary match
    and_or_mux #( .INPUTS   (ROB_ENTRIES),
                  .DW       (1))
    mux_sec ( .data_in  (secondary_match),
              .sel      (match_picked),
              .data_out (exact_match));
    //Encode the Pointer
    always_comb begin : encoder
        cache_forward_addr = 0;
        for (int i = 0; i < ROB_ENTRIES; i++) begin
            if (match_picked[i]) cache_forward_addr = i;
        end
    end
    //Check the Microops for forwarding hazards
    always_comb begin : MicroopOk
        if(cache_microop==5'b00001) begin
            //load==LW
            microop_ok = (rob[cache_forward_addr].microoperation == 5'b00110);
        end else if(cache_microop==5'b00010 | cache_microop==5'b00011) begin
            //load==LH
            microop_ok = (rob[cache_forward_addr].microoperation == 5'b00111 | rob[cache_forward_addr].microoperation == 5'b00110);
        end else if(cache_microop==5'b00100 | cache_microop==5'b00101) begin
            //load==LB
            microop_ok = 1;
        end else begin
            microop_ok = 0;
        end
    end
    always_comb begin : InputMicroopOk
        if(cache_microop==5'b00001) begin
            //load==LW
            input_forward_microop_ok = (rob[store_ticket].microoperation == 5'b00110);
        end else if(cache_microop==5'b00010 | cache_microop==5'b00011) begin
            //load==LH/LHU
            input_forward_microop_ok = (rob[store_ticket].microoperation == 5'b00111 | rob[store_ticket].microoperation == 5'b00110);
        end else if(cache_microop==5'b00100 | cache_microop==5'b00101) begin
            //load==LB/LBU
            input_forward_microop_ok = 1;
        end else begin
            input_forward_microop_ok = 0;
        end
    end
    //Create the Forward Output
    always_comb begin : CreateCacheForwardSignals
        if(input_forward_match) begin
            cache_valid = input_forward_sec & input_forward_microop_ok;
            cache_stall = ~input_forward_sec | ~input_forward_microop_ok;
            cache_data  = store_data;
        end else begin
            cache_valid = one_found & exact_match & microop_ok;
            cache_stall = one_found & ( ~exact_match | ~microop_ok);
            cache_data  = data_out_rob[5];
        end
    end
    //SRAM data banks where the ROB data are being stored
    sram #(ROB_ENTRIES,DATA_WIDTH,9,FU_NUMBER+1,0)
    sram(.clk          (clk),
        .rst_n         (rst_n),

        .wr_en         (upd_en),
        .write_address (upd_positions),
        .new_data      (new_data),

        .read_address  (read_addr_rob),
        .data_out      (data_out_rob));

    always_comb begin : MapSignals
        //Forwarding Address for the Data Cache
        read_addr_rob[5] = cache_forward_addr;
        //Address for Commit Data
        read_addr_rob[6] = head_plus;
        read_addr_rob[4] = head;
        for (int i = 0; i < FU_NUMBER; i++) begin
            upd_en[i]        = update[i].valid;
            upd_positions[i] = update[i].ticket;
            new_data[i]      = update[i].data;

            read_addr_rob[i] = read_address[i];
            data_out[i]      = data_out_rob[i];
        end

        read_addr_rob[7] = read_address[4];
        read_addr_rob[8] = read_address[5];
        data_out[4]      = data_out_rob[7];
        data_out[5]      = data_out_rob[8];

        //register new stores
        upd_en[FU_NUMBER]        = store_valid;
        upd_positions[FU_NUMBER] = store_ticket;
        new_data[FU_NUMBER]      = store_data;
    end

    //Data for Commit
    assign data_for_c   = data_out_rob[4];
    assign data_for_c_2 = data_out_rob[6];
    assign can_commit   = rob[head].is_store ? rob[head].valid & ~rob[head].pending & ~cache_blocked : rob[head].valid & ~rob[head].pending;
    assign will_commit  = (can_commit & ~rob[head].valid_exception) | (rob[head].flushed & rob[head].valid);

    // assign can_commit_2  = (rob[head].is_store | rob[head_plus].is_store) ? 1'b0 : rob[head_plus].valid & ~rob[head_plus].pending & will_commit;
    assign can_commit_2  = (rob[head_plus].is_store) ? 1'b0 : rob[head_plus].valid & ~rob[head_plus].pending & will_commit;
    assign will_commit_2 = (can_commit_2 & ~rob[head_plus].valid_exception) | (rob[head_plus].flushed & rob[head_plus].valid);

    // RETIREMENT
    //Create writeback_1 Request for the Data Cache
    assign cache_writeback_valid   = can_commit & will_commit & rob[head].is_store & ~rob[head].flushed;
    assign cache_writeback_addr    = rob[head].address;
    assign cache_writeback_data    = data_for_c;
    assign cache_writeback_microop = rob[head].microoperation;
    //Create Commit Request for the RF #1
    assign writeback_1.valid_commit = will_commit;
    assign writeback_1.valid_write  = (will_commit & rob[head].valid_dest & ~rob[head].flushed);
    assign writeback_1.flushed      = rob[head].flushed;
    assign writeback_1.ldst         = rob[head].lreg;
    assign writeback_1.pdst         = rob[head].preg;
    assign writeback_1.ppdst        = rob[head].ppreg;
    assign writeback_1.data         = data_for_c;
    assign writeback_1.ticket       = head;
    assign writeback_1.pc           = rob[head].pc;
    //Create Commit Request for the RF #2
    assign writeback_2.valid_commit = will_commit_2;
    assign writeback_2.valid_write  = (will_commit_2 & rob[head_plus].valid_dest & ~rob[head_plus].flushed);
    assign writeback_2.flushed      = rob[head_plus].flushed;
    assign writeback_2.ldst         = rob[head_plus].lreg;
    assign writeback_2.pdst         = rob[head_plus].preg;
    assign writeback_2.ppdst        = rob[head_plus].ppreg;
    assign writeback_2.data         = data_for_c_2;
    assign writeback_2.ticket       = head_plus;
    assign writeback_2.pc           = rob[head_plus].pc;
    //ROB StatsCounter Management
    always_ff @(posedge clk or negedge rst_n) begin : StatsCounter
        if(!rst_n) begin
            counter <= 0;
        end else begin
            if (will_commit_2) begin
                counter <= counter-2;
                if (new_requests.valid_request_1 || new_requests.valid_request_2) counter <= counter-1;
                if (new_requests.valid_request_1 && new_requests.valid_request_2) counter <= counter;
            end else if(will_commit) begin                //Instruction will Commit
                counter <= counter-1;
                if (new_requests.valid_request_1 || new_requests.valid_request_2) counter <= counter;
                if (new_requests.valid_request_1 && new_requests.valid_request_2) counter <= counter +1;
                //end else if(can_commit && !will_commit) begin //Exception Raised->Flush
                //    counter <= 0;
            end else begin                               //No Commit - No Flush
                if (new_requests.valid_request_1 || new_requests.valid_request_2) counter <= counter +1;
                if (new_requests.valid_request_1 && new_requests.valid_request_2) counter <= counter +2;
            end
        end
    end
    //Convert pointers to OH
    assign tail_plus    = tail+1;
    assign tail_oh      = (1 << tail);
    assign tail_plus_oh = (1 << tail_plus);
    //ROB Entry Management
    always_ff @(posedge clk) begin : ROB
        for (int i = 0; i < ROB_ENTRIES; i++) begin
            if(new_requests.valid_request_2 && new_requests.valid_request_1 && tail_plus_oh[i]) begin
                //Register Issue 2
                rob[i].pending         <= 1;
                rob[i].valid_dest      <= new_requests.valid_dest_2;
                rob[i].lreg            <= new_requests.lreg_2;
                rob[i].preg            <= new_requests.preg_2;
                rob[i].ppreg           <= new_requests.ppreg_2;
                rob[i].microoperation  <= new_requests.microoperation_2;
                rob[i].valid_exception <= 0;
                rob[i].is_store        <= 0;
                rob[i].pc              <= new_requests.pc_2;
            end else if(new_requests.valid_request_2 && new_requests.valid_request_1 && tail_oh[i]) begin
                //Register Issue 2
                rob[i].pending         <= 1;
                rob[i].valid_dest      <= new_requests.valid_dest_1;
                rob[i].lreg            <= new_requests.lreg_1;
                rob[i].preg            <= new_requests.preg_1;
                rob[i].ppreg           <= new_requests.ppreg_1;
                rob[i].microoperation  <= new_requests.microoperation_1;
                rob[i].valid_exception <= 0;
                rob[i].is_store        <= 0;
                rob[i].pc              <= new_requests.pc_1;
                end else if(new_requests.valid_request_1 && !new_requests.valid_request_2 &&  tail_oh[i]) begin
                //Register Issue 1
                rob[i].pending         <= 1;
                rob[i].valid_dest      <= new_requests.valid_dest_1;
                rob[i].lreg            <= new_requests.lreg_1;
                rob[i].preg            <= new_requests.preg_1;
                rob[i].ppreg           <= new_requests.ppreg_1;
                rob[i].microoperation  <= new_requests.microoperation_1;
                rob[i].valid_exception <= 0;
                rob[i].is_store        <= 0;
                rob[i].pc              <= new_requests.pc_1;
                end else if(!new_requests.valid_request_1 && new_requests.valid_request_2 &&  tail_oh[i]) begin
                //Register Issue 1
                rob[i].pending         <= 1;
                rob[i].valid_dest      <= new_requests.valid_dest_2;
                rob[i].lreg            <= new_requests.lreg_2;
                rob[i].preg            <= new_requests.preg_2;
                rob[i].ppreg           <= new_requests.ppreg_2;
                rob[i].microoperation  <= new_requests.microoperation_2;
                rob[i].valid_exception <= 0;
                rob[i].is_store        <= 0;
                rob[i].pc              <= new_requests.pc_2;
            end else begin
                if(store_valid && i==store_ticket) begin
                    //Register STORE update from Data Cache
                    rob[i].pending  <= 0;
                    rob[i].is_store <= 1;
                    rob[i].address  <= store_address;
                end else begin
                    //Register FU Updates from EX
                    for (int j = 0; j < FU_NUMBER; j++) begin
                        if(update[j].valid && i ==update[j].ticket) begin
                            rob[i].pending         <= 0;
                            rob[i].valid_exception <= update[j].valid_exception;
                            rob[i].cause           <= update[j].cause;
                        end
                    end
                end
            end
        end
    end
    //ROB Validity Bits Management
    always_ff @(posedge clk or negedge rst_n) begin : RobValidityBits
        if(!rst_n) begin
            for (int i = 0; i < ROB_ENTRIES; i++) begin
                rob[i].valid <= 0;
            end
        end else begin
            for (int i = 0; i < ROB_ENTRIES; i++) begin
                if(new_requests.valid_request_1 && new_requests.valid_request_2 && tail_plus_oh[i]) begin
                    rob[i].valid <= 1;
                end else if(new_requests.valid_request_1 && new_requests.valid_request_2 && tail_oh[i]) begin
                    rob[i].valid <= 1;
                end else if((new_requests.valid_request_1 || new_requests.valid_request_2) &&  tail_oh[i]) begin
                    rob[i].valid <= 1;
                end else if (will_commit && head==i) begin
                    rob[i].valid <= 0;
                end else if (will_commit_2 && head_plus==i) begin
                    rob[i].valid <= 0;
                end
            end
        end
    end
    //ROB Flush Bit Management
    always_ff @(posedge clk) begin : ROBFlushBits
        for (int i = 0; i < ROB_ENTRIES; i++) begin
            if (flush_valid && flush_wr_en[i]) begin
                rob[i].flushed <= 1'b1;
            end else if(new_requests.valid_request_1 && new_requests.valid_request_2 && tail_plus_oh[i]) begin
                rob[i].flushed <= flush_valid;
            end else if(new_requests.valid_request_1 && new_requests.valid_request_2 && tail_oh[i]) begin
                rob[i].flushed <= flush_valid;
            end else if((new_requests.valid_request_1 || new_requests.valid_request_2) &&  tail_oh[i]) begin
                rob[i].flushed <= flush_valid;
            end
        end
    end
    //ROB Head Management
    always_ff @(posedge clk or negedge rst_n) begin : Head
        if(!rst_n) begin
            head <= 0;
        end else begin
            if (will_commit_2) begin
                head <= head +2;
            end else if(will_commit) begin
                head <= head +1;
            end
        end
    end
    //ROB Tail Management
    always_ff @(posedge clk or negedge rst_n) begin : Tail
        if(!rst_n) begin
            tail <= 0;
        end else begin
            if(new_requests.valid_request_1 && new_requests.valid_request_2) begin
                tail <= tail +2;
            end else if(new_requests.valid_request_1 || new_requests.valid_request_2) begin
                tail <= tail +1;
            end
        end
    end


`ifdef INCLUDE_SVAS
    `include "rob_sva.sv"
`endif
endmodule