# Verification Plan (VX_lsu_slice v2)

## Scope

This plan covers unit-level verification of the Vortex `VX_lsu_slice` block. The block is verified through three main interfaces:

- `VX_execute_if`: core-side LSU request input.
- `VX_lsu_mem_if`: memory-side request/response interface.
- `VX_result_if`: load result and completion output.

The goal is to prove that the LSU slice correctly accepts load/store/fence operations, generates valid memory transactions, handles memory-side latency and backpressure, and returns correctly formatted load results.

## Verification Approach

The environment uses directed tests, constrained-random tests, a randomized memory model, assertions/checkers, and a reference scoreboard.

- Directed tests cover known corner cases with predictable expected results.
- Random tests increase coverage across operation type, lane, address, data, and timing combinations.
- The memory model stresses the DUT with latency, backpressure, outstanding operations, and optional out-of-order responses.
- The scoreboard keeps a reference memory image and compares observed load data against expected data.
- Protocol checks monitor ready/valid behavior and illegal request conditions.

## Tests Used

### Directed Basic Load/Store Test

- Why: establishes basic LSU datapath correctness before stressing corner cases.
- What: stores known values, loads them back, and checks the returned data.
- How: directed requests are driven into `VX_execute_if`; `lsu_mem_model_rand.sv` responds through `VX_lsu_mem_if`; the scoreboard checks `VX_result_if`.

### Sign and Zero Extension Test

- Why: byte and halfword loads are common sources of bugs because signed and unsigned load formatting differ.
- What: checks `LB`, `LBU`, `LH`, and `LHU` using edge values such as `0x80`, `0xFF`, and `0x8001`.
- How: directed stores initialize memory, then directed loads verify sign-extended or zero-extended returned values.

### Store Formatting and Byte-Lane Test

- Why: stores must update only the intended byte or halfword lanes without corrupting neighboring bytes.
- What: checks `SB`, `SH`, and `SW` formatting across offsets and lanes.
- How: store operations update the memory model and scoreboard reference image, then later loads confirm the stored contents.

### Lane Sweep Test

- Why: lane-index bugs may not appear if only lane 0 is exercised.
- What: repeats load/store operations across all LSU lanes.
- How: directed sequences iterate through the lane field and compare each lane result with the scoreboard.

### Boundary Address Test

- Why: accesses near memory-range boundaries can expose indexing or address-calculation mistakes.
- What: verifies legal accesses near the edge of the model memory range.
- How: directed addresses are selected near boundary regions and checked by the scoreboard.

### Fence Operation Test

- Why: fence traffic affects ordering/protocol behavior and should be verified explicitly.
- What: injects `INST_LSU_FENCE` into directed and random traffic.
- How: the UVM/testbench flow observes fence requests and confirms that normal LSU traffic remains protocol-correct.

### Constrained-Random Traffic Test

- Why: directed tests do not cover enough combinations of op type, lane, address, data, and timing.
- What: generates mixed aligned loads, stores, lanes, data values, and occasional fences.
- How: randomized sequences drive many transactions while the scoreboard and checkers validate behavior.

### Backpressure and Latency Stress Test

- Why: the LSU must work when the memory side stalls or delays responses.
- What: applies randomized request backpressure and randomized response latency.
- How: `models/lsu_mem_model_rand.sv` controls ready/valid timing and delayed response scheduling.

### Outstanding and Response-Reordering Stress Test

- Why: bugs often appear when multiple requests are in flight.
- What: allows multiple outstanding operations and optional out-of-order memory responses.
- How: the memory model queues responses and the scoreboard tracks pending loads by UUID.

### Handshake Protocol Check

- Why: data correctness is not enough if ready/valid protocol is violated.
- What: checks stable request/response behavior and illegal empty-mask cases.
- How: assertions and procedural checks observe `execute_if`, `lsu_mem_if`, and `result_if`.

### Negative Misalignment Test

