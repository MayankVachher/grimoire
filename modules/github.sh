#!/bin/bash
# ── GitHub Setup: gh, git config, SSH key ────────────

GITHUB_USERNAME="MayankVachher"

setup_github() {
    local machine_name="$1"
    local pkg_mgr="$2"
    local email="mayankv0207+${machine_name}@gmail.com"
    local key_name="${machine_name}-github"

    section "Setting up GitHub for $machine_name"

    # ── Install gh ──
    step "[1/5]" "Installing GitHub CLI..."
    if command -v gh &>/dev/null; then
        info "gh already installed"
    else
        install_packages "$pkg_mgr" gh
        ok "Installed gh"
    fi

    # ── Git config ──
    step "[2/5]" "Configuring git..."
    git config --global user.name "$GITHUB_USERNAME"
    git config --global user.email "$email"
    ok "Set user.name=$GITHUB_USERNAME, user.email=$email"

    # ── SSH key ──
    step "[3/5]" "SSH key ($key_name)..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ -f "$HOME/.ssh/$key_name" ]]; then
        info "Key $key_name already exists"
    else
        ssh-keygen -t ed25519 -f "$HOME/.ssh/$key_name" -N ""
        ok "Generated $key_name"
    fi

    # ── SSH config for GitHub ──
    step "[4/5]" "SSH config for github.com..."
    if grep -q "Host github.com" "$HOME/.ssh/config" 2>/dev/null; then
        info "github.com already in SSH config"
    else
        cat >> "$HOME/.ssh/config" << EOF

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/$key_name
EOF
        chmod 600 "$HOME/.ssh/config"
        ok "Added github.com to SSH config"
    fi

    # ── Add key to GitHub ──
    step "[5/5]" "Adding key to GitHub..."
    info "Your public key:"
    echo ""
    echo -e "${CYAN}  │${NC}    $(cat "$HOME/.ssh/$key_name.pub")"
    echo ""

    if gh auth status &>/dev/null; then
        if gh ssh-key add "$HOME/.ssh/$key_name.pub" -t "$machine_name" 2>/dev/null; then
            ok "Key added to GitHub"
        else
            info "Key may already be registered on GitHub"
        fi
    else
        warn "Not logged in to GitHub. Run: gh auth login"
        warn "Then run: gh ssh-key add ~/.ssh/$key_name.pub -t $machine_name"
    fi

    done_section

    echo -e "${PURPLE}${BOLD}  Verify:${NC}"
    echo -e "    ${BOLD}ssh -T git@github.com${NC}"
    echo ""
}
