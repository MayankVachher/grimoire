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
    step "[1/3]" "SSH key ($key_name)..."
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"

    if test -f "$HOME/.ssh/$key_name"
        info "Key $key_name already exists"
    else
        ssh-keygen -t ed25519 -f "$HOME/.ssh/$key_name" -N ""
        ok "Generated $key_name"
    end

    # ── SSH Config ──
    step "[2/3]" "SSH config..."
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

    # ── Fish function ──
    step "[3/3]" "Fish connection function..."
    set -l fish_config "$HOME/.config/fish/config.fish"

    set -l new_func "function $remote_name --description \"Connect to $remote_name tmux session\"
    set -l project (test (count \$argv) -gt 0; and echo \$argv[1]; or echo \"\")
    if test -n \"\$project\"
        mosh --no-ssh-pty --bind-server=any $remote_name -- tmux new-session -A -s \$project -c $remote_dir\$project
    else
        mosh --no-ssh-pty --bind-server=any $remote_name -- tmux new-session -A -s main -c $remote_dir
    end
end"

    if grep -q "function $remote_name" "$fish_config" 2>/dev/null
        # Extract existing function
        set -l existing (sed -n "/^function $remote_name /,/^end/p" "$fish_config")
        set -l existing_str (printf '%s\n' $existing)
        if test "$existing_str" = "$new_func"
            info "Function $remote_name already up to date"
        else
            warn "Function $remote_name exists but differs:"
            info "Current:"
            for line in $existing
                info "  $line"
            end
            info "New:"
            for line in (string split \n "$new_func")
                info "  $line"
            end
            if confirm "Replace with new version?"
                sed -i.bak "/^function $remote_name /,/^end/d" "$fish_config"
                rm -f "$fish_config.bak"
                echo "" >> "$fish_config"
                echo "$new_func" >> "$fish_config"
                ok "Updated $remote_name function"
            else
                info "Keeping existing function"
            end
        end
    else
        echo "" >> "$fish_config"
        echo "$new_func" >> "$fish_config"
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
