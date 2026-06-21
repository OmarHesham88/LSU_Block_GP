# System Model and Architecture (Phase 2)

## Goal

- documenting a system model for the Vortex execution-to-memory path.
- Show how the LSU slice fits into the larger Vortex architecture, not only the local unit testbench.
- Separate three views clearly:
- upstream Vortex architectural view
- this project's verification abstraction
- remaining gaps that are deferred to later phases

## Scope

- This document is centered on the load/store path, because the project target is `VX_lsu_slice`.
- It does not attempt to model every Vortex block in full microarchitectural detail.
- It focuses on the path from core-side issue into the memory-side request/response channel and back into writeback-visible completion.

## System-Level Vortex View

```text
Host software / runtime
        |
        v
 Simulator / execution backend
        |
        v
 +---------------------- Vortex accelerator ----------------------+
 |                                                                |
 |   Core / warp scheduler / execute stage                        |
 |                  |                                             |
 |                  v                                             |
 |             LSU request issue                                  |
 |                  |                                             |
 |                  v                                             |
 |             +-------------+                                    |
 |             | VX_lsu_slice|                                    |
 |             +-------------+                                    |
 |               |         |                                      |
 |               |         +-----> result / completion path       |
 |               |                                            ^   |
 |               v                                            |   |
 |         memory request path                                |   |
 |               |                                            |   |
 |               v                                            |   |
 |      cache / memory subsystem abstraction                  |   |
 |               |                                            |   |
 |               +-------------> memory responses ------------+   |
 |                                                                |
 +----------------------------------------------------------------+
```

## Core-to-Memory Connection of Interest

- The execute stage issues LSU operations.
- `VX_lsu_slice` converts those requests into memory transactions.
- The memory side may apply backpressure, latency, and response reordering depending on the surrounding subsystem.
- Returning load data is reformatted and forwarded into the result path seen by the core.
- This project verifies that connection at the LSU boundary, not the full upstream cache hierarchy.

## Unit Under Test

- DUT: `VX_lsu_slice`
- Local purpose: bridge core-side LSU issue traffic to memory-side transactions and return correctly formatted load results.
- Verification purpose: prove the LSU slice handles operation decoding, lane behavior, sign/zero extension, handshaking, and memory response integration correctly.

## Verification-Level Architecture Used in This Repository

```text
Directed / random stimulus
        |
        v
  VX_execute_if
        |
        v
   +-------------+
   | VX_lsu_slice|
   +-------------+
      |       |
      |       +-----------------> VX_result_if
      |                              |
      |                              v
      |                        monitor / scoreboard checks
      |
      +-------------------------> VX_lsu_mem_if
                                     |
                                     v
                         randomized memory subsystem model
```

## Interface Roles

- `VX_execute_if`: core-side issue interface used to inject LSU operations into the DUT.
- `VX_lsu_mem_if`: memory-side transaction interface used by the DUT to access the memory subsystem.
- `VX_result_if`: completion/writeback-visible interface used to observe returning load results.

## Repository Blocks Used for the System Model

- DUT wrapper and test connectivity are provided through the local file lists and testbench top.
- Stimulus source: task-driven and randomized sequences in the unit-level testbenches.
- Reference model: scoreboard memory image in `tb/pkg/lsu_scoreboard.sv`.
- Memory subsystem abstraction: `models/lsu_mem_model_rand.sv`.
- Observation path: `result_if` monitoring plus scoreboard comparison.
- UVM structural scaffold: `tb/uvm/lsu_uvm_pkg.sv`.

## Memory-Subsystem Abstraction

- The local memory model is intentionally abstract rather than a full Vortex cache/memory hierarchy.
- It accepts LSU requests through `VX_lsu_mem_if`.
- It can inject:
- request backpressure
- response latency
- multiple outstanding operations
- optional response reordering
- This abstraction is appropriate for Phase 2 because it stresses the exact LSU boundary under controllable conditions without requiring a complete full-chip model.

## Relation to SimX

- SimX validation was completed separately under WSL/Linux using the Vortex `vecadd` regression.
- That run proves the external Vortex toolchain and simulation flow are operational.
- The SimX run does not replace the LSU slice unit-level verification environment in this repository.
- Instead, it supports the architectural assumption that the broader Vortex execution flow is valid enough to use as a reference context for Phase 2 system modeling.

## Implemented Verification Behaviors

- Directed load/store formatting checks
- sign/zero extension checks
- lane sweep across all LSU lanes
- fence traffic injection
- constrained-random aligned accesses
- handshake assertions
- negative misalignment detection

## What This Model Covers

- LSU-visible connection between execution issue and memory request/response handling
- Correct data formatting and byte-lane behavior
- Robustness under latency and backpressure
- Verification-oriented system context for the LSU slice

## What This Model Does Not Yet Cover

- Full-chip RTL integration
- exact cache hierarchy implementation details
- arbitration with other core-side blocks
- cross-block timing interactions beyond the LSU boundary
- software-driven co-simulation tied directly into this local UVM environment

## Architecture Diagram Guidance

- For the thesis/report, the preferred diagram should show the full Vortex execution-to-memory path first.
- A second diagram should zoom in on the LSU verification abstraction used in this repository.
- That two-level presentation is stronger than showing only the local testbench view.

## Phase Mapping

- Phase 1: completed at unit level with constrained-random testing and regression evidence.
- Phase 2 Point 1: UVM structure designed and scaffolded.
- Phase 2 Point 2: SimX execution under WSL/Linux validated with a passing `vecadd` run.
- Phase 2 Point 3: system-model and architecture description documented here with explicit core-to-memory focus.
