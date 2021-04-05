module vga_controller #(
    parameter int ADDR_WIDTH   = 15   ,
    parameter int DATA_WIDTH   = 16   ,
    parameter int COLOR_WIDTH  = 8    ,
    parameter int BASE_ADDR    = 10000, //Start of Frame Buffer
    //Resolution Parameters
    parameter int FRAME_WIDTH  = 640  ,
    parameter int FRAME_HEIGHT = 480  ,
    parameter int HFRONT_PORCH = 16   ,
    parameter int HSYNC_PULSE  = 96   ,
    parameter int HBACK_PORCH  = 48   ,
    parameter int VFRONT_PORCH = 11   ,
    parameter int VSYNC_PULSE  = 2    ,
    parameter int VBACK_PORCH  = 31
) (
    input  logic                   clk    ,
    input  logic                   rst_n  ,
    // Frame Read Interface
    output logic                   valid_o,
    output logic [ ADDR_WIDTH-1:0] address,
    // input  logic                   valid_i,
    input  logic [ DATA_WIDTH-1:0] data_in,
    // VGA Outputs
    output logic                   hsync  ,
    output logic                   vsync  ,
    output logic                   vga_clk,
    output logic [COLOR_WIDTH-1:0] red_o  ,
    output logic [COLOR_WIDTH-1:0] green_o,
    output logic [COLOR_WIDTH-1:0] blue_o
);
    localparam int   HCOUNT_T    = FRAME_WIDTH + HFRONT_PORCH + HSYNC_PULSE + HBACK_PORCH ;
    localparam int   VCOUNT_T    = FRAME_HEIGHT + VFRONT_PORCH + VSYNC_PULSE + VBACK_PORCH;
    localparam int   HCOUNT_SIZE = $clog2(HCOUNT_T)                                       ;
    localparam int   VCOUNT_SIZE = $clog2(VCOUNT_T)                                       ;

    // Internal Signals
    logic [DATA_WIDTH-1:0] next_data, current_data;
    logic [ADDR_WIDTH-1:0] offset     ;
    logic [        10-1:0] hsync_count;
    logic [        10-1:0] vsync_count;
    logic [           7:0] vsync_addr, hsync_addr;
    logic                  cnt_en, half_clk;

    assign vga_clk = half_clk;
    assign address = offset;
    assign offset  = vsync_addr*(FRAME_WIDTH/4) + hsync_addr;
    assign vsync_addr = vsync_count[9:2];
    assign hsync_addr = hsync_count[9:2];
    assign valid_o = (hsync_count<FRAME_WIDTH & vsync_count<FRAME_HEIGHT);

    assign hsync = ~(hsync_count<752 & hsync_count>655);
    assign vsync = ~(vsync_count<493 & vsync_count>490);

    //Half Clock generator
    always_ff @(posedge clk or negedge rst_n) begin : HalfClock
        if(!rst_n) begin
            half_clk <= 0;
        end else begin
            half_clk <= ~half_clk;
        end
    end
    // Counter Management
    always_ff @(posedge clk or negedge rst_n) begin : Syncing
        if(!rst_n) begin
            current_data<= 'b0;
            hsync_count <= 0;
            vsync_count <= 0;
            cnt_en      <= 0;
        end else begin
            if(half_clk) begin
                hsync_count  <= hsync_count + 1;
                // hsync counter reset
                if(hsync_count == HCOUNT_T-1) hsync_count <= 0;
                // vsync counter reset
                if (vsync_count == VCOUNT_T-1) vsync_count <= 0;

                if (!hsync && !cnt_en) begin
                    cnt_en <= 1;
                    vsync_count <= vsync_count + 1;
                end else if (hsync && cnt_en) begin
                    cnt_en <= 0;
                end
            end
        end
    end
    //Pick the Colors
    always_comb begin : ColorsOut
        if(vsync_count>=FRAME_HEIGHT) begin
            red_o   = 0;
            green_o = 0;
            blue_o  = 0;
        end else if(hsync_count<FRAME_WIDTH) begin
            red_o   = {data_in[4:0],3'b0};//data_in[0+:COLOR_WIDTH];
            green_o = {data_in[9:5],3'b0};//data_in[COLOR_WIDTH+:COLOR_WIDTH];
            blue_o  = {data_in[14:10],3'b0};//data_in[2*COLOR_WIDTH+:COLOR_WIDTH];
        end else begin
            red_o   = 0;
            green_o = 0;
            blue_o  = 0;
        end
    end

endmodule