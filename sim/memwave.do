onerror {resume}
quietly WaveActivateNextPane {} 0

radix -binary

add wave -noupdate -label clock /memory_tb/clk
add wave -noupdate -label reset /memory_tb/rst_n

add wave -noupdate -divider "DATA CACHE"

add wave -noupdate -group "tags" -label "way0" -radix hexadecimal {/memory_tb/data_cache/genblk1[0]/SRAM_TAG/Memory_Array}
add wave -noupdate -group "tags" -label "way1" -radix hexadecimal {/memory_tb/data_cache/genblk1[1]/SRAM_TAG/Memory_Array}
add wave -noupdate -group "tags" -label "way2" -radix hexadecimal {/memory_tb/data_cache/genblk1[2]/SRAM_TAG/Memory_Array}
add wave -noupdate -group "tags" -label "way3" -radix hexadecimal {/memory_tb/data_cache/genblk1[3]/SRAM_TAG/Memory_Array}

add wave -noupdate -group "data" -label "way0" -radix hexadecimal {/memory_tb/data_cache/genblk1[0]/SRAM_DATA/Memory_Array}
add wave -noupdate -group "data" -label "way1" -radix hexadecimal {/memory_tb/data_cache/genblk1[1]/SRAM_DATA/Memory_Array}
add wave -noupdate -group "data" -label "way2" -radix hexadecimal {/memory_tb/data_cache/genblk1[2]/SRAM_DATA/Memory_Array}
add wave -noupdate -group "data" -label "way3" -radix hexadecimal {/memory_tb/data_cache/genblk1[3]/SRAM_DATA/Memory_Array}


add wave -noupdate -group "load" -label "valid" /memory_tb/data_cache/load_valid
add wave -noupdate -group "load" -label "address" -radix hexadecimal /memory_tb/data_cache/load_address
add wave -noupdate -group "load" -label "dest" /memory_tb/data_cache/load_dest
add wave -noupdate -group "load" -label "microop" /memory_tb/data_cache/load_microop
add wave -noupdate -group "load" -label "ticket" /memory_tb/data_cache/load_ticket

add wave -noupdate -group "store" -label "valid" /memory_tb/data_cache/store_valid
add wave -noupdate -group "store" -label "address" -radix hexadecimal /memory_tb/data_cache/store_address
add wave -noupdate -group "store" -label "data" /memory_tb/data_cache/store_data
add wave -noupdate -group "store" -label "microop" /memory_tb/data_cache/store_microop

add wave -noupdate -group "L2 write" -label "valid" /memory_tb/data_cache/write_l2_valid
add wave -noupdate -group "L2 write" -label "addr" -radix hexadecimal /memory_tb/data_cache/write_l2_addr
add wave -noupdate -group "L2 write" -label "data" /memory_tb/data_cache/write_l2_data

add wave -noupdate -group "L2 request" -label "valid" /memory_tb/data_cache/request_l2_valid
add wave -noupdate -group "L2 request" -label "addr" -radix hexadecimal /memory_tb/data_cache/request_l2_addr

add wave -noupdate -group "L2 update" -label "valid" /memory_tb/data_cache/update_l2_valid
add wave -noupdate -group "L2 update" -label "addr" -radix hexadecimal /memory_tb/data_cache/update_l2_addr
add wave -noupdate -group "L2 update" -label "data" /memory_tb/data_cache/update_l2_data

add wave -noupdate -group "cache outputs" -label "load blocked" /memory_tb/data_cache/cache_load_blocked
add wave -noupdate -group "cache outputs" -label "store blocked" /memory_tb/data_cache/cache_store_blocked
add wave -noupdate -group "cache outputs" -label "cache will block" /memory_tb/data_cache/cache_will_block
add wave -noupdate -group "cache outputs" -label "output" /memory_tb/data_cache/served_output

add wave -noupdate -label "output used" /memory_tb/data_cache/output_used
add wave -noupdate -label "serve" /memory_tb/data_cache/serve
add wave -noupdate -label "served" /memory_tb/data_cache/served
add wave -noupdate -label "must wait" /memory_tb/data_cache/must_wait


