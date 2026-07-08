# Debug Guide

## First Commands

Run the baseline directed test:

```sh
make smoke
```

Run the Questa UVM flow:

```sh
make questa
```

## Signals to Inspect

- `dut.pc_inst.pc`: current PC.
- `dut.imem.instruction`: fetched instruction.
- `dut.cu.*`: decoded control signals.
- `dut.rf.regfile`: architectural registers.
- `dut.alu_result`: ALU result.
- `dut.dmem.mem`: data memory.
- `intf_inst.dbg_*`: UVM-facing commit/debug view.

## Common Failures

- Wrong immediate: compare `instr` fields against `imm_gen.imm`.
- Wrong branch: check `zero`, `branch`, `imm`, and `next_pc`.
- Wrong load/store: check byte address versus memory index `addr[9:2]`.
- Unknown register values: initialize registers through real instructions before random R-type operations.
- UVM compile fails in Icarus: expected; use Questa/ModelSim for UVM.
