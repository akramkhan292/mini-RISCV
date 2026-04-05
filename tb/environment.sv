class riscv_env extends uvm_env;
  
  `uvm_component_utils(riscv_env)
  
  riscv_agent agent_inst;
  
  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"[BUILD PHASE] ENV",UVM_LOW)
    agent_inst = riscv_agent::type_id::create("agent_inst",this);
  endfunction
  
endclass