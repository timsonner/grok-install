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
- `--revert` undoes the install without touching the network: points `grok2` at the unified build (in `~/.local/bin` if that is on your PATH, otherwise `~/.grok/bin`) and removes `~/.local/bin/grok`, moves `~/.grok/bin/grok-v1` back to `~/.grok/bin/grok`, and on Linux removes `grok` from mise `disable_tools` (backup `config.toml.bak-grok2`) and runs `mise install grok@latest`. Safe to run twice.
- `--help` prints usage.

Windows takes `-Force`, `-KeepV1`, `-Revert` and `-Help`. `-Revert` puts the old `~\.grok\bin` folder first on your user PATH and renames the unified `grok.exe` to `grok2.exe`. The installer puts its folder first on your user PATH and, unless you pass `-KeepV1`, takes an old grok 1.x folder (`~\.grok\bin`) off your user PATH. The old files stay where they are. To pass a flag:

```
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-windows.ps1))) -Force
```

## Troubleshooting

### "Permission Denied: Grok Build isn't available for this account yet."

Every agent turn fails right away, for example:

```
$ grok -p "say hi"
Error: Permission Denied: Grok Build isn't available for this account yet.
```

The interactive TUI shows the same text as `Turn failed in 0.2s: Permission Denied: Grok Build isn't available for this account yet.`

This is an xAI account gate, not an install problem. The binary installs and passes its checksum, `grok --version` prints `grok 2.0.1 ... [unified]`, and subcommands such as `grok --help` and `grok update` run. Only agent turns are refused, and the refusal comes from xAI's servers. Reinstalling, `--force` and switching platforms do not help. When your account is enabled, turns should start working with no reinstall.

If you need working turns in the meantime, roll back to grok 1.x. The unified build stays installed as `grok2`, and grok 1.x answers turns normally.

Quickest way, any Linux or macOS machine this script touched, and on Windows:

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash -s -- --revert
```

Use your platform's script. On Windows: `& ([scriptblock]::Create((irm https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-windows.ps1))) -Revert`.

By hand:

- Omarchy or any machine with mise grok: remove `"grok"` from `disable_tools` in `~/.config/mise/config.toml`, run `mise install grok@latest`, then `mv ~/.local/bin/grok ~/.local/bin/grok2`. Omarchy's own mise config pins grok at `latest`, so it comes back on the 1.x line.
- Official v1 installer on macOS or Linux: the script moved your old binary to `~/.grok/bin/grok-v1`. Run `mv ~/.grok/bin/grok-v1 ~/.grok/bin/grok` and `mv ~/.local/bin/grok ~/.local/bin/grok2`. Installing with `--keep-v1` never moves it in the first place.
- Windows: put `%USERPROFILE%\.grok\bin` back ahead of `%LOCALAPPDATA%\grok\bin` in your user PATH. The script does not keep a PATH backup, so `-Revert` rebuilds the order from those two folders. Your old files were never deleted.

To go forward again, rerun the install one-liner.

### Other things seen while reverting

- grok 1.x installed by mise can report `[alpha]` (for example `grok 1.0.92 (b06756fd6256) [alpha]`). The same commit hash as `2.0.1 ... [unified]` shows the two builds are the same code with a different channel flag.
- `grok update` on the unified build prints `Grok is not updating: config defines no custom channel with binary = "agent-host"`. Update by rerunning this installer.
- Some Omarchy setups put a mise wrapper first on PATH. It hands off to the first real `grok` it finds, so `~/.local/bin/grok` still wins once mise grok is disabled.

## Tested

Linux x86_64 is tested on two Omarchy machines, including replacing mise-managed grok 1.x. Windows x64 is tested on Windows 11 with PowerShell 5.1, and macOS Intel on macOS 15, both including replacing an official grok 1.x install. `--revert` was tested on Linux x86_64 with a throwaway HOME (run twice, mise config edit and link renames), and the revert steps by hand on an Omarchy machine, where grok 1.x answered a turn and the unified build showed the error above. The macOS `--revert`, the Windows `-Revert` (PowerShell parse check only) and Linux ARM are untested, as is macOS Apple Silicon.

It is a pre-release build, so names and URLs on x.ai may change.

## License

MIT. See [LICENSE](LICENSE).
