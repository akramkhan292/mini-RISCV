# RISC-V Processor - Interview Preparation Guide

This document contains detailed explanations and interview questions for each component of the RISC-V processor design.

---

## Table of Contents
1. [ALU (Arithmetic Logic Unit)](#alu)
2. [Register File](#register-file)
3. [Program Counter (PC)](#program-counter)
4. [Control Unit](#control-unit)
5. [Instruction Memory](#instruction-memory)
6. [Data Memory](#data-memory)
7. [Top-Level Core](#top-level-core)
8. [Architecture Concepts](#architecture-concepts)

---

## ALU (Arithmetic Logic Unit)

**File**: `rtl/alu.v`

### What is it?
The ALU performs arithmetic and logic operations requested by the control unit. It combines two 32-bit operands using a 4-bit control signal to produce a result.

### Interview Questions

**Q1: Why use `always @(*)` instead of specifying exact dependencies?**
```
A: always @(*) automatically detects all RHS dependencies.
   Using explicit sensitivity lists can miss dependencies - @(*) is safer.
   Example: always @(a, b, alu_ctrl) might miss result as dependency.
```

**Q2: Why use blocking assignment (=) instead of non-blocking (<=)?**
```
A: This is COMBINATIONAL logic (no clock).
   Blocking (=): evaluates immediately → correct for combinational
   Non-blocking (<=): updates AFTER block → gives stale values
   
   Example of problem with <=:
   always @(*) begin
       result <= a + b;
       another_var <= result;  // Uses OLD result!
   end
   
   With =, values update immediately (correct).
```

**Q3: Why is `zero` a wire and `result` is a reg?**
```
A: result: driven by always block (procedural) → must be reg
   zero: driven by assign (combinational) → must be wire
   
   Rule: Wire = combinational connections
         Reg = procedural assignments or state
```

**Q4: What happens if alu_ctrl is undefined?**
```
A: The default case handles it → result = 0
   This prevents undefined behavior and latches.
```

**Q5: How would you extend the ALU with more operations?**
```
A: Add more cases to the case statement:
   localparam MUL = 4'b0100;  // Multiply
   ...
   case (alu_ctrl)
       MUL: result = a * b;
   endcase
   
   Limited by alu_ctrl width: 4 bits = 16 possible operations.
   Need more bits to support more operations (5 bits = 32 ops).
```

---

## Register File

**File**: `rtl/register_file.v`

### What is it?
32×32-bit storage array. 32 general-purpose registers (x0-x31), each holding a 32-bit value. Supports simultaneous read of two registers and write to one register.

### Memory Organization
```
reg [31:0] regfile [31:0]
    ↑                 ↑
    Each register     32 registers (x0-x31)
    is 32 bits        need 5-bit address

2^5 = 32 → need 5 bits to address 32 registers
Each register holds 2^32 = 4.3 billion different values
```

### Interview Questions

**Q1: Why two read ports but only one write port?**
```
A: Most instructions have TWO operands (e.g., add x5, x1, x2).
   Need to read x1 AND x2 simultaneously → two read ports.
   Only one write per cycle (one result per instruction).
   
   Multi-port memory (simultaneous read/write) is expensive.
   Single-port write is sufficient for one instruction per cycle.
```

**Q2: Why is read asynchronous but write synchronous?**
```
A: Read: No state change → combinational (instant)
   Write: Changes state → sequential (must synchronize with clock)
   
   This allows:
   - Reads to be available immediately (combinational)
   - Writes to be atomic (complete at clock edge)
   - Prevents race conditions
```

**Q3: Why check `if(rd != 0)` before writing?**
```
A: x0 is hardwired to zero in RISC-V architecture.
   Any write to x0 would break semantics.
   
   Example: add x0, x1, x2
   Should NOT change x0 → always remains 0.
   
   This check prevents accidental modification of x0.
```

**Q4: What's the read-write latency?**
```
A: Read: Combinational (0 cycle delay) - happens instantly
   Write: Synchronous (1 cycle) - happens at clock edge
   
   Can read and write same cycle?
   Yes, because:
   - Read happens combinationally (before clock edge)
   - Write happens at clock edge (after read)
   - External sequencing ensures correct order
```

**Q5: Why is regfile declared as 'reg' not 'wire'?**
```
A: Register file HOLDS STATE (memory).
   Only 'reg' can maintain values across clock cycles.
   'wire' is just combinational connection between modules.
   
   Array type in Verilog:
   reg [31:0] mem [255:0]  ← Can hold state
   wire[31:0] net [255:0]  ← NOT valid (wires can't be arrays)
```

---

## Program Counter (PC)

**File**: `rtl/pc_rtl.v`

### What is it?
The PC stores the memory address of the current instruction. On each clock cycle, it updates to the address of the next instruction to fetch.

### Critical Role
- **Fetch Stage**: Uses PC to read instruction from memory
- **Increment**: Normally PC += 4 (RISC-V instructions are 4 bytes)
- **Branching**: On branch, PC = branch_target

### Interview Questions

**Q1: What is the Program Counter and why is it critical?**
```
A: PC = Current instruction address
   Answers: "What instruction is being executed right now?"
   
   Why critical:
   - Controls WHAT instruction to fetch
   - Without PC, processor doesn't know sequence of execution
   - All instruction flow depends on PC
```

**Q2: Why increment by 4, not 1?**
```
A: RISC-V instructions are 32 bits = 4 bytes.
   Memory is byte-addressed (8-bit units).
   
   Instruction addresses:
   0x00000000 → byte 0-3   (first instruction)
   0x00000004 → byte 4-7   (second instruction)
   0x00000008 → byte 8-11  (third instruction)
   
   PC increments by 4 to reach next 4-byte instruction.
```

**Q3: Why `always @(posedge clk or posedge rst)`?**
```
A: Two events trigger the block:
   1. posedge clk: Normal operation (update PC)
   2. posedge rst: Emergency reset (clear PC)
   
   Why both?
   - Clock: Synchronizes with processor operation
   - Reset: Asynchronous reset (don't wait for clock)
           Ensures processor always starts clean
```

**Q4: How does reset work?**
```
A: When rst=1:
   - PC immediately becomes 0 (asynchronous)
   - Does NOT wait for clock edge
   - Fetch stage will read instruction at address 0
   
   Why asynchronous?
   - Need fast recovery from error
   - Clock may be stopped
   - Ensures predictable initialization
```

**Q5: Blocking vs Non-blocking assignment?**
```
A: pc = next_pc    (blocking) - WRONG
   pc <= next_pc   (non-blocking) - CORRECT
   
   Why?
   Non-blocking (<=):
   - Schedules update for end of cycle
   - All RHS evaluations complete first
   - Prevents race conditions
   
   Sequential logic ALWAYS uses non-blocking.
```

---

## Control Unit

**File**: `rtl/control_unit.v`

### What is it?
The "brain" of the processor. Decodes instruction opcodes and generates control signals that configure every other component (ALU, memory, registers).

### Control Signals Generated
```
reg_write   : Write result to register file?
mem_read    : Read from memory?
mem_write   : Write to memory?
alu_src     : ALU operand 2 = register (0) or immediate (1)?
branch      : Is this a branch instruction?
alu_ctrl[3:0]: Which ALU operation?
```

### Interview Questions

**Q1: What is the role of the Control Unit?**
```
A: Decodes instruction → generates control signals
   Every component follows these signals:
   
   Instruction (32 bits) → Control Unit → Control Signals (10+ bits)
                              ↓
                      Affects: ALU, Memory, Registers, PC
   
   Without control unit, datapath wouldn't know what to do.
```

**Q2: Why BOTH func3 and func7 additional to opcode?**
```
A: RISC-V uses hierarchical encoding:
   opcode (7 bits): Instruction category (R-type, I-type, Load, etc.)
   func3 (3 bits):  Operation group (arithmetic vs logic)
   func7 (7 bits):  Exact operation (ADD vs SUB)
   
   Example: Distinguishing ADD vs SUB
   Both have opcode = 0110011 (R-type)
   Both have func3 = 000 (arithmetic)
   ADD:  func7 = 0000000
   SUB:  func7 = 0100000 ← Different!
   
   This encoding saves bits while supporting 100+ operations.
```

**Q3: Why are outputs declared as 'reg'?**
```
A: Outputs are driven by always @(*) block (procedure).
   Procedurally assigned signals → must be 'reg' type.
   
   Rule: if driven by always block → declare as reg
         if driven by assign → declare as wire
```

**Q4: What does `alu_src` control?**
```
A: Data path multiplexer:
   alu_src = 0: ALU operand 2 = rd2 (register value)
   alu_src = 1: ALU operand 2 = immediate (from instruction)
   
   Example:
   add x1, x2, x3  → alu_src = 0 (use x3 register)
   addi x1, x2, 10 → alu_src = 1 (use immediate 10)
   lw x1, 0(x2)    → alu_src = 1 (use immediate offset)
```

**Q5: Why initialize ALL outputs at start of block?**
```
A: Prevents LATCHES (unwanted storage).
   
   Without initialization (WRONG):
   always @(*) begin
       if(condition) reg_write = 1;
       // What if condition is false?
       // Verilog infers storage → unwanted latch!
   end
   
   With initialization (CORRECT):
   always @(*) begin
       reg_write = 0;  // Default
       if(condition) reg_write = 1;
       // Now no latch - reg_write is definitely 0 or 1
   end
```

**Q6: How to support more instructions?**
```
A: Add more cases:
   1. Add new opcode for new instruction type
   2. Add generation of required control signals
   3. Update ALU/memory/register logic if needed
   
   Example: Adding multiply instruction
   localparam MUL = 7'b0110111;
   ...
   case (opcode)
       MUL: begin
           reg_write = 1;
           alu_src = 0;
           alu_ctrl = 4'b1000;  // New ALU operation
       end
   endcase
   
   But limited by RISC-V ISA specification.
```

---

## Instruction Memory

**File**: `rtl/mem.v`

### What is it?
Read-only storage for program code (instructions). Processor reads instructions using PC as address. In simulation, loaded from file.

### Designer Rationale
```
Why read-only?
- Program is fixed at startup
- No self-modifying code allowed
- Simpler hardware
- Security benefit (code can't be changed)
```

### Address Translation: Byte → Word
```
Problem: PC addresses bytes, but memory has 32-bit words

RISC-V byte addressing:
0x00000000 → instruction 0
0x00000004 → instruction 1  (4 bytes later)
0x00000008 → instruction 2

Memory is word-indexed:
mem[0] = instruction at bytes 0-3
mem[1] = instruction at bytes 4-7
mem[2] = instruction at bytes 8-11

Solution: addr[9:2]
Example: PC = 0x00000008 = 0b...00001000
         addr[9:2] = 0b0010 = 2 decimal
         mem[2] ✓

Why [9:2]?
- [1:0] = 00 always (4-byte aligned instructions)
- [9:2] = bits 2-9 (8 bits = 256 addresses)
- [31:10] = upper bits (ignored in simulation)
```

### Interview Questions

**Q1: Why instruction memory read-only?**
```
A: Benefits:
   1. Simpler hardware (no write logic)
   2. Faster access (no write conflicts)
   3. Security (prevent code injection)
   4. Predictable execution (can't modify instructions)
   
   Self-modifying code issues:
   - Cache coherency problems
   - Security vulnerabilities
   - Compiler optimization issues
   
   Modern systems prevent execution from writable memory.
```

**Q2: Why use addr[9:2] instead of full address?**
```
A: RISC-V memory hierarchy:
   
   Byte addressing (programmer view):
   - Each byte has address
   - Variables can span multiple bytes
   - PC is byte-addressed
   
   Word addressing (hardware view):
   - Instructions are 32-bit words
   - Each word is stored as one array element
   - Lower 2 bits always 00 for instructions
   
   Conversion:
   addr[31:0]  → byte address from PC
   addr[9:2]   → word index (remove byte offset)
   
   Example:
   PC = 0x0000000C (12 decimal) = 0b...00001100
   addr[9:2] = 0b0011 (3 decimal)
   mem[3] = instruction at byte address 12
```

**Q3: What does `$readmemh` do?**
```
A: Loads program from hex file into memory array.
   
   Syntax: $readmemh("filename", memory_array)
   
   File format (program.mem):
   FFFFFFFF
   00000000
   12345678
   ...
   
   Maps to:
   mem[0] = 0xFFFFFFFF
   mem[1] = 0x00000000
   mem[2] = 0x12345678
   ...
   
   Used in simulation only (not synthesizable).
   Real hardware: ROM burning, bootloader, or network loading.
```

**Q4: Why combinational read (assign)?**
```
A: Instructions must be available same cycle as PC changes.
   
   Combinational read (CORRECT):
   - Zero delay
   - Instruction available immediately
   - Next cycle can decode instruction
   
   Sequential read (WRONG):
   - 1-cycle delay
   - Would need extra pipeline stage
   - Reduces performance
   
   Real CPUs: Instruction cache (L1 I-cache) acts like this.
```

**Q5: Can we expand beyond 256 words?**
```
A: Current design:
   reg [31:0] mem [255:0]  = 256 words = 1KB
   addr[9:2]              = 10-bit index
   
   To expand:
   reg [31:0] mem [1023:0]  = 1024 words = 4KB
   addr[11:2]               = 12-bit index
   
   Trade-offs:
   + More program storage
   - Slower simulation
   - More memory used
   
   Real CPUs: 64KB-1MB instruction caches
             4GB-128GB main memory
```

---

## Data Memory

**File**: `rtl/data_mem.v`

### What is it?
Read-write storage for program data. Updated during execution. Accessed by Load (LW) and Store (SW) instructions.

### Key Differences from Instruction Memory
```
Instruction Memory:
- Read-only
- No reset (fixed at startup)
- Combinational read

Data Memory:
- Read/write
- Implicitly initialized to 0
- Combinational read, synchronous write
```

### Interview Questions

**Q1: What's the difference between instruction and data memory?**
```
A: Different purposes:
   Instruction: Read-only, fixed program code, sequential access
   Data:        Read/write, variable values, random access
   
   Architecture styles:
   
   HARVARD (this design):
   ✓ Separate buses → simultaneous fetch & execute
   ✓ Faster (no bus contention)
   ✓ Optimizable independently
   ✗ More complex
   
   VON NEUMANN:
   ✓ Unified memory (simpler)
   ✓ Flexible (code can modify itself)
   ✗ Fetch/execute conflicts
   ✗ Slower
   
   Most modern CPUs use Harvard internally (caches).
```

**Q2: Why combinational read but synchronous write?**
```
A: Read: No state change → combinational
         Can access data immediately
         
   Write: Changes stored state → synchronous
          Must coordinate with clock
          Prevents race conditions
          Ensures atomic updates
   
   Timing:
   Same cycle can read old value and write new value:
   - Read happens combinationally (before clock)
   - Write happens at clock edge (after read)
```

**Q3: Why `addr[9:2]` here too?**
```
A: Same byte-to-word address translation as instruction memory.
   
   Load instruction: lw x1, 0(x2)
   - x2 holds base address (byte-addressed)
   - 0 is offset
   - ALU computes: x2 + 0 = address
   - addr[9:2] extracts 32-bit word
   
   Store instruction: sw x1, 0(x2)
   - Same address translation
   - But write instead of read
```

**Q4: Why output 0 when mem_read=0?**
```
A: Prevents undefined value on data bus.
   
   assign data_out = (mem_read) ? mem[addr[9:2]] : 32'd0;
   
   When not reading:
   - Prevent garbage values
   - Prevent Hi-Z conflicts
   - Known state for debugging
   
   Real hardware uses Tri-state or MUX for multiple readers.
```

**Q5: How are memory conflicts handled?**
```
A: This single-port design prevents conflicts:
   - Can't read and write simultaneously
   - Can't have multiple readers/writers
   - One instruction per cycle
   
   Real CPUs handle conflicts:
   - Multi-port memories (complex, expensive)
   - Cache coherency protocols
   - Memory arbitration logic
   - Lock/wait mechanisms
   
   Rule: Design prevents conflicts by design.
```

---

## Top-Level Core

**File**: `rtl/riscv_core.v`

### What is it?
Integrates all components (ALU, registers, memory, control unit, PC) into a complete processor.

### Data Flow

```
Fetch:
PC → Instruction Memory → Instruction

Decode:
Instruction → Opcode/Func Fields → Control Unit → Control Signals

Execute:
Registers → ALU → Result
           Immediate ↗
           
Memory:
Result → Data Memory → Data

Writeback:
Data or Result → Register File

PC Update:
Control + Zero Flag → Next PC
```

### Interview Questions

**Q1: How does instruction flow through the pipeline?**
```
A: Single-cycle pipeline (no actual pipelining):

Cycle N:
1. Fetch: PC = N → Instruction Memory → get instruction
2. Decode: instruction → Control Unit → control signals
3. Register: rs1, rs2 → Register File → rd1, rd2
4. Execute: rd1, rd2 → ALU → result
5. Memory: result → Data Memory → data_out (if load)
6. Writeback: result/data_out → Register File
7. PC Update: PC_next = result (if branch) or PC+4

Cycle N+1:
PC = PC_next → repeat

Real processors pipeline these stages separately.
```

**Q2: How are immediate values extracted?**
```
A: Different instruction formats:
   
   I-type: immediate = SignExtend( instr[31:20] )
   S-type: immediate = SignExtend( {instr[31:25], instr[11:7]} )
   B-type: immediate = SignExtend( {instr[31], instr[7], ...} )
   
   Why SignExtend?
   - Allows negative immediates
   - Preserves arithmetic
   
   Example: -1 in 12 bits = 0xFFF
            SignExtend to 32 bits = 0xFFFFFFFF
            Correct negative value
   
   This design supports basic I-type for simplicity.
```

**Q3: How does branching work?**
```
A: Branch conditions:
   
   beq x1, x2, target:
   1. Control: branch=1, alu_ctrl=SUB
   2. ALU: computes x1 - x2
   3. Result: if zero → equal
   
   PC Update:
   if (branch && zero)
       next_pc = pc + immediate
   else
       next_pc = pc + 4
   
   How does ALU set zero flag?
   - Computes x1 - x2
   - If x1 == x2, result = 0
   - zero = (result == 0)
   - Control can check zero flag
```

**Q4: What prevents data/instruction conflicts?**
```
A: Separate memory systems (Harvard architecture):
   
   Instruction path:
   PC → Instruction Memory → Instruction
   
   Data path:
   Address → Data Memory ↔ Register File
   
   No contention because separate buses.
   
   Real CPUs:
   - Single memory with separate caches
   - Caches handle conflicts
   - Complex arbitration logic
```

**Q5: How would you add pipelining?**
```
A: Current: Single-cycle (no actual pipeline)
   
   5-stage pipeline:
   Stage 1: Fetch        (PC → Instruction)
   Stage 2: Decode       (Instruction → Control)
   Stage 3: Execute      (ALU operation)
   Stage 4: Memory       (Load/Store)
   Stage 5: Writeback    (Update Register)
   
   Implementation:
   - Add pipeline registers between stages
   - Hold intermediate results
   - Forward results to prevent data hazards
   - Handle branch penalties
   
   Benefits: 5x throughput improvement
   Costs: Hazards, stalls, complexity
```

---

## Architecture Concepts

### Wire vs Reg

**Wire**
- Combinational connections
- Driven by `assign` statement
- No storage
- Updated continuously
- Good for: Module connections, combinational outputs

**Reg**
- Procedurally assigned
- Driven by `always` block
- Can hold value
- Updated at specific times  (clock edges or blocking)
- Good for: Sequential logic, memory storage

**Rule**: Match declaration to usage
- Combinational logic → wire
- Sequential logic → reg
- Memory storage → reg
- Inputs → wire (or logic in SystemVerilog)
- Outputs → wire/reg depending on driving logic

### Blocking vs Non-Blocking

**Blocking (=)**
- Evaluates immediately and completely
- Next statement uses new value
- Use for: Combinational logic
```verilog
always @(*) begin
    result = a + b;
    another = result;  // Uses NEW result ✓
end
```

**Non-Blocking (<=)**
- Schedules update for end of cycle
- Next statement uses OLD value
- Use for: Sequential logic, always @posedge
```verilog
always @(posedge clk) begin
    result <= a + b;
    another <= result;  // Uses OLD result ✓
end
```

### Latches

**What is a latch?**
Unintended memory created when not all paths assign a value.

**Example (WRONG)**:
```verilog
always @(*) begin
    if (sel)
        out = a;
    // else missing → out holds old value (latch!)
end
```

**Prevention**:
1. Always assign default
2. Use complete case statements
3. Initialize all signals at start

**Good practice**:
```verilog
always @(*) begin
    out = 32'd0;  // Default
    if (sel)
        out = a;  // Override if needed
end
```

### Combinational vs Sequential

**Combinational**
- No clock involved
- Output depends only on current inputs
- Propagation delay only (nanoseconds)
- Examples: ALU, Multiplexers, Decoders
- Declaration: wire (driven by assign)
- Block type: always @(*)

**Sequential**
- Clock synchronized
- Output depends on inputs and past state
- 1 cycle delay minimum
- Examples: Registers, Counters, Memories
- Declaration: reg (state-holding)
- Block type: always @(posedge clk)

---

## Tips for Interview

### Be Prepared to Discuss:

1. **Architecture Choices**
   - Why Harvard (separate I/D memory)?
   - Why single-cycle?
   - Trade-offs vs pipelined/parallel designs

2. **Data Flow**
   - How does an instruction get executed?
   - What controls each component?
   - Where are bottlenecks?

3. **Hardware Principles**
   - Combinational vs sequential
   - Wire vs reg usage
   - Clock synchronization

4. **Extensions**
   - How to add more instructions?
   - How to add pipelining?
   - How to optimize?

5. **Real Implementations**
   - Relate to ARM, x86, MIPS
   - Discuss cache, branch prediction
   - Memory hierarchies

### Practice Explaining:

- Draw block diagrams
- Trace instruction execution
- Explain control signal generation
- Discuss timing and critical paths
- Compare with real processors

### Common Follow-up Questions:

- "How would you optimize X?"
- "What's the critical path?"
- "How would you debug Y?"
- "What if you had Z constraint?"
- "How does this relate to real CPUs?"

---

## Quick Reference

### Instruction Formats

**R-type** (Register-Register)
```
[31:25] func7    |  [24:20] rs2  |  [19:15] rs1  |  [14:12] func3  |  [11:7] rd  |  [6:0] opcode
```
Example: add x1, x2, x3

**I-type** (Register-Immediate)
```
[31:20] immediate  |  [19:15] rs1  |  [14:12] func3  |  [11:7] rd  |  [6:0] opcode
```
Example: addi x1, x2, 10

**S-type** (Store)
```
[31:25] offset[11:5]  |  [24:20] rs2  |  [19:15] rs1  |  [14:12] func3  |  [11:7] offset[4:0]  |  [6:0] opcode
```
Example: sw x1, 0(x2)

**B-type** (Branch)
```
[31:31] offset[12]  |  [30:25] offset[10:5]  |  [24:20] rs2  |  [19:15] rs1  |  [14:12] func3  |  [11:8] offset[4:1]  |  [7:7] offset[11]  |  [6:0] opcode
```
Example: beq x1, x2, target

### Register Names (ABI)
```
x0   zero   Hardwired zero
x1   ra     Return address
x2   sp     Stack pointer
x5   t0     Temporary
x10-x11 a0-a1  Function arguments / return values
```

### Key Opcodes
```
0110011   R-type (add, sub, and, or)
0010011   I-type (addi)
0000011   Load (lw)
0100011   Store (sw)
1100011   Branch (beq)
```

---

## UVM Testbench Architecture

**Project**: RISC-V Processor UVM Verification

### What is UVM?

**Universal Verification Methodology** is a standardized approach for:
- Creating **reusable** testbench components
- Automating **stimulus generation** (sequences)
- **Monitoring** and **capturing** outputs
- **Verifying** correct behavior (via scoreboards)

### Key UVM Components

#### 1. **Virtual Interface**
Bridge between testbench and DUT. Carries signals (prog_addr, prog_data, prog_we).

#### 2. **Sequence Item**
Transaction class defining instruction format (opcode, rd, rs1, rs2, funct3, funct7, imm).

#### 3. **Sequence**
Generates 5 random instructions with constraints:
- Valid opcode distribution: R-type (30%), I-type (30%), Load (20%), Store (10%), Branch (10%)
- Registers constrained: rd ∈ [1:31], rs1,rs2 ∈ [0:31]

#### 4. **Sequencer**
Built-in UVM component that queues items and distributes to driver on demand.

#### 5. **Driver**
Applies instructions to DUT:
- Encodes instruction using `instr_encoder()`
- Writes sequentially to program memory (addr +4 each cycle)
- Uses virtual interface to drive signals

#### 6. **Monitor**
Observes program writes:
- Detects when prog_we = 1
- Decodes instruction back to fields
- Sends captured transaction to scoreboard

#### 7. **Agent**
Connects sequencer ◄► driver, manages components.

#### 8. **Environment**
Container for agent, preparation for multiple agents.

#### 9. **Test**
Orchestrates simulation:
- Raise objection (keep simulation alive)
- Create sequence and start on sequencer
- Drop objection (end simulation)

### UVM Phases

```
build_phase   → Create components
├─ Create sequencer, driver, monitor
├─ Get virtual interface from config_db
└─ Register with factory

connect_phase → Connect ports
├─ Connect driver.seq_item_port ◄► sequencer.seq_item_export
└─ Monitor ready to capture

run_phase     → Execute test
├─ Sequence generates 5 items
├─ Sequencer queues items
├─ Driver applies to DUT sequentially
├─ Monitor captures outputs
└─ Continue until all objections dropped
```

### Interview Q&A: UVM

**Q1: Why Virtual Interface?**
```
A: Testbench = SystemVerilog, DUT = Verilog
   Virtual interface bridges the gap, enabling hierarchical access.
```

**Q2: Sequence vs Sequencer?**
```
A: Sequence = WHAT (user writes stimulus)
   Sequencer = HOW (UVM distributes items)
```

**Q3: Driver vs Monitor?**
```
A: Driver = APPLY stimulus (write signals)
   Monitor = OBSERVE outputs (read signals, never write)
```

**Q4: Why Constrained Randomization?**
```
A: Without constraints:
   - Random opcode might be invalid (not in RISC-V spec)
   - Random registers might violate CPU design
   
   With constraints:
   - Only valid instruction types generated
   - Registers within valid ranges
   - Better test quality and coverage
```

**Q5: Why raise/drop objection?**
```
A: raise_objection = "I'm running, don't stop simulation"
   drop_objection = "I'm done, simulation can finish"
   
   Prevents premature simulation termination.
```

---

## Summary

| Component | Purpose | Analogy |
|-----------|---------|---------|
| Sequence | WHAT to test | Recipe |
| Sequencer | Distributes items | Line manager |
| Driver | Applies to DUT | Worker |
| Monitor | Observes output | Quality checker |
| Agent | Groups components | Department |
| Environment | Manages agents | Factory |
| Test | Orchestrates all | Director |

**Key Points**:
- ✓ Components are **reusable** across projects
- ✓ Standardized **UVM methodology**
- ✓ Automatic **factory registration**, **copying**, **printing**
- ✓ Built-in **configuration database** for hierarchical settings
- ✓ **TLM ports** for safe transaction passing


