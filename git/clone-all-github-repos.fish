#!/usr/bin/env fish

set --local ver 2.0

test -d ~/log; or mkdir ~/log
set --local log_file ~/log/(status basename | awk -F. '{print $1}').log

set user "pothi"
set --local clone_path ~/archive/clone-all-github-repos/(date +%Y-%m)

# changelog
# 2.0
#   - date: 2026-06-23
#   - tweaks from xAI
#   - Added envsource + GH_TOKEN support
#   - Better logging structure
# version: 1.1
#   - date: 2026-03-13
#   - minor improvements

set --local --export PATH ~/bin ~/.local/bin /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin /snap/bin

# === Load GH_TOKEN from ~/.env (standard format) ===
if not set -q GH_TOKEN
    if test -f ~/.env
        envsource ~/.env
    end
end

if not set -q GH_TOKEN
    echo "Error: GH_TOKEN not set. Add it to ~/.env" | tee -a $log_file
    exit 1
end

# Check prerequisites
if not command -q gh
    echo "Error: gh CLI not found. Install with: apt install gh (Ubuntu)" | tee -a $log_file
    exit 1
end

gh auth status --show-token | grep -q "Token:" || begin
    echo "Error: gh not authenticated. Run: gh auth login" | tee -a $log_file
    exit 1
end

# Monthly check
if test -d $clone_path && count $clone_path/* >/dev/null
    echo "Backups already exist for this month: $clone_path" | tee -a $log_file
    echo "=== Run skipped ===" | tee -a $log_file
    exit 0
end

mkdir -p $clone_path 2> /dev/null

echo "=== Run started: $(date +'%Y-%m-%d %H:%M:%S') ===" | tee -a $log_file

set time_start (date +%s)

echo "Cloning public repos for $user..." | tee -a $log_file
gh repo list $user --limit 200 --visibility public --json nameWithOwner -q '.[].nameWithOwner' | \
    while read -l repo
        if not test -d $clone_path/(string replace '/' '-' $repo)
            echo "Cloning $repo (public)..." | tee -a $log_file
            gh repo clone $repo $clone_path/(string replace '/' '-' $repo) -- --depth=1 2>&1 | tee -a $log_file
        else
            echo "Skipping existing: $repo" | tee -a $log_file
        end
    end

echo "Cloning private repos for $user..." | tee -a $log_file
gh repo list $user --limit 200 --visibility private --json nameWithOwner -q '.[].nameWithOwner' | \
    while read -l repo
        if not test -d $clone_path/(string replace '/' '-' $repo)
            echo "Cloning $repo (private)..." | tee -a $log_file
            gh repo clone $repo $clone_path/(string replace '/' '-' $repo) -- --depth=1 2>&1 | tee -a $log_file
        else
            echo "Skipping existing: $repo" | tee -a $log_file
        end
    end

set time_end (date +%s)
set runtime (math $time_end - $time_start)
set runtime_min (math -s0 $runtime / 60)
set runtime_sec (math $runtime % 60)

echo "Execution time: $runtime_min min $runtime_sec sec" | tee -a $log_file
echo "=== Run completed successfully: $(date +'%Y-%m-%d %H:%M:%S') ===" | tee -a $log_file

