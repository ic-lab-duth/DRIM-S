onerror {resume}
quietly WaveActivateNextPane {} 0

radix -binary

add wave -noupdate -label clock /tb/clk
add wave -noupdate -label reset /tb/rst_n


add wave -noupdate -radix unsigned -group statistics -label "cycle counter" /tb/module_top/top_processor/execution/csr_registers/cycle_counter
add wave -noupdate -radix unsigned -group statistics -label "instruction counter" /tb/module_top/top_processor/execution/csr_registers/instr_counter
add wave -noupdate -radix unsigned -group statistics -label "total issues" /tb/module_top/top_processor/issue/total_issues
add wave -noupdate -radix unsigned -group statistics -label "dual issues" /tb/module_top/top_processor/issue/dual_issues
add wave -noupdate -radix unsigned -group statistics -label "hazards" /tb/module_top/top_processor/issue/hazards
add wave -noupdate -radix unsigned -group statistics -label "stalls" /tb/module_top/top_processor/issue/stalls
add wave -noupdate -radix unsigned -group statistics -label ""reclaim stalls /tb/module_top/top_processor/rr/reclaim_stalls
add wave -noupdate -radix unsigned -group statistics -label "redirect prediction" /tb/module_top/top_processor/ifetch/redir_prediction
add wave -noupdate -radix unsigned -group statistics -label "redirect return" /tb/module_top/top_processor/ifetch/redir_return
add wave -noupdate -radix unsigned -group statistics -label "flushes" /tb/module_top/top_processor/ifetch/flushes
add wave -noupdate -radix unsigned -group statistics -label "branch stalls" /tb/module_top/top_processor/idecode/branch_stalls
add wave -noupdate -radix unsigned -group statistics -label "TOB stalls" /tb/module_top/top_processor/rr/stalls_rob
add wave -noupdate -radix unsigned -group statistics -label "bypass counter a" /tb/module_top/top_processor/idecode/decoder/decoder_full_a/bypass_cntr
add wave -noupdate -radix unsigned -group statistics -label "bypass counter b" /tb/module_top/top_processor/idecode/decoder/decoder_full_b/bypass_cntr


 add wave -noupdate -radix decimal -group parameters -label "icache entries" /tb/module_top/IC_ENTRIES
 add wave -noupdate -radix decimal -group parameters -label "icache data width" /tb/module_top/IC_DW
 add wave -noupdate -radix decimal -group parameters -label "dcache entries" /tb/module_top/DC_ENTRIES
 add wave -noupdate -radix decimal -group parameters -label "dcache data width" /tb/module_top/DC_DW
 add wave -noupdate -radix decimal -group parameters -label "L2 cache entries" /tb/module_top/L2_ENTRIES
 add wave -noupdate -radix decimal -group parameters -label "L2 cache data width" /tb/module_top/L2_DW
 add wave -noupdate -radix decimal -group parameters -label "realistic L2" /tb/module_top/REALISTIC
 add wave -noupdate -radix decimal -group parameters -label "delay in cycles" /tb/module_top/DELAY_CYCLES
 add wave -noupdate -radix decimal -group parameters -label "RAS depth" /tb/module_top/RAS_DEPTH
 add wave -noupdate -radix decimal -group parameters -label "global history bits" /tb/module_top/GSH_HISTORY_BITS
 add wave -noupdate -radix decimal -group parameters -label "GSH size" /tb/module_top/GSH_SIZE
 add wave -noupdate -radix decimal -group parameters -label "BTB size" /tb/module_top/BTB_SIZE
 add wave -noupdate -radix decimal -group parameters -label "dual issue enabled" /tb/module_top/DUAL_ISSUE
 add wave -noupdate -radix decimal -group parameters -label "ROB entries" /tb/module_top/ROB_ENTRIES
 add wave -noupdate -radix decimal -group parameters -label "ROB ticket width" /tb/module_top/ROB_TICKET_W
 add wave -noupdate -radix decimal -group parameters -label "instruction width" /tb/module_top/ISTR_DW
 add wave -noupdate -radix decimal -group parameters -label "address bits" /tb/module_top/ADDR_BITS
 add wave -noupdate -radix decimal -group parameters -label "data width" /tb/module_top/DATA_WIDTH
 add wave -noupdate -radix decimal -group parameters -label "fetch width" /tb/module_top/FETCH_WIDTH
 add wave -noupdate -radix decimal -group parameters -label "register address width" /tb/module_top/R_WIDTH
 add wave -noupdate -radix decimal -group parameters -label "micro operation width" /tb/module_top/MICROOP_W
 add wave -noupdate -radix decimal -group parameters -label "unchangeable st" /tb/module_top/UNCACHEABLE_ST
 add wave -noupdate -radix decimal -group parameters -label "csr depth" /tb/module_top/CSR_DEPTH
 add wave -noupdate -radix decimal -group parameters -label "vector enabled" /tb/module_top/VECTOR_ENABLED
 add wave -noupdate -radix decimal -group parameters -label "vector elements" /tb/module_top/VECTOR_ELEM
 add wave -noupdate -radix decimal -group parameters -label "vector active elements" /tb/module_top/VECTOR_ACTIVE_EL

add wave -noupdate -divider "INSTRUCTION MEMORY"

add wave -noupdate -label "program counter" -radix hexadecimal /tb/module_top/current_pc
add wave -noupdate -label "instructions" -radix hexadecimal /tb/module_top/fetched_data
add wave -noupdate -label "hit" /tb/module_top/hit_icache
add wave -noupdate -label "miss" /tb/module_top/miss_icache
add wave -noupdate -label "partial access"  /tb/module_top/partial_access
add wave -noupdate -label "partial type" /tb/module_top/partial_type

