import SwiftUI
import SwiftData

struct ProfileView: View {
    @Query private var sessions: [WorkoutSession]
    @AppStorage("username") private var username = "Athlete"
    @AppStorage("weightUnit") private var weightUnit = "kg"
    @AppStorage("anthropicAPIKey") private var apiKey = ""
    @State private var showingAPIKeyInput = false
    @State private var tempAPIKey = ""
    @State private var editingName = false
    @State private var tempName = ""

    private var completed: [WorkoutSession] { sessions.filter { $0.endDate != nil } }

    private var totalVolume: Double {
        completed.flatMap { $0.exerciseLogs }.flatMap { $0.sets }
            .filter(\.isCompleted).reduce(0) { $0 + ($1.weight * Double($1.reps)) }
    }

    private var totalSets: Int {
        completed.flatMap { $0.exerciseLogs }.flatMap { $0.sets }
            .filter(\.isCompleted).count
    }

    private var workoutsThisWeek: Int {
        let start = Calendar.current.startOfWeek(for: Date())
        return completed.filter { $0.startDate >= start }.count
    }

    private var streak: Int {
        var count = 0
        var day = Calendar.current.startOfDay(for: Date())
        while completed.contains(where: { Calendar.current.isDate($0.startDate, inSameDayAs: day) }) {
            count += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day)!
        }
        return count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VoltColor.bg.ignoresSafeArea()
                List {
                    profileHeader
                    statsSection
                    aiSection
                    settingsSection
                    aboutSection
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Profile")
            .sheet(isPresented: $showingAPIKeyInput) { apiKeySheet }
        }
    }

    // MARK: - Profile header
    private var profileHeader: some View {
        Section {
            HStack(spacing: VoltSpacing.md) {
                ZStack {
                    Circle()
                        .fill(VoltGradient.brand)
                        .frame(width: 68, height: 68)
                    Text(username.prefix(1).uppercased())
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(.white)
                }
                VStack(alignment: .leading, spacing: 6) {
                    if editingName {
                        TextField("Name", text: $tempName)
                            .font(.title3.bold())
                            .foregroundStyle(VoltColor.label)
                            .onSubmit { saveName() }
                    } else {
                        Text(username)
                            .font(.title3.bold())
                            .foregroundStyle(VoltColor.label)
                    }
                    if streak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill").foregroundStyle(.orange).font(.caption)
                            Text("\(streak)-day streak")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                    }
                }
                Spacer()
                Button(editingName ? "Done" : "Edit") {
                    if editingName { saveName() } else { tempName = username }
                    editingName.toggle()
                }
                .font(.subheadline)
                .foregroundStyle(VoltColor.accent)
            }
            .padding(.vertical, 6)
        }
        .listRowBackground(VoltColor.surface)
    }

    // MARK: - Stats
    private var statsSection: some View {
        Section("Stats") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ProfileStatCard(value: "\(completed.count)", label: "Total Workouts", icon: "dumbbell.fill", color: VoltColor.accent)
                ProfileStatCard(value: "\(workoutsThisWeek)", label: "This Week", icon: "calendar", color: VoltColor.accentGreen)
                ProfileStatCard(value: "\(totalSets)", label: "Total Sets", icon: "repeat", color: VoltColor.accentPurple)
                ProfileStatCard(
                    value: totalVolume >= 1_000_000
                        ? String(format: "%.1fM", totalVolume / 1_000_000)
                        : totalVolume >= 1000
                            ? String(format: "%.1fk", totalVolume / 1000)
                            : String(format: "%.0f", totalVolume),
                    label: "Volume (\(weightUnit))",
                    icon: "scalemass.fill",
                    color: VoltColor.warning
                )
            }
            .padding(.vertical, 4)
        }
        .listRowBackground(Color.clear)
        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
    }

    // MARK: - AI section
    private var aiSection: some View {
        Section("AI Workout Builder") {
            Button { showingAPIKeyInput = true } label: {
                HStack {
                    Image(systemName: apiKey.isEmpty ? "key" : "checkmark.seal.fill")
                        .foregroundStyle(apiKey.isEmpty ? VoltColor.warning : VoltColor.success)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Anthropic API Key")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(VoltColor.label)
                        Text(apiKey.isEmpty ? "Tap to add your key" : "Key configured ✓")
                            .font(.caption)
                            .foregroundStyle(apiKey.isEmpty ? VoltColor.warning : VoltColor.success)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(VoltColor.labelTertiary)
                }
            }
            .listRowBackground(VoltColor.surface)
            .listRowSeparatorTint(VoltColor.border)
        }
    }

    // MARK: - Settings
    private var settingsSection: some View {
        Section("Settings") {
            Picker("Weight Unit", selection: $weightUnit) {
                Text("Kilograms (kg)").tag("kg")
                Text("Pounds (lb)").tag("lb")
            }
            .foregroundStyle(VoltColor.label)
            .listRowBackground(VoltColor.surface)
            .listRowSeparatorTint(VoltColor.border)
        }
    }

    // MARK: - About
    private var aboutSection: some View {
        Section("About") {
            LabeledContent("App", value: "Volt")
                .foregroundStyle(VoltColor.label)
            LabeledContent("Version", value: "1.0.0")
                .foregroundStyle(VoltColor.label)
            LabeledContent("Platform", value: "iOS 17+")
                .foregroundStyle(VoltColor.label)
        }
        .listRowBackground(VoltColor.surface)
        .listRowSeparatorTint(VoltColor.border)
    }

    // MARK: - API Key Sheet
    private var apiKeySheet: some View {
        NavigationStack {
            ZStack {
                VoltColor.bg.ignoresSafeArea()
                VStack(spacing: VoltSpacing.lg) {
                    VStack(spacing: VoltSpacing.md) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(VoltGradient.brand)
                        Text("AI Workout Builder")
                            .font(.title2.bold())
                            .foregroundStyle(VoltColor.label)
                        Text("Enter your Anthropic API key to enable AI-powered workout generation. Your key is stored locally on device only.")
                            .font(.subheadline)
                            .foregroundStyle(VoltColor.labelSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, VoltSpacing.xl)

                    VStack(alignment: .leading, spacing: VoltSpacing.sm) {
                        Text("API KEY")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(VoltColor.labelSecondary)
                            .tracking(0.5)

                        SecureField("sk-ant-...", text: $tempAPIKey)
                            .font(VoltFont.mono(14))
                            .foregroundStyle(VoltColor.label)
                            .padding(VoltSpacing.md)
                            .background(VoltColor.surface)
                            .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radiusSm))
                            .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radiusSm)
                                .stroke(VoltColor.border, lineWidth: 0.5))
                    }

                    VoltButton("Save Key", icon: "key.fill") {
                        apiKey = tempAPIKey.trimmingCharacters(in: .whitespaces)
                        showingAPIKeyInput = false
                    }
                    .disabled(tempAPIKey.trimmingCharacters(in: .whitespaces).isEmpty)

                    if !apiKey.isEmpty {
                        VoltButton("Remove Key", style: .danger) {
                            apiKey = ""
                            tempAPIKey = ""
                            showingAPIKeyInput = false
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, VoltSpacing.lg)
            }
            .navigationTitle("API Key")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingAPIKeyInput = false }
                        .foregroundStyle(VoltColor.labelSecondary)
                }
            }
        }
        .onAppear { tempAPIKey = apiKey }
    }

    private func saveName() {
        let trimmed = tempName.trimmingCharacters(in: .whitespaces)
        username = trimmed.isEmpty ? "Athlete" : trimmed
    }
}

struct ProfileStatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(VoltColor.label)
            Text(label)
                .font(.caption)
                .foregroundStyle(VoltColor.labelSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(VoltSpacing.md)
        .background(color.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: VoltSpacing.radius))
        .overlay(RoundedRectangle(cornerRadius: VoltSpacing.radius)
            .stroke(color.opacity(0.15), lineWidth: 0.5))
    }
}

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let c = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: c) ?? date
    }
}

#Preview("Profile") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutSession.self, Exercise.self, Routine.self, configurations: config)
    let ctx = container.mainContext
    for (title, days) in [("Push Day",0),("Pull Day",1),("Leg Day",2),("Push Day",4),("Full Body",7)] {
        let s = WorkoutSession(title: title)
        s.startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        s.endDate = s.startDate.addingTimeInterval(3600)
        ctx.insert(s)
        let log = ExerciseLog(exerciseName: "Bench Press", exerciseMuscleGroup: "Chest"); ctx.insert(log)
        let ws = WorkoutSet(orderIndex: 0, weight: 80, reps: 8); ws.isCompleted = true
        ctx.insert(ws); log.sets.append(ws); s.exerciseLogs = [log]
    }
    try? ctx.save()
    return ProfileView().modelContainer(container)
}
