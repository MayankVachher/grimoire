#!/bin/bash
# ── Claude Code Setup: install, fish aliases ─────────

setup_claude() {
    local machine_name="$1"
    local pkg_mgr="$2"

    section "Setting up Claude Code on $machine_name"

    # ── Install Claude Code ─��
    step "[1/3]" "Installing Claude Code..."
    if command -v claude &>/dev/null; then
        info "Claude Code already installed"
    else
        if command -v npm &>/dev/null; then
            npm install -g @anthropic-ai/claude-code
            ok "Installed via npm"
        elif command -v brew &>/dev/null; then
            brew install claude
            ok "Installed via brew"
        else
            warn "Install manually: npm install -g @anthropic-ai/claude-code"
            warn "Or visit: https://docs.anthropic.com/en/docs/claude-code"
        fi
    fi

    # ── Fish aliases ──
    step "[2/3]" "Setting up fish aliases..."
    local fish_config="$HOME/.config/fish/config.fish"
    mkdir -p "$HOME/.config/fish"

    if grep -q "function claude-yolo" "$fish_config" 2>/dev/null; then
        info "claude-yolo alias already exists"
    else
        cat >> "$fish_config" << 'FISHEOF'

function claude-yolo --description "Claude Code YOLO mode"
    claude --dangerously-skip-permissions $argv
end
FISHEOF
        ok "Added claude-yolo alias"
    fi

    # ── Claude config directory ──
    step "[3/3]" "Ensuring Claude config directory..."
    mkdir -p "$HOME/.claude"
    ok "Config directory ready"

    done_section

    echo -e "${PURPLE}${BOLD}  Usage:${NC}"
    echo -e "    ${BOLD}claude${NC}       — start Claude Code"
    echo -e "    ${BOLD}claude-yolo${NC}  — start Claude Code (skip permissions)"
    echo ""
}
