quit -sim
file delete -force work

vlib work

#compile the dut code
#set cmd "vlog -F ../dut/files.f +incdir+.../dut/ -lint"
#set cmd "vlog -F files.f +incdir+../rtl/"
#eval $cmd

vlog -f files_rtl.f -f files_sim.f +incdir+../rtl/ +incdir+../sim/ +incdir+../sva/ +define+INCLUDE_SVAS -suppress 2583 -suppress 2597

vsim work.tb -novopt -onfinish "stop" -suppress 8315
log -r /*
do mywave.do
onbreak {wave zoom full}
run -all
wave zoom full
