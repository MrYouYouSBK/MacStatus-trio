# Project S Product Baseline — Trio REV.01

Status: Foundation
Owner: Project S
Product role: Mac system-awareness layer

## Product statement

Trio should answer one question in under one second:

> What matters on my Mac right now?

It is not intended to become a full system monitor, network administration suite, or clone of macOS System Settings.

## Core product boundary

Keep:
- Battery status and useful battery context.
- Network state and quality.
- Current audio output and volume state.
- Bluetooth audio awareness.
- Menu bar / Dock presentation.
- Fast native popover and settings.
- Privacy-first local processing.

Do not expand by default into:
- Full process monitoring.
- CPU/GPU/RAM dashboards.
- Generic hardware telemetry.
- Broad Wi-Fi administration.
- Password-management product behaviour.
- Features whose only purpose is to duplicate System Settings.

## Product direction

### P0 — Status Priority Engine
Create a single priority resolver for the center signal.

Examples:
- Normal: Wi-Fi.
- Bluetooth audio active: active output device.
- Internet failure: network warning.
- VPN state when supported by stable APIs.
- Meeting state when microphone/camera usage can be represented safely.

The renderer must consume a normalized status decision rather than independently deciding priority in each UI surface.

### P0 — Network Quality
Separate local link quality from real Internet health.

Track lightweight signals such as:
- Interface connected/disconnected.
- Internet reachable/unreachable.
- Latency trend.
- Packet-loss trend where implementation remains low-overhead.

Do not turn the popover into a network diagnostics dashboard.

### P0 — Product ownership migration
Before public commercial release:
- Replace upstream bundle identity with a Project S-owned identity.
- Replace upstream Sparkle feed with a Project S-owned feed.
- Generate and own a Project S Sparkle EdDSA keypair.
- Replace upstream website / author surfaces while retaining Apache-2.0 attribution and NOTICE obligations.
- Document upgrade behaviour from the current fork identity.
- Complete Developer ID signing and notarization under Project S credentials.

These changes must be performed as an explicit migration, not as blind text replacement.

### P1 — Battery Intelligence
Expose concise, decision-useful information:
- Health.
- Cycle count.
- Power source.
- Charging state.
- Estimated remaining / time-to-full when trustworthy.
- Unusual drain notification only if confidence is high.

### P1 — Audio Intelligence
Identify current output class:
- Built-in speaker.
- AirPods/headphones.
- Bluetooth speaker.
- USB audio.
- HDMI/display audio.

Prefer an immediately understandable icon over extra text.

### P1 — Profiles
Optional presentation profiles:
- Default.
- Work.
- Meeting.
- Gaming.
- Travel / battery.

Profiles affect priority and presentation; they should not become large automation workflows.

### P2 — Lightweight History
Keep only compact, useful summaries such as:
- Network interruptions today.
- Major audio-output switches.
- Battery discharge trend.

Avoid becoming an iStat-style historical telemetry product.

## Architecture rule

Introduce a normalized model:

System Signals -> Signal Normalizers -> Priority Engine -> Status Snapshot -> Menu Bar / Dock / Popover

The same Status Snapshot must drive all presentation surfaces.

## Quality gates

A release candidate must:
- Pass the existing Swift test suite.
- Remain responsive when CoreAudio/CoreWLAN reads stall.
- Avoid blocking the MainActor with system_profiler or equivalent slow reads.
- Preserve privacy defaults.
- Preserve low idle CPU usage.
- Pass signed/notarized Gatekeeper installation tests.

## App Store strategy

Maintain two possible distribution profiles:
1. Direct: Developer ID + notarization + Sparkle.
2. Store feasibility: sandbox-compatible feature subset.

Do not remove useful direct-distribution capabilities merely to force one binary into the Mac App Store.

## Success criteria

Trio succeeds when:
- A user can understand the important Mac state at a glance.
- Context changes automatically affect the single icon.
- The app remains lighter and simpler than full system-monitor products.
- Project S owns the complete identity, signing and update chain.
