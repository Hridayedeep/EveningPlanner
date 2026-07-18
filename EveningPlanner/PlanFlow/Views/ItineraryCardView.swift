//
//  ItineraryCardView.swift
//  EveningPlanner
//
//  Screen 3. Shows one of the 5 generated variants at a time — "option
//  X/5" labels which one. Thumbs up/down just log via EventLogger today;
//  Shuffle jumps to a different random candidate from the same 5.
//

import SwiftUI

struct ItineraryCardView: View {
    @EnvironmentObject private var flow: PlanFlowViewModel
    @State private var feedbackGiven: Bool?

    var body: some View {
        VStack(spacing: 20) {
            if !flow.variants.isEmpty {
                header
            }

            if let variant = flow.selectedVariant {
                ScrollView {
                    GlassEffectContainer(spacing: 16) {
                        VStack(spacing: 16) {
                            ForEach(Array(variant.stops.enumerated()), id: \.offset) { index, stop in
                                StopCard(index: index + 1, stop: stop)
                            }
                        }
                    }
                }

                feedbackRow

                actionButtons
            } else {
                Spacer()
                Text(flow.generationError ?? "No itinerary could be generated for these preferences.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .planFlowScreenBackground()
        .onChange(of: flow.selectedVariantIndex) { _, _ in
            feedbackGiven = nil
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Option \(flow.selectedVariantIndex + 1) / \(flow.variants.count)")
                    .font(.headline)
                Spacer()
            }

            if let variant = flow.selectedVariant {
                TotalCostBanner(totalCost: variant.totalCost, groupSize: flow.planRequest.groupSize)
            }
        }
    }

    private var feedbackRow: some View {
        HStack(spacing: 16) {
            Spacer()
            Button(action: { giveFeedback(liked: true) }) {
                Image(systemName: feedbackGiven == true ? "hand.thumbsup.fill" : "hand.thumbsup")
                    .frame(width: 44, height: 44)
            }
            .glassEffect(
                feedbackGiven == true ? .regular.tint(.accentColor).interactive() : .regular.interactive(),
                in: .circle
            )

            Button(action: { giveFeedback(liked: false) }) {
                Image(systemName: feedbackGiven == false ? "hand.thumbsdown.fill" : "hand.thumbsdown")
                    .frame(width: 44, height: 44)
            }
            .glassEffect(
                feedbackGiven == false ? .regular.tint(.accentColor).interactive() : .regular.interactive(),
                in: .circle
            )
            Spacer()
        }
        .font(.title3)
        .foregroundStyle(Color.accentColor)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: { flow.bookNow() }) {
                Text("Book now")
            }
            .buttonStyle(.primaryCTA)

            Button(action: { flow.shuffle() }) {
                Text("Shuffle / retry")
            }
            .buttonStyle(.secondaryCTA)
        }
    }

    private func giveFeedback(liked: Bool) {
        feedbackGiven = liked
        flow.logFeedback(liked: liked)
    }
}

private struct TotalCostBanner: View {
    let totalCost: Int
    let groupSize: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(groupSize > 1 ? "TOTAL FOR \(groupSize) TONIGHT" : "TOTAL FOR TONIGHT")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(.secondary)
                Text(PriceFormatter.rupees(totalCost))
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.accentColor, .purple], startPoint: .leading, endPoint: .trailing)
                    )
            }
            Spacer()
            Image(systemName: "indianrupeesign.circle.fill")
                .font(.system(size: 38))
                .foregroundStyle(
                    LinearGradient(colors: [.accentColor, .purple], startPoint: .top, endPoint: .bottom)
                )
        }
        .padding()
        .glassEffect(.regular.tint(.accentColor.opacity(0.35)), in: RoundedRectangle(cornerRadius: 20))
    }
}

private struct StopCard: View {
    let index: Int
    let stop: ItineraryStop

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [.accentColor, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                Text("\(index)")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(stop.venueName)
                    .font(.headline)
                Label(stop.location, systemImage: "mappin.and.ellipse")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Label(stop.timeLabel, systemImage: "clock")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(stop.priceLabel)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().fill(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 16))
    }
}
