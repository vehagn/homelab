#!/usr/bin/env bash
# Runs in the stock node image: installs the pinned Claude Code CLI and gh onto the volume
# when they aren't there at those versions, prepares SSH and git, and starts Remote Control
# in the repository.
set -euo pipefail
# Failing (no login yet, a bad token, no network), wait rather than exit, so that
# `kubectl exec` can look and fix it.
trap 'echo "start.sh failed; waiting for kubectl exec" >&2; sleep infinity' ERR

# The passwd init container makes uid 1000 "agent" with this home; SSH reads it from there.
if [ "$(getent passwd "$(id -u)" | cut -d: -f6)" != "$HOME" ]; then
    echo "passwd home of uid $(id -u) is not $HOME; is the passwd init container mounted?" >&2
    false
fi

tools=$HOME/.local
export PATH="$tools/bin:$PATH"
mkdir -p "$tools/bin"

# Claude Code, pinned by CLAUDE_CODE_VERSION (DISABLE_AUTOUPDATER keeps it there).
if [ "$(claude --version 2>/dev/null | cut -d' ' -f1)" != "$CLAUDE_CODE_VERSION" ]; then
    npm install --global --prefix "$tools" "@anthropic-ai/claude-code@$CLAUDE_CODE_VERSION"
fi

# gh, pinned by GH_VERSION, from its release.
if [ "$(gh --version 2>/dev/null | head -1 | cut -d' ' -f3)" != "$GH_VERSION" ]; then
    arch=$(dpkg --print-architecture)
    name=gh_${GH_VERSION}_linux_${arch}
    curl -fsSL "https://github.com/cli/cli/releases/download/v$GH_VERSION/$name.tar.gz" |
        tar -xz -C /tmp
    install -m 0755 "/tmp/$name/bin/gh" "$tools/bin/gh"
    rm -rf "/tmp/$name"
fi

# SSH refuses keys others can read, and a Secret's files belong to root: copy them in as ours.
if [ -d /etc/agent-ssh ]; then
    mkdir -p ~/.ssh && chmod 0700 ~/.ssh
    for f in /etc/agent-ssh/*; do
        install -m 0600 "$f" ~/.ssh/"$(basename "$f")"
    done
fi

# git over HTTPS with GH_TOKEN, through gh.
gh auth setup-git

repo=${AGENT_REPO:-vehagn/vibe-rations}
dir=~/work/$(basename "$repo")
[ -d "$dir/.git" ] || gh repo clone "$repo" "$dir"
cd "$dir"

# Answer Remote Control's one-time questions ahead: "Enable Remote Control? (y/n)" (asked
# while remoteDialogSeen is unset) and whether to trust the repository folder.
node - "$dir" <<'EOF'
const fs = require("fs"), file = `${process.env.HOME}/.claude.json`, dir = process.argv[2];
let c = {};
try { c = JSON.parse(fs.readFileSync(file, "utf8")); } catch (e) { if (e.code !== "ENOENT") throw e; }
c.remoteDialogSeen = true;
c.projects ??= {};
c.projects[dir] = { ...c.projects[dir], hasTrustDialogAccepted: true };
fs.writeFileSync(`${file}.tmp`, JSON.stringify(c, null, 2), { mode: 0o600 });
fs.renameSync(`${file}.tmp`, file);
EOF

# Permission rules. In bypassPermissions mode (deployment.yaml) everything runs except
# what `deny` names; deny rules hold in every mode. `allow` matters when the mode is
# something else: orchestrating gauss over SSH, and read-only commands for looking
# through code (each part of a pipeline must be allowed; sed only with -n, no find).
node <<'EOF'
const fs = require("fs"), file = `${process.env.HOME}/.claude/settings.json`;
const allow = [
  "Bash(ssh gauss:*)",
  "Bash(grep:*)", "Bash(rg:*)", "Bash(sed -n:*)", "Bash(head:*)", "Bash(tail:*)",
  "Bash(cat:*)", "Bash(wc:*)", "Bash(cut:*)", "Bash(sort:*)", "Bash(uniq:*)", "Bash(ls:*)",
  "Bash(git status:*)", "Bash(git log:*)", "Bash(git diff:*)", "Bash(git show:*)",
];
// Prefix rules: they stop the plain forms, not every spelling (git push origin x -f).
const deny = [
  "Bash(git push --force:*)", "Bash(git push -f:*)",
  "Bash(gh repo delete:*)", "Bash(gh secret:*)", "Bash(gh auth:*)",
  "Bash(ssh gauss reboot:*)", "Bash(ssh gauss poweroff:*)", "Bash(ssh gauss shutdown:*)",
  "Bash(ssh gauss rm -rf /:*)",
  "Edit(~/.ssh/**)", "Edit(~/.claude/settings.json)", "Edit(~/.claude.json)",
];
let s = {};
try { s = JSON.parse(fs.readFileSync(file, "utf8")); } catch (e) { if (e.code !== "ENOENT") throw e; }
s.permissions ??= {};
s.permissions.allow = [...new Set([...(s.permissions.allow ?? []), ...allow])];
s.permissions.deny = [...new Set([...(s.permissions.deny ?? []), ...deny])];
// bypassPermissions otherwise asks, once, in a dialog nobody is there to answer.
s.skipDangerousModePermissionPrompt = true;
fs.mkdirSync(`${process.env.HOME}/.claude`, { recursive: true });
fs.writeFileSync(`${file}.tmp`, JSON.stringify(s, null, 2));
fs.renameSync(`${file}.tmp`, file);
EOF

# The login is the one step left to a person (README.md). Wait for it instead of failing.
until [ -s ~/.claude/.credentials.json ]; do
    echo "not logged in: kubectl exec in and run \`claude\`, then /login; waiting" >&2
    sleep 30
done

# Keep Remote Control up: restart it if it exits (a network outage, a crash).
trap - ERR
flags=()
[ -z "${AGENT_PERMISSION_MODE:-}" ] || flags+=(--permission-mode "$AGENT_PERMISSION_MODE")
[ -z "${AGENT_CAPACITY:-}" ] || flags+=(--capacity "$AGENT_CAPACITY")
while true; do
    rc=0
    claude remote-control --name "${AGENT_NAME:-k8s-agent}" --spawn worktree "${flags[@]}" "$@" ||
        rc=$?
    echo "claude remote-control exited ($rc); restarting in 15s" >&2
    sleep 15
done
