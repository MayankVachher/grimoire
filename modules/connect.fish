#!/usr/bin/env fish
# ── Connection Setup: mosh, tmux, SSH key, config, fish function ─

function setup_connection
    set -l local_name $argv[1]

    section "Connect $local_name to another machine"

    set remote_name (prompt_default "Remote machine name:" "kr4ken")
    set remote_ip (prompt_default "Remote IP:" "192.168.2.51")
    set remote_user (prompt_default "Remote user:" "mayan")
    set remote_dir (prompt_default "Default remote directory:" "/mnt/c/Projects/")

    set -l key_name "$local_name-$remote_name"

    # ── SSH Key ──
    step "[1/5]" "SSH key ($key_name)..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if test -f "$HOME/.ssh/$key_name"
        info "Key $key_name already exists"
    else
        ssh-keygen -t ed25519 -f "$HOME/.ssh/$key_name" -N ""
        ok "Generated $key_name"
    end

    # ── SSH Config ──
    step "[2/5]" "SSH config..."
    if test -f "$HOME/.ssh/config"; and grep -q "Host $remote_name" "$HOME/.ssh/config"
        info "$remote_name already in SSH config"
    else
        echo "
Host $remote_name
    HostName $remote_ip
    User $remote_user
    IdentityFile ~/.ssh/$key_name" >> "$HOME/.ssh/config"
        chmod 600 "$HOME/.ssh/config"
        ok "Added $remote_name to SSH config"
    end

    # ── Tmux config ──
    step "[3/5]" "Configuring tmux..."
    if not grep -q "set -g mouse on" "$HOME/.tmux.conf" 2>/dev/null
        echo "set -g mouse on" >> "$HOME/.tmux.conf"
        ok "Enabled tmux mouse mode"
    else
        info "Tmux mouse mode already enabled"
    end

    set -l fish_path (command -v fish)
    if test -n "$fish_path"
        if grep -q "default-shell" "$HOME/.tmux.conf" 2>/dev/null
            sed -i.bak "s|.*default-shell.*|set-option -g default-shell $fish_path|" "$HOME/.tmux.conf"
            rm -f "$HOME/.tmux.conf.bak"
        else
            echo "set-option -g default-shell $fish_path" >> "$HOME/.tmux.conf"
        end
        ok "Set tmux default shell to fish"
    end

    # ── Bash guards (for SSH/scp compatibility) ──
    step "[4/5]" "Fixing bash for non-interactive sessions..."
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
    else
        info "No .bashrc found, skipping"
    end

    # ── Fish function ──
    step "[5/5]" "Fish connection function..."
    set -l fish_config "$HOME/.config/fish/config.fish"

    if grep -q "function $remote_name" "$fish_config" 2>/dev/null
        info "Function $remote_name already exists in fish config"
    else
        echo "
function $remote_name --description \"Connect to $remote_name tmux session\"
    set -l project (test (count \$argv) -gt 0; and echo \$argv[1]; or echo \"\")
    if test -n \"\$project\"
        mosh --no-ssh-pty $remote_name -- tmux new-session -A -s \$project -c $remote_dir\$project
    else
        mosh --no-ssh-pty $remote_name -- tmux new-session -A -s main -c $remote_dir
    end
end" >> "$fish_config"
        ok "Added $remote_name function to fish config"
    end

    # ── Copy key ──
    info "Your public key:"
    echo ""
    echo $CYAN"  │"$NC"    "(cat "$HOME/.ssh/$key_name.pub")
    echo ""
    info "Attempting ssh-copy-id (you may need to enter a password)..."
    echo ""

    if ssh-copy-id -i "$HOME/.ssh/$key_name" "$remote_name" 2>/dev/null
        ok "Key copied successfully"
    else
        warn "ssh-copy-id failed. Paste the key above into the remote machine's"
        warn "~/.ssh/authorized_keys (Linux) or"
        warn "C:\\Users\\$remote_user\\.ssh\\authorized_keys (Windows)"
    end

    done_section

    echo $PURPLE$BOLD"  Usage:"$NC
    echo "    "$BOLD$remote_name$NC"          — connect to main session"
    echo "    "$BOLD"$remote_name myapp"$NC"    — connect to project session"
    echo "    "$BOLD"Ctrl+b d"$NC"             — detach without killing"
    echo ""
end
