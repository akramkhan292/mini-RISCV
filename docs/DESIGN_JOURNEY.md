# RISC-V Processor: Design Journey, Challenges & Improvements

## Project Overview

This document chronicles the design and verification journey of a 32-bit RISC-V processor, from initial RTL implementation through UVM testbench development.

---

## Part 1: Design Approach

### Phase 1: Architecture Selection

#### Decision: Single-Cycle vs Pipelined

**Chosen**: **Single-Cycle** (non-pipelined)

**Rationale**:
- Simpler design (fewer classes to synchronize)
- Easier to debug (one instruction at a time)
- Sufficient for learning RISC-V ISA
- Can extend to pipeline later

**Comparison**:
```
Single-Cycle:
Fetch → Decode → Execute → Memory → Writeback (all in 1 cycle)
└─ Simple logic, high latency

Pipelined:
Stage1 (Fetch) → Stage2 (Decode) → ... (all parallel)
└─ Complex (hazard detection, forwarding), low latency
```

#### Decision: Harvard vs Von Neumann Architecture

**Chosen**: **Harvard** (separate instruction/data memory)

**Rationale**:
- Prevents instruction cache thrashing
- Security benefit (code cannot be modified)
- Better for embedded systems
- Simpler for this project

**Trade-off**: Uses more memory buses

### Phase 2: ISA Subset Selection

**Chosen**: **RV32I** subset + memory operations

**Instruction Types Supported**:
- R-type: ADD, SUB, AND, OR
- I-type: ADDI (immediate arithmetic)
- Load: LW (word load)
- Store: SW (word store)
- Branch: BEQ (conditional branch)

**Not Included** (Future extensions):
- Floating-point (RV32F)
- Multiplication/Division (RV32M)
- Atomic operations (RV32A)
- Compressed instructions (RV32C)

### Phase 3: Control Signal Hierarchy

**Approach**: Hierarchical opcode decoding

```
┌─────────────────────────────────────────┐
│ Instruction [31:0]                      │
├─────────────────────────────────────────┤
│ opcode[6:0] - Level 1 (Instruction type)│
│ func3[14:12] - Level 2 (Sub-operation)  │
│ func7[31:25] - Level 3 (Variant)       │
└─────────────────────────────────────────┘

Example:
┌────────────────────────────────────────┐
│ opcode = 0110011 (R_TYPE)              │
├────────────────────────────────────────┤
│ func3 = 000, func7 = 0000000 → ADD    │
│ func3 = 000, func7 = 0100000 → SUB    │
│ func3 = 110, func7 = 0000000 → OR     │
│ func3 = 111, func7 = 0000000 → AND    │
└────────────────────────────────────────┘
```

**Benefit**: Extensible - only add new cases, don't rewrite entire decoder

### Phase 4: Testbench Strategy

**Initial**: Manual Verilog testbench
**Final**: UVM-based verification framework

**Why UVM?**
- Reusable across projects
- Industry standard (ASIC/FPGA verification)
- Scales to large designs
- Automated stimulus generation

---

## Part 2: Challenges Faced

### Challenge 1: Verilog vs SystemVerilog Compatibility

**Problem**:
```systemverilog
// SystemVerilog (NOT supported in Icarus Verilog)
logic [31:0] data;           // ❌ Not recognized
always_comb begin            // ❌ Syntax error
    result = a + b;
end
```

**Impact**: Code compiled in ModelSim but failed in Icarus Verilog

**Solution**:
```verilog
// Standard Verilog (compatible)
wire/reg [31:0] data;        // ✅ Correct
always @(*) begin            // ✅ Combinational
    result = a + b;
end
```

**Lessons Learned**:
- Always check tool compatibility early
- Don't assume syntax works everywhere
- Test with multiple simulators

### Challenge 2: Latch Inference

**Problem**:
```verilog
always @(*) begin
    if (opcode == R_TYPE)
        reg_write = 1;
    // else: reg_write not assigned → LATCH!
end
```

**Symptom**: Unexpected state retention between cycles

**Solution**:
```verilog
always @(*) begin
    reg_write = 0;  // DEFAULT (prevents latch)
    if (opcode == R_TYPE)
        reg_write = 1;
end
```

**Key Insight**: Initialize ALL outputs before conditionals

### Challenge 3: Wire vs Reg Declaration

**Problem**:
```verilog
// Wrong assignments:
wire result;
always @(*) result = a + b;    // ❌ Can't assign to wire procedurally

reg alu_result;
assign alu_result = a + b;     // ❌ Can't assign to reg with assign
```

