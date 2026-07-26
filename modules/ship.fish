#!/usr/bin/env fish
# ── ship: branch → PR → wait for CI → merge ─────────

function setup_ship
    section "Setting up ship"

    set -l fish_config "$HOME/.config/fish/config.fish"

    if grep -q "function ship" "$fish_config" 2>/dev/null
        info "ship already installed"
        return
    end

    echo '
function ship --description "commit → branch → PR → wait for CI → merge (-s squash | -m merge)"
    argparse "s/squash" "m/merge" -- $argv; or return
    set -l msg $argv[1]
    if test -z "$msg"
        echo "usage: ship [-s|-m] \"commit message\""
        return 1
    end

    set -l method
    if set -q _flag_squash
        set method squash
    else if set -q _flag_merge
        set method merge
    else
        read -P "merge method — (s)quash or (m)erge commit? " ans
        switch $ans
            case s S squash
                set method squash
            case m M merge
                set method merge
            case "*"
                echo "aborted"
                return 1
        end
    end

    set -l branch (git branch --show-current)
    set -l made_branch 0
    if contains $branch main master
        set branch ship/(string lower (string replace -ra "[^a-zA-Z0-9]+" "-" $msg | string sub -l 40))
        git checkout -b $branch; or return
        set made_branch 1
    end

    git add -A; and git commit -m "$msg"; or begin
        test $made_branch = 1; and git checkout -
        return 1
    end
    git push -u origin $branch; or return
    gh pr create --fill; or return

    if not gh pr checks --watch --fail-level all
        echo "CI failed — PR left open on branch $branch"
        return 1
    end

    gh pr merge --$method --delete-branch
    and git checkout main
    and git pull --ff-only
end' >> "$fish_config"
    ok "Added ship function"
end
