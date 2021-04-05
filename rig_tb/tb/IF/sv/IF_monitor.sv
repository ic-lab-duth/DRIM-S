`ifndef IF_MONITOR_SV
`define IF_MONITOR_SV


class IF_monitor extends uvm_monitor;

	`uvm_component_utils(IF_monitor)

	virtual IF_if vif;

	uvm_analysis_port #(if_trans) analysis_port;
	if_trans trans;


	task run_phase(uvm_phase phase);
		forever begin 
			if(vif.Hit_cache && vif.ready_in) begin
				trans = new();
	  			trans.data = vif.fetched_data;
	  			analysis_port.write(trans);
	  		end
			@(posedge vif.clk);
		end
	endtask
	  
	function new(string name, uvm_component parent);
		super.new(name, parent);
		analysis_port = new("analysis_port", this);
	endfunction

endclass

`endif 