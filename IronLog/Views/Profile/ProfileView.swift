import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var sessions: [WorkoutSession]
    @AppStorage("username") private var username = "Athlete"
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @State private var editingName = false
    @State private var tempName = ""

    private var completedSessions: [WorkoutSession] { sessions.filter { $0.endDate != nil } }

    private var totalVolume: Double {
        completedSessions.flatMap { $0.exerciseLogs }.flatMap { $0.sets }
            .filter(\.isCompleted).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private var totalSets: Int {
        completedSessions.flatMap { $0.exerciseLogs }.flatMap { $0.sets }
            .filter(\.isCompleted).count
    }

    private var workoutsThisWeek: Int {
        let start = Calendar.current.startOfWeek(for: Date())
        return completedSessions.filter { $0.startDate >= start }.count
    }

    private var currentStreak: Int {
        var streak = 0
        var check = Calendar.current.startOfDay(for: Date())
        while true {
            let hit = completedSessions.contains { Calendar.current.isDate($0.startDate, inSameDayAs: check) }
            if hit { streak += 1; check = Calendar.current.date(byAdding: .day, value: -1, to: check)! }
            else { break }
        }
        return streak
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(AppTheme.heroGradient)
                                .frame(width: 68, height: 68)
                            Text(username.prefix(1).uppercased())
                                .font(.title.bold())
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 6) {
                            if editingName {
                                TextField("Your name", text: $tempName)
                                    .font(.title3.bold())
                                    .onSubmit { saveUsername() }
                            } else {
                                Text(username).font(.title3.bold())
                            }
                            if currentStreak > 0 {
                                HStack(spacing: 4) {
                                    Image(systemName: "flame.fill").foregroundStyle(.orange)
                                    Text("\(currentStreak)-day streak")
                                        .font(.caption.bold())
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        Spacer()
                        Button(editingName ? "Done" : "Edit") {
                            if editingName { saveUsername() } else { tempName = username }
                            editingName.toggle()
                        }
                        .font(.subheadline)
                        .buttonStyle(.borderless)
                    }
                    .padding(.vertical, 6)
                }

                // Stats grid
                Section("Stats") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ProfileStatCard(
                            value: "\(completedSessions.count)",
                            label: "Total Workouts",
                            icon: "dumbbell.fill",
                            color: .blue
                        )
                        ProfileStatCard(
                            value: "\(workoutsThisWeek)",
                            label: "This Week",
                            icon: "calendar",
                            color: .green
                        )
                        ProfileStatCard(
                            value: "\(totalSets)",
                            label: "Total Sets",
                            icon: "repeat",
                            color: .purple
                        )
                        ProfileStatCard(
                            value: totalVolume >= 1000
                                ? String(format: "%.1fk", totalVolume / 1000)
                                : String(format: "%.0f", totalVolume),
                            label: "Volume (\(weightUnit))",
                            icon: "scalemass.fill",
                            color: .orange
                        )
                    }
                    .padding(.vertical, 4)
                }

                // Settings
                Section("Settings") {
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("Kilograms (kg)").tag("kg")
                        Text("Pounds (lb)").tag("lb")
                    }
                }

                Section("About") {
                    LabeledContent("App", value: "IronLog")
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Built with", value: "SwiftUI + SwiftData")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Profile")
        }
    }

    private func saveUsername() {
        username = tempName.trimmingCharacters(in: .whitespaces).isEmpty ? "Athlete" : tempName
    }
}

struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.cardPadding)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview("Profile") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, Exercise.self, Routine.self, configurations: config)
    let context = container.mainContext

    for (title, daysAgo) in [("Push Day", 0), ("Pull Day", 1), ("Leg Day", 2), ("Push Day", 4), ("Full Body", 7)] {
        let s = WorkoutSession(title: title)
        s.startDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        s.endDate = s.startDate.addingTimeInterval(3600)
        context.insert(s)
        let log = ExerciseLog(exerciseName: "Bench Press", exerciseMuscleGroup: "Chest")
        context.insert(log)
        let ws = WorkoutSet(orderIndex: 0, weight: 80, reps: 8); ws.isCompleted = true
        context.insert(ws); log.sets.append(ws)
        s.exerciseLogs = [log]
    }
    try? context.save()
    return ProfileView().modelContainer(container)
}
