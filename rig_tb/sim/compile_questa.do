quit -sim
file delete -force work

vlib work
vlog -sv "simulation_parameters_pkg.sv"
vlog -sv "../tb/dut_parameters_pkg.sv"
vlog -sv "../tb/tb_util_pkg.sv"
vlog -sv "../tb/dut_structs_pkg.sv"
vlog -sv "../tb/IF/sv/IF_util_pkg.sv"
vlog -sv "../tb/INSTRUCTION_GENERATOR/sv/instruction_generator/type_definitions.sv"


#compile the dut code
set cmd "vlog -f files_rtl.f +incdir+../../rtl/ +incdir+../../sva/"
eval $cmd

set tb_name top
set agent_list {\
    IF \
}
foreach  ele $agent_list {
  if {$ele != " "} {
    set cmd  "vlog -sv +incdir+../tb/include +incdir+../tb/"
    append cmd $ele "/sv ../tb/" $ele "/sv/" $ele "_pkg.sv ../tb/" $ele "/sv/" $ele "_if.sv -permissive"
    eval $cmd
  }
}

set cmd  "vlog -sv +incdir+../tb/include +incdir+../tb/"
append cmd $tb_name "/sv ../tb/" $tb_name "/sv/" $tb_name "_pkg.sv -permissive"
eval $cmd

set cmd  "vlog -sv +incdir+../tb/include +incdir+../tb/"
append cmd $tb_name "_test/sv ../tb/" $tb_name "_test/sv/" $tb_name "_test_pkg.sv -permissive"
eval $cmd

set cmd  "vlog -sv -timescale 1ns/1ps +incdir+../tb/include +incdir+../tb/"
append cmd $tb_name "_tb/sv ../tb/" $tb_name "_tb/sv/" $tb_name "_th.sv -permissive"
eval $cmd

set cmd  "vlog -sv -timescale 1ns/1ps +incdir+../tb/include +incdir+../tb/"
append cmd $tb_name "_tb/sv ../tb/" $tb_name "_tb/sv/" $tb_name "_tb.sv -permissive"
eval $cmd

vsim top_tb +UVM_TESTNAME=top_test -novopt -voptargs=+acc -solvefaildebug -uvmcontrol=all -classdebug -assertcover
#coverage save -onexit test_.ucdb
run 0
log -r /*
set NoQuitOnFinish 1
do mywave.do
run -all

#coverage report -file report.txt -byfile -detail -cvg