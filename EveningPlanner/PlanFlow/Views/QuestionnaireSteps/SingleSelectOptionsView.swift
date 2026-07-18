//
//  SingleSelectOptionsView.swift
//  EveningPlanner
//
//  An "available: false" option (see plan_my_evening_questionnaire.json's
//  "stay_in") renders disabled with its unavailable_reason as a badge —
//  that's a data flag, not a Swift-side special case.
//

import SwiftUI

struct SingleSelectOptionsView: View {
    let options: [QuestionOption]
    @Binding var answer: AnswerValue?

    private var selectedValue: String? {
        if case .text(let value) = answer { return value }
        return nil
    }

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            VStack(spacing: 12) {
                ForEach(options) { option in
                    let isSelected = selectedValue == option.value
                    Button(action: { answer = .text(option.value) }) {
                        HStack {
                            Text(option.label).font(.headline)
                            Spacer()
                            if !option.isAvailable {
                                Text(option.unavailableReason ?? "Unavailable")
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.secondary.opacity(0.15))
                                    .clipShape(Capsule())
                            } else if isSelected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        isSelected ? .regular.tint(.accentColor).interactive() : .regular.interactive(),
                        in: RoundedRectangle(cornerRadius: 14)
                    )
                    .disabled(!option.isAvailable)
                    .opacity(option.isAvailable ? 1 : 0.55)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
            }
        }
        .onAppear {
            guard selectedValue == nil, let firstAvailable = options.first(where: { $0.isAvailable }) else { return }
            answer = .text(firstAvailable.value)
        }
    }
}
