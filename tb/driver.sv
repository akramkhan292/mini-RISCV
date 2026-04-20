class riscv_driver extends uvm_driver#(instr_item);
  
  virtual riscv_intf vif;
  `uvm_component_utils(riscv_driver)
  bit [31:0] prog_addr_counter = 0;  // Sequential address counter
  
  function new(string name,uvm_component parent);
    super.new(name,parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"[BUILD] driver",UVM_LOW)
    // Get virtual interface from config database
    if (!uvm_config_db#(virtual riscv_intf)::get(this,"","vif",vif))
      `uvm_fatal("NO_VIF","Virtual interface not found in config_db")
  endfunction
  
  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(),"[RUN] Driver starting",UVM_LOW)
    forever begin
      // Get next instruction item from sequencer
      seq_item_port.get_next_item(req);
      
      `uvm_info(get_type_name(),$sformatf("[DRIVER] Got item: opcode=%0h, rd=%0d, addr=%0d", 
               req.opcode, req.rd, prog_addr_counter),UVM_MEDIUM)
      
      // Drive item to virtual interface
      drive_instruction(req);
      
      // Increment address for next instruction
      prog_addr_counter = prog_addr_counter + 4;  // +4 for word addressing (each instr is 32-bit)
      
      // Signal completion to sequencer (ready for next item)
      seq_item_port.item_done();
    end
  endtask
  
  task drive_instruction(instr_item item);
    // Encode instruction: {funct7[31:25] | rs2[24:20] | rs1[19:15] | funct3[14:12] | rd[11:7] | opcode[6:0]}
    bit [31:0] encoded_instr;
    
    encoded_instr = item.instr_encoder();
    
    @(posedge vif.clk);
    vif.prog_addr <= prog_addr_counter;  // Sequential address
    vif.prog_data <= encoded_instr;
    vif.prog_we <= 1'b1;
    
    @(posedge vif.clk);
    vif.prog_we <= 1'b0;
  endtask
  
endclass