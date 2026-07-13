# Project Structure

This repository separates the pipelined CPU datapath, memory models, testbench, and documentation.

## Directory Layout

- `rtl/core/` — pipeline stages, pipeline registers, control, ALU, register file, and PC logic.
- `rtl/memory/` — instruction and data memory models.
- `tb/` — directed smoke and pipeline-hazard tests plus UVM verification components.
- `docs/` — ISA, microarchitecture, verification, debug, and learning notes.
- `build/` — ignored Icarus executables and waveforms created by the Makefile.

## RTL Files

### `rtl/core/`

- `riscv_core.v` — top-level five-stage integration, forwarding, stalls, redirects, WB selection, and retirement/debug wiring.
- `pipeline_regs.v` — IF/ID, ID/EX, EX/MEM, and MEM/WB state.
- `fetch_stage.v` — PC state and instruction fetch.
- `decode_stage.v` — instruction field extraction, register-file read/write, and immediate generation.
- `execute_stage.v` — ALU operation and EX-stage branch/jump resolution.
- `memory_stage.v` — data-memory access and load sign/zero extension.
- `control_unit.v` — opcode and function decode for ALU, memory, branch, and jump controls.
- `alu.v` — arithmetic, logical, shift, and comparison primitives used by the decoded subset.
- `register_file.v` — 32-register file with two read ports, one write port, and hardwired `x0`.
- `imm_gen.v` — immediate generation for the instruction formats recognized by the RTL.
- `pc.v` — program-counter state with an enable for stalls.

### `rtl/memory/`

- `inst_mem.v` — instruction memory with a testbench programming interface.
- `data_mem.v` — data memory with word, halfword, and byte write lanes.

## Testbench

- `tb/tb_riscv_core.v` — directed pipeline smoke test.
- `tb/tb_pipeline_hazards.v` — focused forwarding, stall, flush, and retirement-PC regression.
- `tb/riscv_uvmtb.sv` — UVM top-level testbench.
- `tb/interface.sv` — programming and retirement/debug interface.
- `tb/monitor.sv` — samples coherent retirement transactions.
- `tb/scoreboard.sv` — architectural reference checking.
- `tb/coverage.sv` and `tb/riscv_assertions.sv` — coverage and invariants.

## Useful Simulation Hierarchy

- Instruction memory: `tb_riscv_core.dut.fetch_inst.imem.mem`
- Register file: `tb_riscv_core.dut.decode_inst.rf.regfile`
- Data memory: `tb_riscv_core.dut.memory_inst.dmem.mem`
- Pipeline state: `tb_riscv_core.dut.pipe_regs`

UVM uses `tb_riscv.dut` as the DUT root rather than `tb_riscv_core.dut`.

## Build

- `make test` runs both directed Icarus regressions; `make smoke` and `make pipeline` run them separately.
- `make questa` runs the SystemVerilog/UVM flow in Questa/ModelSim.
- The Makefile discovers RTL below `rtl/`, so adding a core module does not require flattening the directory structure.