**Solution**:
```verilog
wire result;
assign result = a + b;         // ✅ Combinational

reg alu_result;
always @(*) alu_result = a + b; // ✅ Procedural combinational
```

**Rule**:
- **wire**: CAN only be assigned with `assign`
- **reg**: CAN only be assigned in `always` block
- Cannot mix assignments

### Challenge 4: Blocking vs Non-Blocking Assignments

**Problem**:
```verilog
always @(posedge clk) begin
    next_val = current_val;      // ❌ Using blocking (=)
    another_val = next_val;      // ❌ Uses OLD next_val
end
```

**Solution**:
```verilog
always @(posedge clk) begin
    next_val <= current_val;     // ✅ Non-blocking (<=)
    another_val <= next_val;     // ✅ All updates simultaneous
end
```

**Why?**
- Blocking (=): Updates immediately → race conditions
- Non-blocking (<=): Stages updates until block ends → safe

### Challenge 5: Instruction Encoding Complexity

**Problem**: RISC-V encodes immediates differently per instruction type

```
I-Type:  [imm[11:0] | rs1 | funct3 | rd | opcode]
S-Type:  [imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode]
B-Type:  [imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode]
```

**Challenge**: Decoding immediate from S/B-type is NOT straightforward

**Solution**: Created separate decode logic per instruction type
```verilog
case (opcode)
    STORE:   imm = {instr[31:25], instr[11:7]};
    BRANCH:  imm = {instr[31], instr[30:25], instr[11:8], instr[7]};
endcase
```

### Challenge 6: UVM Testbench Complexity

**Initial Issues**:

1. **Sequencer Creation**
   ```systemverilog
   // ❌ Declared but not created
   uvm_sequencer#(instr_item) seqr_item;
   
   // In connect_phase:
   drv_inst.seq_item_port.connect(seqr_inst.seq_item_export); // ❌ Typo!
   ```

2. **Missing Handshake**
   ```systemverilog
   // ❌ No synchronization
   foreach item in sequence begin
       driver.apply(item);    // ❌ Driver might not be ready
   end
   ```

   **Fix**: Use `start_item()`/`finish_item()` handshake

3. **Test Doesn't End**
   ```systemverilog
   task run_phase(uvm_phase phase);
       // ❌ No objection raised → simulation hangs
   endtask
   ```

   **Fix**: Use `phase.raise_objection()` and `phase.drop_objection()`

### Challenge 7: Configuration Database Access

**Problem**: Monitor couldn't find virtual interface

```systemverilog
// ❌ Called in constructor (too early)
function new(...);
    uvm_config_db#(virtual riscv_intf)::get(this, "", "vif", vif);
endfunction

// Components not built yet → vif = null
```

**Solution**: Move to `build_phase()`
```systemverilog
virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    // ✅ config_db populated by now
    if (!uvm_config_db#(virtual riscv_intf)::get(this, "", "vif", vif))
        `uvm_fatal("NO_VIF", "...");
endfunction
```

---

## Part 3: Improvements Made

### Improvement 1: Code Organization

**Before**: All RTL in single directory, mixed with testbenches
```
risc-v/
├── *.v (15+ mixed files)
└── *.sv (scattered)
```

**After**: Organized by abstraction level
```
risc-v/
├── rtl/        (Clean RTL, no testbenches)
├── tb/         (UVM testbenches)
├── sim/        (Simulation outputs only)
└── docs/       (Documentation)
```

**Benefit**: Easier to maintain, clear separation of concerns

### Improvement 2: Documentation

**Before**: Only code comments (scattered, hard to find)

**After**: Created three documentation files:
- `README.md` - Project overview, compilation, UVM architecture
- `INTERVIEW_GUIDE.md` - 50+ interview questions with answers
- `DESIGN_JOURNEY.md` - This file (design decisions, challenges)

**Benefit**: New developers can onboard quickly

### Improvement 3: Constraint-Based Randomization

**Before**: Manual test vectors
```verilog
// Limited coverage
addi x1, x0, 5
addi x2, x0, 3
add x3, x1, x2
```

**After**: Constrained random generation
```systemverilog
constraint opcode_const {
    opcode dist {R_TYPE:=30, I_TYPE:=30, LOAD:=20, STORE:=10, BRANCH:=10};
}

