# llm-ui-verify (Claude Skill)

This repo provides a Claude Code skill + CLI that lets Claude run iOS UI flows, capture simulator video + telemetry, and optionally request an LLM verdict. It is designed for Claude Code environments.

## What this is
- A **Claude Skill** (packaged `.skill`) that tells Claude how to run the tool.
- A **local CLI** that executes XCTest UI flows and collects artifacts.

## Requirements
- macOS with Xcode and iOS Simulator
- `python3` on PATH
- `ffmpeg` on PATH (for keyframes)
- An XCTest UI test that drives your flow
- Accessibility identifiers for elements your UI test taps/reads

## Install the Claude Skill
1) Grab the packaged skill:
   - `/Users/cari/.codex/skills/dist/llm-ui-verify-claude.skill`
2) Install it in your Claude Code environment (use your standard skill install flow).
3) Ensure this repo is available locally on the machine running Claude Code.

### Install this repo (CLI)
```bash
git clone https://github.com/keepgoingcari/llm-ui-verify.git
cd llm-ui-verify
```

## Usage (Claude Code)
Ask Claude to run a verification flow, for example:
- “Run the UI verifier for the host flow.”
- “Verify this UI change and give me a verdict.”

Claude will use the CLI in this repo and return the run artifacts + verdict.

## Usage (CLI)
Run a flow only:
```bash
./tools/verify_flow --project /path/App.xcodeproj --scheme AppScheme \
  --only-testing Target/Class/testMethod --change "Short change description"
```

Run flow + LLM verdict:
```bash
OPENAI_API_KEY=... ./tools/verify_and_review --project /path/App.xcodeproj --scheme AppScheme \
  --only-testing Target/Class/testMethod --change "Short change description"
```

## What you get
- `runs/<timestamp>/video.mp4`
- `runs/<timestamp>/keyframes/` (dense tail frames included)
- `runs/<timestamp>/telemetry/` (per-step snapshots)
- `runs/<timestamp>/telemetry.json` (last snapshot)
- `runs/<timestamp>/verdict.json` (LLM output)

## Notes
- This is intended as a verification “assistant,” not a deterministic CI gate.
- If the app launches late, tail frames ensure the UI is still captured.
