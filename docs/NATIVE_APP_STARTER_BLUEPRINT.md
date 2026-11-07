# Native Apple app starter blueprint

Use a small SwiftUI structure with clear domain boundaries. This is a documented starting point, not a command to rewrite Logbook or make all future apps share its architecture.

## Suggested layout

```text
App/
  AppEntry.swift
  AppRouter.swift
  AppConfiguration.swift
  DesignSystem/       # semantic tokens, typography, components
  Features/<Feature>/ # Views, state/model, actions, focused tests
  Data/               # repositories, persistence, migrations
  Services/           # networking, notifications, integrations
  Resources/          # local fixtures and approved assets
  Extensions/         # only when the app needs Widget/Watch/etc.
Tests/
  Unit/ Integration/ UI/ Fixtures/
```

For a small app, keep fewer folders and avoid empty abstractions. Keep UI state, durable domain state, and service effects distinct enough to test.

## Conventions
- Use SwiftUI and typed navigation destinations. Give important controls stable accessibility identifiers and labels.
- Put semantic design tokens/assets in one design-system module; keep branding and themes specific to the app. Store font/material decisions alongside approved references and tests.
- Give each domain feature an explicit repository boundary. Version persisted data and test migration from the prior version before changing stored shapes. Use atomic writes and recovery/backup paths for user data.
- Keep secrets in Keychain or an approved server-side secret store. Public client IDs are not private secrets. No API secret belongs in source, bundle resources, logs or chat.
- Use async service protocols with explicit offline, retry, cancellation and error states. Do not build UI around an API before validating access and limits.
- Add authentication only when scope requires it; represent authenticated identity separately from mutable email. Authorize every remote record operation on the server.
- Isolate notification permission requests and scheduling from view rendering. Native extensions use App Groups only when shared data is necessary and entitlement/configuration is verified.
- Add WidgetKit, ActivityKit, WatchConnectivity, App Intents or background refresh only for approved use cases and test platform restrictions empirically.

## Tests and CI
- Unit-test calculations, state transitions, migration, persistence, offline queues and authorization invariants.
- Integration-test repositories/services against deterministic fakes or isolated emulators.
- UI-test complete user scenarios with accessibility IDs and synthetic fixtures.
- Capture simulator screenshots on compact and large devices; keep candidates separate from explicitly approved baselines.
- CI should build/test on an available macOS image, report unavailable destinations honestly, preserve `.xcresult`/logs and never let a skipped matrix job masquerade as a pass.

## Release checklist
- Requirements tracker updated with exact commit/evidence and open blockers.
- Build, relevant tests, screenshot review, data upgrade/recovery and privacy boundaries verified.
- Device-only permissions, background behavior and native extensions exercised on physical hardware.
- Signing, bundle IDs, entitlements and App Store requirements checked in the correct environment.
- Export/backup and user recovery paths checked; no production migration without a recoverable backup and explicit authorization.
- User visual acceptance recorded independently from automated tests.
