import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

public enum Mood: String, CaseIterable {
    case bliss = "Bliss", pleasure = "Pleasure", comfort = "Comfort"
    case amused = "Amused", neutral = "Neutral", calm = "Calm"
    case upset = "Upset", sad = "Sad", anxious = "Anxious"
    
    var rgb: (r: Double, g: Double, b: Double) {
        switch self {
        case .bliss:    return (1.0, 0.8, 0.0)
        case .pleasure: return (1.0, 0.5, 0.0)
        case .comfort:  return (0.0, 0.8, 0.8)
        case .amused:   return (0.7, 0.4, 0.9)
        case .neutral:  return (0.8, 0.8, 0.8)
        case .calm:     return (0.4, 0.8, 1.0)
        case .upset:    return (1.0, 0.3, 0.3)
        case .sad:      return (0.3, 0.4, 0.9)
        case .anxious:  return (1.0, 0.4, 0.7)
        }
    }
    
    static func at(col: Int, row: Int) -> Mood {
        let grid = [[self.bliss, .pleasure, .comfort], [.amused, .neutral, .calm], [.upset, .sad, .anxious]]
        return grid[min(max(row, 0), 2)][min(max(col, 0), 2)]
    }
}

public struct FeelingPad: View {
    
    var onSuccess : ((Mood) -> Void)
    var dotWidth: CGFloat = 6
    var spacing: CGFloat = 26
    
    @State var dotLines: Int = 1
    
    var effectRadius: CGFloat = 150
    var maxScale: CGFloat = 2.5
    
    @State var gridSize: CGSize = .zero
    @State var count: Int = 0
    @State var currentMood: Mood = .neutral
    @State var liveColor: Color = .gray
    
    @State private var dragLocation: CGPoint = CGPoint(x: -1000, y: -1000)
    @State private var isDragging: Bool = false
    
    #if canImport(UIKit)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let engineImpact = UIImpactFeedbackGenerator(style: .soft)
    #endif
    @State private var lastHapticLocation: CGPoint = .zero
    @Environment(\.dismiss) var dismiss
    
    public init(onSuccess: @escaping ((Mood) -> Void)) {
        self.onSuccess = onSuccess
    }
    
    public var body: some View {
        ZStack {
            
            VStack(spacing: 0) {
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("How are you feeling?")
                            .foregroundStyle(.secondary)
                        
                        Text(currentMood.rawValue)
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(liveColor.mix(with: .primary, by: 0.2).gradient)
                            .contentTransition(.numericText(value: 1))
                            .animation(.snappy, value: currentMood)
                            .shadow(color: liveColor.opacity(0.2), radius: 10)
                    }
                    Spacer()
                    
                    
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .frame(width: 20, height: 20)
                    }
                    .tint(.gray.opacity(0.2))
                    .buttonStyle(.borderedProminent)
                }
                .padding(.leading, 20)
                .padding(.bottom, 20)
                
