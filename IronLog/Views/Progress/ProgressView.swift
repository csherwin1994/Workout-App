import SwiftUI
import SwiftData
import Charts

struct ProgressView: View {
    @Query(sort: \WorkoutSession.startDate) private var sessions: [WorkoutSession]
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var selectedExercise: String? = nil

    private var completedSessions: [WorkoutSession] {
        sessions.filter { $0.endDate != nil }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: AppTheme.sectionSpacing) {
                    WeeklyVolumeChart(sessions: completedSessions)
                        .sectionHeader("Weekly Volume")

                    WorkoutFrequencyChart(sessions: completedSessions)
                        .sectionHeader("Last 30 Days")

                    ExerciseProgressSection(
                        sessions: completedSessions,
                        exercises: exercises,
                        selectedExercise: $selectedExercise
                    )
                    .sectionHeader("Exercise Progress")
                }
                .padding(.top)
                .padding(.bottom, 32)
            }
            .navigationTitle("Progress")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: – Weekly volume bar chart
struct WeeklyVolumeChart: View {
    let sessions: [WorkoutSession]

    private struct WeekData: Identifiable {
        let id = UUID()
        let label: String
        let volume: Double
        let weekStart: Date
    }

    private var data: [WeekData] {
        let cal = Calendar.current
        return (0..<8).reversed().compactMap { weeksAgo -> WeekData? in
            guard let weekStart = cal.date(byAdding: .weekOfYear, value: -weeksAgo, to: Date()),
                  let weekInterval = cal.dateInterval(of: .weekOfYear, for: weekStart)
            else { return nil }

            let volume = sessions
                .filter { weekInterval.contains($0.startDate) }
                .reduce(0.0) { $0 + $1.totalVolume }

            let fmt = DateFormatter()
            fmt.dateFormat = weeksAgo == 0 ? "'This\nweek'" : "MMM d"
            return WeekData(label: fmt.string(from: weekInterval.start), volume: volume, weekStart: weekInterval.start)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if data.allSatisfy({ $0.volume == 0 }) {
                emptyState
            } else {
                Chart(data) { week in
                    BarMark(
                        x: .value("Week", week.label),
                        y: .value("Volume (kg)", week.volume)
                    )
                    .foregroundStyle(AppTheme.heroGradient)
                    .cornerRadius(6)
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { val in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = val.as(Double.self) {
                                Text(v >= 1000 ? String(format: "%.0fk", v/1000) : String(format: "%.0f", v))
                                    .font(.caption2)
                            }
                        }
                    }
                }
                .frame(height: 180)
                .padding(AppTheme.cardPadding)
                .ironCard()
                .padding(.horizontal)
            }
        }
    }

    private var emptyState: some View {
        HStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "chart.bar")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
                Text("Complete workouts to see volume trends")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        .padding(32)
        .ironCard()
        .padding(.horizontal)
    }
}

// MARK: – 30-day frequency dots
struct WorkoutFrequencyChart: View {
    let sessions: [WorkoutSession]

    private struct DayDot: Identifiable {
        let id = UUID()
        let date: Date
        let count: Int
    }

    private var days: [DayDot] {
        let cal = Calendar.current
        return (0..<30).reversed().compactMap { daysAgo -> DayDot? in
            guard let day = cal.date(byAdding: .day, value: -daysAgo, to: Date()),
                  let interval = cal.dateInterval(of: .day, for: day)
            else { return nil }
            let count = sessions.filter { interval.contains($0.startDate) }.count
            return DayDot(date: interval.start, count: count)
        }
    }

    private var maxCount: Int { days.map(\.count).max() ?? 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 10), spacing: 4) {
                ForEach(days) { day in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(day.count == 0
                              ? Color(.tertiarySystemBackground)
                              : AppTheme.accent.opacity(0.3 + 0.7 * (Double(day.count) / Double(max(maxCount, 1)))))
                        .frame(height: 28)
                        .overlay(
                            day.count > 0
                            ? Text("\(day.count)").font(.system(size: 9, weight: .bold)).foregroundStyle(.white)
                            : nil
                        )
                }
            }

            HStack {
                Circle().fill(Color(.tertiarySystemBackground)).frame(width: 10, height: 10)
                Text("Rest").font(.caption2).foregroundStyle(.secondary)
                Spacer()
                Circle().fill(AppTheme.accent.opacity(0.5)).frame(width: 10, height: 10)
                Text("Trained").font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(AppTheme.cardPadding)
        .ironCard()
        .padding(.horizontal)
    }
}

