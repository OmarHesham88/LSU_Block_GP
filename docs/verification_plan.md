# Verification Plan (VX_lsu_slice v2)

## Scope
- Unit-level verification of `VX_lsu_slice` behavior through `execute_if`, `result_if`, and `lsu_mem_if`.
- Independent workspace: no dependency on old `Verification` local files.

## Features Covered
- Load/store operations: `LB/LBU/LH/LHU/LW/SB/SH/SW`.
- Fence operation testing (`INST_LSU_FENCE`) in directed and random traffic.
- Byte/halfword/word formatting and sign/zero extension.
- Lane sweep across all LSU lanes.
- Ready/valid handshake checks.
- Random latency and request backpressure in memory model.

## Test Strategy
- Directed corner tests:
  - Basic known-value load/store sequences.
  - Sign-extension edges (`0x80`, `0x8001`, `0xFF`).
  - Boundary addresses near memory range end.
  - Lane-sweep directed sequences.
  - Fence-before/after access sequences.
- Constrained-random tests:
  - Random operation mix and random lane.
  - Aligned random addresses.
  - Random data and long sequences.
  - Random fence injection.
- Negative test:
  - Dedicated misalignment expected-fail testbench.

## Checkers
- Scoreboard compares observed load data to reference memory model.
- Handshake stability checks and non-empty mask checks.
- Pending-load queue consistency check at test end.

## Coverage
- Operation type bins (including fence).
- Lane bins.
- Store/load split bins.
- Address alignment bins.
- Crosses: op x lane, store/load x op.

## Pass Criteria
- `wrong_count == 0`.
- No assertion/checker errors in main regression.
- Functional coverage (`issue_cov`) >= 85%.
- Regression seeds pass with no failures.
- Misalignment negative test detects violation.
