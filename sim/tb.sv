`include "structs.sv"
module tb();

logic   rst_n, clk;
integer f,c, d, e;
integer int_alu_file;

//Initialize the Module
    module_top  module_top(
        .clk    (clk),
        .rst_n  (rst_n)
        );
// generate clock
always
    begin
    clk = 1; #5; clk = 0; #5;
end
//Initialize the Files
task sim_initialize;
    // f = $fopen("flushes.txt","w");
    c = $fopen("commits.txt","w");
    d = $fopen("data.txt","w");
    e = $fopen("ex.txt","w");
    int_alu_file = $fopen("int ALU.csv", "w");
    $fwrite(int_alu_file, "time,data 1,data 2,destination,micro operation\n");
    $display("Testbench Starting...");
    if (tb.module_top.DUAL_ISSUE) begin
        // $fwrite(f,"--Dual Issue Enabled--\n");
        $fwrite(c,"--Dual Issue Enabled--\n");
        $fwrite(d,"--Dual Issue Enabled--\n");
        $fwrite(e,"--Dual Issue Enabled--\n");
    end else begin
        // $fwrite(f,"--Dual Issue Disabled--\n");
        $fwrite(c,"--Dual Issue Disabled--\n");
        $fwrite(d,"--Dual Issue Disabled--\n");
        $fwrite(e,"--Dual Issue Disabled--\n");
    end
endtask

task sim_finish;
    $fclose(f);
    $fclose(c);
    $fclose(d);
    $fclose(e);
    $fclose(int_alu_file);
    $display("Testbench End (or deadlock) detected...");
    $finish;
endtask

logic [32-1:0] old_pc;
logic pc_still_unchanged;
logic sim_finished;
int   cycles_pc_unchanged;

// Detect simulation end when PC hangs, since that is what the bootstrap is using
assign pc_still_unchanged = (old_pc == tb.module_top.current_pc);
assign sim_finished       = (cycles_pc_unchanged == 500) & rst_n;

always_ff @(posedge clk or negedge rst_n) begin
    if(~rst_n) begin
        cycles_pc_unchanged <= 0;
    end else begin
        if(pc_still_unchanged) begin
            cycles_pc_unchanged <= cycles_pc_unchanged +1;
        end else begin
            cycles_pc_unchanged <= 0;
            old_pc <= tb.module_top.current_pc;
        end
    end
end

initial begin
    // $readmemh("vmemory.txt",module_top.top_processor.genblk1.vector_top.mem_mod.comp.mem.memory);
    sim_initialize();
    rst_n=1;
    @(posedge clk);
    rst_n=0;
    @(posedge clk);
    rst_n=1;
    @(posedge clk);
    $display("Testbench Starting...");
    @(posedge clk);@(posedge clk);
    wait(sim_finished);
    @(posedge clk);
    sim_finish();
end

//--------------------------------------------------------
//DEBUGGING SECTION
//--------------------------------------------------------
logic [64-1:0][32-1 : 0] final_regfile;
logic           [64-1:0] counter   ;
writeback_toARF          writeback ;
writeback_toARF          writeback2;
logic           [  31:0] f_address ;
logic           [   2:0] f_r_ticket;
logic           [   1:0] f_rat     ;
logic                    f_delayed ;
logic           [   5:0] index     ;
to_execution    [ 1 : 0] execution ;

// Reconstruct the register file based on the last used register renames
// always_comb begin : FinalRegFile
//     for (int i = 0; i < 64; i++) begin
//         if(i>7 & i<16) begin
//             index            = tb.module_top.top_processor.rr.rat.CurrentRAT[i[2:0]];
//             final_regfile[i] = tb.module_top.top_processor.issue.regfile.RegFile[index];
//         end else begin
//             index            = 0;
//             final_regfile[i] = tb.module_top.top_processor.issue.regfile.RegFile[i];
//         end
//     end
// end
always_comb begin : FinalRegFile
    for (int i = 0; i < 64; i++) begin
        if(i<32) begin
            index            = tb.module_top.top_processor.rr.rat.CurrentRAT[i];
            final_regfile[i] = tb.module_top.top_processor.issue.regfile.RegFile[index];
        end else begin
            index            = 0;
            final_regfile[i] = tb.module_top.top_processor.issue.regfile.RegFile[i];
        end
    end
end

assign f_address  = tb.module_top.top_processor.flush_address;
assign f_r_ticket = tb.module_top.top_processor.flush_rob_ticket;
assign f_rat      = tb.module_top.top_processor.flush_rat_id;
assign f_delayed  = tb.module_top.top_processor.idecode.flush_controller.delayed_capture;
assign writeback  = tb.module_top.top_processor.retired_instruction_o;
assign writeback2 = tb.module_top.top_processor.retired_instruction_o_2;
assign execution  = tb.module_top.top_processor.t_execution;

always @(posedge clk) begin
    if(!rst_n) begin
        counter <= 0;
    end else begin
        if(writeback.valid_commit && !writeback.flushed) begin
            $fwrite(c,"time:%d pc:%h preg:%d write_data:%b data:%h \n",$time, writeback.pc, writeback.pdst, writeback.valid_write, writeback.data);
            $fwrite(d,"%d: data:%h \n", counter, writeback.data);
            counter <= counter +1;
            if(writeback2.valid_commit && !writeback2.flushed) begin
                $fwrite(c,"time:%d pc:%h preg:%d write_data:%b data:%h \n",$time, writeback2.pc, writeback2.pdst, writeback2.valid_write, writeback2.data);
                $fwrite(d,"%d: data:%h \n", counter, writeback2.data);
                counter <= counter +1;
            end
        end
        if (execution[0].valid) begin
            $fwrite(e,"time:%d data1:%h data2:%h imm:%h fu:%d microop:%b", $time, execution[0].data1, execution[0].data2, execution[0].immediate, execution[0].functional_unit, execution[0].microoperation);
            if(execution[1].valid) begin
                $fwrite(e," data3:%h data4:%h imm:%h fu:%d microop:%b \n", execution[1].data1, execution[1].data2, execution[1].immediate, execution[1].functional_unit, execution[1].microoperation);
            end else begin
                $fwrite(e," \n");
            end
        end
    end
end

always_ff @( posedge clk ) begin : int_alu_log
    if (tb.module_top.top_processor.execution.valid[2] && tb.module_top.top_processor.execution.input_data[2].valid) begin
        $fwrite(int_alu_file, "%t,%d,%d,%d,%d\n",$time, tb.module_top.top_processor.execution.input_data[2].data1, tb.module_top.top_processor.execution.input_data[2].data2,
        tb.module_top.top_processor.execution.input_data[2].destination, tb.module_top.top_processor.execution.input_data[2].microoperation);
    end
end


endmodule