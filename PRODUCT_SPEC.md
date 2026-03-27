# IronLog Product Spec

## Goal
Build IronLog into a premium dark-mode workout app that does more than tracking. It should help the user decide what to train today.

## Core AI Flow
1. User chooses workout type
2. User enters available time
3. App builds the session
4. App suggests sets, reps, and pacing

## Example Inputs
- Workout type: Push
- Time available: 45 minutes

## Example Output
- Bench Press — 4 x 6-8
- Incline Dumbbell Press — 3 x 8-10
- Cable Fly — 3 x 12-15
- Lateral Raise — 3 x 12-15
- Tricep Pushdown — 3 x 10-12

## MVP Requirements
- Add AI daily workout builder screen
- Add exercise set suggestion logic
- Keep everything local-first initially
- Preserve fast logging flow during workouts
- Use premium dark mode UI with color accents

## Builder Inputs
- Workout type
- Time available
- Goal emphasis: strength, hypertrophy, mixed
- Optional soreness or muscle exclusions

## Builder Outputs
- Ordered exercise list
- Suggested sets and rep ranges
- Suggested rest times
- Approximate total session duration

## Notes
Start with deterministic logic and rules, then layer a real model later if needed.
