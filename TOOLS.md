# LLM Tools

## verify_flow
Runs an iOS simulator flow, records video, captures telemetry, and returns artifact paths.

Usage:
```bash
./tools/verify_flow --project /path/App.xcodeproj --scheme AppScheme \
  --only-testing Target/Class/testMethod --change "<Intended change>" \
  [--device "iPhone 15 Pro"] [--udid <SIM_UDID>] \
  [--app-root /path/App] [--ui-tests-dir /path/AppUITests] \
  [--skip-static-preflight] [--skip-runtime-preflight]
```

Output (JSON on stdout):
```
{
  "run_dir": "runs/2026-02-02_134501",
  "video": "runs/.../video.mp4",
  "keyframes": "runs/.../keyframes/",
  "telemetry": "runs/.../telemetry.json",
  "log": "runs/.../run.log"
}
```

Notes:
- SwiftUI focus for MVP; telemetry should be accessibility-based or custom debug JSON.
- This is a personal dev tool. It is not a deterministic CI gate.
- The LLM should use the artifacts to verify the change and propose fixes.
- Static preflight scans UI test identifiers vs `.accessibilityIdentifier(...)` usage.
- Runtime preflight checks only `Home.*` identifiers at app launch.

## verify_and_review
Runs `verify_flow` and then sends artifacts to an LLM for verification.

Usage:
```bash
./tools/verify_and_review --project /path/App.xcodeproj --scheme AppScheme \
  --only-testing Target/Class/testMethod --change "<Intended change>" \
  [--model gpt-4.1-mini] [--max-frames 12] [--tail-frames 6] [--detail low]
```

Notes:
- Requires `OPENAI_API_KEY` in the environment.
- Writes `llm_response.json` and `verdict.json` into the run directory.
