#!/bin/bash
# ── OS Setup: fish, mosh, tmux, bash guards ──────────

setup_os() {
    local os="$1"
    local pkg_mgr="$2"
    local machine_name="$3"

    section "Setting up $machine_name ($os, $pkg_mgr)"

    # ── Packages ──
    step "[1/4]" "Installing packages..."
    local packages=(fish mosh tmux)

    if [[ "$pkg_mgr" == "brew" ]]; then
        if ! command -v brew &>/dev/null; then
            err "Homebrew not found. Install from https://brew.sh"
            return 1
        fi
    fi

    for pkg in "${packages[@]}"; do
        if command -v "$pkg" &>/dev/null; then
            info "$pkg already installed"
        else
            info "Installing $pkg..."
            install_packages "$pkg_mgr" "$pkg"
        fi
    done
    ok "Packages ready"

    # ── Fish as default shell ──
    step "[2/4]" "Setting fish as default shell..."
    local fish_path
    fish_path="$(command -v fish)"

    if [[ "$SHELL" == *"fish"* ]]; then
        info "Fish is already the default shell"
    elif [[ -n "$fish_path" ]]; then
        if ! grep -q "$fish_path" /etc/shells 2>/dev/null; then
            info "Adding fish to /etc/shells..."
            echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
        fi
        info "Changing default shell to fish..."
        chsh -s "$fish_path"
        ok "Default shell set to fish"
    else
        err "Fish not found in PATH"
    fi

    # ── Fish config directory ──
    step "[3/4]" "Configuring fish..."
    mkdir -p "$HOME/.config/fish"
    if [[ ! -f "$HOME/.config/fish/config.fish" ]]; then
        cat > "$HOME/.config/fish/config.fish" << 'EOF'
if status is-interactive
    # Commands to run in interactive sessions
end
EOF
        ok "Created fish config"
    else
        info "Fish config already exists"
    fi

    # ── Bash guards (for SSH/scp compatibility) ──
    step "[4/4]" "Fixing bash for non-interactive sessions..."
    if [[ -f "$HOME/.bashrc" ]]; then
        if head -5 "$HOME/.bashrc" | grep -q 'case \$- in'; then
            info "Non-interactive guard already present"
        else
            local tmp
            tmp=$(mktemp)
            cat > "$tmp" << 'GUARD'
# Exit early for non-interactive sessions (required for scp/mosh)
case $- in
    *i*) ;;
    *) return;;
esac

GUARD
            cat "$HOME/.bashrc" >> "$tmp"
            mv "$tmp" "$HOME/.bashrc"
            ok "Added non-interactive guard to .bashrc"
        fi

        # Guard cargo env if present
        if grep -q '\.cargo/env' "$HOME/.bashrc" 2>/dev/null; then
            sed -i.bak 's|^\. "\$HOME/\.cargo/env"|[ -f "$HOME/.cargo/env" ] \&\& . "$HOME/.cargo/env"|g' "$HOME/.bashrc"
            sed -i.bak 's|^source "\$HOME/\.cargo/env"|[ -f "$HOME/.cargo/env" ] \&\& . "$HOME/.cargo/env"|g' "$HOME/.bashrc"
            rm -f "$HOME/.bashrc.bak"
            ok "Guarded cargo env sourcing"
        fi
    else
        info "No .bashrc found, skipping"
    fi

    # ── Tmux config ──
    if ! grep -q "set -g mouse on" "$HOME/.tmux.conf" 2>/dev/null; then
        echo "set -g mouse on" >> "$HOME/.tmux.conf"
        ok "Enabled tmux mouse mode"
    else
        info "Tmux mouse mode already enabled"
    fi

    done_section
}
