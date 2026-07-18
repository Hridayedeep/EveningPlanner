# Plan My Evening — Implementation Plan

Based on the hand-drawn flow: Screen 1 → Questionnaire → (API/loading) → Itinerary Option Card → Payment → Success Popup.

## 1. Screen-by-screen breakdown

### Screen 1 — Entry point
- Single button: **"Plan my evening"**
- Taps into Questionnaire screen
- Siri entry point (`PlanEveningIntent`) can also land here, pre-seeded — see Section 5

### Screen 2 — Questionnaire
- **Q1: "What is your vibe?"** — multi-select (lively, romantic, chill, intellectual, food-focused)
  - ⚠️ Not the same as the `occasion` field we built earlier (parents/friends/partner/date). This is a **new field** — treat it as a `Set<Vibe>` tag used for filtering/ranking venues by `tags` in the mock DB (we already have `"romantic"`, `"good_for_dates"`, `"family_friendly"` etc. as venue tags — this maps directly)
  - Decide: does this **replace** or **sit alongside** the `occasion` question from the earlier questionnaire? Recommend: keep both — `occasion` drives who it's for, `vibe` drives tone/filtering. Don't conflate.
- **Q2: "Go out or stay in?"** — single select
  - New field. If "stay in" is selected, this likely short-circuits the whole flow (no venues to book) — needs its own micro-flow (e.g. order-in suggestion) or should be scoped OUT for the hackathon demo entirely. **Recommend: hardcode "Go out" only for the demo, hide/disable "stay in."**
- **Q3: (blank in wireframe)** — undefined. Suggest reusing **duration** or **time slot** here from the original 5-question flow, since it's missing from this new screen but still needed downstream (the itinerary card shows "5:00pm" — that time has to come from somewhere).
- **Next button** → triggers itinerary generation

### Loading state — "(API). Loading..."
- This is your `generateItinerary(for:from:)` call (Section 4) — even though it's local/mock, keep a real loading state (skeleton or spinner, 500ms–1s minimum) so the demo *feels* like it's computing, not instant/fake

### Screen 3 — Itinerary Option Card
- **"option 1 / 5"** with **+ / –** stepper → this means you're generating **multiple itinerary variants**, not just one. Pick top 5 candidate itineraries (e.g. different restaurant picks at the same activity, or different activity+restaurant pairings) and let the user page through them.
- Each stop shown as a card: name, time, location, price (e.g. "Badminton at 5:00pm / Dhyanchand stadium / 500/hr")
- **Book now** → Payment screen
- **Shuffle / retry** → regenerate a new variant (increments/reshuffles within the 5, or re-runs matching with slight randomization)

### Screen 4 — Payment screen
- **Success** / **Failed** buttons — this is a **mock/simulated payment result**, not a real transaction. For the hackathon, this is just two buttons that branch the flow; there is no real payment processing here, and there shouldn't be — treat this screen as a UI stub demonstrating where a real payment SDK would plug in later, not something to wire up to any actual payment provider.

### Screen 5 — Success popup
- **Add to calendar** → this one's real and easy: use `EventKit` (`EKEventStore`) to create a calendar event for each itinerary stop with its time
- **Continue** → dismiss, return to Screen 1 or a "your plan" summary

## 2. Data model additions needed

```swift
struct PlanRequest {
    var occasion: Occasion = .friends        // existing
    var vibe: Set<Vibe> = []                 // NEW — from Q1
    var goingOut: Bool = true                // NEW — from Q2, hardcode true for demo
    var duration: DurationPreset = .evening  // existing, now also covers Q3
    var template: PlanTemplate = .foodOnly   // existing
    var activityType: ActivityType? = nil    // existing
    var restrictions: Set<DietaryRestriction> = []  // existing
}

enum Vibe: String, CaseIterable {
    case lively, romantic, chill, intellectual, foodFocused
}

struct ItineraryVariant: Identifiable {
    let id: Int              // 1...5, for the "option X/5" stepper
    let stops: [ItineraryStop]
    let totalCost: Int
}

struct ItineraryStop {
    let venueName: String
    let location: String
    let time: String
    let priceLabel: String   // "500 / hr", "1000 / head" — keep as display string, not just a number, since units differ per venue type
}
```

## 3. Mock DB additions needed
- Add `"vibe_tags"` array to each venue in `mock_eternal_db.json`, mapped to the `Vibe` enum, so Q1's multi-select can actually filter venues (currently the JSON has `"tags"` with similar-but-not-identical values like `"good_for_dates"` — either reconcile these into one taxonomy or map one to the other in code)
- Add `"pricePerHead"` or `"pricePerHour"` as a proper field (currently `avgCostForTwo` / `avgCostPerHour` exist but aren't unified into one display format) — needed for the itinerary card's price line

## 4. Matching engine change
`generateItinerary` needs to become `generateItineraryVariants(for:from:) -> [ItineraryVariant]` returning up to 5 ranked options instead of one, so the stepper has something to page through. Shuffle = re-roll from the same candidate pool with a different random seed, not a full re-query.

## 5. Siri (App Intents) integration point
The existing `PlanEveningIntent` from `SiriPlanEveningIntent.swift` still applies — it should stage `occasion` + `activityType` and hand off into **Screen 2** (Questionnaire), pre-filled. Vibe and "go out/stay in" stay as in-app-only questions for now — not worth adding to the voice flow given the round-trip risk discussed earlier.

## 6. Scope-cut recommendations given limited hours remaining
Given how much is already built vs. how much this wireframe adds, prioritize in this order:

1. ✅ Keep: single itinerary result (skip the 5-variant stepper — show one "best match" with a **Shuffle** button that re-generates, rather than building a full pageable 1/5 UI). Same user-facing effect, much less UI state to manage.
2. ✅ Keep: mock payment Success/Failed as a 2-button stub screen — trivial to build, demos the flow.
3. ✅ Keep: Add to calendar via `EventKit` — real, fast, impressive in a demo.
4. ⚠️ Cut or hardcode: "Go out or stay in" — hardcode to "Go out," hide the toggle, note it as a roadmap item if asked.
5. ⚠️ Simplify: Vibe multi-select — fine to keep, but map it to existing venue `tags` rather than building a parallel taxonomy, to avoid duplicate data modeling work.

## 7. Suggested build order (remaining hours)
1. Reconcile `Vibe` into existing `PlanRequest`/questionnaire (30–45 min)
2. Single-result itinerary card UI with Shuffle (1–1.5 hr)
3. Payment stub screen, 2 buttons, branching logic (30 min)
4. Success popup + EventKit calendar integration (45 min–1 hr)
5. Wire Siri hand-off into Screen 2 pre-fill (should already work from prior build — verify only)
6. Integration pass + demo rehearsal (remaining buffer)
