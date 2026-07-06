# Privacy Policy

_Last updated: 2026-07-05_

**meta-dev collects no personal data.** It is a local [Claude Code](https://claude.com/claude-code) plugin — a set of skills, agents, and hooks that run entirely on your own machine as part of your Claude Code session.

## What it does with your data

Nothing leaves your machine because of meta-dev. Specifically:

- **No telemetry, analytics, or tracking.** meta-dev does not measure, log to a remote service, or report your usage.
- **No data collection.** It does not gather, store, or transmit your code, prompts, files, identity, or configuration to the author or any third party.
- **Local-only side effects.** Its hooks write short-lived session markers under your system temp directory (`/tmp`) and allow or deny tool calls within your session. These never leave your machine.
- **The one outbound request is a read.** The `sync-docs` skill, only when you explicitly run it, *fetches* public Claude Code documentation to compare against meta-dev's standards. It sends none of your data in the process.

## Contact

Questions about this policy: open an issue at
<https://github.com/farzanmrz/meta-dev/issues>.

This policy applies only to the meta-dev plugin. Your use of Claude Code itself is governed by [Anthropic's Privacy Policy](https://www.anthropic.com/legal/privacy).
