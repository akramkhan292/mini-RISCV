class instr_item extends uvm_sequence_item;

    
    localparam R_TYPE = 7'b0110011;    // Register-Register
    localparam I_TYPE = 7'b0010011;    // Immediate
    localparam LOAD   = 7'b0000011;    // Load
    localparam STORE  = 7'b0100011;    // Store
    localparam BRANCH = 7'b1100011;    // Branch

    `uvm_object_utils_begin(instr_item)
        `uvm_field_int(opcode, UVM_ALL_ON)
        `uvm_field_int(rd, UVM_ALL_ON)
        `uvm_field_int(rs1, UVM_ALL_ON)
        `uvm_field_int(rs2, UVM_ALL_ON)
        `uvm_field_int(imm, UVM_ALL_ON)
        `uvm_field_int(funct3, UVM_ALL_ON)
        `uvm_field_int(funct7, UVM_ALL_ON)
        `uvm_field_int(pc, UVM_ALL_ON)
        `uvm_field_int(instr, UVM_ALL_ON)
        `uvm_field_int(reg_write, UVM_ALL_ON)
        `uvm_field_int(wb_rd, UVM_ALL_ON)
        `uvm_field_int(wb_data, UVM_ALL_ON)
        `uvm_field_int(mem_write, UVM_ALL_ON)
        `uvm_field_int(mem_addr, UVM_ALL_ON)
        `uvm_field_int(mem_wdata, UVM_ALL_ON)
    `uvm_object_utils_end

    rand bit [4:0] rd, rs1, rs2;
    rand bit [31:0] imm;
    rand int num_instructions;
    rand bit [2:0] funct3;
    rand bit [6:0] funct7;
    rand bit [6:0] opcode;
    bit [31:0] prog_addr;
    bit [31:0] prog_data;
    bit [31:0] pc;
    bit [31:0] instr;
    bit reg_write;
    bit [4:0] wb_rd;
    bit [31:0] wb_data;
    bit mem_write;
    bit [31:0] mem_addr;
    bit [31:0] mem_wdata;

    constraint opcode_const {
        opcode dist {R_TYPE:=30,I_TYPE:=30,LOAD:=20,STORE:=10,BRANCH:=10};
    }

    constraint rf_const {
        (opcode == R_TYPE || opcode == I_TYPE || opcode == LOAD) -> (rd inside {[1:31]});
        (opcode != I_TYPE && opcode != LOAD) -> (rs2 inside {[0:31]});
        rs1 inside {[0:31]};
    }

    constraint funct_const {
        if (opcode == R_TYPE) {
            funct7 dist {7'h20 := 1, 7'h00 := 3};
            (funct7==7'h20) -> (funct3 == 0);
            (funct7==7'h00) -> (funct3 dist {0 := 1, 6 := 1, 7 := 1});
        }
        else if (opcode == I_TYPE) funct3 == 3'b000;  // ADDI
        else if (opcode == LOAD)   funct3 == 3'b010;  // LW
        else if (opcode == STORE)  funct3 == 3'b010;  // SW
        else if (opcode == BRANCH) funct3 == 3'b000;  // BEQ
    }
    constraint branch_align {
        (opcode == BRANCH) -> (imm[0] == 0);
    }
    
    function new(string name = "instr_item");
        super.new(name);
    endfunction //new()

    function bit [31:0] instr_encoder();
        logic [31:0] instr;
        case (opcode)
            R_TYPE:
                instr = {funct7,rs2,rs1,funct3,rd,opcode};
            I_TYPE,
            LOAD:
                 instr = {imm[11:0],rs1,funct3,rd,opcode};
            STORE:
                instr = {imm[11:5],rs2,rs1,funct3,imm[4:0],opcode};
            BRANCH: 
                instr = {imm[12],imm[10:5],rs2,rs1,funct3,imm[4:1],imm[11],opcode};
            default: instr = 32'd0;
        endcase
        return instr;
    endfunction
endclass //instr_item extends uvm_sequence_item
