//
//  QuestionnaireView.swift
//  EveningPlanner
//
//  Screen 2. Loads QuestionnaireDefinition from flow.questionnaireProvider
//  and pages through its questions one at a time, with a smoothly
//  animated progress bar pinned to the bottom of the screen.
//

import SwiftUI

struct QuestionnaireView: View {
    @EnvironmentObject private var flow: PlanFlowViewModel
    @State private var currentIndex = 0

    var body: some View {
        VStack(spacing: 0) {
            if let questionnaire = flow.questionnaire {
                ScrollView {
                    if let profile = flow.interestProfile, !profile.isEmpty {
                        prefillBanner(profile: profile)
                    }

                    QuestionRendererView(
                        question: questionnaire.questions[currentIndex],
                        answer: bindingForCurrentAnswer(questionnaire.questions[currentIndex])
                    )
                    .id(questionnaire.questions[currentIndex].id)
                    .padding()
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }

                Spacer(minLength: 0)

                nextButton(questionnaire: questionnaire)
                progressBar(currentIndex: currentIndex, total: questionnaire.questions.count)
            } else if let error = flow.generationError {
                Spacer()
                Text(error).foregroundStyle(.red).padding()
                Spacer()
            } else {
                Spacer()
                ProgressView()
                Spacer()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .planFlowScreenBackground()
        .task {
            await flow.loadQuestionnaireIfNeeded()
        }
    }

    private func prefillBanner(profile: UserInterestProfile) -> some View {
        Label("Pre-filled from \(profile.sourceNames.joined(separator: ", ")) — tap any answer to change it", systemImage: "sparkles")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 12))
            .padding(.horizontal)
            .padding(.top, 8)
    }

    private func bindingForCurrentAnswer(_ question: Question) -> Binding<AnswerValue?> {
        Binding(
            get: { flow.answers[question.id] },
            set: { flow.answers[question.id] = $0 }
        )
    }

    private func isCurrentAnswerValid(_ question: Question) -> Bool {
        guard question.required else { return true }
        switch flow.answers[question.id] {
        case .text(let value): return !value.isEmpty
        case .multipleChoice(let values): return !values.isEmpty
        case .date: return true
        case .none: return false
        }
    }

    private func nextButton(questionnaire: QuestionnaireDefinition) -> some View {
        let question = questionnaire.questions[currentIndex]
        let isLastQuestion = currentIndex == questionnaire.questions.count - 1

        return Button(action: { advance(questionnaire: questionnaire) }) {
            Text("Next")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
        }
        .buttonStyle(.glassProminent)
        .disabled(!isCurrentAnswerValid(question))
        .padding(.horizontal)
        .padding(.top, 8)
        .animation(nil, value: isLastQuestion)
    }

    private func advance(questionnaire: QuestionnaireDefinition) {
        if currentIndex < questionnaire.questions.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentIndex += 1
            }
        } else {
            flow.path.append(PlanFlowRoute.loading)
        }
    }

    private func progressBar(currentIndex: Int, total: Int) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.clear)
                    .glassEffect(.regular, in: Capsule())
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * CGFloat(currentIndex + 1) / CGFloat(total))
                    .animation(.easeInOut(duration: 0.35), value: currentIndex)
            }
        }
        .frame(height: 8)
        .padding(.horizontal)
        .padding(.bottom, 12)
        .padding(.top, 12)
    }
}
