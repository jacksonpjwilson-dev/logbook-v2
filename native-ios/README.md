# Logbook for Apple platforms

This is a separate SwiftUI implementation in `native-ios/`. It does not alter the existing web app or configure Firebase. The original visual reference sheets guide the theme palette and page composition; Stage 5 defines the Home Screen's four pages, dock, and 38 widget types. The 16 theme wallpaper assets are crops from the existing reference wallpaper atlas, as recorded in `../stage5/assets/PROVENANCE.md`.

## Generate and open the Xcode project

On macOS with Xcode 15 or newer:

1. Install XcodeGen once with `brew install xcodegen`.
2. Run `./native-ios/generate-project.sh` from the repository root.
3. Open `native-ios/Logbook.xcodeproj`, choose the `Logbook` scheme, and set your signing team.
4. Replace the sample bundle identifiers and App Group `group.com.example.logbook` with identifiers registered for your Apple Developer account. Keep the same App Group value in the app and widget entitlements.
5. Build and run on an iPhone simulator or device. To run unit tests, select an iPhone simulator destination in Xcode.

The Watch app and WidgetKit extension are separate targets included by the project spec. The project uses local JSON persistence in the shared App Group container so widgets and the Watch companion can read the same snapshot. If the App Group is not configured, the iPhone app falls back to its private Application Support directory; extensions will not share that fallback.

## Current implementation

- Food and water logging, nutrition targets, exercise catalog and custom exercises, workout templates, set logging, workout pause/resume/finish/discard, manual sleep/weight/supplement entries, a basic history view, all 16 themes, and a four-page editable widget home.
- WidgetKit nutrition/workout widgets, Lock Screen accessory families, workout Live Activity with Dynamic Island presentation, a Watch companion for progress and quick workout start/finish, and local notification reminders.
- HealthKit is intentionally absent: no HealthKit framework, entitlement, data request, or permission prompt is present, per the user's instruction.
- No Firebase configuration, account sync, production data, or App Store deployment is included.

The repository runs on Linux and has no Xcode toolchain, so this source has not been compiled or simulator-tested in this workspace. A macOS GitHub Actions workflow is provided to generate the Xcode project and build/test it on a Mac runner. Review its result before device installation.

## Known limits before calling this complete

The native data store starts empty. Existing browser/localStorage records have not been imported. See `MIGRATION.md` before using the native app with any data that needs to be retained. The starter food catalog is small and is not a replacement for a food database or barcode service. Watch support currently shows shared progress and sends quick workout start/finish actions; detailed set entry on the Watch is not implemented. Home widgets open functional in-app destinations, but several of the 38 widget types currently show summary/placeholder values rather than a dedicated data visualization. The wallpaper crops and palette are based on supplied reference material, but should be visually reviewed in Xcode on the target iPhone before approval.

The project must be built, run through the included tests, and reviewed on an Apple device before treating the native conversion as complete.