- Why: illegal/misaligned accesses should be detected instead of silently passing.
- What: intentionally drives a misaligned access and expects a violation.
- How: `tb/tests/vx_lsu_slice_tb_misaligned_neg.sv` runs as an expected-fail negative test.

## Regression Explanation

Regression means running the same verification environment many times with different random seeds. This gives better confidence than one simulation because each seed creates a different random sequence of operations, lanes, addresses, data, memory latency, and backpressure.

The regression script is:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\run_regression.ps1 -Seeds 20 -NumOps 500 -StartSeed 1
```

Expected outputs:

- `out\seed_<seed>.log`: detailed log for each seed.
- `out\regression_summary.csv`: pass/fail summary for all seeds.

The suggested minimum regression is 20 seeds with 500 operations per seed.

## Latest Regression Result

The standard regression was run from Command Prompt using the script above with 20 seeds and 500 random operations per seed.

Result:

```text
Seeds passed: 20 / 20
Seeds failed: 0
Scoreboard failures: 0 for every seed
Issue coverage: 91.67% for every seed
```

The detailed evidence is stored in `out\seed_1.log` through `out\seed_20.log`, with the complete summary in `out\regression_summary.csv`.

## Latest UVM Result

The current UVM scaffold compile path was checked with:

```text
vlog -sv -mfcu -f .\vortex_lsu_slice_stub_uvm.f
```

Result:

```text
Errors: 0
Warnings: 1
```

The warning is from a Vortex macro redefinition in the external RTL headers.

The UVM smoke/main test was checked with:

```text
vsim -c lsu_uvm_smoke_top -do "run -all; quit -f"
```

Result:

```text
scoreboard_pass=151
scoreboard_fail=0
fences=9
pending=0
UVM_ERROR=0
UVM_FATAL=0
```

This means the current UVM flow compiles and runs successfully for the checked smoke/main scenario.

The standard testbench was also run with the enabled assertion module for seed 1 and 500 operations. It completed with 537 scoreboard passes, zero scoreboard failures, 91.67% coverage, and no assertion errors.

## Results Expected From Full Signoff

To claim unit-level LSU signoff, the project should show:

- Directed tests pass.
- Random regression passes for the agreed seed count.
- `wrong_count == 0`.
- No assertion/checker errors.
- Functional coverage target is reached, currently planned as `issue_cov >= 85%`.
- Negative misalignment test reports the expected violation.

## Covered

The current verification plan and implemented environment cover:

- Load operations: `LB`, `LBU`, `LH`, `LHU`, `LW`.
- Store operations: `SB`, `SH`, `SW`.
- Byte, halfword, and word data formatting.
- Sign and zero extension.
- Store byte-lane behavior.
- Lane sweep across all LSU lanes.
- Constrained-random aligned accesses.
- Random memory latency.
- Request backpressure.
- Multiple outstanding memory responses.
- Optional response reordering in the memory model.
- Fence injection.
- Scoreboard-based data checking.
- Pending-load tracking.
- Negative misalignment detection.

## Not Covered Yet

The current scope does not yet cover:

- Full-chip Vortex integration.
- Full cache hierarchy behavior.
- Arbitration with other core-side blocks.
- Synthesis-clean RTL validation.
- Complete UVM coverage database/signoff.
- Advanced assertion/checker suite beyond the current checks.
- Software-driven co-simulation connected directly to this local UVM testbench.

## Future Work

- Add more SystemVerilog assertions for ready/valid stability, mask correctness, response matching, and reset behavior.
- Expand protocol checkers for memory request/response ordering and illegal transaction detection.
- Build a fuller UVM structure with reusable agent, sequencer, driver, monitor, scoreboard, checker, and coverage components.
- Add functional coverage collection and coverage reporting for operation type, lane, load/store split, alignment, fence traffic, and cross coverage.
- Run the full regression again after each significant RTL, testbench, memory-model, or assertion change.
- Connect the unit-level LSU verification flow to broader SimX/software-level workloads.
- Add subsystem or full-chip integration tests around the LSU path.
- Validate the RTL with a synthesis-clean flow.
