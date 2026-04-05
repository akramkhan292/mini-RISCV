class riscv_driver extends uvm_driver;
  
  `uvm_component_utils(riscv_driver)
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"[BUILD] driver",UVM_LOW)
  endfunction
endclass