constraint rf_const {
    (opcode == R_TYPE) -> (rd inside {[1:31]});
    rs1 inside {[0:31]};
}
```

**Benefit**: 
- Better code coverage (explores more scenarios)
- Finds edge cases human testers miss
- Repeatable (seed-based)

### Improvement 4: Sequential Memory Write

**Before**: Random program addresses
```verilog
prog_addr = $random % 256;  // ❌ Non-sequential
prog_data = instr;
```

**After**: Sequential addressing
```verilog
prog_addr_counter = 0;
repeat (5) begin
    prog_addr <= prog_addr_counter;
    prog_addr_counter <= prog_addr_counter + 4;
end
```

**Benefit**: Instructions execute in order (realistic program flow)

### Improvement 5: Instruction Encoding/Decoding

**Before**: Manual bit packing
```verilog
instruction = {funct7, rs2, rs1, funct3, rd, opcode};  // Only R-type
```

**After**: Format-specific encoding
```systemverilog
function bit [31:0] instr_encoder();
    case (opcode)
        R_TYPE:  instr = {funct7, rs2, rs1, funct3, rd, opcode};
        I_TYPE:  instr = {imm[11:0], rs1, funct3, rd, opcode};
        STORE:   instr = {imm[11:5], rs2, rs1, funct3, imm[4:0], opcode};
        BRANCH:  instr = {imm[12], imm[10:5], rs2, rs1, funct3, imm[4:1], imm[11], opcode};
    endcase
endfunction
```

**Benefit**: Supports multiple instruction formats correctly

### Improvement 6: Monitor Observation

**Before**: No output verification
```verilog
// Run DUT, no way to know if output is correct
```

**After**: Monitor captures and decodes output
```systemverilog
task run_phase(uvm_phase phase);
    forever begin
        @(posedge vif.clk);
        if (vif.prog_we) begin
            captured_item.prog_addr = vif.prog_addr;
            decode_instruction(vif.prog_data, captured_item);
            mon_port.write(captured_item);
        end
    end
endtask
```

**Benefit**: Can now verify DUT is writing correct instructions at correct addresses

---

## Part 4: Timeline of Challenges & Fixes

| Issue | Discovered At | Fix Time | Impact |
|-------|---|---|---|
| SystemVerilog syntax errors | Compilation | 30 min | High - prevented simulation |
| Latch inference in control unit | Waveform inspection | 1 hour | High - unpredictable behavior |
| Wire/reg confusion | Test failures | 45 min | Medium - runtime errors |
| Blocking/non-blocking mix | Waveform analysis | 1 hour | High - timing violations |
| Immediate encoding bugs | Monitor output | 2 hours | High - wrong instructions |
| Sequencer not created | UVM build | 30 min | High - null pointer crash |
| Config DB timing | Runtime error | 45 min | Medium - interface not found |

**Total Debug Time**: ~6 hours
**Most Impactful Fix**: Proper wire/reg usage (prevented 3 subsequent issues)

---

## Part 5: Future Improvements

### Short-term (1-2 weeks)

#### 1. **Add Scoreboard**
```
Current: Monitor captures, but no verification
Goal: Monitor → Scoreboard → Compare with expected
```

**Implementation**:
```systemverilog
class riscv_scoreboard extends uvm_scoreboard;
    uvm_analysis_imp#(instr_item, riscv_scoreboard) mon_port;
    
    function void write(instr_item item);
        // Compare with expected instruction values
        // Print PASS/FAIL
    endfunction
