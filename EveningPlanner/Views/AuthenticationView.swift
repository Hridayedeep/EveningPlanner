import SwiftUI
import UIKit

struct AuthenticationView: View {
    @State var safeAreaBottom : CGFloat = .zero
    @State var size : CGSize = .zero
    @State var Xoffset : CGFloat = .zero
    @State var Yoffset : CGFloat = .zero
    @State var progress : CGFloat = .zero
    @State var circleDiameter : CGFloat = 400

    @State var isLocked : Bool = false
    @State private var lastHapticProgress: CGFloat = 0
    
    @Environment(AuthenticationModel.self) var authModel
    let gearGenerator = UIImpactFeedbackGenerator(style: .rigid)
    @State private var successHapticTrigger: Bool = false

    var finalDiameter : CGFloat = 100
    var startingDiameter : CGFloat = 400
    @Environment(\.colorScheme) var colorScheme
    @State var loading = false
    @State var error : String?
    
    var body: some View {
        ZStack {
            VStack(spacing : 0) {
                // MARK: 1. Main Welcome Text (The "Why")
                Text("a new era of health\ntracking is here")
                    .multilineTextAlignment(.center)
                    .font(.title2)
                    .fontWeight(.medium)
                    .fontDesign(.rounded)
                    .foregroundStyle(.secondary)
                    .offset(y: (size.height/4) * progress)
                    .opacity(Double(1) -  2*progress)
                    .blur(radius: 5 * progress)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .ignoresSafeArea()
            .overlay(content: {
                VStack(spacing: 8) {
                    // MARK: 2. App Name
                    Text("Meet Hault")
                        .font(.title)
                        .bold()
                        .opacity((progress - 0.2)/0.8)
                    
                    // MARK: 3. Tagline
                    Text("Pause. Track. Progress.")
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .opacity((progress - 0.9)/0.1)
                        .multilineTextAlignment(.center)
                }
                .offset(y: (size.height/4))
                .offset(y: -progress/2  * (size.height/2))
                .confettiCannon(trigger: .constant(isLocked == true), num : 50, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 180))
            })
            .overlay(alignment: .bottom, content: {
                VStack {
                    AsyncButton {
                        await authenticate(with: .apple)
                    } label: {
                        HStack {
                            Spacer()
                            Image(systemName: "apple.logo")
                            Text("Continue with Apple")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                        .padding()
                        .foregroundStyle(.background)
                    }
                    .asyncButtonStyle(fill: colorScheme == .dark ? .white : .black, foreground: colorScheme == .dark ? .black : .white, shape: Capsule())
                    .padding(.horizontal, 40)
                    .opacity((progress - 0.5) / 0.5)
                    .blur(radius: 10 * (1 - progress))
                    .disabled(loading)
                    
                    AsyncButton {
                        await authenticate(with: .google)
                    } label: {
                        HStack {
                            Spacer()
                            Text("Continue with Google")
                                .fontWeight(.medium)
                            Spacer()
                        }
                        .padding()
                    }
                    .asyncButtonStyle(fill: .clear, foreground: .primary, shape: Capsule())
                    .background {
                        Capsule()
                            .stroke(.gray, lineWidth: 1)
                    }
                    .padding(.horizontal, 40)
                    .opacity((progress - 0.5) / 0.5)
                    .blur(radius: 10 * (1 - progress))
                    .disabled(loading)
                }
                .padding(.bottom, 20)
            })
            .overlay(alignment : .bottom) {
                VStack {
                }
                .frame(width : circleDiameter, height: circleDiameter)
                .glassEffect(.clear.interactive().tint(.clear), in: Circle())
                .contentShape(Circle())
                .clipShape(Circle())
                .shadow(color : .gray.opacity(0.4), radius: 50)
                .background {
                    Capsule()
                        .fill(LinearGradient(colors: [Color.mint.opacity(0.6).opacity(8*progress), Color.cyan.opacity(0.4).opacity(8*progress), Color.blue.opacity(0.2).opacity(8*progress), Color.clear], startPoint: .top, endPoint: .bottom).opacity(1-progress))
                        .blur(radius: 10 + progress * 75)
                        .frame(height: max(0,circleDiameter - (progress) * circleDiameter))
                        .frame(width: max(0,circleDiameter - (progress/2) * circleDiameter))
                        .offset(y: progress * finalDiameter)
                }
                .overlay(content: {
                    VStack(spacing : 8) {
                        Image(systemName: "arrow.up")
                            .symbolEffect(.wiggle)
                            .font(.title2)
                        
                        // MARK: 4. Action Prompt
                        Text("Swipe up to enter")
                            .font(.callout)
                            .fontWeight(.medium)
                    }
                    .offset(y: -circleDiameter/5)
                    .foregroundStyle(.secondary)
                    .opacity(1.0 - 5 * progress)
                })
                .overlay(content: {
                    Image("Hault")
                        .resizable()
                        .scaledToFill()
                        .frame(width: finalDiameter, height: finalDiameter)
                        .clipShape(Circle())
                        .opacity((progress - 0.8) / 0.2)
                        .blur(radius: 1-progress)
                })
                .gesture(
                    DragGesture()
                        .onChanged({ val in
                            Xoffset = val.translation.width
                            let startPoint = isLocked ? -size.height/2 - finalDiameter : 0
                            let proposedOffset = startPoint + val.translation.height

                            Yoffset = min(0, max(-size.height/2 - finalDiameter, proposedOffset))
                            progress = abs(Yoffset / ((size.height/2) + finalDiameter))
                            circleDiameter = startingDiameter - (progress * (startingDiameter - finalDiameter))

                            if Yoffset < 0 {
                                let hapticThreshold: CGFloat = max(0.002, 0.025 * pow(1.0 - progress, 1.5))
                                if abs(progress - lastHapticProgress) > hapticThreshold {
                                    gearGenerator.prepare()
                                    gearGenerator.impactOccurred(intensity: progress)
                                    lastHapticProgress = progress
                                }
                            }
                        })
                        .onEnded({ val in
                            withAnimation(.interpolatingSpring(stiffness: 50, damping: 15)) {
                                if progress > 0.4 {
                                    Xoffset = .zero
                                    progress = 1
                                    Yoffset = -size.height/2 - finalDiameter
                                    circleDiameter = finalDiameter
                                    isLocked = true
                                    successHapticTrigger.toggle()
                                } else {
                                    Xoffset = .zero
                                    Yoffset = .zero
                                    progress = .zero
                                    circleDiameter = startingDiameter
                                    isLocked = false
                                    lastHapticProgress = 0
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: 0.3)
                                }
                            }
                        })
                )
                .offset(y: (circleDiameter / 2) + Yoffset)
            }
        }
        .alert("Authentication Error", isPresented: Binding(get: { error != nil }, set: { if !$0 { error = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
        .sensoryFeedback(.increase, trigger: successHapticTrigger)
        .onGeometryChange(for: CGSize.self) { proxy in
            proxy.size
        } action: { newValue in
            size = newValue
        }
    }
    
    func authenticate(with method: AuthenticationMethod) async {
        do {
            loading = true
            var user = try await authModel.authenticate(with: method)
            await authModel.logUser(user: &user)
            loading = false
        } catch {
            loading = false
            self.error = error.localizedDescription
        }
    }
}

#Preview {
    AuthenticationView()
        .environment(AuthenticationModel.forPreview())
}
