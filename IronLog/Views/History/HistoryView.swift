import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.startDate, order: .reverse) private var sessions: [WorkoutSession]

    var body: some View {
        NavigationStack {
            Group {
                if sessions.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "clock",
                        description: Text("Completed workouts will appear here.")
                    )
                } else {
                    List {
                        ForEach(groupedByMonth, id: \.key) { month, workouts in
                            Section(month) {
                                ForEach(workouts) { session in
                                    NavigationLink {
                                        WorkoutDetailView(session: session)
                                    } label: {
                                        WorkoutHistoryRow(session: session)
                                    }
                                }
                            }
                        }
                    }
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
            let sessions_a = a.value
            let sessions_b = b.value
            return (sessions_a.first?.startDate ?? .distantPast) > (sessions_b.first?.startDate ?? .distantPast)
        }
    }
}

struct WorkoutHistoryRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(session.title)
                    .font(.headline)
                Spacer()
                Text(session.startDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                Label(session.formattedDuration, systemImage: "clock")
                Label("\(session.totalSets) sets", systemImage: "dumbbell")
                Label(String(format: "%.0f kg", session.totalVolume), systemImage: "scalemass")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct WorkoutDetailView: View {
    let session: WorkoutSession

    var sortedLogs: [ExerciseLog] {
        session.exerciseLogs.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        List {
            Section("Summary") {
                LabeledContent("Date", value: session.startDate.formatted(date: .long, time: .shortened))
                LabeledContent("Duration", value: session.formattedDuration)
                LabeledContent("Total Sets", value: "\(session.totalSets)")
                LabeledContent("Total Volume", value: String(format: "%.1f kg", session.totalVolume))
            }

            ForEach(sortedLogs) { log in
                Section(log.exerciseName) {
                    let completedSets = log.completedSets
                    if completedSets.isEmpty {
                        Text("No sets completed").foregroundStyle(.secondary)
                    } else {
                        ForEach(Array(completedSets.enumerated()), id: \.element.id) { index, set in
                            HStack {
                                Text("Set \(index + 1)")
                                Spacer()
                                Text(String(format: "%.1f kg × %d", set.weight, set.reps))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle(session.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
