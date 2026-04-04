#!/bin/bash
# ── Connection Setup: SSH key, config, fish function ─

setup_connection() {
    local local_name="$1"

    section "Connect $local_name to another machine"

    remote_name=$(prompt_default "Remote machine name:" "kr4ken")
    remote_ip=$(prompt_default "Remote IP:" "192.168.2.51")
    remote_user=$(prompt_default "Remote user:" "mayan")
    remote_dir=$(prompt_default "Default remote directory:" "/mnt/c/Projects/")

    local key_name="${local_name}-${remote_name}"

    # ── SSH Key ──
    step "[1/4]" "SSH key ($key_name)..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if [[ -f "$HOME/.ssh/$key_name" ]]; then
        info "Key $key_name already exists"
    else
        ssh-keygen -t ed25519 -f "$HOME/.ssh/$key_name" -N ""
        ok "Generated $key_name"
    fi

    # ── SSH Config ──
    step "[2/4]" "SSH config..."
    if grep -q "Host $remote_name" "$HOME/.ssh/config" 2>/dev/null; then
        info "$remote_name already in SSH config"
    else
        cat >> "$HOME/.ssh/config" << EOF

Host $remote_name
    HostName $remote_ip
    User $remote_user
    IdentityFile ~/.ssh/$key_name
EOF
        chmod 600 "$HOME/.ssh/config"
        ok "Added $remote_name to SSH config"
    fi

    # ── Fish function ──
    step "[3/4]" "Fish connection function..."
    local fish_config="$HOME/.config/fish/config.fish"
    mkdir -p "$HOME/.config/fish"

    if grep -q "function $remote_name" "$fish_config" 2>/dev/null; then
        info "Function $remote_name already exists in fish config"
    else
        cat >> "$fish_config" << FISHEOF

function $remote_name --description "Connect to $remote_name tmux session"
    set -l project (test (count \$argv) -gt 0; and echo \$argv[1]; or echo "")
    if test -n "\$project"
        mosh --no-ssh-pty $remote_name -- tmux new-session -A -s \$project -c ${remote_dir}\$project
    else
        mosh --no-ssh-pty $remote_name -- tmux new-session -A -s main -c ${remote_dir}
    end
end
FISHEOF
        ok "Added $remote_name function to fish config"
    fi

    # ── Copy key ──
    step "[4/4]" "Copying SSH key to $remote_name..."
    echo ""
    info "Your public key:"
    echo ""
    echo -e "${CYAN}  │${NC}    $(cat "$HOME/.ssh/$key_name.pub")"
    echo ""
    info "Attempting ssh-copy-id (you may need to enter a password)..."
    echo ""

    if ssh-copy-id -i "$HOME/.ssh/$key_name" "$remote_name" 2>/dev/null; then
        ok "Key copied successfully"
    else
        warn "ssh-copy-id failed. Paste the key above into the remote machine's"
        warn "~/.ssh/authorized_keys (Linux) or"
        warn "C:\\Users\\$remote_user\\.ssh\\authorized_keys (Windows)"
    fi

    done_section

    echo -e "${PURPLE}${BOLD}  Usage:${NC}"
    echo -e "    ${BOLD}$remote_name${NC}          — connect to main session"
    echo -e "    ${BOLD}$remote_name myapp${NC}    — connect to project session"
    echo -e "    ${BOLD}Ctrl+b d${NC}             — detach without killing"
    echo ""
}
