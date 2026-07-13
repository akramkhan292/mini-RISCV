module riscv_assertions(riscv_intf intf);
  // Sample after the rising-edge nonblocking updates have settled.
  always @(negedge intf.clk) begin
    if (intf.rst) begin
      assert (intf.dbg_pc == 32'd0)
        else $error("Reset did not hold PC at zero: %08h", intf.dbg_pc);
    end

    if (!intf.rst && intf.dbg_commit_valid) begin
      assert (intf.dbg_pc[1:0] == 2'b00)
        else $error("PC is not word aligned: %08h", intf.dbg_pc);

      if (intf.dbg_mem_write) begin
        case (intf.dbg_instr[14:12])
          3'b000: begin end // SB may target any byte lane.
          3'b001: assert (intf.dbg_mem_addr[0] == 1'b0)
            else $error("SH address is not halfword aligned: %08h", intf.dbg_mem_addr);
          3'b010: assert (intf.dbg_mem_addr[1:0] == 2'b00)
            else $error("SW address is not word aligned: %08h", intf.dbg_mem_addr);
          default: $error("Invalid retiring store funct3: %03b", intf.dbg_instr[14:12]);
        endcase
      end
    end
  end
endmodule
