# grimoire

Machine setup wizard for persistent, reconnectable SSH sessions using **mosh + tmux + fish**.

Set up any machine (macOS, Linux, or Windows/WSL) and connect them together with a single command.

## Quick Start

### macOS / Linux

```sh
bash grimoire.sh
```

### Windows

1. Run `grimoire.ps1` as Administrator in PowerShell (installs WSL, OpenSSH, firewall rules)
2. Open WSL, then run `bash grimoire.sh`

## What It Does

### OS Setup
- Installs **fish**, **mosh**, and **tmux**
- Sets fish as the default shell
- Configures tmux (mouse scrolling)
- Fixes bash for non-interactive SSH compatibility (scp, mosh)

### GitHub Setup
- Installs **gh** (GitHub CLI)
- Configures `git` with username and machine-specific email (`mayankv0207+{machine}@gmail.com`)
- Generates a named SSH key (`{machine}-github`)
- Adds `github.com` to `~/.ssh/config`
- Uploads the key to GitHub via `gh`

### Claude Code Setup
- Installs **Claude Code** (via npm or brew)
- Adds `yolo` fish alias (`claude --dangerously-skip-permissions`)

### Connection Setup
- Generates a named SSH key (`{local}-{remote}`)
- Adds the remote to `~/.ssh/config`
- Creates a fish function for one-command connect + tmux
- Copies the SSH key to the remote

### Windows Bootstrap (`grimoire.ps1`)
- Installs/enables WSL
- Configures mirrored networking (fixes mosh UDP)
- Sets up OpenSSH server with WSL bash as default shell
- Opens firewall for mosh (UDP 60000-61000)

## Usage After Setup

```sh
kr4ken              # connect to main tmux session
kr4ken myproject    # connect to project-specific session
```

Inside a session:
- `Ctrl+b d` — detach (session keeps running)
- `Ctrl+b [` — scroll mode (trackpad/arrows, `q` to exit)
- Close the lid, sleep, change networks — mosh reconnects automatically

## Known Issues

- **WSL2 + mosh**: Windows ConPTY injects escape sequences that break mosh's PTY mode. The `--no-ssh-pty` flag is used as a workaround.
- **ssh-copy-id on Windows SSH**: May fail with "path not found". Paste the key manually into `C:\Users\<user>\.ssh\authorized_keys` on the remote.
