module control_unit(
    input logic [6:0] opcode,
    input logic [2:0] func3,
    input logic [6:0] func7,

    output logic reg_write,
    output logic mem_read,
    output logic mem_write,
    output logic alu_src,
    output logic branch,
    output logic [3:0] alu_ctrl
);
    localparam R_TYPE = 7'b0110011;
    localparam I_TYPE = 7'b0010011;
    localparam LOAD   = 7'b0000011;
    localparam STORE  = 7'b0100011;
    localparam BRANCH = 7'b1100011;

    always_comb begin
        //default
        reg_write = 0;
        mem_read = 0;
        mem_write = 0;
        alu_src = 0;
        branch = 0;
        alu_ctrl = 4'b0000;

    //opcode  → category
    //funct3  → sub-category
    //funct7  → exact operation

    //opcode → R-type
    //funct3 → arithmetic group
    //funct7 → SUB (not ADD)

        case (opcode)
            R_TYPE: begin
                reg_write = 1;
                case({func7, func3})
                    {7'b0000000, 3'b000}: alu_ctrl = 4'b0000;  //ADD
                    {7'b0100000, 3'b000}: alu_ctrl = 4'b0001;  //SUB
                    {7'b0000000, 3'b111}: alu_ctrl = 4'b0010;  //AND
                    {7'b0000000, 3'b110}: alu_ctrl = 4'b0011;  //OR
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
                alu_ctrl = 4'b0001; //SUB for BEQ
            end
        endcase
    end

endmodule
