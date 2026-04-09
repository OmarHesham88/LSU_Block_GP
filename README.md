# Verification_v2 Usage

## Current status
- Phase 1 is effectively completed at LSU unit level.
- Phase 2 now has documentation and a UVM scaffold, while SimX/WSL execution is still pending.
- Detailed tracking: `docs\phase_status.md`

## One test run
- `powershell -ExecutionPolicy Bypass -File .\scripts\run_one.ps1 -Seed 1 -NumOps 500`

## Multi-seed regression
- `powershell -ExecutionPolicy Bypass -File .\scripts\run_regression.ps1 -Seeds 20 -NumOps 500 -StartSeed 1`

## Negative misalignment expected-fail test
- `powershell -ExecutionPolicy Bypass -File .\scripts\run_negative_misaligned.ps1`

## UVM scaffold compile path
- `vlog -sv -mfcu -f .\vortex_lsu_slice_stub_uvm.f`
- `vsim -c lsu_uvm_smoke_top -do "run -all; quit -f"`

## Manual simulator commands
1. `vlog -sv -f .\vortex_lsu_slice_stub.f`
2. `vsim -c lsu_slice_tb_v2 -do "do run.do"`

## Outputs
- Per-seed logs in `out\seed_<seed>.log`
- Regression summary in `out\regression_summary.csv`
- Negative-test log in `out\misaligned_neg.log`
- Phase/system documents in `docs\`
