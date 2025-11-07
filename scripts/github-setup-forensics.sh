#!/usr/bin/env bash
set -euo pipefail

echo "== SYSTEM =="
uname -a || true
lsb_release -a 2>/dev/null || true
echo

echo "== GIT =="
git --version
echo
echo "Repo: $(basename "$(git rev-parse --show-toplevel)")"
echo "Branch: $(git rev-parse --abbrev-ref HEAD)"
echo "Remote -v:"
git remote -v
echo
echo "Config (origins, creds, proxies, overrides):"
git config --show-origin -l | grep -E '^(file:|global:|system:).*' -n || true
git config -l --show-origin | grep -E 'remote\.origin|credential|http\..*proxy|core\.sshCommand|url\..*\.insteadof' || true
echo
echo "Hooks:"
ls -l .git/hooks/pre-push 2>/dev/null || echo "no pre-push hook"
echo

echo "== SSH =="
test -f ~/.ssh/config && { echo "~/.ssh/config:"; sed -n '1,200p' ~/.ssh/config; } || echo "no ~/.ssh/config"
echo
echo "Known hosts (github):"
grep -n "github.com" ~/.ssh/known_hosts 2>/dev/null || echo "not present"
echo
echo "Agent + keys:"
ssh-add -l || echo "no agent or no keys loaded"
echo
echo "SSH test to github.com:22 (expect a greeting or success/failure code):"
ssh -T git@github.com -o BatchMode=yes || true
echo
echo "SSH test to ssh.github.com:443:"
ssh -T -p 443 git@ssh.github.com -o BatchMode=yes || true
echo

echo "== GH CLI =="
which gh || echo "gh not found"
gh --version 2>/dev/null || true
gh auth status -h github.com || true
test -f ~/.config/gh/hosts.yml && { echo "~/.config/gh/hosts.yml:"; sed -n '1,120p' ~/.config/gh/hosts.yml; } || echo "no gh hosts.yml"
echo

echo "== ENV =="
env | grep -E '^(HTTPS?_PROXY|ALL_PROXY|NO_PROXY|GIT_SSH_COMMAND)=' || true
echo

echo "== LFS (if present) =="
command -v git-lfs >/dev/null && git lfs env || echo "git-lfs not installed"
echo

echo "== LAST PUSH-LIKE COMMITS AROUND OCT 21 =="
git log --since="2025-10-20 00:00" --until="2025-10-22 23:59" --pretty=format:'%h %ad %s' --date=iso | sed -n '1,40p' || true
