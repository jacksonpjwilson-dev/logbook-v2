# Reusable components inventory

This inventory describes current Logbook code and candidate reuse boundaries. It does not recommend extracting shared packages until a second app has a concrete need.

| Component | Current location | Maturity / tests | Potential use |
|---|---|---|---|
| Domain models and stable IDs | `native-ios/Shared/LogbookModels.swift` | Logbook domain-specific; some business rules have store tests. Keep fitness/food entities out of a universal model. | Persistence conventions can inform all six apps; Logbook models themselves stay app-owned. |
| Persistence and shared state | `native-ios/Shared/SharedStateFile.swift`, `native-ios/Sources/Logbook/LogbookStore.swift` | Local state and App Group access exist; migration, corruption and broader sync/conflict safety remain incomplete. | Data versioning, repository boundaries and backup patterns; do not reuse domain schema. |
| Design tokens / theme engine | `native-ios/Sources/Logbook/HomeScreen.swift`, theme-related models in `LogbookModels.swift`, `native-ios/Resources/LogbookAssets.xcassets` | Default is provisional and awaiting user approval; legacy theme variants must be preserved. | Tokens and material conventions after visual signoff; no cross-app visual branding assumed. |
| Navigation and dashboard widgets | `HomeScreen.swift`, screen files under `native-ios/Sources/Logbook/` | Four Home pages and dock are tested in limited simulator flows; customization and many widget contents remain incomplete. | Routing and widget composition concepts for Daily Briefing, Stack, Crew and Pantry; layouts remain app-specific. |
| Authentication / account roles | Not implemented in native source at last audit | Blocked on provider/backend setup and security design; no local mock counts as implementation. | Secure auth interface can inform all apps if a real shared identity system is selected. |
| Networking and remote data | No validated shared service layer in current audited scope | Food sources, account sync and coaching need separate integration validation. | A tested transport/error/retry layer could be reused; service clients and models should remain separate. |
| Notifications and reminders | `native-ios/Sources/Logbook/ReminderService.swift` | Source exists; scheduling, permissions and delivery need workflow/device verification. | Permission UX and scheduling tests can inform all apps. |
| WidgetKit | `native-ios/Sources/LogbookWidgets/LogbookWidgets.swift` | Native widget source exists; complete widget inventory, deep links and device behavior unverified. | Reuse extension setup patterns in Daily Briefing, Stack, Crew, YKF Arrivals and Pantry. |
| Live Activities / Dynamic Island | `native-ios/Sources/Logbook/WorkoutActivityController.swift`, `native-ios/Shared/WorkoutActivityAttributes.swift`, widget extension | Source exists for workout activity; lifecycle and runtime presentation need verification. | Framework patterns for timed or live state; each app's content and policy remains specific. |
| Apple Watch / WatchConnectivity | `native-ios/Sources/Logbook/WatchBridge.swift`, `native-ios/Sources/LogbookWatch/LogbookWatchApp.swift`, `native-ios/Shared/WatchSnapshot.swift` | Targets/source exist; pairing, watch UI, sync and actual workout logging require physical device tests. | Watch target and message-handling patterns only where future apps need a Watch app. |
| HealthKit | Intentionally not enabled | User has explicitly chosen no Health access. | Do not reuse or enable unless user explicitly authorizes access. |
| Export / backup | Existing audit reports partial export capabilities in app source | Full backup/import/restore and conflict handling remain incomplete. | Format versioning, integrity checks and recovery tests could benefit all apps. |
| QA and screenshot tooling | `native-ios/QA/Scripts/`, `.github/workflows/daily-home-qa.yml`, `native-ios/Tests/` | Run #42 passed 33 unit +4 UI per iPhone 16 and SE; broader UI coverage remains open. | CI matrix, deterministic fixtures, result parsing and candidate screenshot discipline are strong reuse candidates. |
| Diagnostics / logging | No verified app-wide diagnostic framework in current audit | Assess before adding; avoid sensitive logs. | Redacted logging/error presentation patterns for all apps. |

## App fit
- **Logbook:** retain nutrition/training/check-in domain, HealthKit disabled, and existing workout/widget extensions.
- **Daily Briefing:** scheduled content, notification, widget and possibly Live Activity patterns; external-source validation first.
- **Stack:** privacy-sensitive finance storage, account sync, exports and biometric access must be designed separately; do not reuse Logbook data assumptions.
- **Crew:** navigation, settings, secure automation credentials and role/permission concepts; never store provider secrets in plain preferences.
- **YKF Arrivals:** network/API resilience, scheduled refresh, notification and Live Activity patterns if justified; validate aviation data source and terms.
- **Pantry:** catalog search, offline cache, quantity and history patterns; distinguish its inventory entities from Logbook food nutrition records.

Reusable candidates should expose narrow protocols, have independent tests and no app-specific dependencies. Reassess maturity before extraction.
