# Encore — Xcode configuration checklist

Everything you (human) must configure for Notifications + Live Activity + Widget +
App Intents. I write the code; you do these. Concrete identifiers for THIS project:

| Thing | Value |
|---|---|
| App bundle id | `com.amit.EveningPlanner` (existing) |
| Widget extension bundle id | `com.amit.EveningPlanner.EncoreWidget` |
| App Group | `group.com.amit.EveningPlanner` |
| URL scheme | `encore` |
| Background task id (later) | `com.encore.refresh` |

---

## PHASE 0 — Notifications (mostly done)

Local notifications need **no capability and no Info.plist key** — the permission
prompt is automatic. One optional add:

- [ ] **(Optional)** Target **EveningPlanner** → **Signing & Capabilities** →
  **+ Capability** → **Time Sensitive Notifications**.
  Lets the "match found" alert break through Focus. Skip if not offered on a free
  account — notifications still work without it.

Test on a **real device** (Simulator is unreliable for notifications).

---

## PHASE 1 — Foundational (do before Live Activity / Widget)

All on the **EveningPlanner** app target → **Signing & Capabilities** + **Info** tabs.

### 1a. Live Activities switch
- [ ] **Info** tab → hover a row → **+** → add key
  **`Supports Live Activities`** (`NSSupportsLiveActivities`) → value **YES**.

### 1b. App Group (shares data app ⇄ widget/Live Activity)
- [ ] **Signing & Capabilities** → **+ Capability** → **App Groups**.
- [ ] Click **+** under App Groups → add **`group.com.amit.EveningPlanner`** → check it.
  *(Free personal team usually allows this. If provisioning refuses, tell me — the
  widget can fall back to reading bundled seed data instead of the App Group.)*

### 1c. URL scheme (deep links from widget / Live Activity buttons)
- [ ] **Info** tab → **URL Types** section (bottom) → **+**.
- [ ] **Identifier:** `com.amit.EveningPlanner` · **URL Schemes:** `encore` ·
  **Role:** Editor.

### 1d. Calendar usage string (for the existing "Add to calendar" button)
- [ ] **Info** tab → **+** → **`Privacy - Calendars Write Only Usage Description`**
  (`NSCalendarsWriteOnlyAccessUsageDescription`) → value:
  `Encore adds your booked shows to your calendar.`

---

## PHASE 2 — Create the Widget Extension target

This ONE target hosts BOTH the Live Activity and the Home/Lock-screen widget.

- [ ] Menu **File → New → Target…**
- [ ] Choose **Widget Extension** → **Next**.
- [ ] **Product Name:** `EncoreWidget`
- [ ] ✅ Tick **Include Live Activity**. ❌ Leave **Include Configuration App Intent** unchecked (we add our own intents).
- [ ] **Finish** → when prompted **"Activate EncoreWidget scheme?"** → **Activate**.

Xcode generates `EncoreWidget/` with template files. **Tell me when this exists** —
I'll replace the templates with the real Encore Live Activity + widget code.

---

## PHASE 3 — Wire the widget target

### 3a. App Group on the widget (same id)
- [ ] Select target **EncoreWidget** → **Signing & Capabilities** → **+ Capability**
  → **App Groups** → check **`group.com.amit.EveningPlanner`** (same as the app).

### 3b. Shared code = member of BOTH targets
The Live Activity attributes + snapshot + App Intents must compile into the app AND
the widget. After I add these files, for EACH of them:
- [ ] Select the file → **File Inspector** (right panel, ⌥⌘1) → under **Target
  Membership** tick **both** `EveningPlanner` and `EncoreWidget`.

Files that need dual membership (I'll create/mark them):
`EncoreActivityAttributes.swift`, `EncoreSnapshot.swift`, `EncoreIntents.swift`,
and the model files they depend on (`EncoreModels.swift`, `SeedData.swift`).

### 3c. Minimum deployment
- [ ] Confirm **EncoreWidget** target's **Minimum Deployments = iOS 26** (match the
  app) so ActivityKit + interactive-widget APIs are available.

---

## PHASE 4 — App Intents (no capability, small config)

- [ ] **No capability needed.** App Intents just compile in.
- [ ] Any intent used by the widget must be a member of **both** targets (Phase 3b).
- [ ] For Siri/Spotlight phrases I add an `AppShortcutsProvider`; nothing to toggle.

---

## PHASE 5 — (Later, optional) Background refresh

Only when you want the "wakes while app is closed" story live:
- [ ] App target → **Signing & Capabilities** → **+ Capability** → **Background Modes**
  → tick **Background fetch** + **Background processing**.
- [ ] **Info** tab → add **`Permitted background task scheduler identifiers`**
  (`BGTaskSchedulerPermittedIdentifiers`) → array with one item: `com.encore.refresh`.

---

## Recommended order

1. Phase 0 (notifications) — test it works.
2. Phase 1 (foundational: Live Activities switch, App Group, URL scheme, calendar key).
3. Phase 2 (create EncoreWidget target) → **ping me, I add Live Activity + widget code**.
4. Phase 3 (App Group + target membership on widget) → build.
5. Phase 4 (App Intents) → I add intents, you dual-target them → build.
6. Phase 5 (background) — last, optional.

## What needs the PAID Apple Developer account?

Nothing here for the demo. Notifications, Live Activity, Widget, App Intents, App
Groups all run on a **free** personal team on a real device. Only the **live
MusicKit** taste source needs the paid program — deferred.
```
