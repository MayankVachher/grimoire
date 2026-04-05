#!/usr/bin/env fish
# ── Claude Code Setup: install, fish aliases ─────────

function setup_claude
    set -l machine_name $argv[1]

    section "Setting up Claude Code on $machine_name"

    # ── Install Claude Code ──
    step "[1/2]" "Installing Claude Code..."
    if test -x "$HOME/.local/bin/claude"
        info "Claude Code already installed: "($HOME/.local/bin/claude --version 2>/dev/null | head -1)
    else
        curl -fsSL https://claude.ai/install.sh | bash
        ok "Installed Claude Code"
    end

    # ── Fish aliases ──
    step "[2/2]" "Setting up fish aliases..."
    set -l fish_config "$HOME/.config/fish/config.fish"

    if grep -q "function claude-yolo" "$fish_config" 2>/dev/null
        info "claude-yolo alias already exists"
    else
        echo '
function claude-yolo --description "Claude Code YOLO mode"
    claude --dangerously-skip-permissions $argv
end' >> "$fish_config"
        ok "Added claude-yolo alias"
    end

    # ── Claude config directory ──
    mkdir -p "$HOME/.claude"

    done_section

    echo $PURPLE$BOLD"  Usage:"$NC
    echo "    "$BOLD"claude"$NC"       — start Claude Code"
    echo "    "$BOLD"claude-yolo"$NC"  — start Claude Code (skip permissions)"
    echo ""
end
