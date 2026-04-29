# Goblin Mode

Remove one strangely specific Codex style restriction, without patching Codex.

Goblin Mode installs a local Codex profile that uses GPT-5.5's own cached base
instructions with only the creature-metaphor guardrail lines removed.

It does not change server-side safety policy. It does not modify the Codex
binary. It just writes a profile in `~/.codex/config.toml`.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/hrkrshnn/goblin-mode/refs/heads/main/install.sh | bash
```

Then run Codex in Goblin Mode:

```bash
codex --profile goblin-mode
```

For non-interactive runs:

```bash
codex exec --profile goblin-mode "explain this repo like a tired staff engineer"
```

## Demo

<a href="https://asciinema.org/a/dbiXv06clrwzdVQN?autoplay=1">
  <img src="https://asciinema.org/a/dbiXv06clrwzdVQN.svg" alt="Goblin Mode terminal demo" width="100%" />
</a>

Click the preview to open the asciinema player. This one is recorded at 80x24 so
the hosted player renders big and chunky.

The demo starts from the public installer, shows the before/after prompt audit,
then runs a debugging-progress prompt that does not name the listed words.

## What It Does

The installer:

- runs `codex debug models` to refresh local model metadata
- reads GPT-5.5's `base_instructions` from `~/.codex/models_cache.json`
- removes the entire creature-metaphor guardrail lines, not just the words inside them
- prints a before/after audit of the removed lines and verifies no matching lines remain
- writes the cleaned prompt to `~/.codex/gpt-5.5-goblin-mode.md`
- adds this profile to `~/.codex/config.toml`

```toml
[profiles.goblin-mode]
model = "gpt-5.5"
model_instructions_file = "/home/you/.codex/gpt-5.5-goblin-mode.md"
```

## Options

Use a different profile name:

```bash
PROFILE=wild-cardboard-office bash install.sh
codex --profile wild-cardboard-office
```

Use a different model slug, if Codex exposes compatible cached instructions:

```bash
MODEL=gpt-5.5 PROFILE=goblin-mode bash install.sh
```

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/hrkrshnn/goblin-mode/refs/heads/main/uninstall.sh | bash
```

Or from a local checkout:

```bash
./uninstall.sh
```

## Why A Profile?

A top-level `model_instructions_file` override is global and easy to forget.
Goblin Mode is a profile so normal Codex stays normal, and the altered prompt is
only used when you explicitly ask for it:

```bash
codex --profile goblin-mode
```

If you want it to feel global, add a shell alias:

```bash
alias codex-goblin='codex --profile goblin-mode'
```

## Requirements

- Codex CLI
- `node`
- a local Codex model cache, which the installer tries to refresh for you

## Notes

This is intentionally tiny. If Codex changes how it stores model metadata or
removes the source line upstream, the installer will stop with an error instead
of guessing.
