# System Model and Architecture (Phase 2)

## Goal
- Define the verification-visible architecture around `VX_lsu_slice`.
- Clarify the connection between the Vortex core-side request path and the memory-side response path.
- Document which parts are already implemented and which parts are planned for later phases.

## Unit Under Test
- DUT: `VX_lsu_slice`
- Purpose: translate LSU execute requests from the core pipeline into memory transactions and format returning load data back to the core result path.

## Verification-Level System View
```text
Core / execute stage stimulus
        |
        v
  VX_execute_if
        |
        v
   +-------------+
   | VX_lsu_slice|
   +-------------+
      |       |
      |       +-----------------> VX_result_if -> load writeback / completion observation
      |
      +-------------------------> VX_lsu_mem_if -> memory model / backpressure / latency / responses
```

## Interface Roles
- `VX_execute_if`: injects LSU operations as if they were issued by the execute stage.
- `VX_lsu_mem_if`: models the connection from LSU to memory subsystem.
- `VX_result_if`: collects load completions and writeback-visible results.

## Current System Model
- Stimulus source: local testbench tasks driving `execute_if`.
- Reference model: scoreboard memory image in `tb/pkg/lsu_scoreboard.sv`.
- Memory subsystem abstraction: `models/lsu_mem_model_rand.sv`.
- Observation path: `result_if` monitor plus scoreboard comparison.

## Memory-Subsystem Abstraction
- The memory model accepts LSU requests through `VX_lsu_mem_if`.
- It supports configurable:
- request backpressure
- response latency
- outstanding transactions
- optional out-of-order response scheduling
- This is an abstract but useful unit-level model because it stresses the LSU request/response protocol without needing the full Vortex memory hierarchy.

## Implemented Verification Behaviors
- Directed load/store formatting checks
- sign/zero extension checks
- lane sweep across all LSU lanes
- fence traffic injection
- constrained-random aligned accesses
- handshake assertions
- negative misalignment detection test

## What This Covers
- Correct LSU formatting and byte-lane behavior
- Correct interaction with an abstracted memory slave
- Robustness under latency and backpressure

## What This Does Not Yet Cover
- Full-chip integration
- cache hierarchy behavior
- arbitration with other core blocks
- SimX co-simulation
- software-driven end-to-end workloads

## Phase Mapping
- Phase 1: completed at unit level with constrained-random testing and regression evidence.
- Phase 2: architecture and system-model definition now documented here; UVM structure is scaffolded separately for later expansion.
