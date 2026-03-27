import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.filter({ $0.endDate != nil }).isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "clock",
                        description: Text("Completed workouts will appear here.")
                    )
                } else {
                    List {
                        ForEach(groupedByMonth, id: \.key) { month, workouts in
                            Section {
                                ForEach(workouts) { session in
                                    NavigationLink {
                                        WorkoutDetailView(session: session)
                                    } label: {
                                        WorkoutHistoryRow(session: session)
                                    }
                                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                }
                            } header: {
                                Text(month)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                                    .textCase(nil)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("History")
        }
    }

    var groupedByMonth: [(key: String, value: [WorkoutSession])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let grouped = Dictionary(grouping: sessions.filter { $0.endDate != nil }) {
            formatter.string(from: $0.startDate)
        }
        return grouped.sorted { a, b in
            (a.value.first?.startDate ?? .distantPast) > (b.value.first?.startDate ?? .distantPast)
        }
    }
}

struct WorkoutHistoryRow: View {
    let session: WorkoutSession

    private var uniqueMuscleGroups: [Exercise.MuscleGroup] {
        let names = Set(session.exerciseLogs.map(\.exerciseMuscleGroup))
        return names.compactMap { Exercise.MuscleGroup(rawValue: $0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.title)
                        .font(.headline)
                    Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(session.formattedDuration)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemBackground))
                    .clipShape(Capsule())
            }

            HStack(spacing: 16) {
                statPill(value: "\(session.totalSets)", label: "sets", icon: "dumbbell")
                statPill(
                    value: session.totalVolume >= 1000
                        ? String(format: "%.1fk", session.totalVolume / 1000)
                        : String(format: "%.0f", session.totalVolume),
                    label: "kg",
                    icon: "scalemass"
                )
                statPill(value: "\(session.exerciseLogs.count)", label: "exercises", icon: "list.bullet")
            }

            if !uniqueMuscleGroups.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(uniqueMuscleGroups, id: \.self) { group in
                            MuscleBadge(group: group)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func statPill(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.caption2)
            Text("\(value) \(label)").font(.caption)
        }
        .foregroundStyle(.secondary)
    }
}

struct WorkoutDetailView: View {
    let session: WorkoutSession

    var sortedLogs: [ExerciseLog] {
        session.exerciseLogs.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        List {
            Section {
                HStack(spacing: 0) {
                    SummaryStatCell(value: session.formattedDuration, label: "Duration", icon: "clock")
                    Divider()
                    SummaryStatCell(value: "\(session.totalSets)", label: "Sets", icon: "dumbbell")
                    Divider()
                    SummaryStatCell(
                        value: session.totalVolume >= 1000
                            ? String(format: "%.1fk", session.totalVolume / 1000)
                            : String(format: "%.0f", session.totalVolume),
                        label: "Volume (kg)",
                        icon: "scalemass"
                    )
                }
            }

            ForEach(sortedLogs) { log in
                Section {
                    let completedSets = log.completedSets
                    if completedSets.isEmpty {
                        Text("No sets completed").foregroundStyle(.secondary).font(.subheadline)
                    } else {
                        ForEach(Array(completedSets.enumerated()), id: \.element.id) { index, set in
                            HStack {
                                Text("Set \(index + 1)")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
                                Spacer()
                                Text(String(format: "%.1f kg × %d reps", set.weight, set.reps))
                                    .font(.subheadline.bold())
                            }
                        }
                    }
                } header: {
                    HStack(spacing: 8) {
                        Text(log.exerciseName).textCase(nil).font(.subheadline.bold()).foregroundStyle(.primary)
                        if let group = Exercise.MuscleGroup(rawValue: log.exerciseMuscleGroup) {
                            MuscleBadge(group: group)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SummaryStatCell: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.caption).foregroundStyle(AppTheme.accent)
            Text(value).font(.headline.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview("History – with data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, Exercise.self, Routine.self, configurations: config)
    let context = container.mainContext

    for (title, daysAgo, sets) in [
        ("Push Day", 1, [("Bench Press","Chest",[(80.0,8),(85.0,6),(90.0,4)])]),
        ("Pull Day", 3, [("Deadlift","Back",[(100.0,5),(105.0,5)]),("Pull Up","Back",[(0.0,8)])]),
        ("Leg Day", 7, [("Squat","Legs",[(80.0,5),(85.0,5),(90.0,3)])])
    ] as [(String, Int, [(String, String, [(Double, Int)])])] {
        let s = WorkoutSession(title: title)
        s.startDate = Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date())!
        s.endDate = s.startDate.addingTimeInterval(3600)
        context.insert(s)
        for (i, (exName, muscle, ws)) in sets.enumerated() {
            let log = ExerciseLog(exerciseName: exName, exerciseMuscleGroup: muscle, orderIndex: i)
            context.insert(log)
            for (j, (w, r)) in ws.enumerated() {
                let set = WorkoutSet(orderIndex: j, weight: w, reps: r); set.isCompleted = true
                context.insert(set); log.sets.append(set)
            }
            s.exerciseLogs.append(log)
        }
    }
    try? context.save()
    return HistoryView().modelContainer(container)
}

#Preview("History – empty") {
    HistoryView()
        .modelContainer(for: [WorkoutSession.self, Exercise.self, Routine.self], inMemory: true)
}
