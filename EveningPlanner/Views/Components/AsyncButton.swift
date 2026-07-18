import SwiftUI

public enum AsyncButtonLoader {
    case proressView(size: CGFloat)
    case bouncingDots(size: CGFloat, bounce: CGFloat)
    case rotatingCircle(size: CGFloat)
    
    @ViewBuilder @MainActor
    var view: some View {
        switch self {
        case .proressView(let size):
            ProgressView()
                .frame(width: size, height: size)
                
        case .bouncingDots(let size, let bounce):
            BouncingDotsLoader(size: size, bounceHeight: bounce)
        case .rotatingCircle(let size):
            RotationgCircle(size: size)
        }
    }
}

public struct AsyncButton<Label: View>: View {
    var loader: AsyncButtonLoader
    var action: () async -> Void
    var label: () -> Label
    var showSuccessToast = false
    @State private var isPerformingTask = false
    
    public init(loader: AsyncButtonLoader = .bouncingDots(size: 10, bounce: 5), showSuccessToast: Bool = false, action: @escaping () async -> Void, @ViewBuilder label: @escaping () -> Label) {
        self.action = action
        self.label = label
        self.loader = loader
        self.showSuccessToast = showSuccessToast
    }
    @State var successToast = false
    
    public var body: some View {
        Button(action: {
            Task {
                if !isPerformingTask {
                    isPerformingTask = true
                    await action()
                    isPerformingTask = false
                    if showSuccessToast {
                        successToast = true
                    }
                }
            }
        }) {
            label()
                .opacity(isPerformingTask ? 0 : 1)
                .overlay {
                    if isPerformingTask {
                        loader.view
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(duration: 0.5), value: isPerformingTask)
        }
        .dynamicIslandToast(isPresented: $successToast, value: Toast(symbol: "checkmark.seal.fill", title: "", message: "", symbolFont: .callout, symbolForegroundStyle: .green, displayMode: .compact), duration: 1)
    }
}

public struct BouncingDotsLoader: View {
    var size: CGFloat = 10
    var bounceHeight: CGFloat = 10
    
    @State private var isAnimating = false
    
    public var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<3) { index in
                Circle()
                    .frame(width: size, height: size)
                    .offset(y: isAnimating ? -bounceHeight : 0)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

public struct RotationgCircle: View {
    @State var degree: CGFloat = .zero
    var size: CGFloat = 20
    public var body: some View {
        Circle()
            .stroke(style: StrokeStyle(lineWidth: size/4, lineCap: .round))
            .opacity(0.4)
            .frame(width: size)
            .overlay {
                Circle()
                    .trim(from: 0.75, to: 1)
                    .stroke(style: StrokeStyle(lineWidth: size/4, lineCap: .round))
                    .frame(width: size)
                    .rotationEffect(.degrees(-45))
            }
            .rotationEffect(.degrees(degree))
            .onAppear {
                withAnimation(.spring(duration: 1).repeatForever(autoreverses: false)) {
                    degree = 360
                }
            }
    }
}

public struct MyButtonStyle<MyShapeStyle: ShapeStyle, MyShape: Shape, Foreground: ShapeStyle>: ViewModifier {
    var fill: MyShapeStyle
    var shape: MyShape
    var color: Foreground
    public func body(content: Content) -> some View {
        content
            .background {
                shape
                    .fill(fill)
            }
            .foregroundStyle(color)
    }
}

public extension AsyncButton {
    func asyncButtonStyle<MyShapeStyle: ShapeStyle, MyShape: Shape, Foreground: ShapeStyle>(fill: MyShapeStyle, foreground: Foreground, shape: MyShape) -> some View {
        return modifier(MyButtonStyle(fill: fill, shape: shape, color: foreground))
    }
}

#Preview {
    VStack {
        AsyncButton(showSuccessToast: true) {
            try? await Task.sleep(nanoseconds: 4 * 1_000_000_000)
            print("Action Completed!")
        } label: {
            HStack {
                Text("Hello")
                Image(systemName: "checkmark")
            }
            .padding(10)
        }
        .asyncButtonStyle(fill: .yellow, foreground: .background, shape: Capsule())
        
        AsyncButton(loader: .proressView(size: 20)) {
            try? await Task.sleep(nanoseconds: 4 * 1_000_000_000)
            print("Action Completed!")
        } label: {
            Text("Click Me")
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .padding()
        
        AsyncButton(loader: .rotatingCircle(size: 20), showSuccessToast: true) {
            try? await Task.sleep(nanoseconds: 4 * 1_000_000_000)
            print("Action Completed!")
        } label: {
            Image(systemName: "heart.fill")
                .imageScale(.large)
                .padding()
        }
        .asyncButtonStyle(fill: .quinary, foreground: .pink, shape: RoundedRectangle(cornerRadius: 10))
    }
}
