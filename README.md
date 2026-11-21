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

Linux and macOS install to `~/.grok` and link both `~/.grok/bin/grok` and `~/.local/bin/grok`. If `~/.local/bin` is not on your PATH, the script prints the line to add. Windows installs to `%LOCALAPPDATA%\grok\bin\grok.exe` and adds that folder to your user PATH.

## Flags

Pass flags to the shell scripts with `bash -s --`:

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash -s -- --force
```

- `--force` reinstalls even if you are current.
- `--keep-v1` keeps an old grok 1.x as is. By default the script moves an official 1.x `~/.grok/bin/grok` to `~/.grok/bin/grok-v1` and points `~/.grok/bin/grok` at the new build, so it wins wherever the old installer put it on your PATH. On Linux it also removes mise-managed grok 1.x and disables mise grok.
- `--help` prints usage.

Windows takes `-Force`, `-KeepV1` and `-Help`. The installer puts its folder first on your user PATH and, unless you pass `-KeepV1`, takes an old grok 1.x folder (`~\.grok\bin`) off your user PATH. The old files stay where they are. To pass a flag:

```
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-windows.ps1))) -Force
```

## Tested

Linux x86_64 is tested on two Omarchy machines, including replacing mise-managed grok 1.x. Windows x64 is tested on Windows 11 with PowerShell 5.1, and macOS Intel on macOS 15, both including replacing an official grok 1.x install. Linux ARM and macOS Apple Silicon have not been tested on real hardware yet.

It is a pre-release build, so names and URLs on x.ai may change.

## License

MIT. See [LICENSE](LICENSE).
