class riscv_env extends uvm_env;
  
  `uvm_component_utils(riscv_env)
  
  riscv_agent agent_inst;
  riscv_scoreboard sb_inst;
  riscv_coverage cov_inst;
  
  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"[BUILD PHASE] ENV",UVM_LOW)
    agent_inst = riscv_agent::type_id::create("agent_inst",this);
    sb_inst = riscv_scoreboard::type_id::create("sb_inst",this);
    cov_inst = riscv_coverage::type_id::create("cov_inst",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    agent_inst.mon_inst.mon_port.connect(sb_inst.item_export);
    agent_inst.mon_inst.mon_port.connect(cov_inst.analysis_export);
  endfunction
  
endclass
