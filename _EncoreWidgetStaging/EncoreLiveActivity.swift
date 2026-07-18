//
//  EncoreLiveActivity.swift
//  EncoreWidget — Lock Screen + Dynamic Island (see claude.md §10.5)
//
//  Renders EncoreActivityAttributes. Black & white. Live countdown via
//  Text(date, style: .timer). Contextual interactive button per phase (App Intent).
//

import ActivityKit
import WidgetKit
import SwiftUI

struct EncoreLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: EncoreActivityAttributes.self) { context in
            LockScreenLiveActivityView(context: context)
                .widgetURL(URL(string: "encore://event?id=\(context.attributes.eventID)"))
                .activityBackgroundTint(.black)
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Label(context.state.phase.label, systemImage: context.state.phase.symbol)
                        .font(.caption2).foregroundStyle(.white)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.countdownTarget, style: .timer)
                        .font(.caption.monospacedDigit().bold())
                        .foregroundStyle(.white)
                        .frame(maxWidth: 56)
                }
                DynamicIslandExpandedRegion(.center) {
                    Text(context.attributes.eventTitle)
                        .font(.caption.bold()).foregroundStyle(.white).lineLimit(1)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 6) {
                        Text(context.state.statusMessage)
                            .font(.caption2).foregroundStyle(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                        phaseButton(context)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.phase.symbol).foregroundStyle(.white)
            } compactTrailing: {
                Text(context.state.countdownTarget, style: .timer)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.white)
                    .frame(maxWidth: 44)
            } minimal: {
                Image(systemName: context.state.phase.symbol).foregroundStyle(.white)
            }
        }
    }

    @ViewBuilder
    private func phaseButton(_ context: ActivityViewContext<EncoreActivityAttributes>) -> some View {
        let id = context.attributes.eventID
        switch context.state.phase {
        case .getEssentials, .upcoming:
            Button(intent: OrderEssentialsIntent(eventID: id)) {
                Label("Order essentials", systemImage: "bag.fill").font(.caption2.bold())
            }.tint(.white)
        case .liveNow:
            EmptyView()
        case .postShow:
            Button(intent: OrderFoodIntent(eventID: id)) {
                Label("Order food", systemImage: "takeoutbag.and.cup.and.straw.fill").font(.caption2.bold())
            }.tint(.white)
        }
    }
}

// MARK: - Lock Screen / banner view

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<EncoreActivityAttributes>

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Label(context.state.phase.label, systemImage: context.state.phase.symbol)
                    .font(.caption2.bold()).foregroundStyle(.white.opacity(0.7))
                Text(context.attributes.eventTitle)
                    .font(.headline).foregroundStyle(.white).lineLimit(1)
                Text(context.attributes.venueName)
                    .font(.caption).foregroundStyle(.white.opacity(0.6))
                if let readyBy = context.state.readyByText, context.state.phase == .postShow {
                    Text("Hot food home ~\(readyBy)")
                        .font(.caption2.bold()).foregroundStyle(.white)
                } else {
                    Text(context.state.statusMessage)
                        .font(.caption2).foregroundStyle(.white.opacity(0.7)).lineLimit(2)
                }
            }
            Spacer()
            VStack(spacing: 4) {
                Text(context.state.countdownTarget, style: .timer)
                    .font(.title3.monospacedDigit().bold())
                    .foregroundStyle(.white)
                    .frame(maxWidth: 70)
                Text(context.state.phase == .liveNow ? "ends in" : "starts in")
                    .font(.caption2).foregroundStyle(.white.opacity(0.5))
            }
        }
        .padding()
        .background(Color.black)
    }
}
