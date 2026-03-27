import SwiftUI
import SwiftData

@main
struct IronLogApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            WorkoutSession.self,
            Exercise.self,
            Routine.self
        ])
    }
}