add wave -noupdate -group "icache tags" -label "way0" -radix hexadecimal {/tb/module_top/icache/gen_sram[0]/SRAM_TAG/Memory_Array}
add wave -noupdate -group "icache tags" -label "way1" -radix hexadecimal {/tb/module_top/icache/gen_sram[1]/SRAM_TAG/Memory_Array}
add wave -noupdate -group "icache tags" -label "way2" -radix hexadecimal {/tb/module_top/icache/gen_sram[2]/SRAM_TAG/Memory_Array}
add wave -noupdate -group "icache tags" -label "way3" -radix hexadecimal {/tb/module_top/icache/gen_sram[3]/SRAM_TAG/Memory_Array}

add wave -noupdate -group "icache data" -label "way0" -radix hexadecimal {/tb/module_top/icache/gen_sram[0]/SRAM_DATA/Memory_Array}
add wave -noupdate -group "icache data" -label "way1" -radix hexadecimal {/tb/module_top/icache/gen_sram[1]/SRAM_DATA/Memory_Array}
add wave -noupdate -group "icache data" -label "way2" -radix hexadecimal {/tb/module_top/icache/gen_sram[2]/SRAM_DATA/Memory_Array}
add wave -noupdate -group "icache data" -label "way3" -radix hexadecimal {/tb/module_top/icache/gen_sram[3]/SRAM_DATA/Memory_Array}

add wave -noupdate -divider FETCH

add wave -noupdate -group "fetch flow control" -label "ready in"  /tb/module_top/top_processor/if_ready_in
add wave -noupdate -group "fetch flow control" -label "valid out"  /tb/module_top/top_processor/if_valid_o

add wave -noupdate -label "flush"  /tb/module_top/top_processor/flush_valid
add wave -noupdate -label "global history"  /tb/module_top/top_processor/ifetch/predictor/gshare/gl_history
add wave -noupdate -label "branch taken counters"  /tb/module_top/top_processor/ifetch/predictor/gshare/SRAM/Memory_Array
add wave -noupdate -label "branch target buffer" -radix hexadecimal  /tb/module_top/top_processor/ifetch/predictor/btb/SRAM/Memory_Array
add wave -noupdate -label "return address stack" -radix hexadecimal  /tb/module_top/top_processor/ifetch/predictor/ras/buffer

add wave -noupdate -label "half access" /tb/module_top/top_processor/ifetch/half_access

add wave -noupdate -group "fetched instruction A" -label pc -radix hexadecimal /tb/module_top/top_processor/packet_a.pc
add wave -noupdate -group "fetched instruction A" -label data -radix hexadecimal -color blue /tb/module_top/top_processor/packet_a.data
add wave -noupdate -group "fetched instruction A" -label "taken branch" -color yellow /tb/module_top/top_processor/packet_a.taken_branch
add wave -noupdate -group "fetched instruction B" -label pc -radix hexadecimal /tb/module_top/top_processor/packet_b.pc
add wave -noupdate -group "fetched instruction B" -label data -radix hexadecimal -color blue /tb/module_top/top_processor/packet_b.data
add wave -noupdate -group "fetched instruction B" -label "taken branch" -color yellow /tb/module_top/top_processor/packet_b.taken_branch
add wave -noupdate -label "valid" /tb/module_top/top_processor/id_valid_i

add wave -noupdate -divider DECODE

add wave -noupdate -group "decode flow control" -label "valid in" /tb/module_top/top_processor/id_valid_i
add wave -noupdate -group "decode flow control" -label "ready out" /tb/module_top/top_processor/id_ready_o
add wave -noupdate -group "decode flow control" -label "ready in" /tb/module_top/top_processor/id_rr_ready
add wave -noupdate -group "decode flow control" -label "valid out A" /tb/module_top/top_processor/id_valid_1
add wave -noupdate -group "decode flow control" -label "valid out B" /tb/module_top/top_processor/id_valid_2

add wave -noupdate -group "decoded instruction A" -label pc -radix hexadecimal /tb/module_top/top_processor/id_decoded_1_o.pc
add wave -noupdate -group "decoded instruction A" -label rs1 -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_1_o.source1
add wave -noupdate -group "decoded instruction A" -label rs2 -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_1_o.source2
add wave -noupdate -group "decoded instruction A" -label rs3 -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_1_o.source3
add wave -noupdate -group "decoded instruction A" -label rd -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_1_o.destination
add wave -noupdate -group "decoded instruction A" -label immediate -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_1_o.immediate
add wave -noupdate -group "decoded instruction A" -label "functional unit" -radix unsigned -color orange /tb/module_top/top_processor/id_decoded_1_o.functional_unit
add wave -noupdate -group "decoded instruction A" -label "micro operation" -radix unsigned -color orange /tb/module_top/top_processor/id_decoded_1_o.microoperation
add wave -noupdate -group "decoded instruction A" -label "rs1 or pc" -color yellow /tb/module_top/top_processor/id_decoded_1_o.source1_pc
add wave -noupdate -group "decoded instruction A" -label "rs2 or immediate" -color yellow /tb/module_top/top_processor/id_decoded_1_o.source2_immediate
add wave -noupdate -group "decoded instruction A" -label "rs3 valid" -color yellow /tb/module_top/top_processor/id_decoded_1_o.source3_valid
add wave -noupdate -group "decoded instruction A" -label "is branch" -color yellow /tb/module_top/top_processor/id_decoded_1_o.is_branch
add wave -noupdate -group "decoded instruction A" -label "is vector" -color yellow /tb/module_top/top_processor/id_decoded_1_o.is_vector
add wave -noupdate -group "decoded instruction A" -label "is valid" -color yellow /tb/module_top/top_processor/id_decoded_1_o.is_valid
add wave -noupdate -group "decoded instruction A" -label "rm" -radix unsigned -color black /tb/module_top/top_processor/id_decoded_1_o.rm

