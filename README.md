# llm-ui-verify

Minimal orchestration layer that gives an LLM “eyes” for iOS UI verification.

## What it does (MVP)
- Runs a scripted UI flow
- Records simulator video
- Captures a UI telemetry snapshot (SwiftUI-friendly: accessibility tree or custom debug JSON)
- Packages artifacts for an LLM to verify and suggest fixes
- Optional: sends artifacts to an LLM and writes a verdict

## Quick start
### Requirements
- macOS with Xcode (latest) and iOS Simulator
- `python3` on PATH
- `ffmpeg` on PATH (for keyframes)
- An XCTest UI test that drives your flow
- Accessibility identifiers for elements used in the flow

### Setup
1) Add your XCTest UI flow (UI test target).
2) Add accessibility identifiers for any UI elements the test taps/reads.
3) Run the CLI:

```bash
./tools/verify_flow --project /path/App.xcodeproj --scheme AppScheme \
  --only-testing Target/Class/testMethod --change "Updated empty state"
```

This writes artifacts under `runs/`.

### LLM verification
To run the flow and request an LLM verdict:
```bash
OPENAI_API_KEY=... ./tools/verify_and_review --project /path/App.xcodeproj --scheme AppScheme \
  --only-testing Target/Class/testMethod --change "Updated empty state"
```

### What you get
- `runs/<timestamp>/video.mp4`
- `runs/<timestamp>/keyframes/` (including dense tail frames)
- `runs/<timestamp>/telemetry/` (per-step snapshots)
- `runs/<timestamp>/telemetry.json` (last snapshot)
- `runs/<timestamp>/verdict.json` (LLM output)

## Status
This repo is a scaffold for the MVP. The CLI expects runtime inputs, runs `xcodebuild test`, and includes a static + runtime preflight for accessibility identifiers.
