//
//  PaymentView.swift
//  EveningPlanner
//
//  Screen 4. Mock/simulated payment result — a UI stub for where a real
//  payment SDK would plug in later. No real transaction happens here.
//

import SwiftUI

struct PaymentView: View {
    @EnvironmentObject private var flow: PlanFlowViewModel
    @State private var showFailedAlert = false

    var body: some View {
        VStack(spacing: 32) {
            Text("Payment screen")
                .font(.largeTitle.bold())

            Spacer()

            VStack(spacing: 16) {
                Button(action: { flow.path.append(PlanFlowRoute.success) }) {
                    Text("Success")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glassProminent)

                Button(action: { showFailedAlert = true }) {
                    Text("Failed")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.glass)
            }

            Spacer()
        }
        .padding()
        .navigationBarBackButtonHidden(true)
        .planFlowScreenBackground()
        .alert("Payment failed", isPresented: $showFailedAlert) {
            Button("Try again", role: .cancel) {}
        }
    }
}
