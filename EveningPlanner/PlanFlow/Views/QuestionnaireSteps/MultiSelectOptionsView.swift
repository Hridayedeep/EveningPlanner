//
//  MultiSelectOptionsView.swift
//  EveningPlanner
//

import SwiftUI

struct MultiSelectOptionsView: View {
    let options: [QuestionOption]
    @Binding var answer: AnswerValue?

    private var selectedValues: Set<String> {
        if case .multipleChoice(let values) = answer { return Set(values) }
        return []
    }

    var body: some View {
        GlassEffectContainer(spacing: 12) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130), spacing: 12)], spacing: 12) {
                ForEach(options) { option in
                    let isSelected = selectedValues.contains(option.value)
                    Button(action: { toggle(option) }) {
                        HStack(spacing: 6) {
                            if let emoji = option.emoji { Text(emoji) }
                            Text(option.label)
                        }
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .foregroundStyle(isSelected ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .glassEffect(
                        isSelected ? .regular.tint(.accentColor).interactive() : .regular.interactive(),
                        in: .capsule
                    )
                    .disabled(!option.isAvailable)
                    .opacity(option.isAvailable ? 1 : 0.4)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                }
            }
        }
    }

    private func toggle(_ option: QuestionOption) {
        var values = selectedValues
        if values.contains(option.value) {
            values.remove(option.value)
        } else {
            values.insert(option.value)
        }
        answer = .multipleChoice(Array(values))
    }
}
