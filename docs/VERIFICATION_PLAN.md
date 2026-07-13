# Verification Plan

## Goal

Verify in-order architectural retirement and the pipeline mechanisms that preserve it: sequential fetch, writeback destination tracking, forwarding, load-use stalls, redirects, flushes, register writes, and memory writes.

The authoritative observation point is a coherent WB retirement transaction. Internal pipeline signals are used for assertions and diagnosis, not mixed into one architectural transaction.

## Testbench Strategy

- Directed programs target basic ISA behavior and specific pipeline timing cases.
- The programming interface loads instruction memory while reset is asserted.
- The UVM monitor samples only when `dbg_commit_valid` is asserted.
- The scoreboard predicts from the retired PC and instruction, then compares DUT register/store side effects without copying observed DUT values into reference state.
- Planned coverage includes instruction groups, forwarding selections, stalls, redirects, destinations, and side effects.
- Assertions check retirement alignment and basic reset/side-effect invariants; the pipeline-control properties below remain expansion goals.
- A failed directed or UVM check must produce a nonzero simulator/process status.

## Directed Scenarios

### ISA behavior

| Scenario | Purpose |
| --- | --- |
| Arithmetic smoke | `ADDI`, `ADD`, and `SUB` behavior |
| Logical operations | `AND` and `OR` decode and ALU behavior |
| x0 behavior | Writes to `x0` do not change state or create hazards |
| Load semantics | `LB`/`LH` sign extension and `LBU`/`LHU` zero extension from every applicable lane |
| Store granularity | `SB`/`SH` byte lanes and `SW` behavior |
| Memory round trip | Store followed by load from the same address |
| Conditional branches | Taken and not-taken cases for every declared branch type |
| Sign extension | Negative I/S/B immediates |

### Pipeline behavior

| Scenario | Expected result |
| --- | --- |
| Independent instructions | Sequential fetch PCs advance by four with no duplicates |
| ALU result used by next instruction | EX/MEM forwarding, no stall |
| ALU result used two instructions later | MEM/WB forwarding, no stall |
| WB write matches current ID read | WB-to-ID bypass supplies the WB value |
| Two producers target the same `rd` | EX/MEM forwarding wins over older MEM/WB data |
| Load used by next instruction | Exactly one bubble; PC and IF/ID hold |
| Load with no true dependency | No stall |
| Dependency whose destination is `x0` | No stall or forwarding |
| ALU-to-store dependency | Forwarded store data reaches memory |
| ALU/load-to-branch dependency | Branch compares the newest values |
| Taken branch or jump | Redirect target is fetched; IF/ID and ID/EX are flushed |
| Not-taken branch | Sequential path remains `if_pc + 4` |
| Wrong-path register/store instruction | No architectural side effect and no retirement |
| Several different `rd` values in flight | Each WB value writes its own pipelined `wb_rd` |

## Scoreboard Checks

- Retired PCs follow architectural control flow in program order.
- `dbg_instr`, PC, destination, writeback, and store fields describe the same instruction.
- Register-write enable, destination, and data match the reference instruction.
- Store enable, address, data, and lane behavior match the reference instruction.
- Non-writing instructions still retire with both side-effect enables clear.
- Reference register `x0` remains zero.
- Squashed instructions never retire.
- The test observes the required number of retirements or reaches an explicit timeout failure.

## Assertions

- Fetch and retired PCs are instruction aligned.
- Reset invalidates all pipeline entries and returns fetch to PC zero.
- A load-use stall holds PC and IF/ID and inserts an ID/EX bubble.
- An EX redirect flushes IF/ID and ID/EX.
- Invalid entries cannot write a register, write memory, or commit.
- A WB register write uses the MEM/WB destination and never changes `x0`.
- Forwarding never selects destination `x0`.
- Retirement order is in-order and contains no flushed entry.

Alignment assertions for data accesses must match the declared policy. Until misaligned traps exist, do not assert that every byte or halfword address is word-aligned.

## Coverage Goals

- Hit every declared opcode and instruction variant.
- Hit EX/MEM and MEM/WB forwarding on source 1, source 2, branch operands, and store data.
- Hit WB-to-ID bypass on both read ports.
- Hit a load-use stall and a nearby non-hazard that must not stall.
- Hit taken and not-taken branches and an EX redirect flush.
- Hit every byte and halfword lane for subword memory operations.
- Hit destination bins `x0`, low, mid, and high.
- Hit register-writing, memory-writing, and side-effect-free retirements.

Features marked qualification-pending in [ISA_SUBSET.md](ISA_SUBSET.md) are not counted as supported merely because coverage samples their opcode.
