`ifndef IF_COVERAGE_SV
`define IF_COVERAGE_SV

import dut_parameters_pkg::*;
import dut_structs_pkg::*;
import tb_util_pkg::*;
class IF_coverage extends uvm_component;

    `uvm_component_utils(IF_coverage)
    virtual IF_if vif;
    IF_config m_config;    
    bit m_is_covered;
    fetched_packet packet_a, packet_b;

    covergroup m_cov;
        option.per_instance = 1;



        // Basic functional features 
        cp_total_hits: coverpoint vif.Hit_cache iff(vif.rst_n) 
        {
            bins total_hits = {1};
        } 

        cp_total_misses: coverpoint vif.Miss iff(vif.rst_n)
        {
            bins total_misses = {1};
        } 

        cp_total_branches: coverpoint vif.pr_update.valid_jump iff(vif.rst_n)
        {
            bins total_branches = {1};
        }

        cp_partial_accesses: coverpoint vif.partial_access iff(vif.rst_n && vif.Hit_cache)
        {
            // option.at_least = PARTIAL_ACCESSES;
            bins total_partial_accesses = {1};
        } 

        cp_branch1_taken: coverpoint vif.packet_a.taken_branch iff(vif.rst_n && vif.valid_o)
        {
            bins total_branch1_taken = {1};
        } 

        cp_branch2_taken: coverpoint vif.packet_b.taken_branch iff(vif.rst_n && vif.valid_o)
        {
            bins total_branch2_taken = {1};
        } 

        cp_branch1_not_taken: coverpoint vif.packet_a.taken_branch iff(vif.rst_n && vif.valid_o)
        {
            bins total_branch1_not_taken = {0};
        } 

        cp_branch2_not_taken: coverpoint vif.packet_b.taken_branch iff(vif.rst_n && vif.valid_o)
        {
            bins total_branch2_not_taken = {0};
        } 
        
        cp_b1_not_b2_not_taken: cross cp_branch1_not_taken, cp_branch2_not_taken { 
            // option.at_least = BRANCH1_NOT_AND_BRANCH2_NOT_TAKEN;
        } 
        cp_b1_taken_b2_not: cross cp_branch1_taken, cp_branch2_not_taken  { 
            // option.at_least = BRANCH1_TAKEN_AND_BRANCH2_NOT;
        } 
        cp_b2_taken_b1_not: cross cp_branch2_taken, cp_branch1_not_taken  { 
            // option.at_least = BRANCH2_TAKEN_AND_BRANCH1_NOT;
        } 
        cp_both_taken: cross cp_branch1_taken, cp_branch2_taken { 
            // option.at_least = BRANCH_1_AND_2_TAKEN;
        } 

        // Function scenarios
        cp_function_calls: coverpoint vif.is_jumpl iff(vif.rst_n)
        {
            // option.at_least = FUNTION_CALLS;
            bins total_function_calls = {1};
        } 

        cp_function_returns: coverpoint vif.is_return_in iff(vif.rst_n)
        {
            // option.at_least = FUNTION_RETURNS;
            bins total_function_returns = {1};
        } 

        

        // Invalid Instructions scenarios
        // cp_invalid_instructions: coverpoint vif.invalid_instruction iff(vif.rst_n)
        // {
        //     // option.at_least = INVALID_INSTRUCTIONS;
        //     bins total_invalid_instructions = {1};
        // }
        // cp_invalid_instructions_and_flush: cross cp_invalid_instructions, cp_total_flushes { 
        //     // option.at_least = INVALID_INSTRUCTIONS_ON_FLUSH;
        // }

        // // Invalid prediction scenarios
        // cp_invalid_predictions: coverpoint vif.invalid_prediction iff(vif.rst_n)
        // {
        //     // option.at_least = INVALID_PREDICTIONS;
        //     bins total_invalid_predictions = {1};
        // }
        // cp_invalid_predictions_and_flush: cross cp_invalid_predictions, cp_total_flushes { 
        //     // option.at_least = INVALID_PREDICTIONS_ON_FLUSH;
        // }

        // Flush scenarios
        cp_total_flushes: coverpoint vif.must_flush iff(vif.rst_n) 
        {
            // option.at_least = FLUSHES;
            bins total_flushes = {1};
        }
        cp_flush_hit: cross cp_total_flushes, cp_total_hits    { 
            // option.at_least = FLUSH_ON_HIT;
        }


        // Corner case scenarios
        // Invalid instruction while fsm is blocked
        // cp_invalid_instructions_on_miss: cross cp_invalid_instructions, cp_total_misses   { 
        //     // option.at_least = INVALID_INSTRUCTIONS_ON_MISS;
        // }
        // // Invalid prediction while fsm is blocked
        // cp_invalid_predictions_on_miss: cross cp_invalid_predictions, cp_total_misses   { 
        //     // option.at_least = INVALID_PREDICTIONS_ON_MISS;
        // }
        // Flush while fsm is blocked
        cp_flush_miss: cross cp_total_flushes, cp_total_misses { 
            // option.at_least = FLUSH_ON_MISS;
        }
        // Flush & invalid instruction issued while fsm is blocked
        // flush_inv_ins_miss: cross cp_total_flushes, cp_invalid_instructions, cp_total_misses { 
        //     // option.at_least = FLUSH__INV_INSTRUCTION__MISS;
        // }
        // // Flush & invalid prediction issued while fsm is blocked
        // flush_inv_pred_miss: cross cp_total_flushes, cp_invalid_predictions, cp_total_misses { 
        //     // option.at_least = FLUSH__INV_PREDICTION__MISS;
        // }        
        // Flush & function return issued while fsm is blocked
        flush_fnc_ret_miss: cross cp_total_flushes, cp_function_returns, cp_total_misses { 
            // option.at_least = FLUSH__FNC_RETURN__MISS;
        }





    endgroup


    function new(string name, uvm_component parent);
        super.new(name, parent);
        m_cov = new();
    endfunction

    task run_phase(uvm_phase phase);
        forever begin 
            {packet_b,packet_a} = vif.data_out;
            if (m_config.coverage_enable) begin
                m_cov.sample();
                // Check coverage - could use m_cov.option.goal instead of 100 if your simulator supports it
                if (m_cov.get_inst_coverage() >= 100) m_is_covered = 1;
            end
            @(negedge vif.clk);
        end
    endtask



    function void build_phase(uvm_phase phase);
        if (!uvm_config_db #(IF_config)::get(this, "", "config", m_config))
            `uvm_error(get_type_name(), "IF config not found")
    endfunction


    function void report_phase(uvm_phase phase);
        if (m_config.coverage_enable) begin
            // if(!m_is_covered)`uvm_info(get_type_name(), "Could not reach coverage goals and timeout transactions reached", UVM_MEDIUM)
            `uvm_info(get_type_name(), $sformatf("Coverage score = %3.1f%%", m_cov.get_inst_coverage()), UVM_MEDIUM)
        end else
            `uvm_info(get_type_name(), "Coverage disabled for this agent", UVM_MEDIUM)
    endfunction



endclass





`endif 

