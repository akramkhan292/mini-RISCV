module riscv_assertions(riscv_intf intf);
  always @(posedge intf.clk) begin
    if (intf.rst) begin
      assert (intf.dbg_pc == 32'd0)
        else $error("Reset did not hold PC at zero: %08h", intf.dbg_pc);
    end

    if (!intf.rst && intf.dbg_commit_valid) begin
      assert (intf.dbg_pc[1:0] == 2'b00)
        else $error("PC is not word aligned: %08h", intf.dbg_pc);

      if (intf.dbg_mem_write) begin
        assert (intf.dbg_mem_addr[1:0] == 2'b00)
          else $error("Store address is not word aligned: %08h", intf.dbg_mem_addr);
      end

      if (intf.dbg_reg_write && intf.dbg_rd == 5'd0) begin
        assert (intf.dbg_writeback_data == 32'd0)
          else $error("x0 write attempted with non-zero data: %08h", intf.dbg_writeback_data);
      end
    end
  end
endmodule
