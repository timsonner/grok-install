# grok-install

Unofficial one-line installers for Grok Build 2.0 unified. They fetch the `agent-host` binary from https://x.ai/cli/unified. Not affiliated with xAI.

## What each script does

- Reads `https://x.ai/cli/unified/latest` to find the current version.
- Downloads the binary for your platform and verifies its sha256 before replacing anything.
- Links it as `grok`. Run the same command again to update.
- Skips the download if you are already current, and keeps the previous version for rollback.

## One-liners

| Platform | Command |
| --- | --- |
| Linux x86_64 | `curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh \| bash` |
| Linux ARM64 | `curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-arm64.sh \| bash` |
| macOS Apple Silicon | `curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-macos-arm64.sh \| bash` |
| macOS Intel | `curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-macos-x86_64.sh \| bash` |
| Windows x64 (PowerShell) | `irm https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-windows.ps1 \| iex` |

Linux and macOS install to `~/.grok` and link `~/.local/bin/grok`. If `~/.local/bin` is not on your PATH, the script prints the line to add. Windows installs to `%LOCALAPPDATA%\grok\bin\grok.exe` and adds that folder to your user PATH.

## Flags

Pass flags to the shell scripts with `bash -s --`:

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash -s -- --force
```

- `--force` reinstalls even if you are current.
- `--keep-v1` (Linux only) keeps old mise-managed grok 1.x installs. By default they are removed, and mise grok is disabled so it does not shadow the new `grok`.
- `--help` prints usage.

Windows, to use `-Force` or `-Help`:

```
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-windows.ps1))) -Force
```

## Tested

Linux x86_64 is tested on Omarchy. Linux ARM, macOS and Windows have not been tested on real hardware yet.

It is a pre-release build, so names and URLs on x.ai may change.
