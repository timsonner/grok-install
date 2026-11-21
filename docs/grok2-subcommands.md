# What Grok Build 2.0 adds, even when the chat interface says no

Grok Build 2.0 (the "unified" build) is out on x.ai's unified channel. On some accounts the chat interface refuses to start with `Permission Denied: Grok Build isn't available for this account yet.` The rest of the command line still works. This is what I found by running `grok2`, the 2.0.1 binary, next to a normal 1.x install on Omarchy (Linux).

Everything below is output I saw on my own account. Names, IDs and paths are replaced with placeholders.

## What changed from 1.x

I compared `grok --help` (1.0.92) with `grok2 --help` (2.0.1). The command lists match except for five new top-level commands:

| New command | What its help says |
| --- | --- |
| `agent-host` (alias `ah`) | Run or inspect the agent-host daemon |
| `automations` | Validate, deploy, list, test and inspect your Cursor Automations |
| `cloud` | Manage cloud agents (list, get, send, transcript) |
| `env` | Manage cloud-agent environments (list, get, deploy, delete) |
| `bedrock` | Run models on your own AWS account through Amazon Bedrock |

Version string: `grok 2.0.1 (b06756fd6256, public 1.0.92) [unified]`. The public 1.0.92 in the banner and the identical commit hash on 1.0.92 tell me the two builds share code. Unified is a channel, not a rewrite.

## agent-host: the daemon underneath

`grok2 agent-host --help` lists `run` (start the daemon in the foreground) and `status`.

```
$ grok2 agent-host status
not running (no socket at ~/.grok/agent-host/daemon.sock)
session daemon listening at ~/.grok/agent-host/daemon-<pid>.sock
```

It reads from a socket and exits cleanly, so it is a safe first check. It also tells you where the unified build keeps its state.

## cloud: your cloud agents from the terminal

`grok2 cloud list` prints one JSON object per line. This worked while chat turns were refused. Trimmed and anonymized:

```
$ grok2 cloud list
{"bcId":"bc-<id>","status":"FINISHED","source":"<app>","name":"<task name>","repoUrl":"<repo>","branchName":"main","modelName":"grok-4.7", ...}
```

Fields include status, source, repo, branch, pull request URL, lines added and removed, and model. Because the output is JSON lines, it pipes straight into `jq`. The other subcommands are `get` (by ID), `send` (a session or a fresh prompt) and `transcript` (JSONL). I only ran `list`. `send` hands work to a cloud agent, so I left it alone.

## env: cloud-agent environments

```
$ grok2 env list
{"publicId":"<uuid>","scope":"TEAM","id":"<n>","name":null,"owningTeam":<n>,"repos":["github.com/<user>/<repo>"],"createdAtMs":...}
```

One line per environment, with the repos each one covers. `get`, `deploy` and `delete` exist too. Deploy and delete change your account, so I did not run them.

## automations

`grok2 automations list` also ran fine and returned my automations as JSON lines (ID, name, enabled, scope, owner). The help lists `validate`, `deploy`, `get`, `delete`, `adopt`, `pull`, `test` and `runs` (with `list` and `get` under it). `validate` is the one I would try first, since it only checks a YAML file.

## bedrock

The help describes `configure`, `enable`, `status` and `disable`, for running models on your own AWS account. I did not run it.

## Older commands that still work

These exist in 1.x too, and ran under `grok2`:

```
$ grok2 models
You are logged in with cursor.com.
Default model: grok-4.7
Available models:
  - default
  * grok-4.7 (default)
  - grok-4.6
  - composer-2.5
  ...

$ grok2 usage
Plan: Super
Weekly limit: <n>%
Pay-as-you-go: $0.00 used

$ grok2 du
Disk usage for ~/.grok
    403.1 MB  runtime
    349.3 MB  downloads
     81.4 MB  sessions
```

`doctor` checks terminal, clipboard and color support. `inspect` prints the version and what configuration it finds for the current directory. Both ran without a prompt.

## What does not work yet

Agent turns, including the one-shot form, are refused for my account:

```
$ grok2 -p "Reply with the single word: pong"
Error: Permission Denied: Grok Build isn't available for this account yet.
```

Exit code 1, and it fails in a fraction of a second. The binary installs, its checksum matches, and the subcommands above work. The refusal comes from xAI's side, so reinstalling will not change it. 1.x on the same install answers the same prompt with `pong`.

## Try it yourself

The unofficial installer repo is at https://github.com/timsonner/grok-install. One script per platform downloads the unified build, checks its sha256 and installs it as `grok2`, next to whatever `grok` you already have. It does not touch your existing install:

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash
```

Then run `grok2 cloud list` or `grok2 usage` any time to see what works on your account. Run the same command again to update. When your account is switched on, turns should start working in `grok2` with no reinstall. If you want plain `grok` to be the unified build, add `--as-grok` (`-AsGrok` on Windows).

If you installed with an earlier version of the script, which replaced `grok` by default, or used `--as-grok`, and turns are refused, go back to your old `grok` and keep the unified build as `grok2`:

```
curl -fsSL https://raw.githubusercontent.com/timsonner/grok-install/main/grok-install-linux-x86_64.sh | bash -s -- --revert
```

On Windows use `-Revert`.
