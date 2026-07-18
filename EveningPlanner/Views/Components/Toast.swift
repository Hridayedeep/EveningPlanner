import SwiftUI

public struct Toast: Identifiable {
    public enum ToastDisplayMode {
        case compact
        case normal
    }
    
    public var id = UUID()
    public var symbol: String
    public var title: String
    public var message: String
    public var symbolFont: Font
    public var symbolForegroundStyle: Color
    public var displayMode: ToastDisplayMode
    
    public init(symbol: String, title: String, message: String, symbolFont: Font = .callout, symbolForegroundStyle: Color = .green, displayMode: ToastDisplayMode = .compact) {
        self.symbol = symbol
        self.title = title
        self.message = message
        self.symbolFont = symbolFont
        self.symbolForegroundStyle = symbolForegroundStyle
        self.displayMode = displayMode
    }
    
    public static func mock() -> Toast {
        Toast(symbol: "checkmark.seal.fill", title: "Transaction Successful", message: "Your transaction has been successfully processed.", symbolFont: .title, symbolForegroundStyle: .green, displayMode: .normal)
    }
}

public extension View {
    func dynamicIslandToast(isPresented: Binding<Bool>, value: Toast, duration: TimeInterval = 3.0) -> some View {
        self.modifier(DynamicIslandToastModifier(isPresented: isPresented, value: value, duration: duration))
    }
}

public struct DynamicIslandToastModifier: ViewModifier {
    @Binding var isPresented: Bool
    var value: Toast
    var duration: TimeInterval
    
    public func body(content: Content) -> some View {
        ZStack {
            content
            
            if isPresented {
                ToastOverlayView(toast: value, isPresented: $isPresented, duration: duration)
                    .zIndex(9999)
            }
        }
    }
}

public struct ToastOverlayView: View {
    let toast: Toast
    @Binding var isPresented: Bool
    let duration: TimeInterval
    
    @State private var isExpanded = false
    @State private var textHeight: CGFloat = 0
    @State private var dismissTask: Task<Void, Never>?
    
    public var body: some View {
        GeometryReader { proxy in
            let safeArea = proxy.safeAreaInsets
            let size = proxy.size
            
            let hasDynamicIsland = safeArea.top >= 59
            let dynamicIslandWidth: CGFloat = 120
            let dynamicIslandHeight: CGFloat = 36
            let topOffset: CGFloat = 11 + max((safeArea.top - 59), 0)
            
            let expandedWidth = toast.displayMode == .compact ? 200 : size.width - 20
            let basePadding: CGFloat = hasDynamicIsland ? 50 : 30
            let expandedHeight: CGFloat = toast.displayMode == .compact ? 50 : max((hasDynamicIsland ? 90 : 70), textHeight + basePadding)
            
            let scaleX: CGFloat = isExpanded ? 1 : (dynamicIslandWidth / expandedWidth)
            let scaleY: CGFloat = isExpanded ? 1 : (dynamicIslandHeight / expandedHeight)
            
            ZStack {
                if #available(iOS 17.0, *) {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .fill(Color.black)
                        .shadow(color: .gray.opacity(isExpanded ? 0.3 : 0), radius: 10)
                        .overlay(content: {
                            ToastContent(hasDynamicIsland: hasDynamicIsland)
                                .foregroundStyle(.white)
                                .frame(width: expandedWidth, height: expandedHeight)
                                .scaleEffect(x: scaleX, y: scaleY)
                        })
                        .frame(width: isExpanded ? expandedWidth : dynamicIslandWidth, height: isExpanded ? expandedHeight : dynamicIslandHeight)
                        .offset(y: hasDynamicIsland ? topOffset : (isExpanded ? safeArea.top + 10 : -80))
                        .opacity(hasDynamicIsland ? 1 : (isExpanded ? 1 : 0))
                        .geometryGroup()
                        .contentShape(.rect)
                        .gesture(
                            DragGesture()
                                .onEnded({ val in
                                    if val.translation.height < 0 {
                                        dismissToast()
                                    }
                                })
                        )
                } else {
                    RoundedRectangle(cornerRadius: 30)
                        .fill(Color.black)
                        .frame(width: isExpanded ? expandedWidth : dynamicIslandWidth, height: isExpanded ? expandedHeight : dynamicIslandHeight)
                        .offset(y: hasDynamicIsland ? topOffset : (isExpanded ? safeArea.top + 10 : -80))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.bouncy(duration: 0.4, extraBounce: 0.1)) {
                    isExpanded = true
                }
                
                dismissTask = Task {
                    try? await Task.sleep(for: .seconds(duration))
                    if !Task.isCancelled {
                        await MainActor.run {
                            dismissToast()
                        }
                    }
                }
            }
            .onDisappear {
                dismissTask?.cancel()
            }
            .animation(.bouncy(duration: 0.3, extraBounce: 0), value: isExpanded)
            .animation(.bouncy(duration: 0.3, extraBounce: 0), value: textHeight)
        }
    }
    
    private func dismissToast() {
        withAnimation(.bouncy(duration: 0.3, extraBounce: 0)) {
            isExpanded = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
        }
    }
    
    @ViewBuilder
    private func ToastContent(hasDynamicIsland: Bool) -> some View {
        if toast.displayMode == .normal {
            HStack(spacing: 10) {
                Image(systemName: toast.symbol)
                    .font(toast.symbolFont)
                    .foregroundStyle(toast.symbolForegroundStyle)
                    .symbolEffect(.wiggle, options: .default.speed(1.5), value: isExpanded)
                    .frame(width: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    if hasDynamicIsland {
                        Spacer(minLength: 0)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(toast.title)
                            .font(.callout)
                            .fontWeight(.semibold)
                            .foregroundStyle(.white)
                        
                        Text(toast.message)
                            .font(.caption)
                            .foregroundStyle(.white.secondary)
                            .lineLimit(nil)
                    }
                    .onGeometryChange(for: CGFloat.self, of: { proxy in
                        proxy.size.height
                    }, action: { newValue in
                        textHeight = newValue
                    })
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, hasDynamicIsland ? 12 : 0)
            }
            .padding(.leading, 20)
            .blur(radius: isExpanded ? 0 : 5)
            .opacity(isExpanded ? 1 : 0)
        } else {
            HStack {
                Image(systemName: toast.symbol)
                    .font(.title3)
                    .foregroundStyle(toast.symbolForegroundStyle)
                    .symbolEffect(.wiggle, options: .default.speed(1.5), value: isExpanded)
                    .frame(width: 50)
                Spacer()
            }
            .blur(radius: isExpanded ? 0 : 5)
            .opacity(isExpanded ? 1 : 0)
        }
    }
}
