class riscv_agent extends uvm_agent;
  
  `uvm_component_utils(riscv_agent)
  
  riscv_monitor mon_inst;
  riscv_driver drv_inst;
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"[BUILD_PHASE] Agent",UVM_LOW)
    mon_inst = riscv_monitor::type_id::create("mon_inst",this);
    drv_inst = riscv_driver::type_id::create("drv_inst",this);
  endfunction
endclass