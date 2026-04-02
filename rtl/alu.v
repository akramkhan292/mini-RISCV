module alu(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [3:0] alu_ctrl,
    output logic [31:0] result,
    output logic zero 
);


localparam ADD = 4'b0000;
localparam SUB = 4'b0001;
localparam AND = 4'b0010;
localparam OR  = 4'b0011;

// use blocking assignment instead of non-blocking assignment to prevent getting prevent getting older values since all rhs side will be evaluated and then lhs will be evaluated at last
// for example
// a <= c + b;
// d <= a + e; here old value of e be used which is wrong in case of combinational circuit.

    always_comb begin
        case (alu_ctrl)
            ADD: result = a + b;
            SUB: result = a - b;
            AND: result = a & b;
            OR: result = a | b; 
            default: result = 0;
        endcase
    end

    assign zero = (result == 0);
    
endmodule