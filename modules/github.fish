#!/usr/bin/env fish
# ── GitHub Setup: gh, git config, SSH key ────────────

set -g GITHUB_USERNAME "MayankVachher"

function setup_github
    set -l machine_name $argv[1]
    set -l email "mayankv0207+$machine_name@gmail.com"
    set -l key_name "$machine_name-github"

    section "Setting up GitHub for $machine_name"

    # ── Install gh ──
    step "[1/5]" "Installing GitHub CLI..."
    if command -q gh
        info "gh already installed"
    else
        install_packages (detect_pkg_manager) gh
        ok "Installed gh"
    end

    # ── Git config ──
    step "[2/5]" "Configuring git..."
    git config --global user.name "$GITHUB_USERNAME"
    git config --global user.email "$email"
    ok "Set user.name=$GITHUB_USERNAME, user.email=$email"

    # ── SSH key ──
    step "[3/5]" "SSH key ($key_name)..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if test -f "$HOME/.ssh/$key_name"
        info "Key $key_name already exists"
    else
        ssh-keygen -t ed25519 -f "$HOME/.ssh/$key_name" -N ""
        ok "Generated $key_name"
    end

    # ── SSH config for GitHub ──
    step "[4/5]" "SSH config for github.com..."
    set -l ssh_config "$HOME/.ssh/config"
    if grep -q "Host github.com" "$ssh_config" 2>/dev/null
        if grep -A3 "Host github.com" "$ssh_config" | grep -q "IdentityFile.*$key_name"
            info "github.com already configured with $key_name"
        else
            warn "github.com exists in SSH config but points to a different key"
            sed -i "/Host github.com/,/^Host /{ s|IdentityFile.*|IdentityFile ~/.ssh/$key_name| }" "$ssh_config"
            ok "Updated github.com to use $key_name"
        end
    else
        echo "
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/$key_name" >> "$ssh_config"
        chmod 600 "$ssh_config"
        ok "Added github.com to SSH config"
    end

    # ── Verify GitHub SSH ──
    step "[5/5]" "Verifying SSH to GitHub..."

    set -l attempts 0
    set -l ssh_ok false
    while true
        if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"
            set ssh_ok true
            break
        end

        if test $attempts -ge 2
            break
        end

        if test $attempts -gt 0
            warn "SSH to GitHub not working yet. Retrying..."
        end

        # Ensure gh is authed with the right scope
        if not gh auth status &>/dev/null
            info "Logging in to GitHub (open the URL on any browser, even another machine)..."
            if not GH_BROWSER="echo" gh auth login -p https -h github.com --web -s admin:public_key
                warn "Login failed, try again"
            end
            if not gh config set git_protocol ssh --host github.com 2>/dev/null
                warn "Could not set git protocol to SSH"
            end
        end

        # Upload the key
        if gh ssh-key add "$HOME/.ssh/$key_name.pub" -t "$machine_name" 2>/dev/null
            ok "Key added to GitHub"
        end

        set attempts (math $attempts + 1)
    end

    if test "$ssh_ok" = true
        ok "SSH to GitHub works"
    else
        err "SSH to GitHub not working. Fix manually and re-run."
    end

    done_section
end
