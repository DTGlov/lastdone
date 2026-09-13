# LastDone project instructions

- Investigate first and preserve unrelated changes.
- Work in small, reviewable vertical phases; stop after each phase for review.
- Do not create branches, commit, push, merge, reset, rebase, or rewrite history without explicit authorization.
- David manually merges every reviewed feature branch on GitHub. Codex must never create or merge pull requests. After a phase is approved, Codex may commit and push its feature branch, then must stop until David confirms the manual merge.
- Add dependencies only when required and used.
- Use FVM exclusively: `fvm flutter` for Flutter commands and `fvm dart` for Dart commands.
- Use the Dart/Flutter server for analysis and runtime validation, resolving the project SDK through `.fvmrc`.
- Maintain `docs/learning/` as the project develops.

## Feature-phase validation policy

- Prioritize implementation during normal feature phases.
- Do not use Dart/Flutter MCP runtime interaction for per-feature testing unless David explicitly requests it.
- Do not run driver flows, unit tests, widget tests or the complete test suite unless David explicitly requests them.
- Do not add new automated tests during normal feature phases unless David explicitly requests it.
- Preserve all existing tests; never delete, disable or weaken them to satisfy this policy.
- Format changed Dart files with FVM.
- Run `fvm flutter analyze` after implementation.
- Report static-analysis results and any unresolved warnings.
- David will manually test each feature during development.
- Comprehensive automated and end-to-end validation will be performed during release readiness or when David explicitly requests it.
- If a change is too risky to validate safely without an automated test, explain the risk and stop for direction instead of silently proceeding.

The Git workflow remains:

- Codex may commit and push an approved feature branch.
- David manually merges feature branches on GitHub.
- Codex must never create or merge pull requests unless explicitly authorized.
