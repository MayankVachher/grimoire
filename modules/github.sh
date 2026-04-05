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
    local ssh_config="$HOME/.ssh/config"
    if grep -q "Host github.com" "$ssh_config" 2>/dev/null; then
        if grep -A3 "Host github.com" "$ssh_config" | grep -q "IdentityFile.*$key_name"; then
            info "github.com already configured with $key_name"
        else
            warn "github.com exists in SSH config but points to a different key"
            # Replace the IdentityFile line in the github.com block
            sed -i "/Host github.com/,/^Host /{ s|IdentityFile.*|IdentityFile ~/.ssh/$key_name| }" "$ssh_config"
            ok "Updated github.com to use $key_name"
        fi
    else
        cat >> "$ssh_config" << EOF

Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/$key_name
EOF
        chmod 600 "$ssh_config"
        ok "Added github.com to SSH config"
    fi

    # ── Verify GitHub SSH ──
    step "[5/5]" "Verifying SSH to GitHub..."

    local attempts=0
    local ssh_ok=false
    while true; do
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
            ssh_ok=true
            break
        fi

        if [[ $attempts -ge 2 ]]; then
            break
        fi

        if [[ $attempts -gt 0 ]]; then
            warn "SSH to GitHub not working yet. Retrying..."
        fi

        # Ensure gh is authed with the right scope
        if ! gh auth status &>/dev/null; then
            info "Logging in to GitHub (open the URL on any browser, even another machine)..."
            if ! GH_BROWSER="echo" gh auth login -p https -h github.com --web -s admin:public_key; then
                warn "Login failed, try again"
            fi
            if ! gh config set git_protocol ssh --host github.com 2>/dev/null; then
                warn "Could not set git protocol to SSH"
            fi
        fi

        # Upload the key
        if gh ssh-key add "$HOME/.ssh/$key_name.pub" -t "$machine_name" 2>/dev/null; then
            ok "Key added to GitHub"
        fi

        attempts=$((attempts + 1))
    done

    if $ssh_ok; then
        ok "SSH to GitHub works"
    else
        err "SSH to GitHub not working. Fix manually and re-run."
    fi

    done_section
}
