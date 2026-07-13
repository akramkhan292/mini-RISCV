# Debug Guide

## First Commands

Run both directed tests:

```sh
make test
```

Run the Questa UVM flow:

```sh
make questa
```

## Useful Hierarchy

In the directed testbench, the DUT root is `tb_riscv_core.dut`:

- Fetch PC: `dut.fetch_inst.pc_inst.pc`
- Instruction memory: `dut.fetch_inst.imem.mem`
- Register file: `dut.decode_inst.rf.regfile`
- Data memory: `dut.memory_inst.dmem.mem`
- Pipeline registers: `dut.pipe_regs`
- Control decoder: `dut.cu`
- Retirement interface: `dut.dbg_*`

The UVM top uses `tb_riscv.dut`; its monitor observes the same `dbg_*` interface through `intf_inst`.

## Trace the Instruction, Not Just the Signal Name

For a failing instruction, follow its valid bit, PC, instruction, `rs1`, `rs2`, `rd`, operands, and controls through IF/ID, ID/EX, EX/MEM, and MEM/WB. Signals from different stages normally refer to different instructions in the same cycle.

At retirement, these fields must all refer to one WB instruction:

- `dbg_commit_valid`
- `dbg_pc` and `dbg_instr`
- `dbg_reg_write`, `dbg_rd`, and `dbg_writeback_data`
- `dbg_mem_write`, `dbg_mem_addr`, and `dbg_mem_wdata`

## Common Pipeline Failures

### The right value is written to the wrong register

Compare the MEM/WB `rd` with the register-file write address. The address must be `wb_rd`; decode-stage `rd` belongs to a younger instruction. Check that WB data, WB enable, and WB destination advance together.

### PC values repeat or advance irregularly

Check the normal next-PC candidate before looking at branch logic. It must be the current fetch PC plus four. A pipelined `ex_pc + 4` is stale for sequential fetch. Then check selection priority: EX redirect, load-use hold, otherwise `if_pc + 4`.

### A dependent ALU instruction uses an old value

Check both forwarding comparators and muxes. A matching valid EX/MEM producer has priority over MEM/WB, and `rd == 0` never forwards. Verify both operands independently.

### A load consumer is wrong

The load result is not available from EX/MEM. A directly dependent instruction must cause one cycle with PC and IF/ID held and ID/EX invalidated; the consumer then obtains the value from MEM/WB.

### A branch, JALR, or store sees stale data

Forwarding is required for every EX-stage consumer, not just the ALU result path. Inspect the forwarded branch operands, JALR base, and store-data value.

### A wrong-path instruction changes state

On an EX redirect, inspect IF/ID and ID/EX valid bits. Both younger entries must be flushed, and no flushed entry may assert register write, memory write, or commit later.

### A subword load returns the wrong lane

Check the byte address against `addr[1:0]`. Select the addressed byte or halfword first, then apply sign or zero extension. `addr[9:2]` selects only the containing word.

### UVM compilation fails in Icarus

This is expected; use Questa/ModelSim for the UVM flow. Icarus is the directed Verilog smoke-test simulator.
