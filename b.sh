#!/usr/bin/env bash
# codex-relay one-line bootstrap (Linux, no root)
set -u
say(){ printf '\n== %s\n' "$*"; }

say "1/4 ensure gh"
if ! command -v gh >/dev/null 2>&1; then
  mkdir -p "$HOME/bin"
  case "$(uname -m)" in
    x86_64) A=amd64 ;; aarch64|arm64) A=arm64 ;; *) A=amd64 ;;
  esac
  cd /tmp || exit 1
  curl -fsSL -o gh.tgz "https://github.com/cli/cli/releases/download/v2.105.0/gh_2.105.0_linux_${A}.tar.gz" || { echo "gh download failed"; exit 1; }
  tar xzf gh.tgz || exit 1
  cp "gh_2.105.0_linux_${A}/bin/gh" "$HOME/bin/gh" && chmod +x "$HOME/bin/gh"
  export PATH="$HOME/bin:$PATH"
fi
gh --version | head -1

say "2/4 github login (device code once)"
if ! gh auth status >/dev/null 2>&1; then
  gh auth login --hostname github.com --git-protocol https --web || { echo "login failed"; exit 1; }
fi
gh auth status | head -3

say "3/4 fetch agent"
mkdir -p "$HOME/relay"
gh api repos/xhh233/codex-relay/contents/relay-agent.sh -H 'Accept: application/vnd.github.raw' > "$HOME/relay/relay-agent.sh" || { echo "fetch failed"; exit 1; }
chmod +x "$HOME/relay/relay-agent.sh"

say "4/4 start agent (background)"
pkill -f 'relay-agent.sh' 2>/dev/null || true
nohup bash "$HOME/relay/relay-agent.sh" > "$HOME/relay/relay.log" 2>&1 &
sleep 4
tail -n 15 "$HOME/relay/relay.log"