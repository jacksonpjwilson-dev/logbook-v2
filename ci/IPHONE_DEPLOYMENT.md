# Logbook iPhone deployment

On November 25, 2026, the current app source at `19d1b94f7a1b967df15c577cf7292898296bc670` built, signed, installed and launched on the connected iPhone 16 Plus running iOS 27.2.1 (24B156). Xcode 27.2 (27B52) used the existing Apple Developer team. Logbook's process remained alive 15 seconds after launch. This verifies installation and immediate launch survival. Full functional evaluation and physical Watch testing remain open.

Run from the repository root with the existing team configured in Xcode.

```sh
LOGBOOK_DEVELOPMENT_TEAM=7HL7Y5SP24 python3 ci/deploy-iphone.py
```

The script prints its evidence directory containing the build log, installation and launch results, process snapshot and summary. The successful initial deployment evidence is under `/private/var/folders/gt/t1xmkbtn7qgdb845by_rv08w0000gn/T/logbook-iphone-b3w0p392` on this Mac. Temporary evidence may be removed by macOS.

The device build uses `com.logbook.7hl7y5sp24`, its widget extension and its Watch companion identifiers, plus the dedicated App Group `group.com.logbook.7hl7y5sp24`. The example identifier in the repository was unavailable for signing. The generated deployment copy updates the shared-state group consistently for the app and widgets. Register the dedicated group once in Xcode Signing & Capabilities for both targets. This was completed on this Mac.

XcodeGen generates the project in a temporary copy of the current native source. The deployment copy builds the existing SwiftUI Watch companion as a modern single-target watchOS application and embeds it alongside the widgets. The previous watchapp2 product type produced duplicate executable outputs when built for a physical device. Existing working-project Xcode settings and source files are preserved.

Outstanding QA and CI remediation is suspended for interface evaluation. The existing local changes in the milestone notes, QA report, requirements tracker, UI tests, Watch scheme and Xcode workspace remain uncommitted. The earlier Sleep, Food, timer and simulator findings remain recorded there. No UI or unit suite was run for this deployment. HealthKit access retains its previously disabled state.