add wave -noupdate -group "decoded instruction B" -label pc -radix hexadecimal /tb/module_top/top_processor/id_decoded_2_o.pc
add wave -noupdate -group "decoded instruction B" -label rs1 -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_2_o.source1
add wave -noupdate -group "decoded instruction B" -label rs2 -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_2_o.source2
add wave -noupdate -group "decoded instruction B" -label rs3 -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_2_o.source3
add wave -noupdate -group "decoded instruction B" -label rd -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_2_o.destination
add wave -noupdate -group "decoded instruction B" -label immediate -radix unsigned -color blue /tb/module_top/top_processor/id_decoded_2_o.immediate
add wave -noupdate -group "decoded instruction B" -label "functional unit" -radix unsigned -color orange /tb/module_top/top_processor/id_decoded_2_o.functional_unit
add wave -noupdate -group "decoded instruction B" -label "micro operation" -radix unsigned -color orange /tb/module_top/top_processor/id_decoded_2_o.microoperation
add wave -noupdate -group "decoded instruction B" -label "rs1 or pc" -color yellow /tb/module_top/top_processor/id_decoded_2_o.source1_pc
add wave -noupdate -group "decoded instruction B" -label "rs2 or immediate" -color yellow /tb/module_top/top_processor/id_decoded_2_o.source2_immediate
add wave -noupdate -group "decoded instruction B" -label "rs3 valid" -color yellow /tb/module_top/top_processor/id_decoded_2_o.source3_valid
add wave -noupdate -group "decoded instruction B" -label "is branch" -color yellow /tb/module_top/top_processor/id_decoded_2_o.is_branch
add wave -noupdate -group "decoded instruction B" -label "is vector" -color yellow /tb/module_top/top_processor/id_decoded_2_o.is_vector
add wave -noupdate -group "decoded instruction B" -label "is valid" -color yellow /tb/module_top/top_processor/id_decoded_2_o.is_valid
add wave -noupdate -group "decoded instruction B" -label "rm" -radix unsigned -color black /tb/module_top/top_processor/id_decoded_2_o.rm

add wave -noupdate -label "flush control" -radix hexadecimal /tb/module_top/top_processor/idecode/flush_controller/fifo_dual_ported/memory

add wave -noupdate -label valid  /tb/module_top/top_processor/id_ir_valid_o

add wave -noupdate -divider RENAME

add wave -noupdate -label "physical register file" -radix unsigned /tb/module_top/top_processor/issue/regfile/RegFile
add wave -noupdate -label "free list" -radix unsigned  /tb/module_top/top_processor/rr/free_list/mem
add wave -noupdate -label "free list count" /tb/module_top/top_processor/rr/free_list/status_cnt
add wave -noupdate -label "register alias table" -radix unsigned  /tb/module_top/top_processor/rr/rat/CurrentRAT

add wave -noupdate -group "renamed instruction A" -label pc -radix hexadecimal /tb/module_top/top_processor/renamed_o_1.pc
add wave -noupdate -group "renamed instruction A" -label rs1 -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_1.source1
add wave -noupdate -group "renamed instruction A" -label rs2 -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_1.source2
add wave -noupdate -group "renamed instruction A" -label rs3 -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_1.source3
add wave -noupdate -group "renamed instruction A" -label rd -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_1.destination
add wave -noupdate -group "renamed instruction A" -label immediate -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_1.immediate
add wave -noupdate -group "renamed instruction A" -label "functional unit" -radix unsigned -color orange /tb/module_top/top_processor/renamed_o_1.functional_unit
add wave -noupdate -group "renamed instruction A" -label "micro operation" -radix unsigned -color orange /tb/module_top/top_processor/renamed_o_1.microoperation
add wave -noupdate -group "renamed instruction A" -label "ticket" -radix unsigned -color orange /tb/module_top/top_processor/renamed_o_1.ticket
add wave -noupdate -group "renamed instruction A" -label "RAT ID" -radix unsigned -color orange /tb/module_top/top_processor/renamed_o_1.rat_id
add wave -noupdate -group "renamed instruction A" -label "rs1 or pc" -color yellow /tb/module_top/top_processor/renamed_o_1.source1_pc
add wave -noupdate -group "renamed instruction A" -label "rs2 or immediate" -color yellow /tb/module_top/top_processor/renamed_o_1.source2_immediate
add wave -noupdate -group "renamed instruction A" -label "rs3 valid" -color yellow /tb/module_top/top_processor/renamed_o_1.source3_valid
add wave -noupdate -group "renamed instruction A" -label "is branch" -color yellow /tb/module_top/top_processor/renamed_o_1.is_branch
add wave -noupdate -group "renamed instruction A" -label "is vector" -color yellow /tb/module_top/top_processor/renamed_o_1.is_vector
add wave -noupdate -group "renamed instruction A" -label "is valid" -color yellow /tb/module_top/top_processor/renamed_o_1.is_valid
add wave -noupdate -group "renamed instruction A" -label "rm" -radix unsigned -color black /tb/module_top/top_processor/renamed_o_1.rm
add wave -noupdate -label "valid 1" /tb/module_top/top_processor/iq_valid_1

