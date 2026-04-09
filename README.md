# Verification_v2 Usage

## Current status
- Phase 1 is effectively completed at LSU unit level.
- Phase 2 now has documentation and a UVM scaffold, while SimX/WSL execution is still pending.
- Detailed tracking: `docs\phase_status.md`

## External dependency
- This repository is not fully standalone.
- It depends on the external Vortex RTL source tree, referenced by relative paths in `vortex_lsu_slice_stub.f` and `vortex_lsu_slice_stub_uvm.f`.
- Compilation will fail if the Vortex folder is not present in the expected relative location.

## Expected folder layout
```text
<parent>\
├── LSU_Block_GP\                 <- this repository
└── vortex-master\
    └── vortex-master\
        └── hw\rtl\...
```

## Setup note
- The file lists currently expect Vortex here: `../../vortex-master/vortex-master/`
- If you clone only this repository without the Vortex folder beside it, the testbenches will not compile.
- This repository contains the verification environment, scripts, documents, and local copied DUT-related files, but not the full upstream Vortex source tree.

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
