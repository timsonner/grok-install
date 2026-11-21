# AGENTS.md

Guide for coding agents working in this repo.

## Purpose

Unofficial one-line installers for Grok Build 2.0 unified. Each script fetches the `agent-host` binary from https://x.ai/cli/unified and installs it as `grok`.

## Rules

- One script per platform. Keep them independent and small. Do not merge them into one script.
- Every script must:
  - read `https://x.ai/cli/unified/latest` for the version
  - verify the sha256 before replacing anything
  - keep the previous version for rollback
  - skip when already current, unless forced (`--force` or `-Force`)
  - make `--help` work when piped (`curl ... | bash -s -- --help`)
  - make sure an old grok 1.x does not shadow the new `grok` (an official `~/.grok/bin/grok` on Linux and macOS, mise on Linux, `~\.grok\bin` on the Windows user PATH), with an opt-out flag (`--keep-v1` or `-KeepV1`)
  - be safe to run twice: the second run changes nothing and prints nothing misleading
- Before committing, run `bash -n` and `shellcheck` on every `.sh`, and a PowerShell parse on the `.ps1`. Run a changed script twice on real hardware when you can, and check that a fresh terminal resolves the new `grok`.
- When behavior or platform coverage changes, update the README one-liners and the Tested note.
- No secrets, IP addresses or personal information in any file.
- No Co-authored-by or agent trailers in commits.
- Use only Grok models for any agent work.
- No em dashes or arrow characters in docs or messages.
