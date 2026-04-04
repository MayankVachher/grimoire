#!/bin/bash
# ╔══════════════════════════════════════════════════╗
# ║              grimoire — machine setup            ║
# ╚══════════════════════════════════════════════════╝

set -e

GRIMOIRE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Load modules ─────────────────────────────────────
source "$GRIMOIRE_DIR/modules/ui.sh"
source "$GRIMOIRE_DIR/modules/detect.sh"
source "$GRIMOIRE_DIR/modules/os.sh"
source "$GRIMOIRE_DIR/modules/github.sh"
source "$GRIMOIRE_DIR/modules/connect.sh"

# ══════════════════════════════════════════════════════
# ── Main ─────────────────────────────────────────────
# ══════════════════════════════════════════════════════
main() {
    banner

    OS=$(detect_os)
    PKG=$(detect_pkg_manager)

    section "Detected environment"
    info "OS: $OS"
    info "Package manager: $PKG"

    if [[ "$OS" == "unknown" ]]; then
        err "Could not detect OS. Run on macOS, Linux, or WSL."
        exit 1
    fi

    if [[ "$PKG" == "unknown" ]]; then
        err "Could not detect package manager."
        exit 1
    fi

    MACHINE_NAME=$(prompt_default "Name this machine:" "gh0st")

    choices=$(show_multi_menu "What would you like to set up?" \
        "OS (fish, mosh, tmux)" \
        "GitHub (gh, git config, SSH key)" \
        "Connect to a remote machine")

    # Check if "all" was selected
    if [[ "$choices" == *"4"* ]]; then
        choices="1 2 3"
    fi

    for c in $choices; do
        case "$c" in
            1) setup_os "$OS" "$PKG" "$MACHINE_NAME" ;;
            2) setup_github "$MACHINE_NAME" "$PKG" ;;
            3) setup_connection "$MACHINE_NAME" ;;
            *) err "Unknown option: $c" ;;
        esac
    done

    complete_banner
}

main "$@"
