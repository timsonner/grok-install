# Commands used while building and testing this repo

A copy-pasteable log of what was run, grouped by platform. Paths use `~`, and names, IDs and addresses are left out. Outputs are trimmed.

`<version>` below is whatever `https://x.ai/cli/unified/latest` returns (2.0.1 when this was written).

## Find the current unified version and checksum

```
curl -fsS https://x.ai/cli/unified/latest
curl -fsS https://x.ai/cli/unified/agent-host-<version>-linux-x86_64.sha256
```

The sha256 file sits next to the binary and covers the uncompressed file. The `.gz` file has no checksum file.

## Manual install by hand (Linux x86_64), what the scripts automate

```
mkdir -p ~/.grok/downloads ~/.grok/bin ~/.local/bin
cd ~/.grok/downloads
curl -fSL -o agent-host-2.0.1-linux-x86_64 https://x.ai/cli/unified/agent-host-2.0.1-linux-x86_64
echo "$(curl -fsS https://x.ai/cli/unified/agent-host-2.0.1-linux-x86_64.sha256 | cut -d' ' -f1)  agent-host-2.0.1-linux-x86_64" | sha256sum -c -
chmod 755 agent-host-2.0.1-linux-x86_64
ln -sfn ../downloads/agent-host-2.0.1-linux-x86_64 ~/.grok/bin/agent-host
ln -sfn ~/.grok/bin/agent-host ~/.local/bin/grok2
grok2 --version
```

## Install with the scripts

Default (installs `grok2`, leaves your `grok` alone), then the same again to prove a rerun changes nothing:

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash
```

Make it plain `grok`, hiding an old 1.x:

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash -s -- --as-grok
```

Go back to your old `grok`, keep the unified build as `grok2`:

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash -s -- --revert
```

Windows (PowerShell 5.1 or newer), run from a saved copy so flags work:

```
$f = Join-Path $env:TEMP 'grok-install-windows.ps1'
Invoke-WebRequest -UseBasicParsing -Uri https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-windows.ps1 -OutFile $f
& $f
& $f -AsGrok
& $f -Revert
Remove-Item $f
```

## Omarchy (Linux, mise-managed grok): revert by hand

This is what an Omarchy install needed before `--revert` existed.

```
cp ~/.config/mise/config.toml ~/.config/mise/config.toml.bak-grok2
sed -i 's/^disable_tools = \["copilot", "grok"\]/disable_tools = ["copilot"]/' ~/.config/mise/config.toml
mv ~/.local/bin/grok ~/.local/bin/grok2
MISE_MINIMUM_RELEASE_AGE=0 mise install grok@latest
bash -lc 'type -a grok grok2; grok --version; grok2 --version'
bash -lc 'grok -p "Reply with the single word: pong"'
grok2 -p "Reply with the single word: pong"
```

The first replace of mise grok had gone the other way:

```
cp ~/.config/mise/config.toml ~/.config/mise/config.toml.bak.pre-grok2
sed -i 's/^disable_tools = \["copilot"\]/disable_tools = ["copilot", "grok"]/' ~/.config/mise/config.toml
ln -sfn ~/.grok/bin/agent-host ~/.local/bin/grok
mise uninstall grok@1.0.70 grok@1.0.77 grok@1.0.88 grok@1.0.89
```

Look at the mise side before changing anything:

```
grep -n grok /etc/mise/conf.d/omarchy-tools.toml
mise ls grok
bash -lc 'type -a grok; echo $PATH | tr ":" "\n"'
```

## macOS (Intel): revert

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-macos-x86_64.sh | bash -s -- --revert
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-macos-x86_64.sh | bash -s -- --revert
ls -l ~/.grok/bin ~/.local/bin
zsh -lc 'type -a grok grok2; grok --version; grok2 --version'
```

`~/.local/bin` was not on PATH on macOS here, so `grok2` is placed in `~/.grok/bin`.

## Windows 11: -Revert

```
Get-Command grok -All | Select-Object -ExpandProperty Source
[Environment]::GetEnvironmentVariable('Path','User') -split ';' | Select-String 'grok'
& $f -Revert
& $f -Revert
```

A fresh process reads the user PATH from the registry. To check what a new terminal will see from inside an existing session:

```
$env:Path = [Environment]::GetEnvironmentVariable('Path','Machine') + ';' + [Environment]::GetEnvironmentVariable('Path','User')
Get-Command grok, grok2 -All | ForEach-Object { $_.Source }
grok --version
grok2 --version
```

## Subcommand inventory (read-only)

```
grok --help
grok2 --help
grok2 agent-host --help
grok2 automations --help
grok2 bedrock --help
grok2 cloud --help
grok2 env --help
grok2 version
grok2 agent-host status
grok2 models
grok2 cloud list
grok2 env list
grok2 automations list
grok2 automations runs --help
grok2 usage
grok2 doctor
grok2 du
grok2 sessions --help
grok2 inspect
grok update --help
grok2 update --check --json
```

`grok2 update --check --json` printed `Grok is not updating: config defines no custom channel with binary = "agent-host"`. To update, rerun the install script.

## The account gate

```
grok2 -p "Reply with the single word: pong"
```

```
Error: Permission Denied: Grok Build isn't available for this account yet.
```

Exit code 1. The same prompt on a 1.x `grok` that is signed in answers `pong`.

## Script checks

```
bash -n grok-install-linux-x86_64.sh
shellcheck -S warning grok-install-*.sh
pwsh -NoProfile -Command '$e=$null;[void][System.Management.Automation.Language.Parser]::ParseFile("grok-install-windows.ps1",[ref]$null,[ref]$e); if($e){$e|%{$_.Message};exit 1}else{"PARSE OK"}'
```

Throwaway-HOME test on Linux (default, rerun, `--as-grok`, `--revert`), with a fake existing 1.x `grok`:

```
export HOME=$(mktemp -d)
mkdir -p $HOME/.grok/bin $HOME/.grok/downloads $HOME/.local/bin
printf '#!/bin/sh\necho grok 1.0.0-fake\n' > $HOME/.grok/downloads/grok-linux-x86_64
chmod +x $HOME/.grok/downloads/grok-linux-x86_64
ln -s ../downloads/grok-linux-x86_64 $HOME/.grok/bin/grok
export PATH=$HOME/.local/bin:$HOME/.grok/bin:$PATH
bash grok-install-linux-x86_64.sh
bash grok-install-linux-x86_64.sh
bash grok-install-linux-x86_64.sh --as-grok
bash grok-install-linux-x86_64.sh --revert
```

## Look at a Cursor CLI switch (research, read-only)

The unified build is also what the Cursor CLI's hidden `cursor-agent update --channel grok` fetches. That route needs an account gate to be open, so it was not used here.

```
curl -fsSL https://cursor.com/install | head -150
curl -fsSL https://x.ai/cli/install.sh | grep -n -i -E 'channel|unified'
```
