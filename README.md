# PhishSafe SDK

**PhishSafe** is a lightweight, real-time behavioral fraud detection SDK designed for mobile banking apps. It silently monitors user interaction patterns post-login to ensure session legitimacy—catching phishing, screen mirroring, and session hijacking without interrupting user experience.

---

## Why PhishSafe?

Traditional banking security ends at login. PhishSafe fills the *critical gap* between **login and logout**, passively verifying the user through their behavior every step of the way.

---

## Core Capabilities

| Feature                         | Description                                                                |
|---------------------------------|----------------------------------------------------------------------------|
| Behavioral Signal Capture       | Taps, swipes, screen durations, navigation patterns, device posture        |
| Real-Time Trust Scoring         | On-device ML model calculates a session trust score                        |
| Anomaly Detection               | Detects deviations using rule-based and ML logic                           |
| Privacy-First Architecture      | All processing is done locally — nothing is sent to the cloud              |
| Plug-and-Play Integration       | Works as a drop-in SDK for any Flutter-based banking app                   |
| Instant Adaptive Response       | Triggers security actions on risky behavior (e.g., screen lock, alert)     |

---

## Architecture Overview

- **Mobile App (Flutter + Kotlin)**: Embeds the PhishSafe SDK and invokes trust scoring
- **Behavior Tracking Module**: Records taps, swipes, screen durations, and other signals
- **TrustScore Engine**: Combines rule-based checks and a native PyTorch model
- **Export Manager**: Logs each session in a visible JSON format (optional)
- **Dashboard (Optional)**: Admin view to monitor usage logs (React-based)

---

## Tech Stack

- **Mobile**: Flutter (Dart), Kotlin (Android)
- **ML Inference**: PyTorch Mobile (.pt model), Dart–Kotlin bridge via MethodChannels
- **Anomaly Models**: Rule-based logic + Autoencoder / Isolation Forest (offline)
- **Dashboard**: React + Render
- **Backend (Optional)**: Supabase / Firebase / AWS (for future cloud sync)
- **Data Source**: Synthetic behavior logs during session (keystroke timings, patterns)

---

## Getting Started

1. Add the SDK to your Flutter project:

```yaml
dependencies:
  phishsafe_sdk:
    path: ../phishsafe_sdk
