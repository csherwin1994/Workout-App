# IronLog — iOS Workout Tracker

A Hevy-inspired workout tracking app built with **SwiftUI** and **SwiftData**, targeting **iOS 17+**.

## Features

| Feature | Details |
|---|---|
| **Active Workout** | Log exercises, sets, reps & weight in real time |
| **Rest Timer** | Auto-starts after completing a set (90s default) |
| **Exercise Library** | 50+ pre-loaded exercises, filterable by muscle group |
| **Custom Exercises** | Create your own exercises |
| **Routines** | Build and reuse workout templates |
| **History** | Browse past workouts with full set details |
| **Profile & Stats** | Total workouts, sets, volume this week |

## Project Structure

```
IronLog/
├── App/
│   ├── IronLogApp.swift          # App entry point + SwiftData container
│   └── ContentView.swift           # Tab bar navigation
├── Models/
│   ├── Exercise.swift              # Exercise model (muscle group, equipment)
│   ├── WorkoutSession.swift        # WorkoutSession, ExerciseLog, WorkoutSet
│   └── Routine.swift              # Routine + RoutineExercise
├── ViewModels/
│   └── ActiveWorkoutViewModel.swift # Workout timer, set logic
├── Views/
│   ├── Workout/
│   │   ├── WorkoutTabView.swift    # Home tab (start workout / quick-start routine)
│   │   └── ActiveWorkoutView.swift # Full-screen active workout logger
│   ├── History/
│   │   └── HistoryView.swift       # Past workouts list + detail
│   ├── Exercises/
│   │   └── ExerciseLibraryView.swift # Browse / create exercises
│   ├── Routines/
│   │   └── RoutinesView.swift      # Create and manage routines
│   └── Profile/
│       └── ProfileView.swift       # Stats + settings
└── Persistence/
    └── DataManager.swift           # Seeds default exercise library
```

## Requirements

- **Mac with Xcode 15.4+**
- **iOS 17.0+** (uses SwiftData and `@Observable`)
- No third-party dependencies

## Getting Started

1. Clone this repo on your Mac
2. Open `IronLog.xcodeproj` in Xcode
3. Select your iPhone or the iOS Simulator as the run destination
4. Press **Cmd + R** to build and run
5. On first launch the app auto-seeds 50+ exercises

> **Note:** To run on a real device you need a free Apple Developer account.
> Go to **Xcode → Signing & Capabilities** and change the bundle ID to something unique (e.g. `com.yourname.IronLog`).

## Architecture

- **MVVM** — Views observe `ActiveWorkoutViewModel` via `@Observable`
- **SwiftData** — All data persisted locally with automatic migrations
- **SwiftUI** — Declarative UI, NavigationStack, sheets, full-screen covers

## Roadmap / Next Steps

- [ ] Charts for progress over time (weight lifted per exercise)
- [ ] Personal records (PR) detection and badges
- [ ] iCloud sync via CloudKit
- [ ] Apple Watch companion app
- [ ] Plate calculator
- [ ] Body measurements & weight log