                ZStack {
                    
                    Circle()
                        .fill(liveColor.opacity(0.4))
                        .frame(width: 200)
                        .blur(radius: 200)
                        .position(dragLocation)
                        .opacity(isDragging ? 1 : 1)
                    DotGrid()
                        .drawingGroup()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(.white.opacity(0.05), lineWidth: 1)
                        .fill(.ultraThickMaterial)
                }
                .coordinateSpace(name: "gridSpace")
                .contentShape(Rectangle())
                .onGeometryChange(for: CGSize.self) { proxy in
                    proxy.size
                } action: { _, newValue in
                    gridSize = newValue
                    if dotWidth + spacing > 0 {
                        count = Int((newValue.width - spacing) / (dotWidth + spacing))
                        
                        let calculatedLines = Int((newValue.height - spacing) / (dotWidth + spacing))
                        dotLines = max(1, calculatedLines)
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            if !isDragging {
                                #if canImport(UIKit)
                                heavyImpact.impactOccurred(intensity: 1.0)
                                #endif
                                lastHapticLocation = value.location
                                withAnimation(.easeIn(duration: 0.2)) { isDragging = true }
                            }
                            
                            let dist = hypot(value.location.x - lastHapticLocation.x, value.location.y - lastHapticLocation.y)
                            if dist > 10 {
                                #if canImport(UIKit)
                                engineImpact.impactOccurred(intensity: 0.8)
                                #endif
                                lastHapticLocation = value.location
                            }
                           
                            dragLocation = value.location
                            updateLogic(at: value.location)
                        }
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                                isDragging = false
                            }
                        }
                )
                
                Button {
                    onSuccess(currentMood)
                    dismiss()
                } label: {
                    HStack {
                        Spacer()
                        Text("Save")
                            .bold()
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Spacer()
                    }
                    .padding(16)
                    .background {
                        Capsule()
                            .stroke(.white.opacity(0.1), lineWidth: 1)
                            .fill(liveColor.opacity(0.3).gradient)
                    }
                    .animation(.linear(duration: 1), value: liveColor)
                }
                .padding(.top, 20)
            }
            .padding(20)
        }
        .task {
            #if canImport(UIKit)
            heavyImpact.prepare()
            engineImpact.prepare()
            #endif
            dragLocation = CGPoint(x: gridSize.width/2, y: gridSize.height/2)
            currentMood = .neutral
            liveColor = .gray
        }
    }
    
    @ViewBuilder
    func DotGrid() -> some View {
        VStack(spacing: spacing) {
            ForEach(0..<dotLines, id: \.self) { _ in
                HStack(spacing: spacing) {
                    ForEach(0...max(0, count), id: \.self) { _ in
                        Dot()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }
    
    @ViewBuilder
    func Dot() -> some View {
        ZStack {
            Circle()
                .fill(liveColor)
                .blur(radius: 5)
                .opacity(0)
            
            Circle()
                .fill(isDragging ? Color.primary.opacity(0.6) : Color.primary.opacity(0.2))
        }
        .frame(width: dotWidth, height: dotWidth)
        .visualEffect { [dragLocation, isDragging] content, proxy in
            
            let frame = proxy.frame(in: .named("gridSpace"))
            let center = CGPoint(x: frame.midX, y: frame.midY)
            
            let deltaX = dragLocation.x - center.x
            let deltaY = dragLocation.y - center.y
            let distance = hypot(deltaX, deltaY)
            
            var scale: CGFloat = 1.0
            var opacity: Double = 0.15
            var offset: CGSize = .zero
            
            if distance < effectRadius {
                let pct = distance / effectRadius
                let intensity = cos(pct * .pi / 2)
                
                scale = 1.0 + (maxScale - 1.0) * pow(intensity, 3)
                opacity = 0.15 + (0.85 * intensity)
                
                let attraction = 0.35 * pow(intensity, 2)
                
                offset = CGSize(
                    width: deltaX * attraction,
                    height: deltaY * attraction
                )
            }
            
            return content
                .scaleEffect(isDragging ? scale : 1)
                .offset(isDragging ? offset : .zero)
                .opacity(isDragging ? opacity : 1)
        }
    }
    
    func updateLogic(at location: CGPoint) {
        guard gridSize.width > 0 else { return }
        
        let cellW = gridSize.width / 3
        let cellH = gridSize.height / 3
        var tR=0.0, tG=0.0, tB=0.0, tW=0.0
        
        for r in 0..<3 {
            for c in 0..<3 {
                let cX = (CGFloat(c) * cellW) + (cellW/2)
                let cY = (CGFloat(r) * cellH) + (cellH/2)
                let dist = hypot(location.x - cX, location.y - cY)
                let weight = 1.0 / pow(1.0 + dist, 3.0)
                
                let m = Mood.at(col: c, row: r)
                tR += m.rgb.r * weight; tG += m.rgb.g * weight; tB += m.rgb.b * weight
                tW += weight
            }
        }
        liveColor = Color(red: tR/tW, green: tG/tW, blue: tB/tW)
        
        let col = Int(location.x / cellW)
        let row = Int(location.y / cellH)
        let newMood = Mood.at(col: col, row: row)
        if currentMood != newMood { currentMood = newMood }
    }
}

public struct MoodPad: ViewModifier {
    @Binding var isPresented : Bool
    var onSuccess : ((Mood) -> Void)
    var onDismiss : (() -> Void)?
    
    public func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isPresented, onDismiss: {
                if let onDismiss {
                    onDismiss()
                }
            }, content: {
                FeelingPad(onSuccess: onSuccess)
                    .presentationDetents([.fraction(0.75)])
                    .presentationDragIndicator(.visible)
                    .preferredColorScheme(.dark)
                    .interactiveDismissDisabled()
            })
    }
}

public extension View {
    func moodPad(isPresented : Binding<Bool>, onSuccess: @escaping (Mood) -> Void, onDismiss: (() -> Void)? = nil) -> some View {
        return modifier(MoodPad(isPresented: isPresented, onSuccess: onSuccess, onDismiss: onDismiss))
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

#Preview {
    @Previewable @State var show = false
    Text("Hello")
        .onTapGesture {
            show.toggle()
        }
        .moodPad(isPresented: $show, onSuccess: { mood in
            
        })
}
