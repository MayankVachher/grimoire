#!/usr/bin/env fish
# ── OS Detection ─────────────────────────────────────

function detect_os
    switch (uname -s)
        case Darwin
            echo macos
        case Linux
            if test -f /proc/version; and grep -qi microsoft /proc/version
                echo wsl
            else
                echo linux
            end
        case '*'
            echo unknown
    end
end

function detect_pkg_manager
    if command -q brew
        echo brew
    else if command -q apt
        echo apt
    else if command -q dnf
        echo dnf
    else if command -q pacman
        echo pacman
    else
        echo unknown
    end
end

function install_packages
    set -l pkg_mgr $argv[1]
    set -l packages $argv[2..-1]

    switch $pkg_mgr
        case brew
            brew install $packages
        case apt
            sudo apt update -qq; and sudo apt install -y $packages
        case dnf
            sudo dnf install -y $packages
        case pacman
            sudo pacman -S --noconfirm $packages
        case '*'
            err "Unknown package manager"
            return 1
    end
end
