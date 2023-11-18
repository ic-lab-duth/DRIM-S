`include "structs.sv"

module memory_tb() ;

    localparam IC_ENTRIES   = 32  ;
    localparam IC_DW        = 256 ;
    localparam DC_ENTRIES   = 32  ;
    localparam DC_DW        = 256 ;
    localparam L2_ENTRIES   = 2048;
    localparam L2_DW        = 512 ;
    localparam REALISTIC    = 1   ;
    localparam DELAY_CYCLES = 10  ;
    //Predictor Parameters
    localparam RAS_DEPTH        = 8  ;
    localparam GSH_HISTORY_BITS = 2  ;
    localparam GSH_SIZE         = 256;
    localparam BTB_SIZE         = 256;
    //Dual Issue Enabler
    localparam DUAL_ISSUE = 1;
    //ROB Parameters    (Do NOT MODIFY, structs cannot update their widths automatically)
    localparam ROB_ENTRIES  = 8                  ; //default: 8
    localparam ROB_TICKET_W = $clog2(ROB_ENTRIES); //default: DO NOT MODIFY
    //Other Parameters  (DO NOT MODIFY)
    localparam ISTR_DW        = 32        ; //default: 32
    localparam ADDR_BITS      = 32        ; //default: 32
    localparam DATA_WIDTH     = 32        ; //default: 32
    localparam FETCH_WIDTH    = 64        ; //default: 64
    localparam R_WIDTH        = 6         ; //default: 6
    localparam MICROOP_W      = 5         ; //default: 5
    localparam UNCACHEABLE_ST = 4294901760; //default: 4294901760
    //CSR Parameters        (DO NOT MODIFY)
    localparam CSR_DEPTH = 64;
    //Vector Parameters
    localparam VECTOR_ENABLED   = 0;
    localparam VECTOR_ELEM      = 4;
    localparam VECTOR_ACTIVE_EL = 4;
    //===================================================================================
    logic clk, rst_n;



    logic                    icache_valid_i      ;
    logic                    dcache_valid_i      ;
    logic                    cache_store_valid   ;
    logic                    icache_valid_o      ;
    logic                    dcache_valid_o      ;
    logic                    cache_load_valid    ;
    logic                    write_l2_valid      ;
    logic [   ADDR_BITS-1:0] icache_address_i    ;
    logic [   ADDR_BITS-1:0] dcache_address_i    ;
    logic [   ADDR_BITS-1:0] cache_store_addr    ;
    logic [   ADDR_BITS-1:0] icache_address_o    ;
    logic [   ADDR_BITS-1:0] dcache_address_o    ;
    logic [   ADDR_BITS-1:0] write_l2_addr_c     ;
    logic [   ADDR_BITS-1:0] write_l2_addr       ;
    logic [   ADDR_BITS-1:0] cache_load_addr     ;
    logic [       DC_DW-1:0] write_l2_data       ;
    logic [       DC_DW-1:0] write_l2_data_c     ;
    logic [       DC_DW-1:0] dcache_data_o       ;
    logic [  DATA_WIDTH-1:0] cache_store_data    ;
    logic [       IC_DW-1:0] icache_data_o       ;
    logic [   ADDR_BITS-1:0] current_pc          ;
    logic                    hit_icache          ;
    logic                    miss_icache         ;
    logic                    partial_access      ;
    logic [ FETCH_WIDTH-1:0] fetched_data        ;
    logic                    cache_store_uncached;
    logic                    cache_store_cached  ;
    logic                    write_l2_valid_c    ;
    logic [     R_WIDTH-1:0] cache_load_dest     ;
    logic [   MICROOP_W-1:0] cache_load_microop  ;
    logic [   MICROOP_W-1:0] cache_store_microop ;
    logic [ROB_TICKET_W-1:0] cache_load_ticket   ;
    logic [             1:0] partial_type        ;
    ex_update                cache_fu_update     ;
    logic                    cache_will_block    ;
    logic                    cache_blocked       ;
    logic                    cache_store_blocked ;
    logic                    cache_load_blocked  ;

    logic        frame_buffer_write  ;
    logic [15:0] frame_buffer_data   ;
    logic [14:0] frame_buffer_address;
    logic [ 7:0] red_o, green_o, blue_o;
    logic [ 4:0] color               ;


    assign cache_store_uncached = cache_store_valid & (cache_store_addr>=UNCACHEABLE_ST);
    assign cache_store_cached   = cache_store_valid & ~cache_store_uncached;
    //Create the Signals for the write-through into the L2
    assign write_l2_valid = cache_store_uncached | write_l2_valid_c;
    assign write_l2_addr  = cache_store_uncached ? cache_store_addr : write_l2_addr_c;
    assign write_l2_data  = cache_store_uncached ? cache_store_data : write_l2_data_c;

    main_memory #(
            .L2_BLOCK_DW    (L2_DW       ),
            .L2_ENTRIES     (L2_ENTRIES  ),
            .ADDRESS_BITS   (ADDR_BITS   ),
            .ICACHE_BLOCK_DW(IC_DW       ),
            .DCACHE_BLOCK_DW(DC_DW       ),
            .REALISTIC      (REALISTIC   ),
            .DELAY_CYCLES   (DELAY_CYCLES),
            .FILE_NAME      ("memory.txt")
        ) main_memory (
            .clk              (clk             ),
            .rst_n            (rst_n           ),
            //Read Request Input from ICache
            .icache_valid_i   (icache_valid_i  ),
            .icache_address_i (icache_address_i),
            //Output to ICache
            .icache_valid_o   (icache_valid_o  ),
            //.icache_address_o (icache_address_o),
            .icache_data_o    (icache_data_o   ),
            //Read Request Input from DCache
            .dcache_valid_i   (dcache_valid_i  ),
            .dcache_address_i (dcache_address_i),
            //Output to DCache
            .dcache_valid_o   (dcache_valid_o  ),
            .dcache_address_o (dcache_address_o),
            .dcache_data_o    (dcache_data_o   ),
            //Write Request Input from DCache
            .dcache_valid_wr  (write_l2_valid  ),
            .dcache_address_wr(write_l2_addr   ),
            .dcache_data_wr   (write_l2_data   )
            // .dcache_microop_wr(write_l2_microop),
        );
        /////

    data_cache #(
            .DATA_WIDTH   (DATA_WIDTH  ),
            .ADDR_BITS    (ADDR_BITS   ),
            .R_WIDTH      (R_WIDTH     ),
            .MICROOP      (MICROOP_W   ),
            .ROB_TICKET   (ROB_TICKET_W),
            .ENTRIES      (DC_ENTRIES  ),
            .BLOCK_WIDTH  (DC_DW       ),
            .BUFFER_SIZES (4           ),
            .ASSOCIATIVITY(4           )
        ) data_cache (
            .clk                (clk                ),
            .rst_n              (rst_n              ),
            .output_used        (0),
            //Load Input Port
            .load_valid         (cache_load_valid   ),
            .load_address       (cache_load_addr    ),
            .load_dest          (cache_load_dest    ),
            .load_microop       (cache_load_microop ),
            .load_ticket        (cache_load_ticket  ),
            //Store Input Port
            .store_valid        (cache_store_cached ),
            .store_address      (cache_store_addr   ),
            .store_data         (cache_store_data   ),
            .store_microop      (cache_store_microop),
            //Request Write Port to L2
            .write_l2_valid     (write_l2_valid_c   ),
            .write_l2_addr      (write_l2_addr_c    ),
            .write_l2_data      (write_l2_data_c    ),
            //Request Read Port to L2
            .request_l2_valid   (dcache_valid_i     ),
            .request_l2_addr    (dcache_address_i   ),
            // Update Port from L2
            .update_l2_valid    (dcache_valid_o     ),
            .update_l2_addr     (dcache_address_o   ),
            .update_l2_data     (dcache_data_o      ),
            //Output Port
            .cache_will_block   (cache_will_block   ),
            .cache_store_blocked(cache_store_blocked),
            .cache_load_blocked (cache_load_blocked ),
            .served_output      (cache_fu_update    )
        );

        always begin
            clk = 1; #5; clk = 0; #5;
        end

        initial begin
            rst_n=1;
            @(posedge clk);
            rst_n=0;
            @(posedge clk);
            rst_n=1;
            @(posedge clk);@(posedge clk);
            cache_store_valid = 1;
            cache_store_addr = 20;
            cache_store_data = 30;
            cache_store_microop = 5'b00110;
            @(posedge clk);
            cache_store_valid = 0;
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            cache_load_valid = 1;
            cache_load_addr = 20;
            cache_load_microop = 5'b00001;
            @(posedge clk);
            cache_load_valid = 0;
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            @(posedge clk);@(posedge clk);
            $finish;
        end

endmodule