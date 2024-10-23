module permutation_unit #(
    VL = 256
)(
    input  logic slideup,
    input  logic slidedown,
    input  logic compress,
    input  logic sgather,
    input  logic vgather,
    input  logic [1:0] sew,
    input  logic [VL-1:0] opA,
    input  logic [VL-1:0] opB,
    input  logic [VL/8-1:0] mask,
    output logic [VL-1:0] result
);

    logic inverse;
    logic [VL/8-1:0][7:0] perm;
crossbar #(.DW(8), .N(VL/8)) i_crossbar (.inverse(inverse), .perm(perm), .data_i(opA), .data_o(result));
assign inverse = slideup | compress;


logic [VL-1:0] slide_perm, compress_perm, sgather_perm, vgather_perm;
logic [VL/8-1:0] compress_mask;

logic [$clog2(VL/8):0] byte_slide;
assign byte_slide = opB[31:0] << sew;

always_comb for (int i = 0; i < VL/8; ++i) slide_perm[i*8 +: 8] = byte_slide + i;

always_comb begin
    if (sew == 0) begin
        for (int i = 0; i < VL/8; ++i) begin
            vgather_perm[i*8 +: 8] = opB[i*8 +: 8];
            sgather_perm[i*8 +: 8] = opB[0 +: 8];
            compress_mask[i]       = opB[mask];
        end
    end else if (sew == 1) begin
        for (int i = 0; i < VL/16; ++i) begin
            vgather_perm[i*16 +: 8]     = opB[i*16 +: 8] << sew;
            vgather_perm[i*16 + 8 +: 8] = (opB[i*16 +: 8] << sew) + 1;
            sgather_perm[i*16 +: 8]     = opB[0 +: 8] << sew;
            sgather_perm[i*16 + 8 +: 8] = (opB[0 +: 8] << sew) + 1;
            compress_mask[2*i]          = mask[i];
            compress_mask[2*i + 1]      = mask[i];
        end
    end else if (sew == 2) begin
        for (int i = 0; i < VL/32; ++i) begin
            vgather_perm[i*32 +: 8]      = opB[i*32 +: 8] << sew;
            vgather_perm[i*32 + 8 +: 8]  = (opB[i*32 +: 8] << sew) + 1;
            vgather_perm[i*32 + 16 +: 8] = (opB[i*32 +: 8] << sew) + 2;
            vgather_perm[i*32 + 24 +: 8] = (opB[i*32 +: 8] << sew) + 3;
            sgather_perm[i*32 +: 8]      = opB[0 +: 8] << sew;
            sgather_perm[i*32 + 8 +: 8]  = (opB[0 +: 8] << sew) + 1;
            sgather_perm[i*32 + 16 +: 8] = (opB[0 +: 8] << sew) + 2;
            sgather_perm[i*32 + 24 +: 8] = (opB[0 +: 8] << sew) + 3;
            compress_mask[4*i]           = mask[i];
            compress_mask[4*i + 1]       = mask[i];
            compress_mask[4*i + 2]       = mask[i];
            compress_mask[4*i + 3]       = mask[i];
        end
    end else if (sew == 3) begin
        for (int i = 0; i < VL/64; ++i) begin
            vgather_perm[i*64 +: 8]      = opB[i*64 +: 8] << sew;
            vgather_perm[i*64 + 8 +: 8]  = (opB[i*64 +: 8] << sew) + 1;
            vgather_perm[i*64 + 16 +: 8] = (opB[i*64 +: 8] << sew) + 2;
            vgather_perm[i*64 + 24 +: 8] = (opB[i*64 +: 8] << sew) + 3;
            vgather_perm[i*64 + 32 +: 8] = (opB[i*64 +: 8] << sew) + 4;
            vgather_perm[i*64 + 40 +: 8] = (opB[i*64 +: 8] << sew) + 5;
            vgather_perm[i*64 + 48 +: 8] = (opB[i*64 +: 8] << sew) + 6;
            vgather_perm[i*64 + 56 +: 8] = (opB[i*64 +: 8] << sew) + 7;
            sgather_perm[i*64 +: 8]      = opB[0 +: 8] << sew;
            sgather_perm[i*64 + 8 +: 8]  = (opB[0 +: 8] << sew) + 1;
            sgather_perm[i*64 + 16 +: 8] = (opB[0 +: 8] << sew) + 2;
            sgather_perm[i*64 + 24 +: 8] = (opB[0 +: 8] << sew) + 3;
            sgather_perm[i*64 + 32 +: 8] = (opB[0 +: 8] << sew) + 4;
            sgather_perm[i*64 + 40 +: 8] = (opB[0 +: 8] << sew) + 5;
            sgather_perm[i*64 + 48 +: 8] = (opB[0 +: 8] << sew) + 6;
            sgather_perm[i*64 + 56 +: 8] = (opB[0 +: 8] << sew) + 7;
            compress_mask[8*i]           = mask[i];
            compress_mask[8*i + 1]       = mask[i];
            compress_mask[8*i + 2]       = mask[i];
            compress_mask[8*i + 3]       = mask[i];
            compress_mask[8*i + 4]       = mask[i];
            compress_mask[8*i + 5]       = mask[i];
            compress_mask[8*i + 6]       = mask[i];
            compress_mask[8*i + 7]       = mask[i];
        end
    end
end

logic [VL/8-1:0][$clog2(VL/8)-1:0] ones, zeros;
always_comb begin
    ones[0] = 0;
    zeros[VL/8-1] = VL/8 - 1;
    for (int i = 1; i < VL/8; ++i) begin
        if (compress_mask[i-1]) ones[i] = ones[i-1] + 1;
        else ones[i] = ones[i-1];
        if (~compress_mask[VL/8-i]) zeros[VL/8-i-1] = zeros[VL/8-i] - 1;
        else zeros[VL/8-i-1] = zeros[VL/8-i];
    end
end

always_comb for (int i = 0; i < VL/8; ++i) compress_perm[8*i +: 8] = compress_mask[i] ? ones[i] : zeros[i];

assign perm = slideup || slidedown ? slide_perm : compress ? compress_perm : sgather ? sgather_perm : vgather ? vgather_perm : 0;


endmodule : permutation_unit
