#!/usr/bin/env python3
import argparse
import base64
import json
import os
import sys
import time
import urllib.request
from pathlib import Path

def encode_image(path):
    data = Path(path).read_bytes()
    b64 = base64.b64encode(data).decode("ascii")
    return f"data:image/png;base64,{b64}"

def sample_frames(frames, max_frames, tail_frames=6):
    if len(frames) <= max_frames:
        return frames
    tail = frames[-tail_frames:] if tail_frames > 0 else []
    remaining = max_frames - len(tail)
    if remaining <= 0:
        return tail[-max_frames:]
    # Evenly sample the rest
    head = frames[: len(frames) - len(tail)]
    if not head:
        return tail[-max_frames:]
    step = (len(head) - 1) / float(max(1, remaining - 1))
    idxs = [round(i * step) for i in range(remaining)]
    sampled = [head[i] for i in idxs] + tail
    # De-dup while preserving order
    seen = set()
    out = []
    for f in sampled:
        if f not in seen:
            out.append(f)
            seen.add(f)
    return out

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-dir", required=True)
    parser.add_argument("--change", required=True)
    parser.add_argument("--model", default="gpt-4.1-mini")
    parser.add_argument("--max-frames", type=int, default=12)
    parser.add_argument("--tail-frames", type=int, default=6)
    parser.add_argument("--detail", default="low", choices=["low", "high", "auto"])
    parser.add_argument("--telemetry", default=None)
    args = parser.parse_args()

    api_key = os.getenv("OPENAI_API_KEY")
    if not api_key:
        print("OPENAI_API_KEY is not set", file=sys.stderr)
        sys.exit(1)

    run_dir = Path(args.run_dir)
    if not run_dir.exists():
        print(f"Run dir not found: {run_dir}", file=sys.stderr)
        sys.exit(1)

    keyframes_dir = run_dir / "keyframes"
    if not keyframes_dir.exists():
        print(f"Keyframes dir not found: {keyframes_dir}", file=sys.stderr)
        sys.exit(1)

    frames = sorted(keyframes_dir.glob("*.png"))
    if not frames:
        print("No keyframes found", file=sys.stderr)
        sys.exit(1)

    sampled = sample_frames(frames, args.max_frames, args.tail_frames)

    telemetry_text = "(telemetry not found)"
    if args.telemetry:
        telemetry_path = Path(args.telemetry)
        if telemetry_path.exists():
            telemetry_text = telemetry_path.read_text(errors="replace")
    else:
        telemetry_dir = run_dir / "telemetry"
        telemetry_path = run_dir / "telemetry.json"
        if telemetry_dir.exists():
            parts = []
            for f in sorted(telemetry_dir.glob("*.json")):
                parts.append("## " + f.name + "\n" + f.read_text(errors="replace"))
            if parts:
                telemetry_text = "\n\n".join(parts)
        elif telemetry_path.exists():
            telemetry_text = telemetry_path.read_text(errors="replace")

    system_text = (
        "You are a UI verification assistant for iOS apps. "
        "You must verify whether the UI behavior matches the intended change. "
        "Return ONLY valid JSON."
    )

    user_intro = (
        f"Intended change:\n{args.change}\n\n"
        "Artifacts:\n"
        "- Keyframes (sampled)\n"
        "- Telemetry (accessibility tree)\n\n"
        "Task:\n"
        "1) Confirm whether the UI matches the intended change.\n"
        "2) List any issues with evidence from frames or telemetry.\n"
        "3) Suggest a concrete fix in Swift/SwiftUI.\n"
        "4) If uncertain, say 'UNCERTAIN' and explain why.\n\n"
        "Return JSON: {\"verdict\": \"pass|fail|uncertain\", \"issues\": [...], \"suggested_fix\": \"...\"}"
    )

    content = [
        {"type": "input_text", "text": user_intro},
        {"type": "input_text", "text": "Telemetry:\n" + telemetry_text},
    ]

    for frame in sampled:
        content.append({
            "type": "input_image",
            "image_url": encode_image(frame),
            "detail": args.detail,
        })

    payload = {
        "model": args.model,
        "input": [
            {"role": "system", "content": [{"type": "input_text", "text": system_text}]},
            {"role": "user", "content": content},
        ],
    }

    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        "https://api.openai.com/v1/responses",
        data=data,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            body = resp.read().decode("utf-8")
    except urllib.error.HTTPError as e:
        err = e.read().decode("utf-8")
        print(err, file=sys.stderr)
        sys.exit(1)

    response_path = run_dir / "llm_response.json"
    response_path.write_text(body)

    try:
        parsed = json.loads(body)
        output_text = parsed.get("output_text", "")
        if not output_text:
            texts = []
            for item in parsed.get("output", []):
                if item.get("type") == "message":
                    for c in item.get("content", []):
                        if c.get("type") == "output_text":
                            texts.append(c.get("text", ""))
            output_text = "\n".join(texts).strip()
    except json.JSONDecodeError:
        output_text = body

    verdict_path = run_dir / "verdict.json"
    verdict_path.write_text(output_text)

    print(str(verdict_path))

if __name__ == "__main__":
    main()