add wave -noupdate -group "renamed instruction B" -label pc -radix hexadecimal /tb/module_top/top_processor/renamed_o_2.pc
add wave -noupdate -group "renamed instruction B" -label rs1 -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_2.source1
add wave -noupdate -group "renamed instruction B" -label rs2 -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_2.source2
add wave -noupdate -group "renamed instruction B" -label rs3 -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_2.source3
add wave -noupdate -group "renamed instruction B" -label rd -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_2.destination
add wave -noupdate -group "renamed instruction B" -label immediate -radix unsigned -color blue /tb/module_top/top_processor/renamed_o_2.immediate
add wave -noupdate -group "renamed instruction B" -label "functional unit" -radix unsigned -color orange /tb/module_top/top_processor/renamed_o_2.functional_unit
add wave -noupdate -group "renamed instruction B" -label "micro operation" -radix unsigned -color orange /tb/module_top/top_processor/renamed_o_2.microoperation
add wave -noupdate -group "renamed instruction B" -label "ticket" -radix unsigned -color orange /tb/module_top/top_processor/renamed_o_2.ticket
add wave -noupdate -group "renamed instruction B" -label "RAT ID" -radix unsigned -color orange /tb/module_top/top_processor/renamed_o_2.rat_id
add wave -noupdate -group "renamed instruction B" -label "rs1 or pc" -color yellow /tb/module_top/top_processor/renamed_o_2.source1_pc
add wave -noupdate -group "renamed instruction B" -label "rs2 or immediate" -color yellow /tb/module_top/top_processor/renamed_o_2.source2_immediate
add wave -noupdate -group "renamed instruction B" -label "rs3 valid" -color yellow /tb/module_top/top_processor/renamed_o_2.source3_valid
add wave -noupdate -group "renamed instruction B" -label "is branch" -color yellow /tb/module_top/top_processor/renamed_o_2.is_branch
add wave -noupdate -group "renamed instruction B" -label "is vector" -color yellow /tb/module_top/top_processor/renamed_o_2.is_vector
add wave -noupdate -group "renamed instruction B" -label "is valid" -color yellow /tb/module_top/top_processor/renamed_o_2.is_valid
add wave -noupdate -group "renamed instruction B" -label "rm" -radix unsigned -color black /tb/module_top/top_processor/renamed_o_2.rm
add wave -noupdate -label "valid 2" /tb/module_top/top_processor/iq_valid_2

add wave -noupdate -divider "INSTRUCTION QUEUE"

add wave -noupdate -label requests -radix unsigned /tb/module_top/top_processor/rob/new_requests
add wave -noupdate -label "reorder buffer" -radix unsigned  /tb/module_top/top_processor/rob/rob
add wave -noupdate -label "instruction queue" /tb/module_top/top_processor/instruction_queue/memory

add wave -noupdate -divider ISSUE

add wave -noupdate -label "scoreboard" -radix unsigned  /tb/module_top/top_processor/issue/scoreboard

add wave -noupdate -group "issued instruction A" -label pc -radix hexadecimal {/tb/module_top/top_processor/t_execution_o[0].pc}
add wave -noupdate -group "issued instruction A" -label opA -radix unsigned -color blue {/tb/module_top/top_processor/t_execution_o[0].data1}
add wave -noupdate -group "issued instruction A" -label opB -radix unsigned -color blue {/tb/module_top/top_processor/t_execution_o[0].data2}
add wave -noupdate -group "issued instruction A" -label rd -radix unsigned -color blue {/tb/module_top/top_processor/t_execution_o[0].destination}
add wave -noupdate -group "issued instruction A" -label "functional unit" -radix unsigned -color orange {/tb/module_top/top_processor/t_execution_o[0].functional_unit}
add wave -noupdate -group "issued instruction A" -label "micro operation" -radix unsigned -color orange {/tb/module_top/top_processor/t_execution_o[0].microoperation}
add wave -noupdate -group "issued instruction A" -label "ticket" -radix unsigned -color orange {/tb/module_top/top_processor/t_execution_o[0].ticket}
add wave -noupdate -group "issued instruction A" -label "RAT ID" -radix unsigned -color orange {/tb/module_top/top_processor/t_execution_o[0].rat_id}
add wave -noupdate -group "issued instruction A" -label "is valid" -color yellow {/tb/module_top/top_processor/t_execution_o[0].valid}
add wave -noupdate -group "issued instruction A" -label "rm" -radix unsigned -color black {/tb/module_top/top_processor/t_execution_o[0].rm}

