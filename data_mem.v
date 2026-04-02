module data_mem(
    input clk,
    input logic mem_read,
    input logic mem_write,
    input logic [31:0] addr,
    input logic [31:0] data_in,

    output logic [31:0] data_out
);

    logic [31:0] mem [255:0];

    // always_comb begin
    //     if(mem_read)
    //         data_out = mem[addr[9:2]];
    //     else
    //         data_out = 32'd0;
    // end

    assign data_out = (mem_read) ? mem[addr[9:2]] : 32'd0;

    // RAM doesn't need to be reset
    // here both data and instruction memory is byte indexed
    // byte index means every byte have address

    always_ff @(posedge clk) begin

        if (mem_write) begin
            mem[addr[9:2]] <= data_in;
        end
        
    end

    
endmodule