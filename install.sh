#!/usr/bin/env bash
set -euo pipefail

MODEL="${MODEL:-gpt-5.5}"
PROFILE="${PROFILE:-goblin-mode}"
CODEX_HOME="${CODEX_HOME:-$HOME/.codex}"
CONFIG_FILE="$CODEX_HOME/config.toml"
MODEL_CACHE="$CODEX_HOME/models_cache.json"
INSTRUCTIONS_FILE="$CODEX_HOME/$MODEL-goblin-mode.md"

if [[ ! "$PROFILE" =~ ^[A-Za-z0-9_-]+$ ]]; then
  echo "Profile names must use only letters, numbers, underscores, and dashes." >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Codex CLI was not found on PATH. Install Codex first, then rerun Goblin Mode." >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Goblin Mode needs node to edit Codex's JSON/TOML config safely." >&2
  exit 1
fi

mkdir -p "$CODEX_HOME"

echo "Refreshing Codex model metadata..."
codex debug models >/dev/null 2>&1 || true

if [[ ! -f "$MODEL_CACHE" ]]; then
  echo "Could not find $MODEL_CACHE after running 'codex debug models'." >&2
  exit 1
fi

node - "$MODEL_CACHE" "$CONFIG_FILE" "$INSTRUCTIONS_FILE" "$MODEL" "$PROFILE" <<'NODE'
const fs = require("fs");

const [cachePath, configPath, instructionsPath, model, profile] = process.argv.slice(2);
const cache = JSON.parse(fs.readFileSync(cachePath, "utf8"));
const models = Array.isArray(cache) ? cache : cache.models || [];
const entry = models.find((candidate) => candidate.slug === model);

if (!entry || typeof entry.base_instructions !== "string") {
  throw new Error(`Could not find base_instructions for ${model} in ${cachePath}`);
}

const lines = entry.base_instructions.split(/\r?\n/);
const creatureGuardrailPattern =
  /\b(goblin|gremlin|raccoon|troll|ogre|pigeon|animals?|creatures?)\b/i;
const removedLines = [];
const cleaned = lines.filter((line, index) => {
  const shouldRemove = creatureGuardrailPattern.test(line);
  if (shouldRemove) {
    removedLines.push({ number: index + 1, text: line });
  }
  return !shouldRemove;
});
const residualMatches = cleaned
  .map((line, index) => ({ number: index + 1, text: line }))
  .filter(({ text }) => creatureGuardrailPattern.test(text));

if (removedLines.length === 0) {
  throw new Error("No matching creature guardrail lines were found. Codex may have changed its prompt.");
}

if (residualMatches.length > 0) {
  throw new Error(`Cleaned prompt still contains ${residualMatches.length} matching creature guardrail line(s).`);
}

fs.writeFileSync(instructionsPath, `${cleaned.join("\n")}\n`);

const profileHeader = `[profiles.${profile}]`;
let config = fs.existsSync(configPath) ? fs.readFileSync(configPath, "utf8") : "";
const escapedProfile = profile.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const profilePattern = new RegExp(`\\n?\\[profiles\\.${escapedProfile}\\]\\n[\\s\\S]*?(?=\\n\\[|$)`);
config = config.replace(profilePattern, "\n").trimEnd();

const block = [
  "",
  profileHeader,
  `model = ${JSON.stringify(model)}`,
  `model_instructions_file = ${JSON.stringify(instructionsPath)}`,
  ""
].join("\n");

fs.writeFileSync(configPath, `${config}${block}`);

console.log("Prompt before/after audit:");
for (const removedLine of removedLines) {
  console.log(`- before line ${removedLine.number}: ${removedLine.text}`);
  console.log("  after: <removed entire line>");
}
console.log(`Verification: 0 matching creature guardrail line(s) remain after removal.`);
console.log(`Wrote ${instructionsPath}`);
console.log(`Installed Codex profile '${profile}'.`);
NODE

echo
echo "Goblin Mode is installed."
echo "Run it with:"
echo "  codex --profile $PROFILE"
echo
echo "Or for non-interactive runs:"
echo "  codex exec --profile $PROFILE \"your task here\""
