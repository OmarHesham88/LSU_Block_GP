# Signoff Criteria (Unit-Level LSU)

## Required to claim completion
- All directed tests pass.
- Random regression passes for agreed seed count.
- Scoreboard mismatch count is zero.
- Assertion failures are zero.
- Coverage target reached (`issue_cov >= 85%`).
- Misalignment negative test reports expected violation.

## Suggested minimum regression
- 20 seeds x 500 ops per seed.

## Current limits
- Unit-level only (not full-chip/system integration).
- One-hot lane activation per issued instruction.
- Memory model is stress-oriented but still abstract.
