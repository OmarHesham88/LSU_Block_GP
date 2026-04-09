# Phase Status

## Phase 1: Foundation and Core Verification
- `Implemented`: constrained-random LSU unit-level testbench in `tb/tests/vx_lsu_slice_tb_v2.sv`
- `Implemented`: reference scoreboard in `tb/pkg/lsu_scoreboard.sv`
- `Implemented`: randomized memory model in `models/lsu_mem_model_rand.sv`
- `Implemented`: regression automation in `scripts/run_regression.ps1`
- `Implemented`: negative misalignment test in `tb/tests/vx_lsu_slice_tb_misaligned_neg.sv`
- `Evidence`: passing logs in `out/` and summary CSV in `out/regression_summary.csv`
- `Partial`: repository is organized and versionable, but this folder is currently not a Git repository root
- `Outside repo scope`: studying Vortex references is a documentation/research activity, not something provable from code alone

## Phase 2: Full Synthesis and System Modeling
- `Implemented`: verification plan in `docs/verification_plan.md`
- `Implemented`: signoff criteria in `docs/signoff_criteria.md`
- `Implemented`: system-model and interface architecture document in `docs/system_model.md`
- `Implemented`: UVM scaffold in `tb/uvm/lsu_uvm_pkg.sv` with separate file list `vortex_lsu_slice_stub_uvm.f`
- `Not implemented yet`: real SimX-based execution and regression under Linux/WSL
- `Not implemented yet`: full-chip or subsystem-level model beyond the LSU slice abstraction
- `Not implemented yet`: synthesis-clean RTL validation flow

## Overall Assessment
- The project is going fine.
- Phase 1 is substantially complete for the LSU slice unit.
- Phase 2 is now structurally prepared, but some items are still design-stage only and not yet executed end-to-end.
