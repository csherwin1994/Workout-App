import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var sessions: [WorkoutSession]
    @AppStorage("username") private var username = "Athlete"
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @State private var editingName = false
    @State private var tempName = ""

    private var completedSessions: [WorkoutSession] {
        sessions.filter { $0.endDate != nil }
    }

    private var totalVolume: Double {
        completedSessions.flatMap { $0.exerciseLogs }.flatMap { $0.sets }
            .filter(\.isCompleted).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private var totalSets: Int {
        completedSessions.flatMap { $0.exerciseLogs }.flatMap { $0.sets }
            .filter(\.isCompleted).count
    }

    private var workoutsThisWeek: Int {
        let startOfWeek = Calendar.current.startOfWeek(for: Date())
        return completedSessions.filter { $0.startDate >= startOfWeek }.count
    }

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 64, height: 64)
                            Text(username.prefix(1).uppercased())
                                .font(.largeTitle.bold())
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 4) {
                            if editingName {
                                TextField("Your name", text: $tempName)
                                    .font(.title3.bold())
                                    .onSubmit {
                                        username = tempName.isEmpty ? "Athlete" : tempName
                                        editingName = false
                                    }
                            } else {
                                Text(username)
                                    .font(.title3.bold())
                            }
                            Text("Lifting since today")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button(editingName ? "Done" : "Edit") {
                            if editingName {
                                username = tempName.isEmpty ? "Athlete" : tempName
                            } else {
                                tempName = username
                            }
                            editingName.toggle()
                        }
                        .font(.caption)
                    }
                    .padding(.vertical, 8)
                }

                // Stats
                Section("Stats") {
                    StatsGrid(
                        workoutsTotal: completedSessions.count,
                        workoutsThisWeek: workoutsThisWeek,
                        totalSets: totalSets,
                        totalVolume: totalVolume,
                        unit: weightUnit
                    )
                }

                // Settings
                Section("Settings") {
                    Picker("Weight Unit", selection: $weightUnit) {
                        Text("Kilograms (kg)").tag("kg")
                        Text("Pounds (lb)").tag("lb")
                    }
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Built with", value: "SwiftUI + SwiftData")
                }
            }
            .navigationTitle("Profile")
        }
    }
}

struct StatsGrid: View {
    let workoutsTotal: Int
    let workoutsThisWeek: Int
    let totalSets: Int
    let totalVolume: Double
    let unit: String

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            StatCard(value: "\(workoutsTotal)", label: "Total Workouts")
            StatCard(value: "\(workoutsThisWeek)", label: "This Week")
            StatCard(value: "\(totalSets)", label: "Total Sets")
            StatCard(
                value: totalVolume >= 1000
                    ? String(format: "%.1fk", totalVolume / 1000)
                    : String(format: "%.0f", totalVolume),
                label: "Volume (\(unit))"
            )
        }
        .padding(.vertical, 4)
    }
}

struct StatCard: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
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

    for (title, daysAgo) in [("Push Day", 0), ("Pull Day", 2), ("Leg Day", 4), ("Push Day", 7), ("Full Body", 9)] {
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
