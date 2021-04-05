onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb/clk
add wave -noupdate /tb/rst_n
add wave -noupdate -divider <NULL>
add wave -noupdate -radix unsigned /tb/module_top/top_processor/ifetch/predictor/gshare/GS_SIZE
add wave -noupdate -radix unsigned /tb/module_top/top_processor/ifetch/predictor/btb/BTB_SIZE
add wave -noupdate -radix unsigned /tb/module_top/top_processor/ifetch/predictor/ras/RAS_SIZE
add wave -noupdate -radix unsigned /tb/module_top/top_processor/issue/SC_SIZE
add wave -noupdate -radix unsigned /tb/module_top/top_processor/rob/ROB_SIZE
add wave -noupdate -radix unsigned /tb/module_top/data_cache/load_buffer/LD_BF_SIZE
add wave -noupdate -radix unsigned /tb/module_top/data_cache/store_buffer/ST_BF_SIZE
add wave -noupdate -radix unsigned /tb/module_top/data_cache/wait_buffer/WT_BF_SIZE
add wave -noupdate -divider Statistics
add wave -noupdate -radix unsigned /tb/module_top/top_processor/execution/csr_registers/cycle_counter
add wave -noupdate -radix unsigned /tb/module_top/top_processor/execution/csr_registers/instr_counter
add wave -noupdate -radix unsigned /tb/module_top/top_processor/issue/total_issues
add wave -noupdate -radix unsigned /tb/module_top/top_processor/issue/dual_issues
add wave -noupdate -radix unsigned /tb/module_top/top_processor/issue/hazards
add wave -noupdate -radix unsigned /tb/module_top/top_processor/issue/stalls
add wave -noupdate -radix unsigned /tb/module_top/top_processor/rr/reclaim_stalls
add wave -noupdate -radix unsigned /tb/module_top/top_processor/ifetch/redir_prediction
add wave -noupdate -radix unsigned /tb/module_top/top_processor/ifetch/redir_return
add wave -noupdate -radix unsigned /tb/module_top/top_processor/ifetch/flushes
add wave -noupdate -radix unsigned /tb/module_top/top_processor/idecode/branch_stalls
add wave -noupdate -radix unsigned /tb/module_top/top_processor/rr/stalls_rob
add wave -noupdate -divider <NULL>
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/frame_buffer_write
add wave -noupdate -radix unsigned /tb/module_top/frame_buffer_address
add wave -noupdate -radix unsigned /tb/module_top/frame_buffer_data
add wave -noupdate /tb/module_top/color
add wave -noupdate -divider <NULL>
add wave -noupdate -radix unsigned /tb/module_top/vga_address
add wave -noupdate -radix unsigned /tb/module_top/vga_data
add wave -noupdate -divider Pipeline
add wave -noupdate -divider IF
add wave -noupdate /tb/module_top/top_processor/ifetch/valid_o
add wave -noupdate /tb/module_top/top_processor/ifetch/ready_in
add wave -noupdate /tb/module_top/top_processor/ifetch/current_pc
add wave -noupdate /tb/module_top/top_processor/ifetch/instruction_out
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/ifetch/new_entry
add wave -noupdate /tb/module_top/top_processor/ifetch/pc_orig
add wave -noupdate /tb/module_top/top_processor/ifetch/target_pc
add wave -noupdate /tb/module_top/top_processor/ifetch/is_taken
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/pr_update_o
add wave -noupdate /tb/module_top/top_processor/ifetch/invalid_prediction
add wave -noupdate /tb/module_top/top_processor/ifetch/invalid_instruction
add wave -noupdate /tb/module_top/top_processor/ifetch/must_flush
add wave -noupdate /tb/module_top/top_processor/ifetch/is_return_in
add wave -noupdate /tb/module_top/top_processor/ifetch/is_return_fsm
add wave -noupdate /tb/module_top/top_processor/ifetch/is_jumpl
add wave -noupdate /tb/module_top/top_processor/ifetch/over_priority
add wave -noupdate /tb/module_top/top_processor/ifetch/current_pc
add wave -noupdate -radix hexadecimal /tb/module_top/top_processor/ifetch/correct_address
add wave -noupdate /tb/module_top/top_processor/ifetch/next_pc
add wave -noupdate /tb/module_top/top_processor/ifetch/old_pc
add wave -noupdate /tb/module_top/top_processor/ifetch/half_access
add wave -noupdate -divider ICache
add wave -noupdate -radix hexadecimal /tb/module_top/icache/address
add wave -noupdate /tb/module_top/icache/hit
add wave -noupdate /tb/module_top/icache/miss
add wave -noupdate /tb/module_top/icache/line_selector
add wave -noupdate -radix binary /tb/module_top/icache/offset_selector
add wave -noupdate /tb/module_top/icache/valid_o
add wave -noupdate -radix hexadecimal /tb/module_top/icache/address_out
add wave -noupdate /tb/module_top/icache/ready_in
add wave -noupdate /tb/module_top/icache/data_in
add wave -noupdate /tb/module_top/icache/partial_access
add wave -noupdate /tb/module_top/icache/partial_type
add wave -noupdate -divider predictor
add wave -noupdate /tb/module_top/top_processor/ifetch/predictor/pc_in
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/ifetch/predictor/pc_out_ras
add wave -noupdate /tb/module_top/top_processor/ifetch/predictor/is_return
add wave -noupdate /tb/module_top/top_processor/ifetch/next_pc_saved
add wave -noupdate -divider ID
add wave -noupdate /tb/module_top/top_processor/idecode/branch_stall
add wave -noupdate /tb/module_top/top_processor/idecode/one_slot_free
add wave -noupdate /tb/module_top/top_processor/idecode/two_slots_free
add wave -noupdate /tb/module_top/top_processor/idecode/is_branch
add wave -noupdate /tb/module_top/top_processor/idecode/two_branches
add wave -noupdate /tb/module_top/top_processor/idecode/must_flush
add wave -noupdate /tb/module_top/top_processor/idecode/branch_if
add wave -noupdate /tb/module_top/top_processor/idecode/pr_update
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/idecode/valid_i
add wave -noupdate /tb/module_top/top_processor/idecode/ready_o
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/idecode/decoder/pc_in_1
add wave -noupdate /tb/module_top/top_processor/idecode/decoder/pc_in_2
add wave -noupdate /tb/module_top/top_processor/idecode/old_pc
add wave -noupdate /tb/module_top/top_processor/idecode/invalid_prediction
add wave -noupdate /tb/module_top/top_processor/idecode/invalid_instruction
add wave -noupdate /tb/module_top/top_processor/idecode/is_jumpl
add wave -noupdate /tb/module_top/top_processor/idecode/decoder/is_jumpl_a
add wave -noupdate /tb/module_top/top_processor/idecode/decoder/is_jumpl_b
add wave -noupdate /tb/module_top/top_processor/idecode/is_return
add wave -noupdate /tb/module_top/top_processor/idecode/decoder/is_return_32a
add wave -noupdate /tb/module_top/top_processor/idecode/decoder/is_return_32b
add wave -noupdate /tb/module_top/top_processor/idecode/must_flush
add wave -noupdate /tb/module_top/top_processor/idecode/correct_address
add wave -noupdate -divider {Flush Controller}
add wave -noupdate /tb/module_top/top_processor/idecode/valid_branch_32a
add wave -noupdate /tb/module_top/top_processor/idecode/flush_controller/valid_transaction
add wave -noupdate /tb/module_top/top_processor/idecode/valid_branch_32b
add wave -noupdate /tb/module_top/top_processor/idecode/flush_controller/valid_transaction_2
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/idecode/flush_controller/must_capture
add wave -noupdate /tb/module_top/top_processor/idecode/flush_controller/capture_1
add wave -noupdate /tb/module_top/top_processor/idecode/flush_controller/capture_2
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/idecode/valid_o
add wave -noupdate /tb/module_top/top_processor/idecode/output1
add wave -noupdate /tb/module_top/top_processor/idecode/valid_o_2
add wave -noupdate /tb/module_top/top_processor/idecode/output2
add wave -noupdate -divider RR
add wave -noupdate /tb/module_top/top_processor/rr/valid_i_1
add wave -noupdate /tb/module_top/top_processor/rr/instruction_1
add wave -noupdate /tb/module_top/top_processor/rr/valid_i_2
add wave -noupdate /tb/module_top/top_processor/rr/instruction_2
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/rr/valid_o_1
add wave -noupdate /tb/module_top/top_processor/rr/instruction_o_1
add wave -noupdate /tb/module_top/top_processor/rr/valid_o_2
add wave -noupdate /tb/module_top/top_processor/rr/instruction_o_2
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/rr/flush_valid
add wave -noupdate -radix unsigned /tb/module_top/top_processor/flush_address
add wave -noupdate /tb/module_top/top_processor/ir_valid_o_1
add wave -noupdate /tb/module_top/top_processor/id_ir_valid_o
add wave -noupdate -childformat {{/tb/module_top/top_processor/id_decoded_1_o.pc -radix unsigned}} -subitemconfig {/tb/module_top/top_processor/id_decoded_1_o.pc {-height 15 -radix unsigned}} /tb/module_top/top_processor/id_decoded_1_o
add wave -noupdate -childformat {{/tb/module_top/top_processor/renamed_1.pc -radix unsigned}} -subitemconfig {/tb/module_top/top_processor/renamed_1.pc {-height 15 -radix unsigned}} /tb/module_top/top_processor/renamed_1
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/rr/ready_i
add wave -noupdate /tb/module_top/top_processor/rr/fl_valid_1
add wave -noupdate /tb/module_top/top_processor/rr/fl_valid_2
add wave -noupdate /tb/module_top/top_processor/rr/fl_push
add wave -noupdate /tb/module_top/top_processor/rr/rob_status
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/rr/rat/take_checkpoint
add wave -noupdate /tb/module_top/top_processor/rr/dual_branch
add wave -noupdate /tb/module_top/top_processor/rr/instr_num
add wave -noupdate -radix unsigned -childformat {{{/tb/module_top/top_processor/rr/rat/CurrentRAT[31]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[30]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[29]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[28]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[27]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[26]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[25]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[24]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[23]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[22]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[21]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[20]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[19]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[18]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[17]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[16]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[15]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[14]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[13]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[12]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[11]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[10]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[9]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[8]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[7]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[6]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[5]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[4]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[3]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[2]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[1]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CurrentRAT[0]} -radix unsigned}} -subitemconfig {{/tb/module_top/top_processor/rr/rat/CurrentRAT[31]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[30]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[29]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[28]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[27]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[26]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[25]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[24]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[23]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[22]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[21]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[20]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[19]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[18]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[17]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[16]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[15]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[14]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[13]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[12]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[11]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[10]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[9]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[8]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[7]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[6]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[5]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[4]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[3]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[2]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[1]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CurrentRAT[0]} {-height 15 -radix unsigned}} /tb/module_top/top_processor/rr/rat/CurrentRAT
add wave -noupdate -radix unsigned -childformat {{{/tb/module_top/top_processor/rr/rat/CheckpointedRAT[3]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CheckpointedRAT[2]} -radix unsigned} {{/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1]} -radix unsigned -childformat {{{[31]} -radix unsigned} {{[30]} -radix unsigned} {{[29]} -radix unsigned} {{[28]} -radix unsigned} {{[27]} -radix unsigned} {{[26]} -radix unsigned} {{[25]} -radix unsigned} {{[24]} -radix unsigned} {{[23]} -radix unsigned} {{[22]} -radix unsigned} {{[21]} -radix unsigned} {{[20]} -radix unsigned} {{[19]} -radix unsigned} {{[18]} -radix unsigned} {{[17]} -radix unsigned} {{[16]} -radix unsigned} {{[15]} -radix unsigned} {{[14]} -radix unsigned} {{[13]} -radix unsigned} {{[12]} -radix unsigned} {{[11]} -radix unsigned} {{[10]} -radix unsigned} {{[9]} -radix unsigned} {{[8]} -radix unsigned} {{[7]} -radix unsigned} {{[6]} -radix unsigned} {{[5]} -radix unsigned} {{[4]} -radix unsigned} {{[3]} -radix unsigned} {{[2]} -radix unsigned} {{[1]} -radix unsigned} {{[0]} -radix unsigned}}} {{/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0]} -radix unsigned -childformat {{{[31]} -radix unsigned} {{[30]} -radix unsigned} {{[29]} -radix unsigned} {{[28]} -radix unsigned} {{[27]} -radix unsigned} {{[26]} -radix unsigned} {{[25]} -radix unsigned} {{[24]} -radix unsigned} {{[23]} -radix unsigned} {{[22]} -radix unsigned} {{[21]} -radix unsigned} {{[20]} -radix unsigned} {{[19]} -radix unsigned} {{[18]} -radix unsigned} {{[17]} -radix unsigned} {{[16]} -radix unsigned} {{[15]} -radix unsigned} {{[14]} -radix unsigned} {{[13]} -radix unsigned} {{[12]} -radix unsigned} {{[11]} -radix unsigned} {{[10]} -radix unsigned} {{[9]} -radix unsigned} {{[8]} -radix unsigned} {{[7]} -radix unsigned} {{[6]} -radix unsigned} {{[5]} -radix unsigned} {{[4]} -radix unsigned} {{[3]} -radix unsigned} {{[2]} -radix unsigned} {{[1]} -radix unsigned} {{[0]} -radix unsigned}}}} -subitemconfig {{/tb/module_top/top_processor/rr/rat/CheckpointedRAT[3]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[2]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1]} {-height 15 -radix unsigned -childformat {{{[31]} -radix unsigned} {{[30]} -radix unsigned} {{[29]} -radix unsigned} {{[28]} -radix unsigned} {{[27]} -radix unsigned} {{[26]} -radix unsigned} {{[25]} -radix unsigned} {{[24]} -radix unsigned} {{[23]} -radix unsigned} {{[22]} -radix unsigned} {{[21]} -radix unsigned} {{[20]} -radix unsigned} {{[19]} -radix unsigned} {{[18]} -radix unsigned} {{[17]} -radix unsigned} {{[16]} -radix unsigned} {{[15]} -radix unsigned} {{[14]} -radix unsigned} {{[13]} -radix unsigned} {{[12]} -radix unsigned} {{[11]} -radix unsigned} {{[10]} -radix unsigned} {{[9]} -radix unsigned} {{[8]} -radix unsigned} {{[7]} -radix unsigned} {{[6]} -radix unsigned} {{[5]} -radix unsigned} {{[4]} -radix unsigned} {{[3]} -radix unsigned} {{[2]} -radix unsigned} {{[1]} -radix unsigned} {{[0]} -radix unsigned}}} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][31]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][30]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][29]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][28]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][27]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][26]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][25]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][24]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][23]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][22]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][21]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][20]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][19]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][18]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][17]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][16]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][15]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][14]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][13]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][12]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][11]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][10]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][9]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][8]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][7]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][6]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][5]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][4]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][3]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][2]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][1]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[1][0]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0]} {-height 15 -radix unsigned -childformat {{{[31]} -radix unsigned} {{[30]} -radix unsigned} {{[29]} -radix unsigned} {{[28]} -radix unsigned} {{[27]} -radix unsigned} {{[26]} -radix unsigned} {{[25]} -radix unsigned} {{[24]} -radix unsigned} {{[23]} -radix unsigned} {{[22]} -radix unsigned} {{[21]} -radix unsigned} {{[20]} -radix unsigned} {{[19]} -radix unsigned} {{[18]} -radix unsigned} {{[17]} -radix unsigned} {{[16]} -radix unsigned} {{[15]} -radix unsigned} {{[14]} -radix unsigned} {{[13]} -radix unsigned} {{[12]} -radix unsigned} {{[11]} -radix unsigned} {{[10]} -radix unsigned} {{[9]} -radix unsigned} {{[8]} -radix unsigned} {{[7]} -radix unsigned} {{[6]} -radix unsigned} {{[5]} -radix unsigned} {{[4]} -radix unsigned} {{[3]} -radix unsigned} {{[2]} -radix unsigned} {{[1]} -radix unsigned} {{[0]} -radix unsigned}}} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][31]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][30]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][29]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][28]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][27]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][26]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][25]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][24]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][23]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][22]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][21]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][20]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][19]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][18]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][17]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][16]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][15]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][14]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][13]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][12]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][11]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][10]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][9]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][8]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][7]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][6]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][5]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][4]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][3]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][2]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][1]} {-radix unsigned} {/tb/module_top/top_processor/rr/rat/CheckpointedRAT[0][0]} {-radix unsigned}} /tb/module_top/top_processor/rr/rat/CheckpointedRAT
add wave -noupdate -radix unsigned /tb/module_top/top_processor/rr/rat/next_ckp
add wave -noupdate /tb/module_top/top_processor/rr/rat/next_ckp_plus
add wave -noupdate /tb/module_top/top_processor/rr/rat/instr_num
add wave -noupdate /tb/module_top/top_processor/rr/rat/instr_1_rn
add wave -noupdate /tb/module_top/top_processor/rr/rat/instr_2_rn
add wave -noupdate /tb/module_top/top_processor/rr/flush_valid
add wave -noupdate /tb/module_top/top_processor/rr/flush_rat_id
add wave -noupdate /tb/module_top/top_processor/rr/rat/write_en_1
add wave -noupdate /tb/module_top/top_processor/rr/rat/write_addr_1
add wave -noupdate /tb/module_top/top_processor/rr/rat/write_data_1
add wave -noupdate /tb/module_top/top_processor/rr/rat/write_en_2
add wave -noupdate /tb/module_top/top_processor/rr/rat/write_addr_2
add wave -noupdate /tb/module_top/top_processor/rr/rat/write_data_2
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/id_valid_1_o
add wave -noupdate /tb/module_top/top_processor/id_valid_2_o
add wave -noupdate -divider IQ
add wave -noupdate /tb/module_top/top_processor/renamed_1
add wave -noupdate /tb/module_top/top_processor/renamed_2
add wave -noupdate /tb/module_top/top_processor/renamed_o_1
add wave -noupdate /tb/module_top/top_processor/renamed_o_2
add wave -noupdate -divider IS
add wave -noupdate -childformat {{/tb/module_top/top_processor/issue/Instruction1.source1 -radix unsigned} {/tb/module_top/top_processor/issue/Instruction1.source2 -radix unsigned} {/tb/module_top/top_processor/issue/Instruction1.destination -radix unsigned}} -subitemconfig {/tb/module_top/top_processor/issue/Instruction1.source1 {-height 15 -radix unsigned} /tb/module_top/top_processor/issue/Instruction1.source2 {-height 15 -radix unsigned} /tb/module_top/top_processor/issue/Instruction1.destination {-height 15 -radix unsigned}} /tb/module_top/top_processor/issue/Instruction1
add wave -noupdate /tb/module_top/top_processor/issue/Instruction2
add wave -noupdate /tb/module_top/top_processor/issue/t_execution
add wave -noupdate -radix unsigned -childformat {{{/tb/module_top/top_processor/issue/regfile/RegFile[63]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[62]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[61]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[60]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[59]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[58]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[57]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[56]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[55]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[54]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[53]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[52]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[51]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[50]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[49]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[48]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[47]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[46]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[45]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[44]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[43]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[42]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[41]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[40]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[39]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[38]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[37]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[36]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[35]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[34]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[33]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[32]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[31]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[30]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[29]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[28]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[27]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[26]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[25]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[24]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[23]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[22]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[21]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[20]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[19]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[18]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[17]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[16]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[15]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[14]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[13]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[12]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[11]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[10]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[9]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[8]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[7]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[6]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[5]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[4]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[3]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[2]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[1]} -radix unsigned} {{/tb/module_top/top_processor/issue/regfile/RegFile[0]} -radix unsigned}} -subitemconfig {{/tb/module_top/top_processor/issue/regfile/RegFile[63]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[62]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[61]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[60]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[59]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[58]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[57]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[56]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[55]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[54]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[53]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[52]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[51]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[50]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[49]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[48]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[47]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[46]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[45]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[44]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[43]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[42]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[41]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[40]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[39]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[38]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[37]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[36]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[35]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[34]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[33]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[32]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[31]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[30]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[29]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[28]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[27]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[26]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[25]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[24]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[23]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[22]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[21]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[20]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[19]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[18]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[17]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[16]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[15]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[14]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[13]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[12]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[11]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[10]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[9]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[8]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[7]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[6]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[5]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[4]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[3]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[2]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[1]} {-height 15 -radix unsigned} {/tb/module_top/top_processor/issue/regfile/RegFile[0]} {-height 15 -radix unsigned}} /tb/module_top/top_processor/issue/regfile/RegFile
add wave -noupdate -radix unsigned -childformat {{{/tb/final_regfile[63]} -radix unsigned} {{/tb/final_regfile[62]} -radix unsigned} {{/tb/final_regfile[61]} -radix unsigned} {{/tb/final_regfile[60]} -radix unsigned} {{/tb/final_regfile[59]} -radix unsigned} {{/tb/final_regfile[58]} -radix unsigned} {{/tb/final_regfile[57]} -radix unsigned} {{/tb/final_regfile[56]} -radix unsigned} {{/tb/final_regfile[55]} -radix unsigned} {{/tb/final_regfile[54]} -radix unsigned} {{/tb/final_regfile[53]} -radix unsigned} {{/tb/final_regfile[52]} -radix unsigned} {{/tb/final_regfile[51]} -radix unsigned} {{/tb/final_regfile[50]} -radix unsigned} {{/tb/final_regfile[49]} -radix unsigned} {{/tb/final_regfile[48]} -radix unsigned} {{/tb/final_regfile[47]} -radix unsigned} {{/tb/final_regfile[46]} -radix unsigned} {{/tb/final_regfile[45]} -radix unsigned} {{/tb/final_regfile[44]} -radix unsigned} {{/tb/final_regfile[43]} -radix unsigned} {{/tb/final_regfile[42]} -radix unsigned} {{/tb/final_regfile[41]} -radix unsigned} {{/tb/final_regfile[40]} -radix unsigned} {{/tb/final_regfile[39]} -radix unsigned} {{/tb/final_regfile[38]} -radix unsigned} {{/tb/final_regfile[37]} -radix unsigned} {{/tb/final_regfile[36]} -radix unsigned} {{/tb/final_regfile[35]} -radix unsigned} {{/tb/final_regfile[34]} -radix unsigned} {{/tb/final_regfile[33]} -radix unsigned} {{/tb/final_regfile[32]} -radix unsigned} {{/tb/final_regfile[31]} -radix unsigned} {{/tb/final_regfile[30]} -radix unsigned} {{/tb/final_regfile[29]} -radix unsigned} {{/tb/final_regfile[28]} -radix unsigned} {{/tb/final_regfile[27]} -radix unsigned} {{/tb/final_regfile[26]} -radix unsigned} {{/tb/final_regfile[25]} -radix unsigned} {{/tb/final_regfile[24]} -radix unsigned} {{/tb/final_regfile[23]} -radix unsigned} {{/tb/final_regfile[22]} -radix unsigned} {{/tb/final_regfile[21]} -radix unsigned} {{/tb/final_regfile[20]} -radix unsigned} {{/tb/final_regfile[19]} -radix unsigned} {{/tb/final_regfile[18]} -radix unsigned} {{/tb/final_regfile[17]} -radix unsigned} {{/tb/final_regfile[16]} -radix unsigned} {{/tb/final_regfile[15]} -radix unsigned} {{/tb/final_regfile[14]} -radix unsigned} {{/tb/final_regfile[13]} -radix unsigned} {{/tb/final_regfile[12]} -radix unsigned} {{/tb/final_regfile[11]} -radix unsigned} {{/tb/final_regfile[10]} -radix unsigned} {{/tb/final_regfile[9]} -radix unsigned} {{/tb/final_regfile[8]} -radix unsigned} {{/tb/final_regfile[7]} -radix unsigned} {{/tb/final_regfile[6]} -radix unsigned} {{/tb/final_regfile[5]} -radix unsigned} {{/tb/final_regfile[4]} -radix unsigned} {{/tb/final_regfile[3]} -radix unsigned} {{/tb/final_regfile[2]} -radix unsigned} {{/tb/final_regfile[1]} -radix unsigned} {{/tb/final_regfile[0]} -radix unsigned}} -subitemconfig {{/tb/final_regfile[63]} {-height 15 -radix unsigned} {/tb/final_regfile[62]} {-height 15 -radix unsigned} {/tb/final_regfile[61]} {-height 15 -radix unsigned} {/tb/final_regfile[60]} {-height 15 -radix unsigned} {/tb/final_regfile[59]} {-height 15 -radix unsigned} {/tb/final_regfile[58]} {-height 15 -radix unsigned} {/tb/final_regfile[57]} {-height 15 -radix unsigned} {/tb/final_regfile[56]} {-height 15 -radix unsigned} {/tb/final_regfile[55]} {-height 15 -radix unsigned} {/tb/final_regfile[54]} {-height 15 -radix unsigned} {/tb/final_regfile[53]} {-height 15 -radix unsigned} {/tb/final_regfile[52]} {-height 15 -radix unsigned} {/tb/final_regfile[51]} {-height 15 -radix unsigned} {/tb/final_regfile[50]} {-height 15 -radix unsigned} {/tb/final_regfile[49]} {-height 15 -radix unsigned} {/tb/final_regfile[48]} {-height 15 -radix unsigned} {/tb/final_regfile[47]} {-height 15 -radix unsigned} {/tb/final_regfile[46]} {-height 15 -radix unsigned} {/tb/final_regfile[45]} {-height 15 -radix unsigned} {/tb/final_regfile[44]} {-height 15 -radix unsigned} {/tb/final_regfile[43]} {-height 15 -radix unsigned} {/tb/final_regfile[42]} {-height 15 -radix unsigned} {/tb/final_regfile[41]} {-height 15 -radix unsigned} {/tb/final_regfile[40]} {-height 15 -radix unsigned} {/tb/final_regfile[39]} {-height 15 -radix unsigned} {/tb/final_regfile[38]} {-height 15 -radix unsigned} {/tb/final_regfile[37]} {-height 15 -radix unsigned} {/tb/final_regfile[36]} {-height 15 -radix unsigned} {/tb/final_regfile[35]} {-height 15 -radix unsigned} {/tb/final_regfile[34]} {-height 15 -radix unsigned} {/tb/final_regfile[33]} {-height 15 -radix unsigned} {/tb/final_regfile[32]} {-height 15 -radix unsigned} {/tb/final_regfile[31]} {-height 15 -radix unsigned} {/tb/final_regfile[30]} {-height 15 -radix unsigned} {/tb/final_regfile[29]} {-height 15 -radix unsigned} {/tb/final_regfile[28]} {-height 15 -radix unsigned} {/tb/final_regfile[27]} {-height 15 -radix unsigned} {/tb/final_regfile[26]} {-height 15 -radix unsigned} {/tb/final_regfile[25]} {-height 15 -radix unsigned} {/tb/final_regfile[24]} {-height 15 -radix unsigned} {/tb/final_regfile[23]} {-height 15 -radix unsigned} {/tb/final_regfile[22]} {-height 15 -radix unsigned} {/tb/final_regfile[21]} {-height 15 -radix unsigned} {/tb/final_regfile[20]} {-height 15 -radix unsigned} {/tb/final_regfile[19]} {-height 15 -radix unsigned} {/tb/final_regfile[18]} {-height 15 -radix unsigned} {/tb/final_regfile[17]} {-height 15 -radix unsigned} {/tb/final_regfile[16]} {-height 15 -radix unsigned} {/tb/final_regfile[15]} {-height 15 -radix unsigned} {/tb/final_regfile[14]} {-height 15 -radix unsigned} {/tb/final_regfile[13]} {-height 15 -radix unsigned} {/tb/final_regfile[12]} {-height 15 -radix unsigned} {/tb/final_regfile[11]} {-height 15 -radix unsigned} {/tb/final_regfile[10]} {-height 15 -radix unsigned} {/tb/final_regfile[9]} {-height 15 -radix unsigned} {/tb/final_regfile[8]} {-height 15 -radix unsigned} {/tb/final_regfile[7]} {-height 15 -radix unsigned} {/tb/final_regfile[6]} {-height 15 -radix unsigned} {/tb/final_regfile[5]} {-height 15 -radix unsigned} {/tb/final_regfile[4]} {-height 15 -radix unsigned} {/tb/final_regfile[3]} {-height 15 -radix unsigned} {/tb/final_regfile[2]} {-height 15 -radix unsigned} {/tb/final_regfile[1]} {-height 15 -radix unsigned} {/tb/final_regfile[0]} {-height 15 -radix unsigned}} /tb/final_regfile
add wave -noupdate -divider 1
add wave -noupdate /tb/module_top/top_processor/issue/wr_en_1
add wave -noupdate /tb/module_top/top_processor/issue/wr_en_1_dummy
add wave -noupdate /tb/module_top/top_processor/issue/rd_ok_Ia
add wave -noupdate /tb/module_top/top_processor/issue/src1_ok_Ia
add wave -noupdate /tb/module_top/top_processor/issue/src2_ok_Ia
add wave -noupdate /tb/module_top/top_processor/issue/fu_ok_Ia
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/issue/pending_Ia_src1
add wave -noupdate /tb/module_top/top_processor/issue/in_rob_Ia_src1
add wave -noupdate /tb/module_top/top_processor/issue/pending_Ia_src2
add wave -noupdate /tb/module_top/top_processor/issue/in_rob_Ia_src2
add wave -noupdate /tb/module_top/top_processor/issue/regfile/RegFile
add wave -noupdate /tb/module_top/top_processor/issue/regfile/write_En
add wave -noupdate -radix unsigned /tb/module_top/top_processor/issue/regfile/write_Addr
add wave -noupdate /tb/module_top/top_processor/issue/regfile/write_Data
add wave -noupdate /tb/module_top/top_processor/issue/scoreboard
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/top_processor/issue/t_execution
add wave -noupdate -divider Execution
add wave -noupdate /tb/module_top/top_processor/execution/t_execution
add wave -noupdate /tb/module_top/top_processor/execution/fu_update
add wave -noupdate /tb/module_top/top_processor/fu_update_o
add wave -noupdate -divider {Load-Store Unit}
add wave -noupdate /tb/module_top/top_processor/execution/load_store_unit/valid
add wave -noupdate -childformat {{/tb/module_top/top_processor/execution/load_store_unit/input_data.destination -radix unsigned}} -subitemconfig {/tb/module_top/top_processor/execution/load_store_unit/input_data.destination {-height 15 -radix unsigned}} /tb/module_top/top_processor/execution/load_store_unit/input_data
add wave -noupdate -divider {Data Cache}
add wave -noupdate /tb/module_top/data_cache/load_valid
add wave -noupdate /tb/module_top/data_cache/load_address
add wave -noupdate -radix unsigned /tb/module_top/data_cache/load_dest
add wave -noupdate /tb/module_top/data_cache/load_microop
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/data_cache/store_valid
add wave -noupdate /tb/module_top/data_cache/store_address
add wave -noupdate /tb/module_top/data_cache/store_data
add wave -noupdate /tb/module_top/data_cache/store_microop
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/data_cache/serve
add wave -noupdate /tb/module_top/data_cache/hit
add wave -noupdate /tb/module_top/data_cache/served
add wave -noupdate -childformat {{/tb/module_top/data_cache/served_output.destination -radix unsigned}} -subitemconfig {/tb/module_top/data_cache/served_output.destination {-height 15 -radix unsigned}} /tb/module_top/data_cache/served_output
add wave -noupdate /tb/module_top/data_cache/block_picked
add wave -noupdate /tb/module_top/data_cache/served_data
add wave -noupdate -radix unsigned /tb/module_top/data_cache/offset_select
add wave -noupdate /tb/module_top/data_cache/data_operation/input_block
add wave -noupdate -radix unsigned -childformat {{{/tb/module_top/data_cache/data_operation/selector[8]} -radix unsigned} {{/tb/module_top/data_cache/data_operation/selector[7]} -radix unsigned} {{/tb/module_top/data_cache/data_operation/selector[6]} -radix unsigned} {{/tb/module_top/data_cache/data_operation/selector[5]} -radix unsigned} {{/tb/module_top/data_cache/data_operation/selector[4]} -radix unsigned} {{/tb/module_top/data_cache/data_operation/selector[3]} -radix unsigned} {{/tb/module_top/data_cache/data_operation/selector[2]} -radix unsigned} {{/tb/module_top/data_cache/data_operation/selector[1]} -radix unsigned} {{/tb/module_top/data_cache/data_operation/selector[0]} -radix unsigned}} -subitemconfig {{/tb/module_top/data_cache/data_operation/selector[8]} {-height 15 -radix unsigned} {/tb/module_top/data_cache/data_operation/selector[7]} {-height 15 -radix unsigned} {/tb/module_top/data_cache/data_operation/selector[6]} {-height 15 -radix unsigned} {/tb/module_top/data_cache/data_operation/selector[5]} {-height 15 -radix unsigned} {/tb/module_top/data_cache/data_operation/selector[4]} {-height 15 -radix unsigned} {/tb/module_top/data_cache/data_operation/selector[3]} {-height 15 -radix unsigned} {/tb/module_top/data_cache/data_operation/selector[2]} {-height 15 -radix unsigned} {/tb/module_top/data_cache/data_operation/selector[1]} {-height 15 -radix unsigned} {/tb/module_top/data_cache/data_operation/selector[0]} {-height 15 -radix unsigned}} /tb/module_top/data_cache/data_operation/selector
add wave -noupdate /tb/module_top/data_cache/data_operation/data_loaded_8
add wave -noupdate /tb/module_top/data_cache/data_operation/data_loaded_16
add wave -noupdate /tb/module_top/data_cache/data_operation/data_loaded_32
add wave -noupdate /tb/module_top/data_cache/wt_ready
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/data_cache/wait_buffer/saved_valid
add wave -noupdate /tb/module_top/data_cache/wait_buffer/saved_is_store
add wave -noupdate /tb/module_top/data_cache/wait_buffer/saved_address
add wave -noupdate /tb/module_top/data_cache/wait_buffer/saved_data
add wave -noupdate /tb/module_top/data_cache/wait_buffer/saved_info
add wave -noupdate -divider <NULL>
add wave -noupdate /tb/module_top/data_cache/request_l2_valid
add wave -noupdate /tb/module_top/data_cache/request_l2_addr
add wave -noupdate /tb/module_top/data_cache/update_l2_valid
add wave -noupdate /tb/module_top/data_cache/update_l2_addr
add wave -noupdate /tb/module_top/data_cache/update_l2_data
add wave -noupdate -divider {Branch Resolver}
add wave -noupdate -childformat {{/tb/module_top/top_processor/execution/branch_resolver/input_data.microoperation -radix binary}} -subitemconfig {/tb/module_top/top_processor/execution/branch_resolver/input_data.microoperation {-height 15 -radix binary}} /tb/module_top/top_processor/execution/branch_resolver/input_data
add wave -noupdate /tb/module_top/top_processor/execution/branch_resolver/pr_update
add wave -noupdate /tb/module_top/top_processor/execution/csr_registers/csr_registers
add wave -noupdate /tb/module_top/top_processor/execution/branch_resolver/csr_address
add wave -noupdate /tb/module_top/top_processor/execution/branch_resolver/csr_data
add wave -noupdate /tb/module_top/top_processor/execution/branch_resolver/csr_wr_en
add wave -noupdate /tb/module_top/top_processor/execution/branch_resolver/csr_wr_data
add wave -noupdate -divider ROB
add wave -noupdate /tb/module_top/top_processor/rob/cache_blocked
add wave -noupdate /tb/module_top/top_processor/rob/will_commit
add wave -noupdate /tb/module_top/top_processor/rob/rob
add wave -noupdate /tb/module_top/top_processor/rob/update
add wave -noupdate /tb/module_top/top_processor/rob/head
add wave -noupdate /tb/module_top/top_processor/rob/tail
add wave -noupdate /tb/module_top/top_processor/rob/counter
add wave -noupdate /tb/module_top/top_processor/rob/counter_actual
add wave -noupdate -divider <NULL>
add wave -noupdate -divider {Main Memory}
add wave -noupdate /tb/module_top/main_memory/ram
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {500 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 159
configure wave -valuecolwidth 176
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {726025 ns} {726525 ns}
