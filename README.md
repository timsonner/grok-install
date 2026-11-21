# grok-install

Unofficial one-line installers for Grok Build 2.0 unified. They fetch the `agent-host` binary from https://x.ai/cli/unified and install it as **`grok2`, next to your existing `grok`**. Not affiliated with xAI.

Why `grok2` and not `grok`: Grok Build agent turns are account-gated right now. On accounts that are not switched on, every turn fails with `Permission Denied: Grok Build isn't available for this account yet.` while the subcommands still work. Installing beside your working `grok` means nothing you rely on breaks. See [Troubleshooting](#troubleshooting).

## What each script does

- Reads `https://x.ai/cli/unified/latest` to find the current version.
- Downloads the binary for your platform and verifies its sha256 before replacing anything.
- Installs it as `grok2`. Your existing `grok` (mise, the official 1.x installer, or a Windows `.grok\bin` folder) is not touched. Run the same command again to update.
- Skips the download if you are already current, and keeps the previous version for rollback.

## One-liners

| Platform | Command |
| --- | --- |
| Linux x86_64 | `curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh \| bash` |
| Linux ARM64 | `curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-arm64.sh \| bash` |
| macOS Apple Silicon | `curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-macos-arm64.sh \| bash` |
| macOS Intel | `curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-macos-x86_64.sh \| bash` |
| Windows x64 (PowerShell) | `irm https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-windows.ps1 \| iex` |

Then run `grok2 --version`. It should print `grok 2.0.1 ... [unified]`.

Linux and macOS install to `~/.grok` and link `grok2` in `~/.local/bin` if that is on your PATH, otherwise in `~/.grok/bin`. If neither is on your PATH, the script prints the line to add. Windows installs to `%LOCALAPPDATA%\grok\bin\grok2.exe` and adds that folder to the end of your user PATH, after your existing entries.

## Flags

Pass flags to the shell scripts with `bash -s --`:

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash -s -- --as-grok
```

- `--force` reinstalls even if you are current.
- `--as-grok` installs as plain `grok` instead. The script links `grok`, moves an official 1.x `~/.grok/bin/grok` to `~/.grok/bin/grok-v1`, and on Linux disables mise grok and removes its 1.x versions. Use it only if your account can run Grok Build turns.
- `--keep-v1` with `--as-grok` keeps an old grok 1.x as is.
- `--revert` undoes an `--as-grok` install (or one from an older version of this script, which replaced `grok` by default) without touching the network. It points `grok2` at the unified build, removes the `grok` link, moves `~/.grok/bin/grok-v1` back to `~/.grok/bin/grok`, and on Linux removes `grok` from mise `disable_tools` (backup `config.toml.bak-grok2`) and runs `mise install grok@latest`. Safe to run twice.
- `--help` prints usage.

Windows takes `-Force`, `-AsGrok`, `-KeepV1`, `-Revert` and `-Help`. `-AsGrok` installs `grok.exe`, puts its folder first on your user PATH and, unless you pass `-KeepV1`, takes an old `~\.grok\bin` off it. `-Revert` puts the old `~\.grok\bin` folder first on your user PATH and renames the unified `grok.exe` to `grok2.exe`. To pass a flag:

```
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-windows.ps1))) -AsGrok
```

## Docs

- [docs/grok2-subcommands.md](docs/grok2-subcommands.md): what Grok Build 2.0 adds, and which of it works when turns are gated.
- [docs/commands.md](docs/commands.md): copy-pasteable commands used while building and testing this repo, grouped by platform.

## Troubleshooting

### "Permission Denied: Grok Build isn't available for this account yet."

Every agent turn fails right away, for example:

```
$ grok -p "say hi"
Error: Permission Denied: Grok Build isn't available for this account yet.
```

The interactive TUI shows the same text as `Turn failed in 0.2s: Permission Denied: Grok Build isn't available for this account yet.`

This is an xAI account gate, not an install problem. The binary installs and passes its checksum, `grok --version` prints `grok 2.0.1 ... [unified]`, and subcommands such as `grok --help` and `grok update` run. Only agent turns are refused, and the refusal comes from xAI's servers. Reinstalling, `--force` and switching platforms do not help. When your account is enabled, turns should start working with no reinstall.

If you installed with the default, your existing `grok` was never touched, so keep using it for turns and use `grok2` for the subcommands. If you used `--as-grok`, or an older version of this script that replaced `grok` by default, roll back to your old `grok`. The unified build stays installed as `grok2`.

Quickest way, on Linux or macOS (use your platform's script):

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

Default install (`grok2` only, existing `grok` untouched), rerun, `--as-grok` and `--revert` on Linux x86_64 with throwaway home folders and a fake existing 1.x, and the default on a real Omarchy install where mise grok 1.x stayed in place, `grok` still answered a turn and a rerun changed nothing. Earlier versions of `--revert` ran twice (second run changed nothing) on Linux x86_64 (Omarchy), macOS Intel (macOS 15) and Windows 11 with PowerShell 5.1. Windows `-Revert` and the new Windows default were checked by PowerShell parse and `-Help` plus the earlier hardware run, not run end to end after the grok2 default change. The macOS scripts' new default, Linux ARM and macOS Apple Silicon are untested on real hardware. On the macOS and Windows machines used, the old 1.x was not signed in, so a 1.x turn was not tested there.

It is a pre-release build, so names and URLs on x.ai may change.

## License

MIT. See [LICENSE](LICENSE).
