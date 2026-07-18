import SwiftUI

public struct RoundedCross: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.maxY/3))
        path.addQuadCurve(to: CGPoint(x: rect.maxX/3, y: rect.minY), control: CGPoint(x: rect.maxX/3, y: rect.maxY/3))
        path.addLine(to: CGPoint(x: 2*rect.maxX/3, y: rect.minY))
        
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.maxY/3), control: CGPoint(x: 2*rect.maxX/3, y: rect.maxY/3))
        path.addLine(to: CGPoint(x: rect.maxX, y: 2*rect.maxY/3))

        path.addQuadCurve(to: CGPoint(x: 2*rect.maxX/3, y: rect.maxY), control: CGPoint(x: 2*rect.maxX/3, y: 2*rect.maxY/3))
        path.addLine(to: CGPoint(x: rect.maxX/3, y: rect.maxY))

        path.addQuadCurve(to: CGPoint(x: rect.minX, y: 2*rect.maxY/3), control: CGPoint(x: rect.maxX/3, y: 2*rect.maxY/3))
    
        return path
    }
}

public struct SlimRectangle: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: 4*rect.maxY/5))
        path.addLine(to: CGPoint(x: rect.maxX, y: 4*rect.maxY/5))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))

        return path
    }
}

public struct Triangle: Shape {
    public init() {}
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.minY))

        return path
    }
}

public struct ConfettiParticle: Identifiable {
    public let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var vx: CGFloat
    var vy: CGFloat
    var color: Color
    var shapeType: Int // 0: Circle, 1: Triangle, 2: RoundedCross, 3: SlimRectangle, 4: Rectangle
    var size: CGFloat
    var rotation: Double
    var rotationSpeed: Double
}

public struct ConfettiParticleView: View {
    let particle: ConfettiParticle
    @State private var currentX: CGFloat
    @State private var currentY: CGFloat
    @State private var currentRotation: Double
    @State private var opacity: Double = 1.0
    
    public init(particle: ConfettiParticle) {
        self.particle = particle
        self._currentX = State(initialValue: particle.x)
        self._currentY = State(initialValue: particle.y)
        self._currentRotation = State(initialValue: particle.rotation)
    }
    
    public var body: some View {
        Group {
            switch particle.shapeType {
            case 0:
                Circle().fill(particle.color)
            case 1:
                Triangle().fill(particle.color)
            case 2:
                RoundedCross().fill(particle.color)
            case 3:
                SlimRectangle().fill(particle.color)
            default:
                Rectangle().fill(particle.color)
            }
        }
        .frame(width: particle.size, height: particle.size)
        .rotationEffect(.degrees(currentRotation))
        .offset(x: currentX, y: currentY)
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeOut(duration: 1.5)) {
                currentX += particle.vx * 1.5
                currentY += particle.vy * 1.5 + 200 // Simulate gravity drift
                currentRotation += particle.rotationSpeed * 1.5
                opacity = 0.0
            }
        }
    }
}

public struct ConfettiCannonModifier: ViewModifier {
    @Binding var isPresented: Bool
    var num: Int
    var openingAngle: Angle
    var closingAngle: Angle
    
    @State private var particles: [ConfettiParticle] = []
    
    public func body(content: Content) -> some View {
        content
            .overlay(
                ZStack {
                    ForEach(particles) { particle in
                        ConfettiParticleView(particle: particle)
                    }
                }
            )
            .onChange(of: isPresented) { oldValue, newValue in
                if newValue {
                    fireParticles()
                    // Clean up particles after duration without mutating isPresented
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                        particles.removeAll()
                    }
                }
            }
    }
    
    private func fireParticles() {
        var newParticles: [ConfettiParticle] = []
        for _ in 0..<num {
            let angle = Double.random(in: openingAngle.degrees...closingAngle.degrees) * .pi / 180
            let speed = Double.random(in: 100...300)
            let particle = ConfettiParticle(
                x: 0,
                y: 0,
                vx: cos(angle) * speed,
                vy: -sin(angle) * speed,
                color: [Color.red, Color.blue, Color.green, Color.yellow, Color.pink, Color.purple, Color.orange].randomElement() ?? .red,
                shapeType: Int.random(in: 0...4),
                size: CGFloat.random(in: 6...14),
                rotation: Double.random(in: 0...360),
                rotationSpeed: Double.random(in: 90...360)
            )
            newParticles.append(particle)
        }
        particles = newParticles
    }
}

public extension View {
    func confettiCannon(trigger: Binding<Bool>, num: Int = 50, openingAngle: Angle = .degrees(0), closingAngle: Angle = .degrees(180)) -> some View {
        self.modifier(ConfettiCannonModifier(isPresented: trigger, num: num, openingAngle: openingAngle, closingAngle: closingAngle))
    }
}