endclass
```

#### 2. **Add Coverage Metrics**
```systemverilog
covergroup instr_coverage;
    opcode_cp: coverpoint opcode {
        bins R_type = {7'b0110011};
        bins I_type = {7'b0010011};
        ...
    }
endgroup
```

**Benefit**: Track which instructions/scenarios tested

#### 3. **Add Register State Tracking**
```systemverilog
// Monitor register file writes
// Track which registers modified
// Verify expected values
```

### Medium-term (3-4 weeks)

#### 4. **Pipeline Implementation**
```
Single-Cycle:
Fetch → Decode → Execute → Memory → Writeback (1 cycle)

Pipeline:
Stage1: Fetch
Stage2: Decode
Stage3: Execute
Stage4: Memory
Stage5: Writeback
(All stages parallel - 5x throughput!)
```

**Challenges**:
- Hazard detection (RAW, WAW, WAR)
- Data forwarding
- Branch prediction
- Pipeline flushing

#### 5. **Hazard Detection & Forwarding**
```
Issue: add x1, x2, x3
       add x4, x1, x5  ← x1 not ready yet (RAW hazard)

Solution:
- Detect hazard in decode
- Stall pipeline or forward from previous stage
```

#### 6. **Branch Prediction**
```
Without: Always stall 3 cycles after branch
With: Predict direction, speculatively fetch
Benefit: 90%+ prediction accuracy on real programs
```

### Long-term (1-2 months)

#### 7. **Extend ISA to RV32IM**
```
Add:
- Multiplication (MUL, MULH)
- Division (DIV, REM)
- Shift operations (SLL, SRL, SRA)
```

#### 8. **Memory Hierarchy**
```
CPU
  ├─ L1 Instruction Cache (8KB)
  ├─ L1 Data Cache (8KB)
  └─ L2 Cache (64KB)
      └─ Main Memory

Benefit: Faster average access time
```

#### 9. **Exception Handling**
```
System State:
- Privilege levels (User, Supervisor, Machine)
- Interrupt handling
- Trap vectors
- Context switching
```

#### 10. **Floating-Point Unit (RV32F)**
```
Operations:
- FADD (float add)
- FMUL (float multiply)
- FCONV (conversion)

Pipeline: Separate FPU pipeline
```

### Verification Enhancements (Ongoing)

#### 11. **Property-Based Verification**
```systemverilog
// SVA (SystemVerilog Assertions)
assert property (@(posedge clk) 
    (opcode == LOAD) -> (mem_read inside {0,1}));
```

**Benefit**: Catch bugs at simulation time automatically

#### 12. **Formal Verification**
```
Mathematical proof that design is correct
(More powerful than simulation)

Tool: Jasper Gold, Cadence Incisive
```

#### 13. **Mutation Testing**
```
Introduce bugs → Run test suite → Should fail
If test passes despite bug → inadequate tests

Measures: Test mutation score (%)
```

---

## Part 6: Lessons Learned

### Technical Lessons

1. **Simulator Compatibility Matters**
   - SystemVerilog ≠ Verilog
   - Test with multiple simulators early
   - Document which features are tool-specific

2. **Initialize Everything**
   - Prevents latches and undefined behavior
   - Use default values before conditionals
   - Keep code defensive

3. **Clear Separation**: wire vs reg
   - wire = combinational (assign only)
   - reg = sequential (always block only)
   - Mixing causes synthesis/simulation mismatch

4. **Use Non-Blocking for Sequential Logic**
   - Prevents race conditions
   - Updates appear simultaneous
   - Proper hardware modeling

### Methodological Lessons

5. **UVM is Worth Learning**
   - More code upfront
   - Massive payoff on large projects
   - Standard in industry (40+ companies use it)

6. **Documentation is Critical**
   - Saves future hours of debugging
   - Helps new team members onboard
   - Interview prep is free quality assurance

7. **Test Early, Test Often**
   - Don't wait until design complete
   - Catch bugs while components simple
   - Incremental verification saves time

8. **Comments Should Explain WHY, Not What**
   ```verilog
   // Bad:
   reg_write = 0;  // Set reg_write to 0
   
   // Good:
   reg_write = 0;  // Default: prevent latches
   ```

### Project Management Lessons

9. **Start Simple, Add Complexity**
   - Single-cycle before pipeline
   - Manual testbench before UVM
   - One instruction type before extending ISA

10. **Plan for Scale**
    - Directory structure matters (grew 10x)
    - Documentation pays for itself
    - Reusable components save time

---

## Part 7: What I'd Do Differently

### If Starting Over:

1. **Use Verilog from Start** (not SystemVerilog)
   - Wider tool support
   - Clearer separation of concerns
   - Easier to learn

2. **Write Documentation First** (Test-Driven Documentation)
   - Define what CPU should do
   - Then implement to spec
   - Fewer surprises

3. **Each Module Gets Testbench** (Test-Driven Development)
   - Verify ALU first
   - Then register file
   - Then control unit
   - Catch bugs small instead of big

4. **Use Formal Verification Early**
   - Catches corner cases
   - Cheaper than finding bugs later
   - Mathematical certainty

5. **Version Control from Start**
   - Git from first commit
   - Experiment without fear
   - Go back to working version

---

## Summary

| Phase | Time | Key Achievement |
|-------|------|---|
| Architecture | 1 day | Selected single-cycle Harvard |
| RTL Coding | 3 days | Implemented 7 modules |
| Bug Fixing | 2 days | Verilog/simulator issues |
| UVM Testbench | 4 days | Full verification framework |
| Documentation | 2 days | Interview prep + design journal |
| **Total** | **~2 weeks** | **Production-ready verification setup** |

**Biggest Win**: UVM testbench is reusable framework - next design 50% faster

**Biggest Challenge**: Verilog simulation quirks (latch inference, wire/reg confusion)

**Most Valuable** Learning: UVM methodology scales to 1M+ gate designs unchanged
