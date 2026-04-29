#!/usr/bin/env bash
set -euo pipefail

MODEL="${MODEL:-gpt-5.5}"
PROFILE="${PROFILE:-goblin-mode}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME/config.toml"
INSTRUCTIONS_FILE="$CODEX_HOME/$MODEL-goblin-mode.md"

if [[ ! "$PROFILE" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Profile names must use only letters, numbers, underscores, and dashes." >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Goblin Mode uninstall needs node to edit Codex's TOML config safely." >&2
  exit 1
fi

node - "$CONFIG_FILE" "$PROFILE" <<'NODE'
const fs = require("fs");

const [configPath, profile] = process.argv.slice(2);
if (!fs.existsSync(configPath)) {
  process.exit(0);
}

const escapedProfile = profile.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const profilePattern = new RegExp(`\\n?\\[profiles\\.${escapedProfile}\\]\\n[\\s\\S]*?(?=\\n\\[|$)`);
const config = fs.readFileSync(configPath, "utf8").replace(profilePattern, "\n").trimEnd();
fs.writeFileSync(configPath, config ? `${config}\n` : "");
NODE

rm -f "$INSTRUCTIONS_FILE"

echo "Goblin Mode profile '$PROFILE' removed."
