#!/usr/bin/env fish
# ── Colors & Formatting ──────────────────────────────

set -g BOLD (set_color --bold)
set -g DIM (set_color --dim)
set -g RED (set_color red)
set -g GREEN (set_color green)
set -g YELLOW (set_color yellow)
set -g BLUE (set_color blue)
set -g PURPLE (set_color magenta)
set -g CYAN (set_color cyan)
set -g NC (set_color normal)

function banner
    echo ""
    echo $PURPLE$BOLD
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║           ✦  grimoire  ✦             ║"
    echo "  ║        machine setup wizard          ║"
    echo "  ╚══════════════════════════════════════╝"
    echo $NC
end

function section
    echo ""
    echo $CYAN$BOLD"  ┌─ $argv[1]"$NC
    echo $CYAN"  │"$NC
end

function step
    echo $CYAN"  ├─"$NC" "$GREEN$argv[1]$NC" $argv[2]"
end

function info
    echo $CYAN"  │"$NC"  "$DIM$argv[1]$NC
end

function warn
    echo $CYAN"  │"$NC"  "$YELLOW"⚠ $argv[1]"$NC
end

function err
    echo $CYAN"  │"$NC"  "$RED"✗ $argv[1]"$NC
end

function ok
    echo $CYAN"  │"$NC"  "$GREEN"✓ $argv[1]"$NC
end

function done_section
    echo $CYAN"  │"$NC
    echo $CYAN"  └─ "$GREEN$BOLD"done"$NC
    echo ""
end

function prompt_default
    echo -n $CYAN"  │"$NC"  "$BOLD$argv[1]$NC" "$DIM"[$argv[2]]"$NC" " >&2
    read -l input
    if test -n "$input"
        echo $input
    else
        echo $argv[2]
    end
end

function show_multi_menu
    set -l title $argv[1]
    set -l options $argv[2..-1]
    set -l count (count $options)

    echo "" >&2
    echo $CYAN"  │"$NC >&2
    echo $CYAN"  │"$NC"  "$BOLD$title$NC >&2
    echo $CYAN"  │"$NC"  "$DIM"(space-separated, e.g. 1 3)"$NC >&2
    echo $CYAN"  │"$NC >&2

    for i in (seq (count $options))
        echo $CYAN"  │"$NC"    "$PURPLE$i$NC") $options[$i]" >&2
    end

    set -l all_idx (math $count + 1)
    echo $CYAN"  │"$NC"    "$PURPLE$all_idx$NC") All of the above" >&2

    echo $CYAN"  │"$NC >&2
    echo -n $CYAN"  │"$NC"  "$BOLD"Choose:"$NC" " >&2
    read -l choices
    echo $choices
end

function complete_banner
    echo $PURPLE$BOLD
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║         ✦  setup complete  ✦         ║"
    echo "  ╚══════════════════════════════════════╝"
    echo $NC
end
