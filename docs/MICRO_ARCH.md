# Five-Stage Microarchitecture

## Architecture

The CPU is an in-order, single-issue RV32I-subset pipeline. Up to five instructions occupy independent stages, separated by IF/ID, ID/EX, EX/MEM, and MEM/WB registers.

```text
                 +---------- forwarding ----------+
                 |                                |
PC -> IF -> IF/ID -> ID -> ID/EX -> EX -> EX/MEM -> MEM -> MEM/WB -> WB
 ^                 |                |                                  |
 |                 +-- WB bypass ---+----------------------------------+
 +-- redirect from EX, otherwise IF PC + 4
```

Each pipeline entry carries a valid bit. A bubble is an entry with `valid = 0`; its control signals must not update architectural state.

## Stage Responsibilities

### IF: instruction fetch

- Hold the byte-addressed PC and fetch the corresponding instruction.
- Compute the sequential candidate from the current fetch PC: `if_pc + 4`.
- Hold PC and IF/ID during a load-use stall.
- On an EX redirect, select the branch or jump target and invalidate the younger IF/ID entry.

The normal next PC must not come from an older instruction's EX/MEM register. Feeding a delayed `ex_pc + 4` back to IF repeats or skips fetch addresses because that PC belongs to another instruction.

Ignoring reset, the address selection is `next_pc = ex_redirect ? ex_target : if_pc + 4`. A load-use stall disables the PC write; an EX redirect overrides that younger stall and enables the target update.

### ID: decode and register read

- Extract `opcode`, `funct3`, `funct7`, `rs1`, `rs2`, and `rd`.
- Generate the immediate and control signals.
- Read two register operands.
- Apply WB-to-ID bypass when a WB write and an ID read address match. Writes or matches involving `x0` are ignored.
- Detect an immediate dependency on a load in EX. The response is to hold PC and IF/ID and insert an invalid ID/EX bubble for one cycle.

The WB-to-ID path is required even with an asynchronous-read, synchronous-write register file. At a rising edge, the ID/EX registers sample their right-hand sides before nonblocking register-file writes take effect. A matching WB value must therefore be selected combinationally ahead of the ID/EX capture; otherwise ID/EX can latch the old register value on that same edge.

### EX: execute and redirect

- Select each source independently from the ID/EX value, EX/MEM result, or MEM/WB writeback value.
- Give EX/MEM priority over MEM/WB when both match, because EX/MEM is newer.
- Do not forward an EX/MEM load as though its ALU result were loaded data; the one-cycle load-use stall allows the value to be forwarded from MEM/WB instead.
- Feed forwarded values to every consumer that needs them, including ALU inputs, branch comparison, JALR base calculation, and store data.
- Resolve conditional branches, `JAL`, and `JALR` in EX and generate the redirect target.

When a redirect is taken, IF/ID and ID/EX are flushed. The redirect has priority over a younger decode-stage stall.

### MEM: data-memory access

- Use the EX address for loads and stores.
- Apply byte enables for `SB`, `SH`, and `SW`.
- Select the addressed byte or halfword before sign or zero extension for subword loads.
- Carry store and retirement metadata forward even though the memory side effect occurs in MEM.

### WB: writeback and retirement

- Select the loaded value for loads, `pc + 4` for a qualified link instruction, or the ALU result otherwise.
- Write only when the MEM/WB entry is valid, register write is enabled, and `wb_rd != 0`.
- Publish a coherent retirement/debug transaction for the valid, nonsquashed instruction.

The register-file write address must be `wb_rd`, not the `rd` currently visible in ID. The WB data, enable, and destination are one transaction and must all come from the same MEM/WB entry. Using the decode-stage `rd` destroys architectural state whenever a different instruction is in ID while an older instruction writes back.

## Pipeline Control Summary

| Event | PC | IF/ID | ID/EX | Older stages |
| --- | --- | --- | --- | --- |
| Normal cycle | Advance to `if_pc + 4` | Capture | Capture | Advance |
| Load-use hazard | Hold | Hold | Insert bubble | Advance |
| Taken branch/jump in EX | Load redirect target | Flush | Flush | Advance |
| Reset | Set to zero | Invalidate | Invalidate | Invalidate |

Only true source operands participate in hazard checks. Matches on `x0` do not cause a stall or forwarding.

## Forwarding Rules

For each EX source independently:

1. Use the EX/MEM result when that entry is valid, writes a nonzero `rd`, is not a load whose data is unavailable, and `rd` matches the source.
2. Otherwise use the MEM/WB writeback value when that entry is valid, writes a nonzero `rd`, and `rd` matches the source.
3. Otherwise use the operand captured in ID/EX.

WB-to-ID bypass is separate from EX forwarding. It covers the same-cycle register-file timing case at the decode boundary.

## Retirement and Debug Interface

The top level exposes:

- `dbg_commit_valid`
- `dbg_pc`, `dbg_instr`
- `dbg_reg_write`, `dbg_rd`, `dbg_writeback_data`
- `dbg_mem_write`, `dbg_mem_addr`, `dbg_mem_wdata`

All fields must describe the same WB-stage instruction. `dbg_commit_valid` denotes every valid, nonsquashed retirement, not only instructions that write a register. Register and memory enables then identify its architectural side effect. Flushed bubbles never commit.

This is a verification interface, not a production instruction or data bus.

## Main Blocks

- `fetch_stage`: PC state and instruction-memory access.
- `pipeline_regs`: IF/ID, ID/EX, EX/MEM, and MEM/WB state, including valid and retirement metadata.
- `decode_stage`: field extraction, register-file access, immediate generation, and WB destination connection.
- `control_unit`: opcode and function decode.
- `execute_stage`: ALU, branch/jump decision, and redirect target.
- `memory_stage`: data-memory access and load formatting.
- `riscv_core`: stage integration, hazard control, forwarding selection, WB selection, and debug output.

## Current Limitations

- Single issue and in-order execution only.
- Branches and jumps resolve in EX; there is no branch prediction.
- Instruction and data memories are small internal simulation models with fixed-latency behavior; there is no external bus, cache, or back-pressure protocol.
- There are no illegal-instruction, misalignment, access-fault, interrupt, exception, CSR, or privilege mechanisms.
- RV32M, RV32A, RV32C, and floating-point extensions are outside the declared subset.
- Operations listed as qualification-pending in [ISA_SUBSET.md](ISA_SUBSET.md) are not claimed as supported.
