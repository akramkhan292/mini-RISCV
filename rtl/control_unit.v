module control_unit(
    input wire [6:0] opcode,
    input wire [2:0] func3,
    input wire [6:0] func7,

    output reg reg_write,
    output reg mem_read,
    output reg mem_write,
    output reg alu_src,
    output reg branch,
    output reg [3:0] alu_ctrl
);
    localparam R_TYPE = 7'b0110011;    // Register-Register
    localparam I_TYPE = 7'b0010011;    // Immediate
    localparam LOAD   = 7'b0000011;    // Load
    localparam STORE  = 7'b0100011;    // Store
    localparam BRANCH = 7'b1100011;    // Branch

    always @(*) begin
        // Default: prevent latches
        reg_write = 0;
        mem_read = 0;
        mem_write = 0;
        alu_src = 0;
        branch = 0;
        alu_ctrl = 4'b0000;

        case (opcode)
            R_TYPE: begin
                reg_write = 1;
                case({func7, func3})
                    {7'b0000000, 3'b000}: alu_ctrl = 4'b0000;  // ADD
                    {7'b0100000, 3'b000}: alu_ctrl = 4'b0001;  // SUB
                    {7'b0000000, 3'b111}: alu_ctrl = 4'b0010;  // AND
                    {7'b0000000, 3'b110}: alu_ctrl = 4'b0011;  // OR
                endcase
            end
            I_TYPE: begin
                reg_write = 1;
                alu_src = 1;
                alu_ctrl = 4'b0000;
            end
            LOAD: begin
                reg_write = 1;
                mem_read = 1;
                alu_src = 1;
                alu_ctrl = 4'b0000;
            end
            STORE: begin
                mem_write = 1;
                alu_src = 1;
                alu_ctrl = 4'b0000;
            end
            BRANCH: begin
                branch = 1;
                alu_ctrl = 4'b0001;
            end
        endcase
    end

endmodule
