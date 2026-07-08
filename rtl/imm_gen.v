module imm_gen(
    input wire [31:0] instr,
    output reg [31:0] imm
);
    wire [6:0] opcode = instr[6:0];

    localparam I_TYPE = 7'b0010011;
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;

    always @(*) begin
        case (opcode)
            I_TYPE,
            LOAD:
                imm = {{20{instr[31]}}, instr[31:20]};

            STORE:
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

            BRANCH:
                imm = {{19{instr[31]}}, instr[31], instr[7],
                       instr[30:25], instr[11:8], 1'b0};

            default:
                imm = 32'd0;
        endcase
    end
endmodule
