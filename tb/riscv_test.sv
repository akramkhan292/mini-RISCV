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
    riscv_sequence seq;
    
    `uvm_info(get_type_name(),"[Test] Run Phase starting",UVM_LOW)
    
    // Raise objection to keep simulation running
    phase.raise_objection(this);
    
    // Create and start sequence on sequencer
    seq = riscv_sequence::type_id::create("seq",this);
    seq.start(env_inst.agent_inst.seqr_inst);
    
    `uvm_info(get_type_name(),"[Test] Sequence finished",UVM_LOW)
    
    // Lower objection to end simulation
    phase.drop_objection(this);
  endtask
endclass