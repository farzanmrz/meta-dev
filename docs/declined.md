# Declined register

Drift items from sync-docs runs (and design decisions) that were reviewed and DECLINED, so they don't resurface each run. One line each: date · item · reason.

- 2026-07-05 · scheduled currency runs · declined — sync-docs is on-demand, user-invoked only.
- 2026-07-05 · router rename away from skill-creation · declined — /skill- muscle memory + naming constraint; descriptions do the routing.
- 2026-07-05 · rules/ as default instruction layer · declined — root-file-first under ~200 lines; rules return only as rung-2 glob-shaped graduations.
- 2026-07-05 · patching vendored aggregate_benchmark delta sign · declined — byte-identity with upstream; sign-flip documented in eval-pipeline.md §5.
- 2026-07-05 · `disallowed-tools: [Write,Edit]` on review-*/validate-* skills · declined — their deep modes legitimately write scratch fixtures/workspaces; the guarantee is "inspected artifacts unmodified", enforced by each skill's completion self-check instead.
