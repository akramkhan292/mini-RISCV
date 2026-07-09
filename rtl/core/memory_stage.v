module memory_stage(
    input wire clk,
    input wire mem_read,
    input wire mem_write,
    input wire [2:0] store_type,
    input wire [31:0] addr,
    input wire [31:0] data_in,
    input wire [2:0] func3,

    output wire [31:0] load_data
);

    wire [31:0] data_out;

    data_mem dmem (
        .clk(clk),
        .mem_read(mem_read),
        .mem_write(mem_write),
        .store_type(store_type),
        .addr(addr),
        .data_in(data_in),
        .data_out(data_out)
    );

    assign load_data = 
        (func3 == 3'b000) ? {{24{data_out[7]}},   data_out[7:0]}    : // LB
        (func3 == 3'b001) ? {{16{data_out[15]}},  data_out[15:0]}   : // LH
        (func3 == 3'b100) ? {24'b0,               data_out[7:0]}    : // LBU
        (func3 == 3'b101) ? {16'b0,               data_out[15:0]}   : // LHU
                            data_out;

endmodule
