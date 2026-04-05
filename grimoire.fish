#!/usr/bin/env fish
# ╔══════════════════════════════════════════════════╗
# ║              grimoire — machine setup            ║
# ╚══════════════════════════════════════════════════╝

set GRIMOIRE_DIR (status dirname)

# ── Load modules ─────────────────────────────────────
source "$GRIMOIRE_DIR/modules/ui.fish"
source "$GRIMOIRE_DIR/modules/detect.fish"
source "$GRIMOIRE_DIR/modules/github.fish"
source "$GRIMOIRE_DIR/modules/connect.fish"
source "$GRIMOIRE_DIR/modules/claude.fish"

# ══════════════════════════════════════════════════════
# ── Main ─────────────────────────────────────────────
# ══════════════════════════════════════════════════════

banner

set OS (detect_os)
section "Detected environment"
info "OS: $OS"

if test "$OS" = unknown
    err "Could not detect OS. Run on macOS, Linux, or WSL."
    exit 1
end

set MACHINE_NAME (prompt_default "Name this machine:" "gh0st")

# ── Fish plugins (always) ──
section "Setting up fish plugins"

step "[1/2]" "Installing fisher..."
if type -q fisher
    info "Fisher already installed"
else
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
    ok "Installed fisher"
end

step "[2/2]" "Installing tide..."
if fisher list | grep -q tide
    info "Tide already installed"
else
    fisher install ilancosman/tide@v6
    ok "Installed tide"
end

done_section

# ── Menu ──
set choices (show_multi_menu "What would you like to set up?" \
    "GitHub (gh, git config, SSH key)" \
    "Claude Code (nvm, node, claude, yolo alias)" \
    "Connect to a remote machine (mosh, tmux)")

# Check if "all" was selected
if string match -q '*4*' "$choices"
    set choices "1 2 3"
end

for c in (string split ' ' $choices)
    switch $c
        case 1
            setup_github $MACHINE_NAME
        case 2
            setup_claude $MACHINE_NAME
        case 3
            setup_connection $MACHINE_NAME
        case '*'
            err "Unknown option: $c"
    end
end

complete_banner