add wave -noupdate -group "issued instruction B" -label pc -radix hexadecimal {/tb/module_top/top_processor/t_execution_o[1].pc}
add wave -noupdate -group "issued instruction B" -label opA -radix unsigned -color blue {/tb/module_top/top_processor/t_execution_o[1].data1}
add wave -noupdate -group "issued instruction B" -label opB -radix unsigned -color blue {/tb/module_top/top_processor/t_execution_o[1].data2}
add wave -noupdate -group "issued instruction B" -label rd -radix unsigned -color blue {/tb/module_top/top_processor/t_execution_o[1].destination}
add wave -noupdate -group "issued instruction B" -label "functional unit" -radix unsigned -color orange {/tb/module_top/top_processor/t_execution_o[1].functional_unit}
add wave -noupdate -group "issued instruction B" -label "micro operation" -radix unsigned -color orange {/tb/module_top/top_processor/t_execution_o[1].microoperation}
add wave -noupdate -group "issued instruction B" -label "ticket" -radix unsigned -color orange {/tb/module_top/top_processor/t_execution_o[1].ticket}
add wave -noupdate -group "issued instruction B" -label "RAT ID" -radix unsigned -color orange {/tb/module_top/top_processor/t_execution_o[1].rat_id}
add wave -noupdate -group "issued instruction B" -label "is valid" -color yellow {/tb/module_top/top_processor/t_execution_o[1].valid}
add wave -noupdate -group "issued instruction B" -label "rm" -radix unsigned -color black {/tb/module_top/top_processor/t_execution_o[1].rm}

add wave -noupdate -group "issued instruction Vector" -label opA -radix unsigned -color blue {/tb/module_top/top_processor/t_vector.data1}
add wave -noupdate -group "issued instruction Vector" -label opB -radix unsigned -color blue {/tb/module_top/top_processor/t_vector.data2}
add wave -noupdate -group "issued instruction Vector" -label "is valid" -color yellow {/tb/module_top/top_processor/t_vector.valid}
add wave -noupdate -group "issued instruction Vector" -label "rm" -radix unsigned -color black {/tb/module_top/top_processor/t_vector.instruction}

add wave -noupdate -divider EXECUTION

add wave -noupdate -group "load store unit" -label data -radix unsigned {/tb/module_top/top_processor/fu_update_o[0].data}
add wave -noupdate -group "load store unit" -label destination -radix unsigned {/tb/module_top/top_processor/fu_update_o[0].destination}
add wave -noupdate -group "load store unit" -label ticket -radix unsigned -color orange {/tb/module_top/top_processor/fu_update_o[0].ticket}
add wave -noupdate -group "load store unit" -label valid -color yellow {/tb/module_top/top_processor/fu_update_o[0].valid}
add wave -noupdate -group "load store unit" -label busy -color yellow {/tb/module_top/top_processor/busy_fu[0]}
add wave -noupdate -group "load store unit" -label exception -color black {/tb/module_top/top_processor/fu_update_o[0].valid_exception}
add wave -noupdate -group "load store unit" -label cause -radix unsigned -color black {/tb/module_top/top_processor/fu_update_o[0].cause}

add wave -noupdate -group "floating ALU" -label data -radix unsigned {/tb/module_top/top_processor/fu_update_o[1].data}
add wave -noupdate -group "floating ALU" -label destination -radix unsigned {/tb/module_top/top_processor/fu_update_o[1].destination}
add wave -noupdate -group "floating ALU" -label ticket -radix unsigned -color orange {/tb/module_top/top_processor/fu_update_o[1].ticket}
add wave -noupdate -group "floating ALU" -label valid -color yellow {/tb/module_top/top_processor/fu_update_o[1].valid}
add wave -noupdate -group "floating ALU" -label busy -color yellow {/tb/module_top/top_processor/busy_fu[1]}
add wave -noupdate -group "floating ALU" -label exception -color black {/tb/module_top/top_processor/fu_update_o[1].valid_exception}
add wave -noupdate -group "floating ALU" -label cause -radix unsigned -color black {/tb/module_top/top_processor/fu_update_o[1].cause}

add wave -noupdate -group "int ALU" -label data -radix unsigned {/tb/module_top/top_processor/fu_update_o[2].data}
add wave -noupdate -group "int ALU" -label destination -radix unsigned {/tb/module_top/top_processor/fu_update_o[2].destination}
add wave -noupdate -group "int ALU" -label ticket -radix unsigned -color orange {/tb/module_top/top_processor/fu_update_o[2].ticket}
add wave -noupdate -group "int ALU" -label valid -color yellow {/tb/module_top/top_processor/fu_update_o[2].valid}
add wave -noupdate -group "int ALU" -label busy -color yellow {/tb/module_top/top_processor/busy_fu[2]}
add wave -noupdate -group "int ALU" -label exception -color black {/tb/module_top/top_processor/fu_update_o[2].valid_exception}
add wave -noupdate -group "int ALU" -label cause -radix unsigned -color black {/tb/module_top/top_processor/fu_update_o[2].cause}

add wave -noupdate -group "branch resolver" -label data -radix unsigned {/tb/module_top/top_processor/fu_update_o[3].data}
add wave -noupdate -group "branch resolver" -label destination -radix unsigned {/tb/module_top/top_processor/fu_update_o[3].destination}
add wave -noupdate -group "branch resolver" -label ticket -radix unsigned -color orange {/tb/module_top/top_processor/fu_update_o[3].ticket}
add wave -noupdate -group "branch resolver" -label valid -color yellow {/tb/module_top/top_processor/fu_update_o[3].valid}
add wave -noupdate -group "branch resolver" -label busy -color yellow {/tb/module_top/top_processor/busy_fu[3]}
add wave -noupdate -group "branch resolver" -label exception -color black {/tb/module_top/top_processor/fu_update_o[3].valid_exception}
add wave -noupdate -group "branch resolver" -label cause -radix unsigned -color black {/tb/module_top/top_processor/fu_update_o[3].cause}

