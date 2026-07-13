class base_test extends uvm_test;
  
  `uvm_component_utils(base_test)
  riscv_env env_inst;

  localparam int EXPECTED_COMMITS = 8;
  localparam int COMMIT_TIMEOUT_CYCLES = 100;
  
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
    int timeout_cycles;
    
    `uvm_info(get_type_name(),"[Test] Run Phase starting",UVM_LOW)
    
    // Raise objection to keep simulation running
    phase.raise_objection(this);
    
    // Create and start sequence on sequencer
    seq = riscv_sequence::type_id::create("seq",this);
    seq.start(env_inst.agent_inst.seqr_inst);

    repeat (2) @(posedge env_inst.agent_inst.drv_inst.vif.clk);
    env_inst.agent_inst.drv_inst.vif.rst <= 1'b0;

    timeout_cycles = 0;
    while (env_inst.sb_inst.commit_count < EXPECTED_COMMITS &&
           timeout_cycles < COMMIT_TIMEOUT_CYCLES) begin
      @(posedge env_inst.agent_inst.drv_inst.vif.clk);
      timeout_cycles++;
    end

    // Drain the pipeline and prove that no wrong-path or duplicate instruction
    // retires after the expected program has completed.
    repeat (8) @(posedge env_inst.agent_inst.drv_inst.vif.clk);

    if (env_inst.sb_inst.commit_count != EXPECTED_COMMITS)
      `uvm_fatal("COMMIT_TIMEOUT", $sformatf(
        "Expected %0d committed instructions, observed %0d after %0d cycles",
        EXPECTED_COMMITS, env_inst.sb_inst.commit_count, timeout_cycles))
    
    `uvm_info(get_type_name(), $sformatf(
      "[Test] Sequence finished after %0d committed instructions",
      env_inst.sb_inst.commit_count), UVM_LOW)
    
    // Lower objection to end simulation
    phase.drop_objection(this);
  endtask
endclass

class riscv_smoke_test extends base_test;
  `uvm_component_utils(riscv_smoke_test)

  function new(string name="riscv_smoke_test", uvm_component parent);
    super.new(name, parent);
  endfunction
endclass
