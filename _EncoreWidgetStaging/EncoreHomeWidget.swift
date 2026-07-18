//
//  EncoreHomeWidget.swift
//  EncoreWidget — Home/Lock screen widget (see claude.md §10.4)
//
//  Reads the App Group snapshot the app writes; shows the #1 matched show with an
//  interactive Book button (App Intent — no app launch needed to fire the intent).
//  Black & white. Small + medium families.
//

import WidgetKit
import SwiftUI
import AppIntents

struct EncoreEntry: TimelineEntry {
    let date: Date
    let snapshot: EncoreSnapshot?
}

struct EncoreProvider: TimelineProvider {
    func placeholder(in context: Context) -> EncoreEntry {
        EncoreEntry(date: Date(), snapshot: EncoreSnapshot(
            nextEventTitle: "Dil-Luminati Tour", nextEventVenue: "JLN Stadium",
            heroHeadline: "You've had Diljit on repeat"))
    }

    func getSnapshot(in context: Context, completion: @escaping (EncoreEntry) -> Void) {
        completion(EncoreEntry(date: Date(), snapshot: EncoreSharedStore.readSnapshot()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EncoreEntry>) -> Void) {
        let entry = EncoreEntry(date: Date(), snapshot: EncoreSharedStore.readSnapshot())
        completion(Timeline(entries: [entry], policy: .after(Date().addingTimeInterval(15 * 60))))
    }
}

struct EncoreHomeWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "EncoreHomeWidget", provider: EncoreProvider()) { entry in
            EncoreWidgetView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Encore — For You")
        .description("The show that best matches your music taste.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct EncoreWidgetView: View {
    @Environment(\.widgetFamily) var family
    let entry: EncoreEntry

    var body: some View {
        if let snap = entry.snapshot, let title = snap.nextEventTitle {
            content(snap, title: title)
        } else {
            emptyState
        }
    }

    @ViewBuilder
    private func content(_ snap: EncoreSnapshot, title: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("FOR YOU")
                .font(.system(size: 10, weight: .bold)).tracking(2)
                .foregroundStyle(.white.opacity(0.5))

            Text(snap.heroHeadline ?? title)
                .font(family == .systemSmall ? .caption.bold() : .subheadline.bold())
                .foregroundStyle(.white)
                .lineLimit(family == .systemSmall ? 3 : 2)

            if family == .systemMedium, let venue = snap.nextEventVenue {
                Text("\(title) · \(venue)")
                    .font(.caption2).foregroundStyle(.white.opacity(0.6)).lineLimit(1)
            }

            Spacer(minLength: 4)

            if let id = snap.nextEventID {
                Button(intent: BookShowIntent(eventID: id)) {
                    Text(snap.planStatus == "booked" ? "View night" : "See the night")
                        .font(.caption2.bold())
                        .foregroundStyle(.black)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Capsule().fill(.white))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: "waveform").foregroundStyle(.white)
            Text("Open Encore to find shows for your taste.")
                .font(.caption).foregroundStyle(.white.opacity(0.8))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
