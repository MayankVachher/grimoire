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
    read -l -P $CYAN"  │"$NC"  "$BOLD$argv[1]$NC" "$DIM"[$argv[2]]"$NC" " input; or exit 1
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
    echo $CYAN"  │"$NC"    "$PURPLE"0"$NC") None" >&2

    echo $CYAN"  │"$NC >&2
    read -l -P $CYAN"  │"$NC"  "$BOLD"Choose:"$NC" " choices; or exit 1
    echo $choices
end

function confirm
    read -l -P $CYAN"  │"$NC"  "$BOLD$argv[1]$NC" "$DIM"[y/N]"$NC" " answer; or exit 1
    string match -qi 'y' "$answer"
end

function show_icon_menu
    set -l default $argv[1]
    set -l icons \
        "🐙" "🦑" "🐉" "🐺" "🦊" \
        "🔮" "⚡" "🌀" "💀" "👾" \
        "🤖" "🎮" "🚀" "🛸" "⚔️" \
        "🦇" "🐍" "🌊" "🔥" "💎"

    echo "" >&2
    echo $CYAN"  │"$NC >&2
    echo $CYAN"  │"$NC"  "$BOLD"Choose a prompt icon:"$NC >&2
    echo $CYAN"  │"$NC >&2

    for i in (seq (count $icons))
        set -l row_end ""
        if test (math "$i % 5") -eq 0
            set row_end "\n"$CYAN"  │"$NC
        end
        echo -n "    "$PURPLE$i$NC") $icons[$i]" >&2
        if test -n "$row_end"
            echo -e $row_end >&2
        end
    end

    echo "" >&2
    echo $CYAN"  │"$NC >&2
    if test -n "$default"
        read -l -P $CYAN"  │"$NC"  "$BOLD"Choose [1-20]:"$NC" "$DIM"[$default]"$NC" " choice; or exit 1
    else
        read -l -P $CYAN"  │"$NC"  "$BOLD"Choose [1-20]:"$NC" " choice; or exit 1
    end

    if test -n "$choice"; and test "$choice" -ge 1 2>/dev/null; and test "$choice" -le 20 2>/dev/null
        echo $icons[$choice]
    else if test -n "$default"
        echo $default
    else
        echo $icons[1]
    end
end

function complete_banner
    echo $PURPLE$BOLD
    echo "  ╔══════════════════════════════════════╗"
    echo "  ║         ✦  setup complete  ✦         ║"
    echo "  ╚══════════════════════════════════════╝"
    echo $NC
end
