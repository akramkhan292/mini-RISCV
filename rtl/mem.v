module inst_mem(
    input logic [31:0] addr,
    output logic [31:0] instruction
);

    logic [31:0] mem [255:0];

    // for loading instruction in memory.
    initial begin
        $readmemh("program.mem",mem);
    end

    // [1:0] is offset bit because one instruction contains 4 bytes of data so we will access as
    // 00 0000 0000 -> x0
    // 00 0000 0100 -> x4
    // 00 0000 1000 -> x8
    // 00 0000 1100 -> xC
    // ..
    // last 2 lsb bit is should be 00 and use of accessing byte of instruction
    // why till 9 because we going for 255 length of tower

    assign instruction = mem[addr[9:2]];
    
endmodule