virtual signal -env /memory_tb/data_cache/load_buffer/ -install /memory_tb/data_cache/load_buffer/ {(concat_noflatten) &{saved_data[3], saved_address[3], saved_ticket[3], saved_info[3]}} ld_buffer3
virtual signal -env /memory_tb/data_cache/load_buffer/ -install /memory_tb/data_cache/load_buffer/ {(concat_noflatten) &{saved_data[2], saved_address[2], saved_ticket[2], saved_info[3]}} ld_buffer2
virtual signal -env /memory_tb/data_cache/load_buffer/ -install /memory_tb/data_cache/load_buffer/ {(concat_noflatten) &{saved_data[1], saved_address[1], saved_ticket[1], saved_info[3]}} ld_buffer1
virtual signal -env /memory_tb/data_cache/load_buffer/ -install /memory_tb/data_cache/load_buffer/ {(concat_noflatten) &{saved_data[0], saved_address[0], saved_ticket[0], saved_info[3]}} ld_buffer0
virtual signal -env /memory_tb/data_cache/load_buffer/ -install /memory_tb/data_cache/load_buffer/ {(concat_range 3:0) &{ld_buffer3, ld_buffer2, ld_buffer1, ld_buffer0}} ld_buffer
add wave -noupdate -radix hexadecimal -label "load buffer" /memory_tb/data_cache/load_buffer/ld_buffer

virtual signal -env /memory_tb/data_cache/store_buffer/ -install /memory_tb/data_cache/store_buffer/ {(concat_noflatten) &{saved_data[3], saved_address[3], saved_ticket[3], saved_info[3]}} st_buffer3
virtual signal -env /memory_tb/data_cache/store_buffer/ -install /memory_tb/data_cache/store_buffer/ {(concat_noflatten) &{saved_data[2], saved_address[2], saved_ticket[2], saved_info[3]}} st_buffer2
virtual signal -env /memory_tb/data_cache/store_buffer/ -install /memory_tb/data_cache/store_buffer/ {(concat_noflatten) &{saved_data[1], saved_address[1], saved_ticket[1], saved_info[3]}} st_buffer1
virtual signal -env /memory_tb/data_cache/store_buffer/ -install /memory_tb/data_cache/store_buffer/ {(concat_noflatten) &{saved_data[0], saved_address[0], saved_ticket[0], saved_info[3]}} st_buffer0
virtual signal -env /memory_tb/data_cache/store_buffer/ -install /memory_tb/data_cache/store_buffer/ {(concat_range 3:0) &{st_buffer3, st_buffer2, st_buffer1, st_buffer0}} st_buffer
add wave -noupdate -radix hexadecimal -label "store buffer" /memory_tb/data_cache/store_buffer/st_buffer

virtual signal -env /memory_tb/data_cache/wait_buffer/ -install /memory_tb/data_cache/wait_buffer/ {(concat_noflatten) &{saved_data[3], saved_address[3], saved_info[3]}} wt_buffer3
virtual signal -env /memory_tb/data_cache/wait_buffer/ -install /memory_tb/data_cache/wait_buffer/ {(concat_noflatten) &{saved_data[2], saved_address[2], saved_info[3]}} wt_buffer2
virtual signal -env /memory_tb/data_cache/wait_buffer/ -install /memory_tb/data_cache/wait_buffer/ {(concat_noflatten) &{saved_data[1], saved_address[1], saved_info[3]}} wt_buffer1
virtual signal -env /memory_tb/data_cache/wait_buffer/ -install /memory_tb/data_cache/wait_buffer/ {(concat_noflatten) &{saved_data[0], saved_address[0], saved_info[3]}} wt_buffer0
virtual signal -env /memory_tb/data_cache/wait_buffer/ -install /memory_tb/data_cache/wait_buffer/ {(concat_range 3:0) &{wt_buffer3, wt_buffer2, wt_buffer1, wt_buffer0}} wt_buffer
add wave -noupdate -radix hexadecimal -label "wait buffer" /memory_tb/data_cache/wait_buffer/wt_buffer
add wave -noupdate -radix hexadecimal -label "wait buffer" /memory_tb/data_cache/hit


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