class riscv_sequence extends uvm_sequence#(instr_item);

    `uvm_object_utils(riscv_sequence)

    function new(name = "riscv_sequence");
        super.new(name);
    endfunction //new()

    task body();
        repeat(5) begin
            req = instr_item::type_id::create("instr_pkt",this);
            start_item(req);
            assert(req.randomize());
            finish_item(req);
        end
    endtask

endclass //riscv_sequence extends uvm_sequence