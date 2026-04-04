#!/bin/bash
# ── OS & Package Manager Detection ───────────────────

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif grep -qi microsoft /proc/version 2>/dev/null; then
        echo "wsl"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

detect_pkg_manager() {
    if command -v brew &>/dev/null; then echo "brew"
    elif command -v apt &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v pacman &>/dev/null; then echo "pacman"
    else echo "unknown"
    fi
}

install_packages() {
    local pkg_mgr="$1"
    shift
    local packages=("$@")

    case "$pkg_mgr" in
        brew)   brew install "${packages[@]}" ;;
        apt)    sudo apt update -qq && sudo apt install -y "${packages[@]}" ;;
        dnf)    sudo dnf install -y "${packages[@]}" ;;
        pacman) sudo pacman -S --noconfirm "${packages[@]}" ;;
        *)      err "Unknown package manager"; return 1 ;;
    esac
}