add wave -noupdate -group "predictor update" -label "valid jump" -color yellow /tb/module_top/top_processor/pr_update_o.valid_jump
add wave -noupdate -group "predictor update" -label "jump taken" -color yellow /tb/module_top/top_processor/pr_update_o.jump_taken
add wave -noupdate -group "predictor update" -label "is comp" -color yellow /tb/module_top/top_processor/pr_update_o.is_comp
add wave -noupdate -group "predictor update" -label "RAT ID" -radix unsigned -color orange /tb/module_top/top_processor/pr_update_o.rat_id
add wave -noupdate -group "predictor update" -label "ticket" -radix unsigned -color orange /tb/module_top/top_processor/pr_update_o.ticket
add wave -noupdate -group "predictor update" -label "original pc" -radix hexadecimal /tb/module_top/top_processor/pr_update_o.orig_pc
add wave -noupdate -group "predictor update" -label "jump address" -radix hexadecimal /tb/module_top/top_processor/pr_update_o.jump_address

add wave -noupdate -divider WRITEBACK

add wave -noupdate -label "reorder buffer data" -radix unsigned  /tb/module_top/top_processor/rob/sram/Memory_Array

add wave -noupdate -divider REGISTERS

add wave -noupdate -group "reserved registers" -label r0--zero -radix unsigned   {/tb/final_regfile[0]}
add wave -noupdate -group "reserved registers" -label r1--ra -radix unsigned   {/tb/final_regfile[1]}
add wave -noupdate -group "reserved registers" -label r2--sp -radix unsigned   {/tb/final_regfile[2]}
add wave -noupdate -group "reserved registers" -label r3--gp -radix unsigned   {/tb/final_regfile[3]}
add wave -noupdate -group "reserved registers" -label r4--tp -radix unsigned   {/tb/final_regfile[4]}

add wave -noupdate -group "temporary registers" -label r5--t0 -radix unsigned  {/tb/final_regfile[5]}
add wave -noupdate -group "temporary registers" -label r6--t1 -radix unsigned  {/tb/final_regfile[6]}
add wave -noupdate -group "temporary registers" -label r7--t2 -radix unsigned  {/tb/final_regfile[7]}
add wave -noupdate -group "temporary registers" -label r28--t3 -radix unsigned  {/tb/final_regfile[28]}
add wave -noupdate -group "temporary registers" -label r29--t4 -radix unsigned  {/tb/final_regfile[29]}
add wave -noupdate -group "temporary registers" -label r30--t5 -radix unsigned  {/tb/final_regfile[30]}
add wave -noupdate -group "temporary registers" -label r31--t6 -radix unsigned  {/tb/final_regfile[31]}

add wave -noupdate -group "saved registers" -label r8--s0 -radix unsigned  {/tb/final_regfile[8]}
add wave -noupdate -group "saved registers" -label r9--s1 -radix unsigned  {/tb/final_regfile[9]}
add wave -noupdate -group "saved registers" -label r18--s2 -radix unsigned  {/tb/final_regfile[18]}
add wave -noupdate -group "saved registers" -label r19--s3 -radix unsigned  {/tb/final_regfile[19]}
add wave -noupdate -group "saved registers" -label r20--s4 -radix unsigned  {/tb/final_regfile[20]}
add wave -noupdate -group "saved registers" -label r21--s5 -radix unsigned  {/tb/final_regfile[21]}
add wave -noupdate -group "saved registers" -label r22--s6 -radix unsigned  {/tb/final_regfile[22]}
add wave -noupdate -group "saved registers" -label r23--s7 -radix unsigned  {/tb/final_regfile[23]}
add wave -noupdate -group "saved registers" -label r24--s8 -radix unsigned  {/tb/final_regfile[24]}
add wave -noupdate -group "saved registers" -label r25--s9 -radix unsigned  {/tb/final_regfile[25]}
add wave -noupdate -group "saved registers" -label r26--s10 -radix unsigned  {/tb/final_regfile[26]}
add wave -noupdate -group "saved registers" -label r27--s11 -radix unsigned  {/tb/final_regfile[27]}

add wave -noupdate -group "arguments registers" -label r10--a0 -radix unsigned  {/tb/final_regfile[10]}
add wave -noupdate -group "arguments registers" -label r11--a1 -radix unsigned  {/tb/final_regfile[11]}
add wave -noupdate -group "arguments registers" -label r12--a2 -radix unsigned  {/tb/final_regfile[12]}
add wave -noupdate -group "arguments registers" -label r13--a3 -radix unsigned  {/tb/final_regfile[13]}
add wave -noupdate -group "arguments registers" -label r14--a4 -radix unsigned  {/tb/final_regfile[14]}
add wave -noupdate -group "arguments registers" -label r15--a5 -radix unsigned  {/tb/final_regfile[15]}
add wave -noupdate -group "arguments registers" -label r16--a6 -radix unsigned  {/tb/final_regfile[16]}
add wave -noupdate -group "arguments registers" -label r17--a7 -radix unsigned  {/tb/final_regfile[17]}

add wave -noupdate -divider "DATA CACHE"

add wave -noupdate -group "tags" -label "way0" -radix hexadecimal {/tb/module_top/data_cache/genblk1[0]/SRAM_TAG/Memory_Array}
add wave -noupdate -group "tags" -label "way1" -radix hexadecimal {/tb/module_top/data_cache/genblk1[1]/SRAM_TAG/Memory_Array}
add wave -noupdate -group "tags" -label "way2" -radix hexadecimal {/tb/module_top/data_cache/genblk1[2]/SRAM_TAG/Memory_Array}
add wave -noupdate -group "tags" -label "way3" -radix hexadecimal {/tb/module_top/data_cache/genblk1[3]/SRAM_TAG/Memory_Array}

