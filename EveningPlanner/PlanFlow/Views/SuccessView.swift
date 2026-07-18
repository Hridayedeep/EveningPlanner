//
//  SuccessView.swift
//  EveningPlanner
//
//  Screen 5 (popup). "Add to calendar" is real — it uses EventKit via
//  CalendarService to create one event per itinerary stop.
//

import SwiftUI

private enum CalendarAddState: Equatable {
    case idle
    case adding
    case added
    case failed(String)
}

struct SuccessView: View {
    @EnvironmentObject private var flow: PlanFlowViewModel
    @State private var calendarState: CalendarAddState = .idle

    var body: some View {
        VStack(spacing: 24) {
            Text("Success screen")
                .font(.largeTitle.bold())

            Spacer()

            VStack(spacing: 12) {
                Button(action: addToCalendar) {
                    Label(calendarButtonTitle, systemImage: calendarIcon)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)
                .disabled(calendarState == .adding || calendarState == .added)

                if case .failed(let message) = calendarState {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }

            Button(action: { flow.reset() }) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.glass)

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .planFlowScreenBackground()
    }

    private var calendarButtonTitle: String {
        switch calendarState {
        case .idle: return "Add to calendar"
        case .adding: return "Adding…"
        case .added: return "Added to calendar"
        case .failed: return "Try again"
        }
    }

    private var calendarIcon: String {
        calendarState == .added ? "checkmark" : "calendar.badge.plus"
    }

    private func addToCalendar() {
        guard let variant = flow.selectedVariant else { return }
        calendarState = .adding
        Task {
            do {
                try await CalendarService().addEvents(for: variant)
                calendarState = .added
            } catch {
                calendarState = .failed(error.localizedDescription)
            }
        }
    }
}
