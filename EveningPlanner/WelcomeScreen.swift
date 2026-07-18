//
//  WelcomeScreen.swift
//  EveningPlanner
//
//  Screen 1. Owns the NavigationStack and the single PlanFlowViewModel
//  shared by every downstream screen via @EnvironmentObject.
//

import SwiftUI

struct WelcomeScreen: View {
    @StateObject private var flow = PlanFlowViewModel()

    var body: some View {
        NavigationStack(path: $flow.path) {
            WelcomeContent()
                .navigationDestination(for: PlanFlowRoute.self) { route in
                    destination(for: route)
                }
        }
        .environmentObject(flow)
    }

    @ViewBuilder
    private func destination(for route: PlanFlowRoute) -> some View {
        switch route {
        case .appleMusicPermission:
            AppleMusicPermissionView()
        case .questionnaire:
            QuestionnaireView()
        case .loading:
            LoadingView()
        case .itinerary:
            ItineraryCardView()
        case .payment:
            PaymentView()
        case .success:
            SuccessView()
        }
    }
}

private struct WelcomeContent: View {
    @EnvironmentObject private var flow: PlanFlowViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("Plan My Evening")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            Spacer()

            Button(action: { flow.path.append(PlanFlowRoute.appleMusicPermission) }) {
                Text("Plan my evening")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.glassProminent)
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .planFlowScreenBackground()
    }
}

#Preview {
    WelcomeScreen()
}
