import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .workout

    enum Tab {
        case workout, history, progress, exercises, routines, profile
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutTabView()
                .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
                .tag(Tab.workout)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(Tab.history)

            ProgressView()
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.progress)

            ExerciseLibraryView()
                .tabItem { Label("Exercises", systemImage: "list.bullet") }
                .tag(Tab.exercises)

            RoutinesView()
                .tabItem { Label("Routines", systemImage: "repeat") }
                .tag(Tab.routines)

            ProfileView()
                .tabItem { Label("Profile", systemImage: "person.fill") }
                .tag(Tab.profile)
        }
        .tint(.blue)
    }
}

#Preview("iPhone 17 – Home") {
    ContentView()
        .modelContainer(for: [WorkoutSession.self, Exercise.self, Routine.self], inMemory: true)
}
