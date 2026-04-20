class riscv_monitor extends uvm_monitor;

  localparam R_TYPE = 7'b0110011;    // Register-Register
  localparam I_TYPE = 7'b0010011;    // Immediate
  localparam LOAD   = 7'b0000011;    // Load
  localparam STORE  = 7'b0100011;    // Store
  localparam BRANCH = 7'b1100011;    // Branch
  
  `uvm_component_utils(riscv_monitor)

  virtual riscv_intf vif;
  instr_item captured_item;
  uvm_analysis_port#(instr_item) mon_port;

  function new(string name, uvm_component parent);
    super.new(name,parent);
    mon_port = new("mon_port",this);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    `uvm_info(get_type_name(),"[BUILD] Monitor",UVM_LOW)
    // Get virtual interface from config database
    if(!uvm_config_db#(virtual riscv_intf)::get(this, "","vif",vif))
      `uvm_fatal("NO_VIF","interface not found")
  endfunction

  task run_phase(uvm_phase phase);
    `uvm_info(get_type_name(),"[RUN] Monitor starting",UVM_LOW)
    forever begin
      @(posedge vif.clk);
      if(vif.prog_we) begin
        captured_item = instr_item::type_id::create("captured_item",this);
        captured_item.prog_addr = vif.prog_addr;
        decode_instruction(vif.prog_data);
        mon_port.write(captured_item);
        `uvm_info(get_type_name(),$sformatf("[MONITOR] Captured: Addr=%0d, Opcode=%0h",
                 captured_item.prog_addr, captured_item.opcode),UVM_MEDIUM)
      end
    end
  endtask

  function void decode_instruction(bit [31:0] instr);
    captured_item.opcode = instr[6:0];
    case (captured_item.opcode)
            R_TYPE:
                begin
                  captured_item.rd = instr[11:7];
                  captured_item.funct3 = instr[14:12];
                  captured_item.rs1 = instr[19:15];
                  captured_item.rs2 = instr[24:20];
                  captured_item.funct7 = instr[31:25];
                end
            I_TYPE,
            LOAD:
                begin
                  captured_item.rd = instr[11:7];
                  captured_item.funct3 = instr[14:12];
                  captured_item.rs1 = instr[19:15];
                  captured_item.imm[11:0] = instr[31:20];
                end
            STORE:
                begin
                  captured_item.imm[4:0] = instr[11:7];
                  captured_item.funct3 = instr[14:12];
                  captured_item.rs1 = instr[19:15];
                  captured_item.rs2 = instr[24:20];
                  captured_item.imm[11:5] = instr[31:25];
                end
            BRANCH:
                begin
                  captured_item.imm[11] = instr[7];
                  captured_item.imm[4:1] = instr[11:8];
                  captured_item.funct3 = instr[14:12];
                  captured_item.rs1 = instr[19:15];
                  captured_item.rs2 = instr[24:20];
                  captured_item.imm[10:5] = instr[30:25];
                  captured_item.imm[12] = instr[31];
                end
        endcase
  endfunction
endclass