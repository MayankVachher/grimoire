#!/bin/bash
# ── Colors & Formatting ──────────────────────────────

BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

banner() {
    echo ""
    echo -e "${PURPLE}${BOLD}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║           ✦  grimoire  ✦             ║"
    echo "  ║        machine setup wizard          ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

section() {
    echo ""
    echo -e "${CYAN}${BOLD}  ┌─ $1${NC}"
    echo -e "${CYAN}  │${NC}"
}

step() {
    echo -e "${CYAN}  ├─${NC} ${GREEN}$1${NC} $2"
}

info() {
    echo -e "${CYAN}  │${NC}  ${DIM}$1${NC}"
}

warn() {
    echo -e "${CYAN}  │${NC}  ${YELLOW}⚠ $1${NC}"
}

err() {
    echo -e "${CYAN}  │${NC}  ${RED}✗ $1${NC}"
}

ok() {
    echo -e "${CYAN}  │${NC}  ${GREEN}✓ $1${NC}"
}

done_section() {
    echo -e "${CYAN}  │${NC}"
    echo -e "${CYAN}  └─ ${GREEN}${BOLD}done${NC}"
    echo ""
}

prompt() {
    echo -ne "${CYAN}  │${NC}  ${BOLD}$1${NC} "
}

prompt_default() {
    echo -ne "${CYAN}  │${NC}  ${BOLD}$1${NC} ${DIM}[$2]${NC} " >&2
    read -r input
    echo "${input:-$2}"
}

show_menu() {
    local title="$1"
    shift
    local options=("$@")

    echo "" >&2
    echo -e "${CYAN}  │${NC}" >&2
    echo -e "${CYAN}  │${NC}  ${BOLD}$title${NC}" >&2
    echo -e "${CYAN}  │${NC}" >&2

    for i in "${!options[@]}"; do
        echo -e "${CYAN}  │${NC}    ${PURPLE}$((i+1))${NC}) ${options[$i]}" >&2
    done

    echo -e "${CYAN}  │${NC}" >&2
    prompt "Choose [1-${#options[@]}]:" >&2
    read -r choice
    echo "$choice"
}

show_multi_menu() {
    local title="$1"
    shift
    local options=("$@")

    echo "" >&2
    echo -e "${CYAN}  │${NC}" >&2
    echo -e "${CYAN}  │${NC}  ${BOLD}$title${NC}" >&2
    echo -e "${CYAN}  │${NC}  ${DIM}(space-separated, e.g. 1 3 4)${NC}" >&2
    echo -e "${CYAN}  │${NC}" >&2

    for i in "${!options[@]}"; do
        echo -e "${CYAN}  │${NC}    ${PURPLE}$((i+1))${NC}) ${options[$i]}" >&2
    done

    local max=${#options[@]}
    echo -e "${CYAN}  │${NC}    ${PURPLE}$((max+1))${NC}) All of the above" >&2

    echo -e "${CYAN}  │${NC}" >&2
    prompt "Choose:" >&2
    read -r choices
    echo "$choices"
}

complete_banner() {
    echo -e "${PURPLE}${BOLD}"
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║         ✦  setup complete  ✦         ║"
    echo "  ╚══════════════════════════════════════╝"
    echo -e "${NC}"
}