// MARK: – Per-exercise weight progress
struct ExerciseProgressSection: View {
    let sessions: [WorkoutSession]
    let exercises: [Exercise]
    @Binding var selectedExercise: String?

    private struct SetPoint: Identifiable {
        let id = UUID()
        let date: Date
        let maxWeight: Double
    }

    private var exercisesWithHistory: [String] {
        let names = Set(sessions.flatMap { $0.exerciseLogs }.map(\.exerciseName))
        return exercises.filter { names.contains($0.name) }.map(\.name).sorted()
    }

    private var selectedName: String {
        selectedExercise ?? exercisesWithHistory.first ?? ""
    }

    private var chartData: [SetPoint] {
        sessions
            .compactMap { session -> SetPoint? in
                let log = session.exerciseLogs.first { $0.exerciseName == selectedName }
                guard let log,
                      let maxWeight = log.sets.filter(\.isCompleted).map(\.weight).max(),
                      maxWeight > 0
                else { return nil }
                return SetPoint(date: session.startDate, maxWeight: maxWeight)
            }
            .sorted { $0.date < $1.date }
    }

    private var personalRecord: Double {
        chartData.map(\.maxWeight).max() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if exercisesWithHistory.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.largeTitle).foregroundStyle(.secondary)
                        Text("Log workouts to track progress per exercise")
                            .font(.subheadline).foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    Spacer()
                }
                .padding(32)
                .ironCard()
                .padding(.horizontal)
            } else {
                // Exercise picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(exercisesWithHistory, id: \.self) { name in
                            FilterChip(label: name, isSelected: selectedName == name) {
                                selectedExercise = name
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // PR badge + chart
                VStack(alignment: .leading, spacing: 16) {
                    if personalRecord > 0 {
                        HStack(spacing: 6) {
                            Image(systemName: "trophy.fill")
                                .foregroundStyle(.yellow)
                            Text("PR: \(String(format: "%.1f kg", personalRecord))")
                                .font(.subheadline.bold())
                            Spacer()
                            Text("\(chartData.count) sessions")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    if chartData.count < 2 {
                        Text("Need at least 2 sessions to show a trend")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Chart(chartData) { point in
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Weight (kg)", point.maxWeight)
                            )
                            .foregroundStyle(AppTheme.accent)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Weight (kg)", point.maxWeight)
                            )
                            .foregroundStyle(AppTheme.accent.opacity(0.12))

                            PointMark(
                                x: .value("Date", point.date),
                                y: .value("Weight (kg)", point.maxWeight)
                            )
                            .foregroundStyle(AppTheme.accent)
                            .symbolSize(30)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .day, count: max(1, chartData.count / 4))) { _ in
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    .font(.caption2)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { val in
                                AxisGridLine()
                                AxisValueLabel { Text("\(val.as(Double.self).map { Int($0) } ?? 0) kg").font(.caption2) }
                            }
                        }
                        .frame(height: 180)
                    }
                }
                .padding(AppTheme.cardPadding)
                .ironCard()
                .padding(.horizontal)
            }
        }
    }
}

#Preview("Progress – with data") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, Exercise.self, Routine.self, configurations: config)
    let context = container.mainContext
    DataManager.seedExercisesIfNeeded(context: context)

    let weights: [Double] = [60, 65, 67.5, 70, 70, 72.5, 75]
    for (i, w) in weights.enumerated() {
        let s = WorkoutSession(title: "Push Day")
        s.startDate = Calendar.current.date(byAdding: .day, value: -(weights.count - i) * 4, to: Date())!
        s.endDate = s.startDate.addingTimeInterval(3600)
        context.insert(s)
        let log = ExerciseLog(exerciseName: "Bench Press", exerciseMuscleGroup: "Chest")
        context.insert(log)
        let ws = WorkoutSet(orderIndex: 0, weight: w, reps: 5); ws.isCompleted = true
        context.insert(ws); log.sets.append(ws)
        s.exerciseLogs = [log]
    }
    try? context.save()
    return ProgressView().modelContainer(container)
}
