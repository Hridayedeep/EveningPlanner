//
//  ContentView.swift
//  EveningPlanner
//
//  Created by Amit Raj on 18/07/26.
//

import SwiftUI
import Combine

// MARK: - Themes & Style Tokens
struct Theme {
    static let darkBackground = Color(red: 0.05, green: 0.04, blue: 0.12)
    static let darkSecondary = Color(red: 0.10, green: 0.08, blue: 0.20)
    static let purpleGlow = Color(red: 0.50, green: 0.25, blue: 0.85)
    static let accentGold = Color(red: 0.98, green: 0.70, blue: 0.25)
    static let textLight = Color.white
    static let textMuted = Color.gray.opacity(0.8)
    
    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [darkBackground, Color(red: 0.08, green: 0.06, blue: 0.18)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    static var glowGradient: LinearGradient {
        LinearGradient(
            colors: [purpleGlow, Color(red: 0.30, green: 0.15, blue: 0.60)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

struct GlassmorphicCard: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Theme.darkSecondary.opacity(0.6))
            )
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

extension View {
    func glassCard() -> some View {
        self.modifier(GlassmorphicCard())
    }
}

// MARK: - Models
enum ActivityCategory: String, Codable, CaseIterable {
    case dining = "Dining"
    case fitness = "Fitness"
    case productivity = "Productivity"
    case relax = "Relaxation"
    case social = "Social"
    case creative = "Creative"
    case selfCare = "Self Care"
    
    var icon: String {
        switch self {
        case .dining: return "fork.knife"
        case .fitness: return "figure.run"
        case .productivity: return "laptopcomputer"
        case .relax: return "moon.stars"
        case .social: return "bubble.left.and.bubble.right"
        case .creative: return "paintpalette"
        case .selfCare: return "heart.text.square"
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .dining:
            return LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .fitness:
            return LinearGradient(colors: [Color.green, Color.teal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .productivity:
            return LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .relax:
            return LinearGradient(colors: [Color.indigo, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .social:
            return LinearGradient(colors: [Color.pink, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .creative:
            return LinearGradient(colors: [Color.yellow, Color.orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .selfCare:
            return LinearGradient(colors: [Color.teal, Color.blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct SubTask: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var isCompleted: Bool = false
}

struct Activity: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var notes: String = ""
    var category: ActivityCategory
    var startTime: Date
    var endTime: Date
    var isCompleted: Bool = false
    var subTasks: [SubTask] = []
    
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }
}

struct EveningPlan: Codable, Identifiable {
    var id = UUID()
    var date: Date
    var activities: [Activity] = []
    var summary: String = ""
}

enum Mood: String, CaseIterable, Identifiable {
    case chill = "Chill"
    case productive = "Productivity"
    case creative = "Creative"
    case social = "Social"
    case energetic = "Energetic"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .chill: return "bed.double"
        case .productive: return "briefcase"
        case .creative: return "wand.and.stars"
        case .social: return "person.3"
        case .energetic: return "bolt"
        }
    }
    
    var description: String {
        switch self {
        case .chill: return "Unwind, relax, read or watch something cozy."
        case .productive: return "Finish projects, organize, learn something new."
        case .creative: return "Write, paint, code, brainstorm ideas."
        case .social: return "Connect with friends, call family, host dinner."
        case .energetic: return "Workout, deep clean, prepare for tomorrow."
        }
    }
}

// MARK: - PlanManager
class PlanManager: ObservableObject {
    @Published var activePlan: EveningPlan
    @Published var customRoutines: [EveningPlan] = []
    
    private let activePlanKey = "EveningPlanner.ActivePlan"
    private let customRoutinesKey = "EveningPlanner.CustomRoutines"
    
    init() {
        if let data = UserDefaults.standard.data(forKey: activePlanKey),
           let plan = try? JSONDecoder().decode(EveningPlan.self, from: data) {
            self.activePlan = plan
        } else {
            self.activePlan = PlanManager.createDefaultPlan()
        }
        
        if let data = UserDefaults.standard.data(forKey: customRoutinesKey),
           let routines = try? JSONDecoder().decode([EveningPlan].self, from: data) {
            self.customRoutines = routines
        } else {
            self.customRoutines = []
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(activePlan) {
            UserDefaults.standard.set(data, forKey: activePlanKey)
        }
        if let data = try? JSONEncoder().encode(customRoutines) {
            UserDefaults.standard.set(data, forKey: customRoutinesKey)
        }
        objectWillChange.send()
    }
    
    func addActivity(_ activity: Activity) {
        activePlan.activities.append(activity)
        sortActivities()
        save()
    }
    
    func updateActivity(_ activity: Activity) {
        if let index = activePlan.activities.firstIndex(where: { $0.id == activity.id }) {
            activePlan.activities[index] = activity
            sortActivities()
            save()
        }
    }
    
    func deleteActivity(_ activity: Activity) {
        activePlan.activities.removeAll(where: { $0.id == activity.id })
        save()
    }
    
    func toggleActivityCompletion(_ activity: Activity) {
        if let index = activePlan.activities.firstIndex(where: { $0.id == activity.id }) {
            activePlan.activities[index].isCompleted.toggle()
            let isComp = activePlan.activities[index].isCompleted
            for subIndex in 0..<activePlan.activities[index].subTasks.count {
                activePlan.activities[index].subTasks[subIndex].isCompleted = isComp
            }
            save()
        }
    }
    
    func toggleSubTaskCompletion(activityId: UUID, subTaskId: UUID) {
        if let actIndex = activePlan.activities.firstIndex(where: { $0.id == activityId }) {
            if let subIndex = activePlan.activities[actIndex].subTasks.firstIndex(where: { $0.id == subTaskId }) {
                activePlan.activities[actIndex].subTasks[subIndex].isCompleted.toggle()
                let allDone = activePlan.activities[actIndex].subTasks.allSatisfy { $0.isCompleted }
                if allDone && !activePlan.activities[actIndex].subTasks.isEmpty {
                    activePlan.activities[actIndex].isCompleted = true
                } else if !allDone {
                    activePlan.activities[actIndex].isCompleted = false
                }
                save()
            }
        }
    }
    
    func applyRoutine(_ plan: EveningPlan) {
        let calendar = Calendar.current
        let today = Date()
        
        var newActivities: [Activity] = []
        for activity in plan.activities {
            var newActivity = activity
            newActivity.id = UUID()
            
            let startComponents = calendar.dateComponents([.hour, .minute], from: activity.startTime)
            let endComponents = calendar.dateComponents([.hour, .minute], from: activity.endTime)
            
            if let newStart = calendar.date(bySettingHour: startComponents.hour ?? 18, minute: startComponents.minute ?? 0, second: 0, of: today),
               let newEnd = calendar.date(bySettingHour: endComponents.hour ?? 19, minute: endComponents.minute ?? 0, second: 0, of: today) {
                newActivity.startTime = newStart
                newActivity.endTime = newEnd
            }
            
            newActivity.isCompleted = false
            newActivity.subTasks = activity.subTasks.map { SubTask(title: $0.title, isCompleted: false) }
            
            newActivities.append(newActivity)
        }
        
        activePlan.activities = newActivities
        activePlan.summary = plan.summary
        sortActivities()
        save()
    }
    
    private func sortActivities() {
        activePlan.activities.sort { $0.startTime < $1.startTime }
    }
    
    var completionProgress: Double {
        guard !activePlan.activities.isEmpty else { return 0.0 }
        let completed = activePlan.activities.filter { $0.isCompleted }.count
        return Double(completed) / Double(activePlan.activities.count)
    }
    
    static func createDefaultPlan() -> EveningPlan {
        let calendar = Calendar.current
        let today = Date()
        
        let start1 = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!
        let end1 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!
        let act1 = Activity(
            title: "Evening Workout & Stretch",
            notes: "Light jogging followed by core workout and full body stretch.",
            category: .fitness,
            startTime: start1,
            endTime: end1,
            subTasks: [
                SubTask(title: "15 min Warmup"),
                SubTask(title: "30 min Core Exercise"),
                SubTask(title: "15 min Stretching")
            ]
        )
        
        let start2 = calendar.date(bySettingHour: 19, minute: 15, second: 0, of: today)!
        let end2 = calendar.date(bySettingHour: 20, minute: 15, second: 0, of: today)!
        let act2 = Activity(
            title: "Cook a Healthy Dinner",
            notes: "Prepare salmon salad with roasted sweet potatoes.",
            category: .dining,
            startTime: start2,
            endTime: end2,
            subTasks: [
                SubTask(title: "Chop veggies"),
                SubTask(title: "Bake sweet potatoes"),
                SubTask(title: "Pan sear salmon")
            ]
        )
        
        let start3 = calendar.date(bySettingHour: 21, minute: 0, second: 0, of: today)!
        let end3 = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: today)!
        let act3 = Activity(
            title: "Read & Wind Down",
            notes: "Reading 'Atomic Habits' and drinking chamomile tea.",
            category: .relax,
            startTime: start3,
            endTime: end3,
            subTasks: [
                SubTask(title: "Brew chamomile tea"),
                SubTask(title: "Read 15 pages"),
                SubTask(title: "No screens after 9:30 PM")
            ]
        )
        
        return EveningPlan(
            date: today,
            activities: [act1, act2, act3],
            summary: "A balanced evening of workout, cooking, and relaxation."
        )
    }
}

// MARK: - Smart AI Recommender Engine
struct AIRecommendationEngine {
    static func generatePlan(for mood: Mood, hoursAvailable: Int) -> EveningPlan {
        let calendar = Calendar.current
        let today = Date()
        
        var activities: [Activity] = []
        var summary = ""
        
        let startHour = 18
        let totalMinutes = hoursAvailable * 60
        
        switch mood {
        case .chill:
            summary = "Unwind, pamper yourself, and relax with minimal screen time."
            
            let s1 = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: today)!
            let e1 = calendar.date(byAdding: .minute, value: min(45, totalMinutes / 3), to: s1)!
            activities.append(Activity(
                title: "Warm Bath & Skincare",
                notes: "Decompress after a long day.",
                category: .selfCare,
                startTime: s1,
                endTime: e1,
                subTasks: [SubTask(title: "Face mask"), SubTask(title: "Listen to ambient music")]
            ))
            
            let s2 = calendar.date(byAdding: .minute, value: 15, to: e1)!
            let e2 = calendar.date(byAdding: .minute, value: min(60, totalMinutes / 3), to: s2)!
            activities.append(Activity(
                title: "Cozy Dinner & Tea",
                notes: "Order or prepare a simple comforting meal.",
                category: .dining,
                startTime: s2,
                endTime: e2,
                subTasks: [SubTask(title: "Eat without phone"), SubTask(title: "Brew herbal tea")]
            ))
            
            let s3 = calendar.date(byAdding: .minute, value: 15, to: e2)!
            let e3 = calendar.date(byAdding: .minute, value: min(90, totalMinutes / 3), to: s3)!
            activities.append(Activity(
                title: "Fiction Reading or Movie Night",
                notes: "Indulge in a relaxing storytelling activity.",
                category: .relax,
                startTime: s3,
                endTime: e3,
                subTasks: [SubTask(title: "Dim the lights"), SubTask(title: "Put phone on Sleep Focus")]
            ))
            
        case .productive:
            summary = "A sprint to clear chores, prep for tomorrow, and study."
            
            let s1 = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: today)!
            let e1 = calendar.date(byAdding: .minute, value: min(90, totalMinutes / 2), to: s1)!
            activities.append(Activity(
                title: "Skill Learning / Project Work",
                notes: "Deep focus session on your current project or course.",
                category: .productivity,
                startTime: s1,
                endTime: e1,
                subTasks: [SubTask(title: "Close all distraction tabs"), SubTask(title: "50 min work / 10 min break")]
            ))
            
            let s2 = calendar.date(byAdding: .minute, value: 10, to: e1)!
            let e2 = calendar.date(byAdding: .minute, value: min(45, totalMinutes / 4), to: s2)!
            activities.append(Activity(
                title: "Quick Healthy Dinner",
                notes: "Fuel up efficiently.",
                category: .dining,
                startTime: s2,
                endTime: e2
            ))
            
            let s3 = calendar.date(byAdding: .minute, value: 10, to: e2)!
            let e3 = calendar.date(byAdding: .minute, value: min(45, totalMinutes / 4), to: s3)!
            activities.append(Activity(
                title: "Tomorrow Prep & Clean",
                notes: "Organize desk and prepare clothes for tomorrow.",
                category: .selfCare,
                startTime: s3,
                endTime: e3,
                subTasks: [SubTask(title: "Clean desk & wash dishes"), SubTask(title: "Plan top 3 tasks for tomorrow")]
            ))
            
        case .creative:
            summary = "Ignite your imagination through expression, ideation, and play."
            
            let s1 = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: today)!
            let e1 = calendar.date(byAdding: .minute, value: min(90, totalMinutes / 2), to: s1)!
            activities.append(Activity(
                title: "Creative Sandbox Time",
                notes: "Paint, write, draw, compose, or write code for fun.",
                category: .creative,
                startTime: s1,
                endTime: e1,
                subTasks: [SubTask(title: "No strict rules - just explore"), SubTask(title: "Put on creative playlist")]
            ))
            
            let s2 = calendar.date(byAdding: .minute, value: 15, to: e1)!
            let e2 = calendar.date(byAdding: .minute, value: min(60, totalMinutes / 4), to: s2)!
            activities.append(Activity(
                title: "Inspiring Dinner & Journal",
                notes: "Have a delicious meal and write down ideas.",
                category: .dining,
                startTime: s2,
                endTime: e2,
                subTasks: [SubTask(title: "Jot down creative reflections")]
            ))
            
            let s3 = calendar.date(byAdding: .minute, value: 15, to: e2)!
            let e3 = calendar.date(byAdding: .minute, value: min(60, totalMinutes / 4), to: s3)!
            activities.append(Activity(
                title: "Artistic Ingestion",
                notes: "Listen to an educational podcast, read poetry, or analyze art.",
                category: .relax,
                startTime: s3,
                endTime: e3
            ))
            
        case .social:
            summary = "Strengthen bonds, engage in rich conversations, and share vibes."
            
            let s1 = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: today)!
            let e1 = calendar.date(byAdding: .minute, value: min(60, totalMinutes / 3), to: s1)!
            activities.append(Activity(
                title: "Call Friends / Family",
                notes: "Catch up with people who matter to you.",
                category: .social,
                startTime: s1,
                endTime: e1,
                subTasks: [SubTask(title: "Call at least one relative"), SubTask(title: "Text friends for weekend plan")]
            ))
            
            let s2 = calendar.date(byAdding: .minute, value: 15, to: e1)!
            let e2 = calendar.date(byAdding: .minute, value: min(90, totalMinutes * 2/3), to: s2)!
            activities.append(Activity(
                title: "Dinner Out / Host Friend",
                notes: "Enjoy a meal with great company.",
                category: .dining,
                startTime: s2,
                endTime: e2,
                subTasks: [SubTask(title: "Try a new local place or share a meal")]
            ))
            
        case .energetic:
            summary = "Activate your body, sweat out the stress, and plan for action."
            
            let s1 = calendar.date(bySettingHour: startHour, minute: 0, second: 0, of: today)!
            let e1 = calendar.date(byAdding: .minute, value: min(60, totalMinutes / 2), to: s1)!
            activities.append(Activity(
                title: "High Intensity Workout",
                notes: "Cardio, weight lifting, or intense yoga.",
                category: .fitness,
                startTime: s1,
                endTime: e1,
                subTasks: [SubTask(title: "Push past limits"), SubTask(title: "Hydrate well")]
            ))
            
            let s2 = calendar.date(byAdding: .minute, value: 15, to: e1)!
            let e2 = calendar.date(byAdding: .minute, value: min(60, totalMinutes / 4), to: s2)!
            activities.append(Activity(
                title: "High Protein Recovery Dinner",
                notes: "Replenish nutrients.",
                category: .dining,
                startTime: s2,
                endTime: e2
            ))
            
            let s3 = calendar.date(byAdding: .minute, value: 15, to: e2)!
            let e3 = calendar.date(byAdding: .minute, value: min(45, totalMinutes / 4), to: s3)!
            activities.append(Activity(
                title: "Stretch & Foam Roll",
                notes: "Soothe muscles to prevent soreness.",
                category: .selfCare,
                startTime: s3,
                endTime: e3
            ))
        }
        
        return EveningPlan(date: today, activities: activities, summary: summary)
    }
}

// MARK: - Main Application Tab Shell
struct ContentView: View {
    @StateObject private var manager = PlanManager()
    @State private var selectedTab = 0
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor(white: 0.6, alpha: 0.8)
        UITabBar.appearance().backgroundColor = UIColor(Theme.darkSecondary.opacity(0.95))
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView(manager: manager, selectedTab: $selectedTab)
                .tabItem {
                    Label("Dashboard", systemImage: "square.grid.2x2.fill")
                }
                .tag(0)
            
            TimelineView(manager: manager)
                .tabItem {
                    Label("Timeline", systemImage: "clock.fill")
                }
                .tag(1)
            
            SmartGeneratorView(manager: manager, selectedTab: $selectedTab)
                .tabItem {
                    Label("AI Planner", systemImage: "wand.and.stars")
                }
                .tag(2)
            
            RoutinesGalleryView(manager: manager, selectedTab: $selectedTab)
                .tabItem {
                    Label("Routines", systemImage: "square.stack.3d.up.fill")
                }
                .tag(3)
            
            AnalyticsView(manager: manager)
                .tabItem {
                    Label("Analytics", systemImage: "chart.bar.xaxis")
                }
                .tag(4)
        }
        .tint(Theme.accentGold)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Dashboard Screen
struct DashboardView: View {
    @ObservedObject var manager: PlanManager
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack {
                    HStack {
                        Circle()
                            .fill(Theme.purpleGlow.opacity(0.15))
                            .frame(width: 250, height: 250)
                            .blur(radius: 50)
                            .offset(x: -50, y: -50)
                        Spacer()
                    }
                    Spacer()
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("EVENING PLANNER")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(Theme.accentGold)
                                    .tracking(2)
                                
                                Text(greetingMessage)
                                    .font(.title)
                                    .fontWeight(.black)
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            
                            VStack(alignment: .trailing) {
                                Text(currentDayString)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Text(currentDateString)
                                    .font(.caption2)
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.08)))
                        }
                        .padding(.horizontal)
                        
                        HStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .stroke(Color.white.opacity(0.05), lineWidth: 12)
                                    .frame(width: 110, height: 110)
                                
                                Circle()
                                    .trim(from: 0.0, to: CGFloat(manager.completionProgress))
                                    .stroke(
                                        AngularGradient(
                                            gradient: Gradient(colors: [Theme.purpleGlow, Theme.accentGold, Theme.purpleGlow]),
                                            center: .center
                                        ),
                                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                    )
                                    .frame(width: 110, height: 110)
                                    .rotationEffect(Angle(degrees: -90))
                                    .animation(.easeInOut, value: manager.completionProgress)
                                
                                VStack {
                                    Text("\(Int(manager.completionProgress * 100))%")
                                        .font(.title2)
                                        .fontWeight(.black)
                                        .foregroundColor(.white)
                                    Text("Done")
                                        .font(.caption2)
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            .padding(.leading, 8)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Tonight's Progress")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(progressSubtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                
                                Button(action: {
                                    selectedTab = 1
                                }) {
                                    Text("View Timeline")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.accentGold)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(Capsule().stroke(Theme.accentGold, lineWidth: 1))
                                }
                                .padding(.top, 4)
                            }
                            Spacer()
                        }
                        .glassCard()
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Schedule")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            if manager.activePlan.activities.isEmpty {
                                VStack(spacing: 12) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 40))
                                        .foregroundColor(Theme.accentGold.opacity(0.7))
                                    Text("Your evening is currently blank.")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Quickly generate a custom evening using our AI Planner or choose a routine template.")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.6))
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                    
                                    HStack(spacing: 16) {
                                        Button(action: { selectedTab = 2 }) {
                                            Label("AI Planner", systemImage: "wand.and.stars")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(Theme.accentGold))
                                        }
                                        
                                        Button(action: { selectedTab = 3 }) {
                                            Label("Routines", systemImage: "square.stack.3d.up.fill")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 10)
                                                .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.1)))
                                        }
                                    }
                                    .padding(.top, 8)
                                }
                                .padding(.vertical, 24)
                                .frame(maxWidth: .infinity)
                                .glassCard()
                                .padding(.horizontal)
                            } else {
                                if let current = currentActivity {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("ONGOING NOW")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.accentGold)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Capsule().fill(Theme.accentGold.opacity(0.15)))
                                            
                                            Spacer()
                                            
                                            Text(timeRangeString(for: current))
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                        }
                                        
                                        HStack(alignment: .top, spacing: 14) {
                                            Circle()
                                                .fill(current.category.gradient)
                                                .frame(width: 44, height: 44)
                                                .overlay(
                                                    Image(systemName: current.category.icon)
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 18))
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(current.title)
                                                    .font(.headline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                
                                                if !current.notes.isEmpty {
                                                    Text(current.notes)
                                                        .font(.subheadline)
                                                        .foregroundColor(.white.opacity(0.6))
                                                        .lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                            
                                            Button(action: {
                                                manager.toggleActivityCompletion(current)
                                            }) {
                                                Image(systemName: current.isCompleted ? "checkmark.circle.fill" : "circle")
                                                    .font(.title2)
                                                    .foregroundColor(current.isCompleted ? .green : Theme.accentGold)
                                            }
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .glassCard()
                                    .padding(.horizontal)
                                }
                                
                                if let next = nextActivity {
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("UPCOMING NEXT")
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white.opacity(0.6))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                            
                                            Spacer()
                                            
                                            Text(timeRangeString(for: next))
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.5))
                                        }
                                        
                                        HStack(alignment: .top, spacing: 14) {
                                            Circle()
                                                .fill(next.category.gradient)
                                                .frame(width: 38, height: 38)
                                                .overlay(
                                                    Image(systemName: next.category.icon)
                                                        .foregroundColor(.white)
                                                        .font(.system(size: 16))
                                                )
                                            
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(next.title)
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.white.opacity(0.9))
                                                
                                                if !next.notes.isEmpty {
                                                    Text(next.notes)
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.5))
                                                        .lineLimit(1)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 4)
                                    }
                                    .glassCard()
                                    .padding(.horizontal)
                                }
                                
                                if currentActivity == nil && nextActivity == nil {
                                    VStack(spacing: 8) {
                                        Text("All planned activities are finished or scheduled for later.")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.7))
                                            .multilineTextAlignment(.center)
                                            .padding()
                                    }
                                    .frame(maxWidth: .infinity)
                                    .glassCard()
                                    .padding(.horizontal)
                                }
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Evening Philosophy")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "quote.opening")
                                        .font(.title)
                                        .foregroundColor(Theme.accentGold.opacity(0.6))
                                    Spacer()
                                }
                                
                                Text("An evening well-planned brings a morning of content. Focus on balanced relaxation, structured work, and quality self-care to complete your daily journey.")
                                    .font(.body)
                                    .italic()
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(4)
                                
                                HStack {
                                    Spacer()
                                    Text("— The Evening Planner")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(Theme.accentGold)
                                }
                            }
                            .glassCard()
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var greetingMessage: String {
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 12 { return "Prep Your Evening" }
        else if hour < 17 { return "Plan Your Evening" }
        else if hour < 21 { return "Good Evening!" }
        else { return "Relax & Wind Down" }
    }
    
    private var currentDayString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: Date())
    }
    
    private var currentDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: Date())
    }
    
    private var progressSubtitle: String {
        let total = manager.activePlan.activities.count
        let completed = manager.activePlan.activities.filter { $0.isCompleted }.count
        
        if total == 0 {
            return "No activities planned for tonight yet."
        } else if completed == total {
            return "Superb! You completed all \(total) activities tonight!"
        } else if completed == 0 {
            return "You have \(total) activities scheduled. Time to get started!"
        } else {
            return "Completed \(completed) of \(total) activities. Keep going!"
        }
    }
    
    private var currentActivity: Activity? {
        let now = Date()
        return manager.activePlan.activities.first { activity in
            now >= activity.startTime && now <= activity.endTime && !activity.isCompleted
        } ?? manager.activePlan.activities.first { activity in
            now >= activity.startTime && now <= activity.endTime
        }
    }
    
    private var nextActivity: Activity? {
        let now = Date()
        return manager.activePlan.activities
            .filter { $0.startTime > now }
            .min(by: { $0.startTime < $1.startTime })
    }
    
    private func timeRangeString(for activity: Activity) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: activity.startTime)) - \(formatter.string(from: activity.endTime))"
    }
}

