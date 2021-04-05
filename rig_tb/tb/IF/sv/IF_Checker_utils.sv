import IF_util_pkg::*;
class IF_Checker_utils;

    // Gshare Predictor
    bit [GSH_SIZE-1:0][GSH_COUNTER_NUM*2-1:0] gshare_array;
    bit [GSH_HISTORY_BITS-1:0] gsh_history;
    // Branch Target Buffer (BTB)
    IF_util_pkg::btb_array_entry_s [BTB_SIZE-1:0] btb_array;
    // Return Address Stack (RAS)
    bit[PC_BITS-1:0] ras_queue [$:RAS_DEPTH-1];
    // Predictor updates
    IF_util_pkg::predictor_update_extended pr_queue[$];


    // Initialize Checker components
    int gs_fl;
    int btb_fl;
    function new();
        gs_fl = $fopen("GShare.txt");
        btb_fl = $fopen("BTB.txt");
    endfunction 


    /*
    // Gshare Predictor
    */
    function bit[1:0] update_counter_value (bit is_taken, bit[1:0] old_counter_value);
        bit[1:0] new_counter_value;

        if(is_taken) begin
            if(old_counter_value<2'b11) begin 
                new_counter_value = old_counter_value+1;
            end else begin 
                new_counter_value = old_counter_value;
            end
        end else begin
            if(old_counter_value>2'b00) begin 
                new_counter_value = old_counter_value-1;
            end else begin 
                new_counter_value = old_counter_value;
            end
        end
        return new_counter_value;
    endfunction 

    function void gsh_update(input int pc, bit is_taken);
        int line, counter_id;
        int cnt_value_before;// #todo remove this
        // update counter value
        line = pc[$clog2(GSH_SIZE):1];
        counter_id = pc[GSH_HISTORY_BITS:1] ^ gsh_history;
        cnt_value_before = gshare_array[line][counter_id*2+:2];
        gshare_array[line][counter_id*2+:2] = update_counter_value(is_taken, gshare_array[line][counter_id*2+:2]);
        //update gsh history
        gsh_history = {is_taken, gsh_history[GSH_HISTORY_BITS-1:1]};
        // $display("[GSHARE] @ %0t ps updt counter, pc=%0d, line=%3d, cnt_id=%0d, is_taken=%0d, cnt_value_before=%0d, cnt_value_after=%0d history_after=%0d",$time(),pc,line,counter_id,is_taken,cnt_value_before,gshare_array[line][counter_id*2+:2],gsh_history);
    endfunction 

    function bit gsh_read(input int pc);
        int line, counter_id;
        bit[1:0] counter_value;
        bit is_taken;

        line = pc[$clog2(GSH_SIZE):1];
        counter_id = pc[GSH_HISTORY_BITS:1] ^ gsh_history;
        counter_value = gshare_array[line][(counter_id*2)+:2];

        is_taken = counter_value>1;

        // $display("[GSHARE] @ %0t ps read counter, pc=%0d, line=%0d, cnt_id=%0d, is_taken=%0d, cnt_value=%0d, history=%0d",$time(),pc,line,counter_id,is_taken,counter_value,gsh_history);
        return is_taken;
    endfunction

    /*
    // Branch Target Buffer (BTB)
    */
    function void btb_update(input int orig_pc, input int target_pc);
        int line;
        // $display("[BTB update] @ %0t ps orig_pc=%0d, target_pc=%0d",$time(),orig_pc,target_pc);
        line = orig_pc[$clog2(BTB_SIZE):1];
        btb_array[line].orig_pc = orig_pc;
        btb_array[line].target_pc = target_pc;
        btb_array[line].valid = 1;
    endfunction

    function btb_read_s btb_read(input int pc);
        btb_read_s btb;
        int line;

        line = pc[$clog2(BTB_SIZE):1];
        btb.target_pc = btb_array[line].target_pc;
        btb.hit = (pc==btb_array[line].orig_pc)&(btb_array[line].valid);
        // $display("[BTB read] @ %0t ps pc=%0d orig_pc=%0d, target_pc=%0d, btb.valid=%b, btb_hit=%b",$time(),pc,btb_array[line].orig_pc,btb.target_pc,btb_array[line].valid,btb.hit);
        return btb;
    endfunction

    function void btb_invalidate(input int pc, input bit pr_after_btb_inv);
        int line;
        if(!pr_after_btb_inv) begin
            line = pc[$clog2(BTB_SIZE):1];
            btb_array[line].valid = 0;
            // $display("[BTB invalidate]: orig_pc=%0d",pc);
        end
            
    endfunction


    /*
    // Return Address Stack (RAS)
    */
    function void ras_push(input int pc);
        if(ras_queue.size()==RAS_DEPTH) ras_queue = ras_queue[0:$-1]; // if overflow delete last item
        ras_queue.push_front(pc);
        // $display("[RAS] pushed:%0d, queue_size(after push)=%0d, queue=%p",pc,ras_queue.size(),ras_queue);
    endfunction

    function bit[PC_BITS-1:0] ras_pop();
        bit[PC_BITS-1:0] return_pc; 
        assert(ras_queue.size()>0) else $fatal("popping from empty ras?");
        return_pc = ras_queue.pop_front();
        // $display("[RAS] popped:%0d, queue_size(after pop)=%0d, queue=%p",return_pc,ras_queue.size(),ras_queue);
        return return_pc;
    endfunction

    /*
    // Checker general functions
    */
    // Combines Gshare and BTB to determine if input pc is taken
    function bit is_taken(input int pc);
        btb_read_s btb;
        bit gshare_hit, btb_hit, taken;

        gshare_hit = gsh_read(pc);
        btb = btb_read(pc);
        btb_hit = btb.hit;
        taken = gshare_hit & btb_hit;
        return taken;
    endfunction 

    // Returns the target pc of the branch
    function bit[PC_BITS-1:0] get_target_pc(input int pc);
        btb_read_s btb;
        bit[PC_BITS-1:0] target_pc;

        // assert (is_taken(pc)) else $fatal("Input pc is not predicted as taken");
        btb = btb_read(pc);
        target_pc = btb.target_pc;
        return target_pc;
    endfunction

  

    function void get_pr_updates();
        IF_util_pkg::predictor_update_extended pr_trans;

        int pr_trans_num;
        int index;
        // pr_trans_num = skip_pr ? pr_queue.size()-1:pr_queue.size();
        pr_trans_num = pr_queue.size();
        // $display("Start of getting updates (queue size=%0d)",pr_queue.size());
        // $display("pr_queue[0]=%p",pr_queue[0]);
        // $display("pr_queue[1]=%p",pr_queue[1]);
        for (int i = 0; i < pr_trans_num; i++) begin
            pr_trans = pr_queue[0];
            if(!pr_trans.skip_once) begin
                pr_trans = pr_queue.pop_front();
                gsh_update(pr_trans.pr_update.orig_pc, pr_trans.pr_update.jump_taken);
                if(!pr_trans.skip_btb) btb_update(pr_trans.pr_update.orig_pc, pr_trans.pr_update.jump_address);
            end
        end
        pr_trans_num = pr_queue.size();
        for (int i = 0; i < pr_trans_num; i++) begin
            pr_queue[i].skip_once = 0;
        end
        
    endfunction


    function bit[2*PC_BITS-1:0] get_next_pc_restart(
        input bit flush,
        input bit invalid_instruction,
        input bit invalid_prediction,
        input bit function_return,
        input bit delayed_function_return,
        input int flush_PC,
        input int restart_PC);

        bit[PC_BITS-1:0] next_pc_1, next_pc_2, RAS_not_empty;
        RAS_not_empty = ras_queue.size()>0;
        if(flush) begin
            next_pc_1 = flush_PC;
            next_pc_2 = next_pc_1 + 4;
        end else if(invalid_instruction||invalid_prediction) begin
            next_pc_1 = restart_PC;
            next_pc_2 = next_pc_1 + 4;
        end else if((function_return||delayed_function_return) && RAS_not_empty) begin
            next_pc_1 = ras_pop() + 4;
            next_pc_2 = next_pc_1 + 4;
        end 

        return {next_pc_2,next_pc_1};
    endfunction


    function bit[2*PC_BITS-1:0] get_next_pc_normal(
        input bit is_taken_a,
        input bit is_taken_b,
        input bit half_access_fsm,
        input bit partial_access,
        input int pc_a,
        input int pc_b,
        input int next_pc_1_i,
        input int next_pc_2_i);

        bit[PC_BITS-1:0] next_pc_1, next_pc_2;
        if(is_taken_a) begin
            if(half_access_fsm) begin
                if(is_taken_b) begin
                    next_pc_1 = get_target_pc(pc_b);
                    next_pc_2 = next_pc_1 + 4;
                end else begin 
                    next_pc_1 = pc_b + 4;
                    next_pc_2 = next_pc_1 + 4;
                end
            end else begin 
                next_pc_1 = pc_a;
                next_pc_2 = get_target_pc(pc_a);
            end
        end else if(is_taken_b) begin
            if(partial_access) begin
                next_pc_1 = next_pc_1_i;
                next_pc_2 = next_pc_2_i;
            end else begin
                next_pc_1 = get_target_pc(pc_b);
                next_pc_2 = next_pc_1 + 4;
            end
        end else begin 
            if(partial_access) begin
                next_pc_1 = next_pc_1_i;
                next_pc_2 = next_pc_2_i;
            end else begin
                next_pc_1 = pc_b + 4;
                next_pc_2 = next_pc_1 + 4;
            end
        end
        return {next_pc_2,next_pc_1};
    endfunction

endclass