add wave -noupdate -group "data" -label "way0" -radix hexadecimal {/tb/module_top/data_cache/genblk1[0]/SRAM_DATA/Memory_Array}
add wave -noupdate -group "data" -label "way1" -radix hexadecimal {/tb/module_top/data_cache/genblk1[1]/SRAM_DATA/Memory_Array}
add wave -noupdate -group "data" -label "way2" -radix hexadecimal {/tb/module_top/data_cache/genblk1[2]/SRAM_DATA/Memory_Array}
add wave -noupdate -group "data" -label "way3" -radix hexadecimal {/tb/module_top/data_cache/genblk1[3]/SRAM_DATA/Memory_Array}


add wave -noupdate -group "load" -label "valid" /tb/module_top/data_cache/load_valid
add wave -noupdate -group "load" -label "address" -radix hexadecimal /tb/module_top/data_cache/load_address
add wave -noupdate -group "load" -label "dest" /tb/module_top/data_cache/load_dest
add wave -noupdate -group "load" -label "microop" /tb/module_top/data_cache/load_microop
add wave -noupdate -group "load" -label "ticket" /tb/module_top/data_cache/load_ticket

add wave -noupdate -group "store" -label "valid" /tb/module_top/data_cache/store_valid
add wave -noupdate -group "store" -label "address" -radix hexadecimal /tb/module_top/data_cache/store_address
add wave -noupdate -group "store" -label "data" /tb/module_top/data_cache/store_data
add wave -noupdate -group "store" -label "microop" /tb/module_top/data_cache/store_microop

add wave -noupdate -group "L2 write" -label "valid" /tb/module_top/data_cache/write_l2_valid
add wave -noupdate -group "L2 write" -label "addr" -radix hexadecimal /tb/module_top/data_cache/write_l2_addr
add wave -noupdate -group "L2 write" -label "data" /tb/module_top/data_cache/write_l2_data

add wave -noupdate -group "L2 request" -label "valid" /tb/module_top/data_cache/request_l2_valid
add wave -noupdate -group "L2 request" -label "addr" -radix hexadecimal /tb/module_top/data_cache/request_l2_addr

add wave -noupdate -group "L2 update" -label "valid" /tb/module_top/data_cache/update_l2_valid
add wave -noupdate -group "L2 update" -label "addr" -radix hexadecimal /tb/module_top/data_cache/update_l2_addr
add wave -noupdate -group "L2 update" -label "data" /tb/module_top/data_cache/update_l2_data

add wave -noupdate -group "cache outputs" -label "load blocked" /tb/module_top/data_cache/cache_load_blocked
add wave -noupdate -group "cache outputs" -label "store blocked" /tb/module_top/data_cache/cache_store_blocked
add wave -noupdate -group "cache outputs" -label "cache will block" /tb/module_top/data_cache/cache_will_block
add wave -noupdate -group "cache outputs" -label "output" /tb/module_top/data_cache/served_output

add wave -noupdate -label "output used" /tb/module_top/data_cache/output_used
add wave -noupdate -label "serve" /tb/module_top/data_cache/serve
add wave -noupdate -label "served" /tb/module_top/data_cache/served
add wave -noupdate -label "must wait" /tb/module_top/data_cache/must_wait


virtual signal -env /tb/module_top/data_cache/load_buffer/ -install /tb/module_top/data_cache/load_buffer/ {(concat_noflatten) &{saved_data[3], saved_address[3], saved_ticket[3], saved_info[3]}} ld_buffer3
virtual signal -env /tb/module_top/data_cache/load_buffer/ -install /tb/module_top/data_cache/load_buffer/ {(concat_noflatten) &{saved_data[2], saved_address[2], saved_ticket[2], saved_info[2]}} ld_buffer2
virtual signal -env /tb/module_top/data_cache/load_buffer/ -install /tb/module_top/data_cache/load_buffer/ {(concat_noflatten) &{saved_data[1], saved_address[1], saved_ticket[1], saved_info[1]}} ld_buffer1
virtual signal -env /tb/module_top/data_cache/load_buffer/ -install /tb/module_top/data_cache/load_buffer/ {(concat_noflatten) &{saved_data[0], saved_address[0], saved_ticket[0], saved_info[0]}} ld_buffer0
virtual signal -env /tb/module_top/data_cache/load_buffer/ -install /tb/module_top/data_cache/load_buffer/ {(concat_range 3:0) &{ld_buffer3, ld_buffer2, ld_buffer1, ld_buffer0}} ld_buffer
add wave -noupdate -radix hexadecimal -label "load buffer" /tb/module_top/data_cache/load_buffer/ld_buffer

virtual signal -env /tb/module_top/data_cache/store_buffer/ -install /tb/module_top/data_cache/store_buffer/ {(concat_noflatten) &{saved_data[3], saved_address[3], saved_ticket[3], saved_info[3]}} st_buffer3
virtual signal -env /tb/module_top/data_cache/store_buffer/ -install /tb/module_top/data_cache/store_buffer/ {(concat_noflatten) &{saved_data[2], saved_address[2], saved_ticket[2], saved_info[2]}} st_buffer2
virtual signal -env /tb/module_top/data_cache/store_buffer/ -install /tb/module_top/data_cache/store_buffer/ {(concat_noflatten) &{saved_data[1], saved_address[1], saved_ticket[1], saved_info[1]}} st_buffer1
virtual signal -env /tb/module_top/data_cache/store_buffer/ -install /tb/module_top/data_cache/store_buffer/ {(concat_noflatten) &{saved_data[0], saved_address[0], saved_ticket[0], saved_info[0]}} st_buffer0
virtual signal -env /tb/module_top/data_cache/store_buffer/ -install /tb/module_top/data_cache/store_buffer/ {(concat_range 3:0) &{st_buffer3, st_buffer2, st_buffer1, st_buffer0}} st_buffer
add wave -noupdate -radix hexadecimal -label "store buffer" /tb/module_top/data_cache/store_buffer/st_buffer

