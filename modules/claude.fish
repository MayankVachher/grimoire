#!/usr/bin/env fish
# ── Claude Code Setup: nvm, node, install, fish aliases ─

function setup_claude
    set -l machine_name $argv[1]

    section "Setting up Claude Code on $machine_name"

    # ── nvm.fish for node version management ──
    step "[1/4]" "Setting up nvm.fish..."
    if fisher list 2>/dev/null | grep -q nvm.fish
        info "nvm.fish already installed"
    else
        fisher install jorgebucaran/nvm.fish
        ok "Installed nvm.fish"
    end

    # ── Install Node.js ──
    step "[2/4]" "Installing Node.js..."
    if command -q node
        info "Node.js already installed: "(node --version)
    else
        nvm install lts
        ok "Installed Node.js LTS"
    end

    # ── Install Claude Code ──
    step "[3/4]" "Installing Claude Code..."
    if command -q claude
        info "Claude Code already installed"
    else
        npm install -g @anthropic-ai/claude-code
        ok "Installed Claude Code"
    end

    # ── Fish aliases ──
    step "[4/4]" "Setting up fish aliases..."
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