// MARK: - Timeline Screen
struct TimelineView: View {
    @ObservedObject var manager: PlanManager
    @State private var showingAddSheet = false
    @State private var editingActivity: Activity? = nil
    @State private var expandedActivities: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Theme.purpleGlow.opacity(0.12))
                            .frame(width: 300, height: 300)
                            .blur(radius: 60)
                            .offset(x: 80, y: 80)
                    }
                }
                
                VStack(spacing: 0) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Evening Schedule")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            Text("Timeline overview of today's activities")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        Spacer()
                        
                        Button(action: {
                            showingAddSheet = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(10)
                                .background(Circle().fill(Theme.accentGold))
                        }
                    }
                    .padding()
                    
                    if manager.activePlan.activities.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Your schedule is empty")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            Text("Click the '+' button above to add an activity or use the AI Planner.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                        }
                        Spacer()
                    } else {
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(Array(manager.activePlan.activities.enumerated()), id: \.element.id) { index, activity in
                                    HStack(alignment: .top, spacing: 0) {
                                        VStack(spacing: 0) {
                                            ZStack {
                                                Circle()
                                                    .fill(activity.isCompleted ? Color.green : Theme.accentGold)
                                                    .frame(width: 16, height: 16)
                                                    .shadow(color: (activity.isCompleted ? Color.green : Theme.accentGold).opacity(0.5), radius: 6)
                                                
                                                if activity.isCompleted {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 8))
                                                        .foregroundColor(.black)
                                                        .fontWeight(.bold)
                                                }
                                            }
                                            
                                            if index < manager.activePlan.activities.count - 1 {
                                                Rectangle()
                                                    .fill(
                                                        LinearGradient(
                                                            colors: [
                                                                activity.isCompleted ? Color.green : Theme.accentGold,
                                                                manager.activePlan.activities[index + 1].isCompleted ? Color.green : Theme.accentGold
                                                            ],
                                                            startPoint: .top,
                                                            endPoint: .bottom
                                                        )
                                                    )
                                                    .frame(width: 2)
                                                    .frame(minHeight: 80)
                                            }
                                        }
                                        .frame(width: 40)
                                        
                                        VStack(alignment: .leading, spacing: 10) {
                                            VStack(alignment: .leading, spacing: 8) {
                                                HStack(alignment: .top) {
                                                    VStack(alignment: .leading, spacing: 4) {
                                                        Text(timeString(from: activity.startTime) + " - " + timeString(from: activity.endTime))
                                                            .font(.caption2)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(Theme.accentGold)
                                                        
                                                        Text(activity.title)
                                                            .font(.headline)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(.white)
                                                            .strikethrough(activity.isCompleted, color: .white.opacity(0.5))
                                                    }
                                                    Spacer()
                                                    
                                                    Text(activity.category.rawValue)
                                                        .font(.system(size: 9, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 4)
                                                        .background(Capsule().fill(activity.category.gradient))
                                                }
                                                
                                                if !activity.notes.isEmpty {
                                                    Text(activity.notes)
                                                        .font(.subheadline)
                                                        .foregroundColor(.white.opacity(0.6))
                                                        .padding(.top, 2)
                                                }
                                                
                                                if !activity.subTasks.isEmpty {
                                                    Button(action: {
                                                        toggleExpanded(activity.id)
                                                    }) {
                                                        HStack {
                                                            Text("\(activity.subTasks.filter { $0.isCompleted }.count)/\(activity.subTasks.count) tasks")
                                                                .font(.caption)
                                                                .foregroundColor(.white.opacity(0.5))
                                                            Spacer()
                                                            Image(systemName: expandedActivities.contains(activity.id) ? "chevron.up" : "chevron.down")
                                                                .font(.caption)
                                                                .foregroundColor(.white.opacity(0.5))
                                                        }
                                                        .padding(.top, 4)
                                                    }
                                                    
                                                    if expandedActivities.contains(activity.id) {
                                                        VStack(alignment: .leading, spacing: 6) {
                                                            ForEach(activity.subTasks) { subtask in
                                                                Button(action: {
                                                                    manager.toggleSubTaskCompletion(activityId: activity.id, subTaskId: subtask.id)
                                                                }) {
                                                                    HStack {
                                                                        Image(systemName: subtask.isCompleted ? "checkmark.square.fill" : "square")
                                                                            .foregroundColor(subtask.isCompleted ? .green : .white.opacity(0.4))
                                                                        Text(subtask.title)
                                                                            .font(.caption)
                                                                            .foregroundColor(subtask.isCompleted ? .white.opacity(0.5) : .white)
                                                                            .strikethrough(subtask.isCompleted, color: .white.opacity(0.3))
                                                                        Spacer()
                                                                    }
                                                                }
                                                                .buttonStyle(PlainButtonStyle())
                                                            }
                                                        }
                                                        .padding(.leading, 4)
                                                        .padding(.top, 4)
                                                        .transition(.opacity)
                                                    }
                                                }
                                                
                                                HStack {
                                                    Button(action: {
                                                        manager.toggleActivityCompletion(activity)
                                                    }) {
                                                        Label(activity.isCompleted ? "Mark Pending" : "Mark Done", systemImage: activity.isCompleted ? "arrow.uturn.backward" : "checkmark")
                                                            .font(.caption2)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(activity.isCompleted ? Theme.accentGold : .green)
                                                    }
                                                    
                                                    Spacer()
                                                    
                                                    Button(action: {
                                                        editingActivity = activity
                                                    }) {
                                                        Image(systemName: "pencil")
                                                            .font(.caption)
                                                            .foregroundColor(.white.opacity(0.6))
                                                    }
                                                    .padding(.trailing, 8)
                                                    
                                                    Button(action: {
                                                        manager.deleteActivity(activity)
                                                    }) {
                                                        Image(systemName: "trash")
                                                            .font(.caption)
                                                            .foregroundColor(.red.opacity(0.8))
                                                    }
                                                }
                                                .padding(.top, 8)
                                            }
                                            .glassCard()
                                            .padding(.trailing)
                                            .padding(.bottom, 16)
                                        }
                                    }
                                }
                            }
                            .padding(.top)
                        }
                    }
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingAddSheet) {
                ActivityEditView(manager: manager, activityToEdit: nil)
            }
            .sheet(item: $editingActivity) { activity in
                ActivityEditView(manager: manager, activityToEdit: activity)
            }
        }
    }
    
    private func toggleExpanded(_ id: UUID) {
        withAnimation {
            if expandedActivities.contains(id) {
                expandedActivities.remove(id)
            } else {
                expandedActivities.insert(id)
            }
        }
    }
    
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Activity Add / Edit Sheets
struct ActivityEditView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager: PlanManager
    
    var activityToEdit: Activity?
    
    @State private var title = ""
    @State private var notes = ""
    @State private var category: ActivityCategory = .relax
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var subtasksList: [String] = []
    @State private var newSubtask = ""
    
    init(manager: PlanManager, activityToEdit: Activity?) {
        self.manager = manager
        self.activityToEdit = activityToEdit
        
        let today = Date()
        let calendar = Calendar.current
        
        _title = State(initialValue: activityToEdit?.title ?? "")
        _notes = State(initialValue: activityToEdit?.notes ?? "")
        _category = State(initialValue: activityToEdit?.category ?? .relax)
        
        let defaultStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today) ?? today
        let defaultEnd = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today) ?? today
        
        _startTime = State(initialValue: activityToEdit?.startTime ?? defaultStart)
        _endTime = State(initialValue: activityToEdit?.endTime ?? defaultEnd)
        _subtasksList = State(initialValue: activityToEdit?.subTasks.map { $0.title } ?? [])
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                Form {
                    Section(header: Text("Details").foregroundColor(Theme.accentGold)) {
                        TextField("Title (e.g., Dinner with family)", text: $title)
                            .foregroundColor(.white)
                        
                        Picker("Category", selection: $category) {
                            ForEach(ActivityCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .foregroundColor(.white)
                        
                        TextField("Notes/Description", text: $notes)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Theme.darkSecondary.opacity(0.8))
                    
                    Section(header: Text("Schedule").foregroundColor(Theme.accentGold)) {
                        DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                        DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    }
                    .listRowBackground(Theme.darkSecondary.opacity(0.8))
                    
                    Section(header: Text("Checklist Tasks").foregroundColor(Theme.accentGold)) {
                        HStack {
                            TextField("New subtask...", text: $newSubtask)
                                .foregroundColor(.white)
                            Button(action: addSubtask) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(Theme.accentGold)
                                    .font(.title3)
                            }
                        }
                        
                        ForEach(subtasksList, id: \.self) { task in
                            HStack {
                                Text(task)
                                    .foregroundColor(.white)
                                Spacer()
                                Button(action: {
                                    subtasksList.removeAll(where: { $0 == task })
                                }) {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                    .listRowBackground(Theme.darkSecondary.opacity(0.8))
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle(activityToEdit == nil ? "Add Activity" : "Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .foregroundColor(Theme.accentGold)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveActivity()
                    }
                    .foregroundColor(Theme.accentGold)
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func addSubtask() {
        let trimmed = newSubtask.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !subtasksList.contains(trimmed) {
            subtasksList.append(trimmed)
            newSubtask = ""
        }
    }
    
    private func saveActivity() {
        if var existing = activityToEdit {
            existing.title = title
            existing.notes = notes
            existing.category = category
            existing.startTime = startTime
            existing.endTime = endTime
            existing.subTasks = subtasksList.map { taskTitle in
                let alreadyCompleted = activityToEdit?.subTasks.first(where: { $0.title == taskTitle })?.isCompleted ?? false
                return SubTask(title: taskTitle, isCompleted: alreadyCompleted)
            }
            manager.updateActivity(existing)
        } else {
            let newActivity = Activity(
                title: title,
                notes: notes,
                category: category,
                startTime: startTime,
                endTime: endTime,
                subTasks: subtasksList.map { SubTask(title: $0) }
            )
            manager.addActivity(newActivity)
        }
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Smart Generator Screen
struct SmartGeneratorView: View {
    @ObservedObject var manager: PlanManager
    @Binding var selectedTab: Int
    
    @State private var selectedMood: Mood = .chill
    @State private var hoursAvailable = 3
    @State private var generatedPlan: EveningPlan? = nil
    @State private var isGenerating = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack {
                    HStack {
                        Spacer()
                        Circle()
                            .fill(Theme.purpleGlow.opacity(0.12))
                            .frame(width: 250, height: 250)
                            .blur(radius: 50)
                            .offset(x: 50, y: -50)
                    }
                    Spacer()
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Evening Generator")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            Text("Let AI customize an optimal evening schedule for you.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How are you feeling?")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(Mood.allCases) { mood in
                                        Button(action: {
                                            withAnimation {
                                                selectedMood = mood
                                            }
                                        }) {
                                            VStack(spacing: 8) {
                                                Image(systemName: mood.icon)
                                                    .font(.title2)
                                                Text(mood.rawValue)
                                                    .font(.caption)
                                                    .fontWeight(.bold)
                                            }
                                            .frame(width: 90, height: 85)
                                            .foregroundColor(selectedMood == mood ? .black : .white)
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(selectedMood == mood ? Theme.accentGold : Theme.darkSecondary.opacity(0.6))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(selectedMood == mood ? Theme.accentGold : Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            Text(selectedMood.description)
                                .font(.caption)
                                .italic()
                                .foregroundColor(.white.opacity(0.6))
                                .padding(.horizontal)
                                .padding(.top, 4)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("How many hours do you have?")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            HStack(spacing: 12) {
                                ForEach(1...6, id: \.self) { hr in
                                    Button(action: {
                                        hoursAvailable = hr
                                    }) {
                                        Text("\(hr) hr\(hr > 1 ? "s" : "")")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, 12)
                                            .foregroundColor(hoursAvailable == hr ? .black : .white)
                                            .background(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .fill(hoursAvailable == hr ? Theme.accentGold : Theme.darkSecondary.opacity(0.6))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(hoursAvailable == hr ? Theme.accentGold : Color.white.opacity(0.08), lineWidth: 1)
                                            )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Button(action: triggerGeneration) {
                            HStack {
                                Spacer()
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .black))
                                } else {
                                    Image(systemName: "wand.and.stars")
                                    Text("Generate Custom Evening Plan")
                                }
                                Spacer()
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.vertical, 16)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Theme.accentGold))
                            .shadow(color: Theme.accentGold.opacity(0.4), radius: 10, y: 5)
                        }
                        .padding(.horizontal)
                        .disabled(isGenerating)
                        
                        if let plan = generatedPlan {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Your Tailored Evening Plan")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                
                                Text(plan.summary)
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                                    .italic()
                                
                                VStack(alignment: .leading, spacing: 0) {
                                    ForEach(plan.activities) { act in
                                        HStack(alignment: .top, spacing: 12) {
                                            Circle()
                                                .fill(act.category.gradient)
                                                .frame(width: 32, height: 32)
                                                .overlay(Image(systemName: act.category.icon).foregroundColor(.white).font(.system(size: 12)))
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(timeRangeString(for: act))
                                                    .font(.caption2)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(Theme.accentGold)
                                                
                                                Text(act.title)
                                                    .font(.subheadline)
                                                    .fontWeight(.bold)
                                                    .foregroundColor(.white)
                                                
                                                if !act.notes.isEmpty {
                                                    Text(act.notes)
                                                        .font(.caption)
                                                        .foregroundColor(.white.opacity(0.5))
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(.vertical, 10)
                                        
                                        if act.id != plan.activities.last?.id {
                                            Divider().background(Color.white.opacity(0.08))
                                        }
                                    }
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(Color.white.opacity(0.03)))
                                
                                Button(action: {
                                    manager.applyRoutine(plan)
                                    selectedTab = 1
                                }) {
                                    HStack {
                                        Spacer()
                                        Text("Activate This Evening Plan")
                                        Spacer()
                                    }
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Theme.purpleGlow))
                                    .shadow(color: Theme.purpleGlow.opacity(0.3), radius: 8, y: 4)
                                }
                                .padding(.top, 4)
                            }
                            .glassCard()
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func triggerGeneration() {
        withAnimation {
            isGenerating = true
            generatedPlan = nil
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation {
                generatedPlan = AIRecommendationEngine.generatePlan(for: selectedMood, hoursAvailable: hoursAvailable)
                isGenerating = false
            }
        }
    }
    
    private func timeRangeString(for activity: Activity) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: activity.startTime)) - \(formatter.string(from: activity.endTime))"
    }
}

// MARK: - Routines Gallery Screen
struct RoutineTemplate: Identifiable {
    var id = UUID()
    var name: String
    var description: String
    var icon: String
    var color: Color
    var plan: EveningPlan
}

struct RoutinesGalleryView: View {
    @ObservedObject var manager: PlanManager
    @Binding var selectedTab: Int
    
    @State private var selectedTemplate: RoutineTemplate? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack {
                    HStack {
                        Circle()
                            .fill(Theme.purpleGlow.opacity(0.1))
                            .frame(width: 250, height: 250)
                            .blur(radius: 50)
                            .offset(x: -50, y: 100)
                        Spacer()
                    }
                    Spacer()
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Evening Routines")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            Text("Preconfigured evening templates you can apply instantly.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal)
                        
                        VStack(spacing: 16) {
                            ForEach(templates) { template in
                                Button(action: {
                                    selectedTemplate = template
                                }) {
                                    HStack(spacing: 16) {
                                        Circle()
                                            .fill(template.color.opacity(0.15))
                                            .frame(width: 50, height: 50)
                                            .overlay(
                                                Image(systemName: template.icon)
                                                    .font(.title3)
                                                    .foregroundColor(template.color)
                                            )
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(template.name)
                                                .font(.headline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            
                                            Text(template.description)
                                                .font(.caption)
                                                .foregroundColor(.white.opacity(0.6))
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.4))
                                    }
                                    .glassCard()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
            .sheet(item: $selectedTemplate) { template in
                RoutineDetailView(manager: manager, template: template, selectedTab: $selectedTab)
            }
        }
    }
    
    private var templates: [RoutineTemplate] {
        let calendar = Calendar.current
        let today = Date()
        
        let start1 = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: today)!
        let end1 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!
        let start2 = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: today)!
        let end2 = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: today)!
        let start3 = calendar.date(bySettingHour: 20, minute: 30, second: 0, of: today)!
        let end3 = calendar.date(bySettingHour: 22, minute: 0, second: 0, of: today)!
        
        let digitalDetox = RoutineTemplate(
            name: "Digital Detox",
            description: "A serene evening focused completely off screens. Perfect after high-screen work days.",
            icon: "eye.slash.fill",
            color: .green,
            plan: EveningPlan(
                date: today,
                activities: [
                    Activity(title: "Outdoor Walk & Unplug", notes: "Leave phone home, enjoy nature.", category: .fitness, startTime: start1, endTime: end1),
                    Activity(title: "Cook Slow & Mindfully", notes: "No podcast or TV in background.", category: .dining, startTime: start2, endTime: end2),
                    Activity(title: "Read a physical book", notes: "Read at least 30 pages by soft candlelight.", category: .relax, startTime: start3, endTime: end3, subTasks: [SubTask(title: "Keep phone in locker/other room"), SubTask(title: "Brew night-time tea")])
                ],
                summary: "Disconnect to reconnect. A screen-free evening of walking, cooking, and reading."
            )
        )
        
        let cozyCinema = RoutineTemplate(
            name: "Cozy Cinema Night",
            description: "Indulge in comfort foods, dim lighting, and a cinematic masterpiece.",
            icon: "film.fill",
            color: .orange,
            plan: EveningPlan(
                date: today,
                activities: [
                    Activity(title: "Prep Comfort Food & Snacks", notes: "Popcorn, healthy dips, pizza.", category: .dining, startTime: start1, endTime: end1),
                    Activity(title: "Watch a Chosen Movie", notes: "No scrolling social media during movie.", category: .relax, startTime: start2, endTime: end3, subTasks: [SubTask(title: "Dim overhead lights"), SubTask(title: "Pick movie beforehand")])
                ],
                summary: "Relaxing movie night with comfort foods and cozy lighting."
            )
        )
        
        let productiveSprint = RoutineTemplate(
            name: "Productive Sprint",
            description: "Finish chores, prep tomorrow, and invest in learning a new skill.",
            icon: "briefcase.fill",
            color: .blue,
            plan: EveningPlan(
                date: today,
                activities: [
                    Activity(title: "30-min House Chores", notes: "Vacuum, dishes, laundry.", category: .selfCare, startTime: start1, endTime: calendar.date(byAdding: .minute, value: 30, to: start1)!),
                    Activity(title: "Coding / Reading Study", notes: "Focused learning blocks.", category: .productivity, startTime: calendar.date(byAdding: .minute, value: 30, to: start1)!, endTime: end2, subTasks: [SubTask(title: "Open tutorials"), SubTask(title: "Complete 1 coding challenge")]),
                    Activity(title: "Next Day Setup & Journal", notes: "Plan priorities, select outfit.", category: .selfCare, startTime: start3, endTime: end3)
                ],
                summary: "Organize house, study skill, and prepare for a successful tomorrow."
            )
        )
        
        let mindfulWindDown = RoutineTemplate(
            name: "Mindful Wind Down",
            description: "Calm your nervous system, stretch out body tension, and prepare for deep sleep.",
            icon: "leaf.fill",
            color: .purple,
            plan: EveningPlan(
                date: today,
                activities: [
                    Activity(title: "Gentle Yoga & Breathing", notes: "Focus on deep abdominal breathing.", category: .fitness, startTime: start1, endTime: end1),
                    Activity(title: "Light soup & salad dinner", notes: "Nutritious and easy to digest.", category: .dining, startTime: start2, endTime: end2),
                    Activity(title: "Journal & Meditation", notes: "Write down 3 things you are grateful for today.", category: .selfCare, startTime: start3, endTime: end3, subTasks: [SubTask(title: "10 mins breathing space meditation"), SubTask(title: "Log gratitude entry")])
                ],
                summary: "Calming body exercises and reflections to ease into deep rest."
            )
        )
        
        return [digitalDetox, cozyCinema, productiveSprint, mindfulWindDown]
    }
}

// MARK: - Routine Detail Sheet
struct RoutineDetailView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var manager: PlanManager
    
    var template: RoutineTemplate
    @Binding var selectedTab: Int
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack(spacing: 20) {
                    VStack(spacing: 12) {
                        Image(systemName: template.icon)
                            .font(.system(size: 50))
                            .foregroundColor(template.color)
                        
                        Text(template.name)
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                        Text(template.description)
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    VStack(alignment: .leading) {
                        Text("Timeline Preview")
                            .font(.headline)
                            .foregroundColor(Theme.accentGold)
                            .padding(.leading)
                        
                        ScrollView {
                            VStack(spacing: 0) {
                                ForEach(template.plan.activities) { act in
                                    HStack(alignment: .top, spacing: 14) {
                                        Circle()
                                            .fill(act.category.gradient)
                                            .frame(width: 32, height: 32)
                                            .overlay(Image(systemName: act.category.icon).foregroundColor(.white).font(.system(size: 12)))
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(timeRangeString(for: act))
                                                .font(.caption2)
                                                .fontWeight(.bold)
                                                .foregroundColor(Theme.accentGold)
                                            
                                            Text(act.title)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            
                                            if !act.notes.isEmpty {
                                                Text(act.notes)
                                                    .font(.caption)
                                                    .foregroundColor(.white.opacity(0.5))
                                            }
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.04)))
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(spacing: 12) {
                        Button(action: {
                            manager.applyRoutine(template.plan)
                            presentationMode.wrappedValue.dismiss()
                            selectedTab = 1
                        }) {
                            HStack {
                                Spacer()
                                Text("Apply Routine Tonight")
                                Spacer()
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Theme.accentGold))
                            .shadow(color: Theme.accentGold.opacity(0.3), radius: 8, y: 4)
                        }
                        
                        Button("Close") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .foregroundColor(.white.opacity(0.6))
                        .font(.subheadline)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func timeRangeString(for activity: Activity) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: activity.startTime)) - \(formatter.string(from: activity.endTime))"
    }
}

// MARK: - Analytics Screen
struct AnalyticsView: View {
    @ObservedObject var manager: PlanManager
    
    var body: some View {
        NavigationView {
            ZStack {
                Theme.backgroundGradient.ignoresSafeArea()
                
                VStack {
                    HStack {
                        Circle()
                            .fill(Theme.purpleGlow.opacity(0.1))
                            .frame(width: 250, height: 250)
                            .blur(radius: 50)
                            .offset(x: -50, y: -50)
                        Spacer()
                    }
                    Spacer()
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Evening Insights")
                                .font(.title)
                                .fontWeight(.black)
                                .foregroundColor(.white)
                            Text("Analyze your night scheduling and performance.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            VStack(spacing: 8) {
                                Text("TOTAL ACTIVITIES")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("\(manager.activePlan.activities.count)")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(Theme.accentGold)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .glassCard()
                            
                            VStack(spacing: 8) {
                                Text("COMPLETED")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("\(manager.activePlan.activities.filter { $0.isCompleted }.count)")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.green)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .glassCard()
                            
                            VStack(spacing: 8) {
                                Text("COMPLETION RATE")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text("\(Int(manager.completionProgress * 100))%")
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(Theme.purpleGlow)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .glassCard()
                            
                            VStack(spacing: 8) {
                                Text("TOTAL HOURS")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white.opacity(0.5))
                                
                                Text(String(format: "%.1f", totalHoursPlanned))
                                    .font(.system(size: 32, weight: .black))
                                    .foregroundColor(.cyan)
                            }
                            .frame(height: 100)
                            .frame(maxWidth: .infinity)
                            .glassCard()
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Activity Distribution")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            if manager.activePlan.activities.isEmpty {
                                Text("Add activities to see distribution analysis.")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.5))
                                    .italic()
                                    .padding(.vertical, 8)
                            } else {
                                VStack(spacing: 12) {
                                    ForEach(ActivityCategory.allCases, id: \.self) { cat in
                                        let count = categoryCount(cat)
                                        if count > 0 {
                                            VStack(spacing: 6) {
                                                HStack {
                                                    Label(cat.rawValue, systemImage: cat.icon)
                                                        .font(.caption)
                                                        .foregroundColor(.white)
                                                    
                                                    Spacer()
                                                    
                                                    Text("\(count) activity(\(count > 1 ? "ies" : ""))")
                                                        .font(.caption2)
                                                        .foregroundColor(.white.opacity(0.6))
                                                }
                                                
                                                GeometryReader { geo in
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .fill(Color.white.opacity(0.05))
                                                        .frame(height: 8)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 4)
                                                                .fill(cat.gradient)
                                                                .frame(width: geo.size.width * CGFloat(Double(count) / Double(manager.activePlan.activities.count)), height: 8),
                                                            alignment: .leading
                                                        )
                                                }
                                                .frame(height: 8)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .glassCard()
                        .padding(.horizontal)
                        
                        Spacer(minLength: 40)
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private var totalHoursPlanned: Double {
        let totalSeconds = manager.activePlan.activities.reduce(0.0) { sum, act in
            sum + act.duration
        }
        return totalSeconds / 3600.0
    }
    
    private func categoryCount(_ category: ActivityCategory) -> Int {
        manager.activePlan.activities.filter { $0.category == category }.count
    }
}

#Preview {
    ContentView()
}
