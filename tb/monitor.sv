class riscv_monitor extends uvm_monitor;
  
  `uvm_component_utils(riscv_monitor)
  
  function new(string name, uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"[BUILD] Monitor",UVM_LOW)
  endfunction
endclass