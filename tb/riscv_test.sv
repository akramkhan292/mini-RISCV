class base_test extends uvm_test;
  
  `uvm_component_utils(base_test)
  riscv_env env_inst;
  
  function new(string name="base_test",uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"[BUILD PHASE] Test",UVM_LOW)
    env_inst = riscv_env::type_id::create("env_inst",this);
    `uvm_info(get_type_name(),"[BUILD PHASE] ENV created",UVM_LOW)
  endfunction
  
  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(),"[Test] Run Phase",UVM_LOW)
  endtask
endclass