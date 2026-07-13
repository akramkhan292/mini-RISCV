class riscv_sequence extends uvm_sequence#(instr_item);

    `uvm_object_utils(riscv_sequence)

    function new(string name = "riscv_sequence");
        super.new(name);
    endfunction //new()

    task body();
        add_i(5'd1, 5'd0, 12'd5);      // x1 = 5
        add_i(5'd2, 5'd0, 12'd3);      // x2 = 3
        add_r(5'd3, 5'd1, 5'd2, 3'b000, 7'b0000000); // x3 = x1 + x2
        add_r(5'd4, 5'd3, 5'd2, 3'b000, 7'b0100000); // x4 = x3 - x2
        add_s(5'd0, 5'd3, 12'd0);      // mem[0] = x3
        add_l(5'd5, 5'd0, 12'd0);      // x5 = mem[0]
        add_b(5'd5, 5'd3, 13'd8);      // skip next instruction when x5 == x3
        add_i(5'd6, 5'd0, 12'd1);      // skipped
        add_i(5'd7, 5'd0, 12'd9);      // x7 = 9
    endtask

    task send_item(instr_item item);
        begin
            req = item;
            start_item(req);
            finish_item(req);
        end
    endtask

    task add_i(bit [4:0] rd, bit [4:0] rs1, bit [11:0] imm);
        instr_item item = instr_item::type_id::create("addi_item");
        item.opcode = 7'b0010011;
        item.rd = rd;
        item.rs1 = rs1;
        item.rs2 = 5'd0;
        item.funct3 = 3'b000;
        item.funct7 = 7'd0;
        item.imm = {{20{imm[11]}}, imm};
        send_item(item);
    endtask

    task add_l(bit [4:0] rd, bit [4:0] rs1, bit [11:0] imm);
        instr_item item = instr_item::type_id::create("lw_item");
        item.opcode = 7'b0000011;
        item.rd = rd;
        item.rs1 = rs1;
        item.rs2 = 5'd0;
        item.funct3 = 3'b010;
        item.funct7 = 7'd0;
        item.imm = {{20{imm[11]}}, imm};
        send_item(item);
    endtask

    task add_s(bit [4:0] rs1, bit [4:0] rs2, bit [11:0] imm);
        instr_item item = instr_item::type_id::create("sw_item");
        item.opcode = 7'b0100011;
        item.rd = 5'd0;
        item.rs1 = rs1;
        item.rs2 = rs2;
        item.funct3 = 3'b010;
        item.funct7 = 7'd0;
        item.imm = {{20{imm[11]}}, imm};
        send_item(item);
    endtask

    task add_b(bit [4:0] rs1, bit [4:0] rs2, bit [12:0] imm);
        instr_item item = instr_item::type_id::create("beq_item");
        item.opcode = 7'b1100011;
        item.rd = 5'd0;
        item.rs1 = rs1;
        item.rs2 = rs2;
        item.funct3 = 3'b000;
        item.funct7 = 7'd0;
        item.imm = {{19{imm[12]}}, imm};
        send_item(item);
    endtask

    task add_r(bit [4:0] rd, bit [4:0] rs1, bit [4:0] rs2,
               bit [2:0] funct3, bit [6:0] funct7);
        instr_item item = instr_item::type_id::create("rtype_item");
        item.opcode = 7'b0110011;
        item.rd = rd;
        item.rs1 = rs1;
        item.rs2 = rs2;
        item.funct3 = funct3;
        item.funct7 = funct7;
        item.imm = 32'd0;
        send_item(item);
    endtask

endclass //riscv_sequence extends uvm_sequence
