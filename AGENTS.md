# AGENTS.md

Guide for coding agents working in this repo.

## Purpose

Unofficial one-line installers for Grok Build 2.0 unified. Each script fetches the `agent-host` binary from https://x.ai/cli/unified and installs it as `grok2`, next to the user's existing `grok`.

## Rules

- One script per platform. Keep them independent and small. Do not merge them into one script.
- Every script must:
  - read `https://x.ai/cli/unified/latest` for the version
  - verify the sha256 before replacing anything
  - keep the previous version for rollback
  - skip when already current, unless forced (`--force` or `-Force`)
  - make `--help` work when piped (`curl ... | bash -s -- --help`)
  - by default install as `grok2` only and leave any existing `grok` completely untouched: no mise changes, no moving the official 1.x `grok`, no PATH reordering that shadows it. On Windows the install folder goes at the END of the user PATH
  - put `grok2` in a directory already on PATH (`~/.local/bin` if it is on PATH, else `~/.grok/bin`)
  - offer `--as-grok` (`-AsGrok`) as the opt-in for the old replace behavior (link as plain `grok`, hide an official 1.x, mise on Linux, `~\.grok\bin` on the Windows user PATH), with `--keep-v1` (`-KeepV1`) to skip hiding 1.x
  - offer `--revert` (`-Revert`) that undoes `--as-grok` and the older replace-by-default installs, offline and safe to run twice
  - be safe to run twice: the second run changes nothing and prints nothing misleading
- Before committing, run `bash -n` and `shellcheck` on every `.sh`, and a PowerShell parse on the `.ps1`. Run a changed script twice on real hardware when you can, and check that a fresh terminal resolves `grok2` and still resolves the existing `grok` unchanged.
- When behavior or platform coverage changes, update the README one-liners, `docs/commands.md` and the Tested note.
- No machine details anywhere in the repo, in files or commit messages: no hostnames, machine names, hardware models, machine IDs, usernames or home paths with a name. Group by platform only (Omarchy/Linux, macOS Intel, Windows 11).
- No secrets, IP addresses or personal information in any file.
- No Co-authored-by or agent trailers in commits.
- Use only Grok models for any agent work.
- No em dashes or arrow characters in docs or messages.
