class riscv_agent extends uvm_agent;
  
  `uvm_component_utils(riscv_agent)
  
  riscv_monitor mon_inst;
  riscv_driver drv_inst;
  uvm_sequencer#(instr_item) seqr_inst;  // Sequencer to feed items to driver
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"[BUILD_PHASE] Agent",UVM_LOW)
    mon_inst = riscv_monitor::type_id::create("mon_inst",this);
    drv_inst = riscv_driver::type_id::create("drv_inst",this);
    seqr_inst = uvm_sequencer#(instr_item)::type_id::create("seqr_inst",this);
  endfunction

  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info(get_type_name(),"[CONNECT_PHASE] Agent",UVM_LOW)
    // Connect driver to sequencer
    drv_inst.seq_item_port.connect(seqr_inst.seq_item_export);
  endfunction
endclass