virtual signal -env /tb/module_top/data_cache/wait_buffer/ -install /tb/module_top/data_cache/wait_buffer/ {(concat_noflatten) &{saved_data[3], saved_address[3], saved_info[3]}} wt_buffer3
virtual signal -env /tb/module_top/data_cache/wait_buffer/ -install /tb/module_top/data_cache/wait_buffer/ {(concat_noflatten) &{saved_data[2], saved_address[2], saved_info[2]}} wt_buffer2
virtual signal -env /tb/module_top/data_cache/wait_buffer/ -install /tb/module_top/data_cache/wait_buffer/ {(concat_noflatten) &{saved_data[1], saved_address[1], saved_info[1]}} wt_buffer1
virtual signal -env /tb/module_top/data_cache/wait_buffer/ -install /tb/module_top/data_cache/wait_buffer/ {(concat_noflatten) &{saved_data[0], saved_address[0], saved_info[0]}} wt_buffer0
virtual signal -env /tb/module_top/data_cache/wait_buffer/ -install /tb/module_top/data_cache/wait_buffer/ {(concat_range 3:0) &{wt_buffer3, wt_buffer2, wt_buffer1, wt_buffer0}} wt_buffer
add wave -noupdate -radix hexadecimal -label "wait buffer" /tb/module_top/data_cache/wait_buffer/wt_buffer

add wave -noupdate -divider "MEMORY"

add wave -noupdate -label "memory" -radix hexadecimal /tb/module_top/main_memory/ram

add wave -noupdate -divider "VECTOR"

add wave -noupdate -label "valid" -radix hexadecimal /tb/module_top/top_processor/genblk1/vector_top/valid_fifo
add wave -noupdate -label "instruction" -radix hexadecimal /tb/module_top/top_processor/genblk1/vector_top/dispatch_mod/dec_mul/instruction_temp
add wave -noupdate -label "rs1" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/dispatch_mod/dec_mul/scalar_op_1_temp
add wave -noupdate -label "rs2" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/dispatch_mod/dec_mul/scalar_op_2_temp

add wave -noupdate -label "scoreboard" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/dispatch_mod/scoreboard_unit/register_status



add wave -noupdate -group "Dispatched instruction" -label "sew out" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/sew_out
add wave -noupdate -group "Dispatched instruction" -label "memory sew" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/memory_sew

add wave -noupdate -group "Dispatched instruction" -label "stride" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/stride
add wave -noupdate -group "Dispatched instruction" -label "address" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/addr
add wave -noupdate -group "Dispatched instruction" -label "mode" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/mode_memory
add wave -noupdate -group "Dispatched instruction" -label "memory enable" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/memory_enable


add wave -noupdate -group "Dispatched instruction" -label "vs1" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/operand_1
add wave -noupdate -group "Dispatched instruction" -label "vs2" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/operand_2
add wave -noupdate -group "Dispatched instruction" -label "vd" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/destination
add wave -noupdate -group "Dispatched instruction" -label "mask" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/mask_bits
add wave -noupdate -group "Dispatched instruction" -label "immediate" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/operand_1_immediate_out
add wave -noupdate -group "Dispatched instruction" -label "scalar" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/operand_1_scalar_out

add wave -noupdate -group "Dispatched instruction" -label "alu op" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/alu_op_out
add wave -noupdate -group "Dispatched instruction" -label "masked" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/masked_operation
add wave -noupdate -group "Dispatched instruction" -label "load" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/load_operation
add wave -noupdate -group "Dispatched instruction" -label "store" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/store_operation
add wave -noupdate -group "Dispatched instruction" -label "indexed" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/indexed_memory_operation
add wave -noupdate -group "Dispatched instruction" -label "write back" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/write_back_enable
add wave -noupdate -group "Dispatched instruction" -label "multiplication" -radix unsigned /tb/module_top/top_processor/genblk1/vector_top/multiplication_flag


add wave -noupdate -label "lane 0 registers" -radix hexadecimal {/tb/module_top/top_processor/genblk1/vector_top/vector_lanes[0]/vec_lane/vis_mod/vrf/vector_register}
add wave -noupdate -label "lane 1 registers" -radix hexadecimal {/tb/module_top/top_processor/genblk1/vector_top/vector_lanes[1]/vec_lane/vis_mod/vrf/vector_register}
add wave -noupdate -label "lane 2 registers" -radix hexadecimal {/tb/module_top/top_processor/genblk1/vector_top/vector_lanes[2]/vec_lane/vis_mod/vrf/vector_register}
add wave -noupdate -label "lane 3 registers" -radix hexadecimal {/tb/module_top/top_processor/genblk1/vector_top/vector_lanes[3]/vec_lane/vis_mod/vrf/vector_register}

add wave -noupdate -label "memory" -radix hexadecimal /tb/module_top/top_processor/genblk1/vector_top/mem_mod/comp/mem/memory


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