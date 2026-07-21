#!/usr/bin/env fish

# changelog
# 2.4 - 2026-07-21
#   - change name from envsource to load_env
# 2.3 - 2026-06-24
#   - Fixed cron authentication issue
# 2.0
#   - date: 2026-06-23
#   - tweaks from xAI
#   - Added envsource + GH_TOKEN support
#   - Better logging structure
# version: 1.1
#   - date: 2026-03-13
#   - minor improvements

set --local ver 2.6

test -d ~/log; or mkdir -p ~/log
set --local log_file ~/log/(status basename | string replace '.fish' '').log

set user "pothi"
set --local clone_path ~/archive/clone-all-github-repos/(date +%Y-%m)
set --local --export PATH ~/bin ~/.local/bin /opt/homebrew/bin /usr/local/bin $PATH

# Load GH_TOKEN
if not set -q GH_TOKEN
    if test -f ~/.env
        load_env ~/.env
    end
end

if not set -q GH_TOKEN
    echo "ERROR: GH_TOKEN not set." | tee -a $log_file
    exit 1
end

echo "=== Run started: $(date +'%Y-%m-%d %H:%M:%S') ===" | tee -a $log_file
echo "Debug → User: $user | Token length: "(string length $GH_TOKEN) | tee -a $log_file

if not command -q gh
    echo "Error: gh CLI not found." | tee -a $log_file
    exit 1
end

if test -d $clone_path && count $clone_path/* >/dev/null
    echo "Backups already exist for this month → skipping" | tee -a $log_file
    exit 0
end

mkdir -p $clone_path

set time_start (date +%s)   # ← This was missing

function clone_repo --argument repo clone_path log_file
    set repo_name (string replace '/' '-' $repo)
    set target "$clone_path/$repo_name"

    if not test -d $target
        echo "→ Cloning $repo ..." | tee -a $log_file
        gh repo clone $repo $target -- --depth=1 2>&1 | tee -a $log_file
    else
        echo "→ Skipping (exists): $repo" | tee -a $log_file
    end
end

echo "Fetching & cloning public repos..." | tee -a $log_file
gh repo list $user --limit 400 --visibility public --json nameWithOwner -q '.[].nameWithOwner' | \
    while read -l repo
        clone_repo $repo $clone_path $log_file
    end

echo "Fetching & cloning private repos..." | tee -a $log_file
gh repo list $user --limit 400 --visibility private --json nameWithOwner -q '.[].nameWithOwner' | \
    while read -l repo
        clone_repo $repo $clone_path $log_file
    end

set time_end (date +%s)
set runtime (math $time_end - $time_start)
set runtime_min (math -s0 $runtime / 60)
set runtime_sec (math $runtime % 60)

echo "Execution time: $runtime_min min $runtime_sec sec" | tee -a $log_file
echo "=== Run completed: $(date +'%Y-%m-%d %H:%M:%S') ===" | tee -a $log_file
