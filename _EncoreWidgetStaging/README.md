# EncoreWidget — staged extension code

These 3 files are the real widget-extension code. They can't live in the app's
source folder (the `@main` bundle would collide with the app target), so they're
staged here.

## After your friend creates the `EncoreWidget` target (Phase 2):

1. In Finder/Xcode, DELETE the auto-generated template files inside `EncoreWidget/`
   (usually `EncoreWidget.swift`, `EncoreWidgetLiveActivity.swift`,
   `EncoreWidgetBundle.swift`, `AppIntent.swift`). Keep `Assets.xcassets` + `Info.plist`.
2. MOVE these 3 files into the `EncoreWidget/` folder:
   - `EncoreWidgetBundle.swift`
   - `EncoreLiveActivity.swift`
   - `EncoreHomeWidget.swift`
   They'll auto-join the widget target (synchronized group).
3. Make sure these SHARED files are ticked into the **EncoreWidget** target too
   (File Inspector → Target Membership → EncoreWidget):
   `EncoreSnapshot.swift`, `EncoreActivityAttributes.swift`, `EncoreIntents.swift`,
   `EncoreModels.swift`, `SeedData.swift`, `EncoreTheme.swift`.
4. Build the `EncoreWidget` scheme once, then run the app scheme.

Nothing here needs the paid account.
