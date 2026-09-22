#!/usr/bin/env bash
# aliases.sh - my git aliases, as a script you can source.
#
# Why: I retype `git log --oneline --graph --decorate` a dozen times a day.
# These are the ones that survived. Source this from your ~/.bashrc or
# ~/.zshrc:
#
#   echo 'source ~/dev-snippets/git/aliases.sh' >> ~/.bashrc
#
# Or just run it once to see them, then cherry-pick what you like.
#
# Gotchas:
#   - `git config --global alias.X` writes to ~/.gitconfig. If you already have
#     an alias named the same, this overwrites it. Check with `git config
#     --get-regexp '^alias\.'` first.
#   - The `!` prefix means "run this as a shell command", not a git subcommand.
#     Quoting inside those is finicky; that's why a couple are one-liners.
set -euo pipefail

# Status and log
git config --global alias.s   'status -sb'
git config --global alias.lg  'log --oneline --graph --decorate -20'
git config --global alias.ll  'log --pretty=format:"%C(yellow)%h%Creset %ad %C(cyan)%an%Creset %s" --date=short'
git config --global alias.last 'log -1 HEAD --stat'

# Diff helpers
git config --global alias.d   'diff'
git config --global alias.ds  'diff --stat'
git config --global alias.dw  'diff --word-diff'

# Branching
git config --global alias.sw  'switch'
git config --global alias.swc 'switch -c'
git config --global alias.br  'branch -vv'
git config --global alias.bra 'branch -a'

# Undo / fixups
git config --global alias.unstage 'restore --staged'
git config --global alias.uncommit 'reset --soft HEAD~1'
git config --global alias.amend 'commit --amend --no-edit'

# Housekeeping
git config --global alias.stashes 'stash list'
git config --global alias.prune-branches 'remote prune origin'
# The dangerous one. Show what it would delete first:
git config --global alias.gone '!git branch -vv | awk "/: gone]/ {print \$1}"'

echo "installed git aliases. try: git lg"
echo "see them all: git config --get-regexp '^alias\.'"
