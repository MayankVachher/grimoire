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

clear
banner

set OS (detect_os)
section "Detected environment"
info "OS: $OS"

if test "$OS" = unknown
    err "Could not detect OS. Run on macOS, Linux, or WSL."
    exit 1
end

set MACHINE_NAME (prompt_default "Name this machine:" (hostname))

# ── Base packages (always) ──
section "Setting up base packages"

set -l pkg_mgr (detect_pkg_manager)

step "[1/4]" "Installing mosh..."
if command -q mosh
    info "mosh already installed"
else
    install_packages $pkg_mgr mosh
    ok "Installed mosh"
end

step "[2/4]" "Installing tmux..."
if command -q tmux
    info "tmux already installed"
else
    install_packages $pkg_mgr tmux
    ok "Installed tmux"
end

step "[3/6]" "Configuring tmux..."
if not grep -q "set -g mouse on" "$HOME/.tmux.conf" 2>/dev/null
    echo "set -g mouse on" >> "$HOME/.tmux.conf"
    ok "Enabled tmux mouse mode"
else
    info "Tmux mouse mode already enabled"
end

set -l fish_path (command -v fish)
if test -n "$fish_path"
    # Remove old default-shell if present
    if grep -q "default-shell" "$HOME/.tmux.conf" 2>/dev/null
        sed -i.bak "/default-shell/d" "$HOME/.tmux.conf"
        rm -f "$HOME/.tmux.conf.bak"
    end
    # Use default-command with login flag so fish fully initializes PATH
    if grep -q "default-command" "$HOME/.tmux.conf" 2>/dev/null
        sed -i.bak "s|.*default-command.*|set-option -g default-command \"$fish_path -l\"|" "$HOME/.tmux.conf"
        rm -f "$HOME/.tmux.conf.bak"
    else
        echo "set-option -g default-command \"$fish_path -l\"" >> "$HOME/.tmux.conf"
    end
    ok "Set tmux default command to fish (login shell)"
end

step "[4/6]" "Bash guards for non-interactive sessions..."
if test -f "$HOME/.bashrc"
    if head -5 "$HOME/.bashrc" | grep -q 'case \$- in'
        info "Non-interactive guard already present"
    else
        set -l tmp (mktemp)
        echo '# Exit early for non-interactive sessions (required for scp/mosh)
case $- in
    *i*) ;;
    *) return;;
esac
' > $tmp
        cat "$HOME/.bashrc" >> $tmp
        mv $tmp "$HOME/.bashrc"
        ok "Added non-interactive guard to .bashrc"
    end

    # Guard cargo env if present
    if grep -q '\.cargo/env' "$HOME/.bashrc" 2>/dev/null
        sed -i.bak 's|^\. "\$HOME/\.cargo/env"|[ -f "$HOME/.cargo/env" ] \&\& . "$HOME/.cargo/env"|g' "$HOME/.bashrc"
        sed -i.bak 's|^source "\$HOME/\.cargo/env"|[ -f "$HOME/.cargo/env" ] \&\& . "$HOME/.cargo/env"|g' "$HOME/.bashrc"
        rm -f "$HOME/.bashrc.bak"
        ok "Guarded cargo env sourcing"
    end
    # Exec fish from interactive bash (for Windows OpenSSH)
    if not grep -q "exec fish" "$HOME/.bashrc" 2>/dev/null
        echo '
# Hand off to fish for interactive sessions
exec fish' >> "$HOME/.bashrc"
        ok "Added exec fish to .bashrc"
    else
        info "exec fish already in .bashrc"
    end
else
    info "No .bashrc found, skipping"
end

step "[5/6]" "Installing fisher..."
if type -q fisher
    info "Fisher already installed"
else
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
    ok "Installed fisher"
end

step "[6/6]" "Installing tide..."
if fisher list | grep -q tide
    info "Tide already installed"
else
    fisher install ilancosman/tide@v6
    ok "Installed tide"
end

set -l fish_config "$HOME/.config/fish/config.fish"

# ── Configure tide prompt ──
set -l icon (show_icon_menu)
set -U tide_os_icon "$icon"
set -U tide_left_prompt_items os context pwd git newline character
set -U tide_right_prompt_items cmd_duration time
set -U tide_prompt_style lean
ok "Configured tide prompt with $icon"
if not grep -q "fish_add_path.*local/bin" "$fish_config" 2>/dev/null
    echo 'fish_add_path ~/.local/bin' >> "$fish_config"
    ok "Added ~/.local/bin to fish PATH"
else
    info "~/.local/bin already in fish config"
end

warn "Restart tmux for changes to take effect: tmux kill-server"

done_section

# ── Menu ──
set choices (show_multi_menu "What would you like to set up?" \
    "GitHub (gh, git config, SSH key)" \
    "Claude Code (nvm, node, claude, yolo alias)" \
    "Connect to a remote machine")

# Check if "all" was selected
if string match -q '*4*' "$choices"
    set choices "1 2 3"
end

# Check for "none"
if string match -q '*0*' "$choices"
    complete_banner
    exit 0
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
