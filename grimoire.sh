#!/bin/bash
# ╔══════════════════════════════════════════════════╗
# ║         grimoire — fish bootstrap                ║
# ╚══════════════════════════════════════════════════╝
#
# Ensures fish is installed, then hands off to grimoire.fish

set -e

GRIMOIRE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Detect package manager ──
detect_pkg_manager() {
    if command -v brew &>/dev/null; then echo "brew"
    elif command -v apt &>/dev/null; then echo "apt"
    elif command -v dnf &>/dev/null; then echo "dnf"
    elif command -v pacman &>/dev/null; then echo "pacman"
    else echo "unknown"
    fi
}

install_fish() {
    local pkg_mgr="$1"
    echo "  Installing fish..."
    case "$pkg_mgr" in
        brew)   brew install fish ;;
        apt)    sudo apt update -qq && sudo apt install -y fish ;;
        dnf)    sudo dnf install -y fish ;;
        pacman) sudo pacman -S --noconfirm fish ;;
        *)      echo "  ✗ Unknown package manager. Install fish manually."; exit 1 ;;
    esac
}

set_default_shell() {
    local fish_path="$1"
    if [[ "$SHELL" == *"fish"* ]]; then
        return
    fi
    if ! grep -q "$fish_path" /etc/shells 2>/dev/null; then
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi
    chsh -s "$fish_path"
    echo "  ✓ Default shell set to fish"
}

# ── Main ──
if command -v fish &>/dev/null; then
    echo "  ✓ Fish already installed"
else
    PKG=$(detect_pkg_manager)
    install_fish "$PKG"
fi

fish_path="$(command -v fish)"
set_default_shell "$fish_path"

exec fish "$GRIMOIRE_DIR/grimoire.fish" "$@"
