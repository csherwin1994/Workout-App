import SwiftUI

// MARK: - Animation Type

enum ExerciseAnimationType: Equatable {
    case benchPress, shoulderPress, curl, tricepExtension
    case squat, deadlift, row, pullUp, lunge, legCurl
    case plank, run, generic
}

// MARK: - Exercise Extension

extension Exercise {
    var animationType: ExerciseAnimationType {
        switch name {
        // Chest
        case "Bench Press", "Incline Bench Press", "Decline Bench Press",
             "Dumbbell Bench Press", "Incline Dumbbell Press", "Decline Dumbbell Press",
             "Push Up", "Wide Push Up", "Decline Push Up", "Diamond Push Up",
             "Close Grip Push Up", "Chest Dip", "Pec Deck", "Svend Press",
             "Dumbbell Fly", "Incline Dumbbell Fly", "Cable Fly",
             "Low Cable Fly", "High Cable Fly", "Smith Machine Bench Press":
            return .benchPress
        // Shoulders
        case "Overhead Press", "Push Press", "Bradford Press",
             "Arnold Press", "Dumbbell Shoulder Press", "Machine Shoulder Press",
             "Landmine Press", "Lateral Raise", "Front Raise",
             "Bent Over Lateral Raise", "Cable Lateral Raise", "Cable Front Raise",
             "Landmine Lateral Raise", "Upright Row":
            return .shoulderPress
        // Biceps
        case "Dumbbell Curl", "Barbell Curl", "Cable Curl", "Hammer Curl",
             "Concentration Curl", "Preacher Curl", "Machine Curl",
             "Incline Dumbbell Curl", "Zottman Curl", "Spider Curl",
             "Bayesian Curl", "Cable Hammer Curl":
            return .curl
        // Triceps
        case "Tricep Pushdown", "Rope Pushdown", "Overhead Tricep Extension",
             "Skull Crusher", "Bench Dip", "Tricep Dip", "Close Grip Bench Press",
             "Cable Kickback", "Kickback", "Reverse Grip Pushdown",
             "Cable Overhead Tricep Extension", "Tate Press":
            return .tricepExtension
        // Legs – squat pattern
        case "Squat", "Front Squat", "Hack Squat", "Leg Press", "Goblet Squat",
             "Smith Machine Squat", "Sissy Squat", "Pistol Squat", "Banded Squat",
             "Wall Sit", "Leg Extension", "Abductor Machine", "Adductor Machine",
             "Single Leg Press", "Bulgarian Split Squat":
            return .squat
        // Hinge / glutes
        case "Deadlift", "Romanian Deadlift", "Single Leg RDL",
             "Stiff Leg Deadlift", "Sumo Deadlift", "Rack Pull", "Good Morning",
             "Back Extension", "Hyperextension", "Dumbbell Hip Thrust",
             "Hip Thrust", "Glute Bridge":
            return .deadlift
        // Back – vertical pull
        case "Pull Up", "Chin Up", "Neutral Grip Pull Up",
             "Lat Pulldown", "Close Grip Lat Pulldown", "Straight Arm Pulldown",
             "Face Pull", "Rear Delt Fly", "Cable Reverse Fly", "Reverse Fly":
            return .pullUp
        // Back – horizontal pull
        case "Barbell Row", "Dumbbell Row", "Chest Supported Row",
             "Seated Cable Row", "Single Arm Cable Row", "T-Bar Row",
             "Kroc Row", "Pendlay Row", "Meadows Row", "Inverted Row":
            return .row
        // Lunge / calf
        case "Lunge", "Walking Lunge", "Reverse Lunge", "Step Up",
             "Calf Raise", "Seated Calf Raise", "Donkey Calf Raise":
            return .lunge
        // Leg curl / hamstring isolation
        case "Leg Curl", "Seated Leg Curl", "Nordic Curl", "Glute-Ham Raise":
            return .legCurl
        // Core
        case "Plank", "Side Plank", "Hollow Body Hold", "L-Sit",
             "Dead Bug", "Bird Dog", "Ab Rollout", "Hanging Leg Raise",
             "Toes to Bar", "Dragon Flag", "Pallof Press", "Crunch",
             "Sit Up", "V-Up", "Bicycle Crunch", "Russian Twist",
             "Oblique Crunch", "Decline Crunch", "Cable Crunch",
             "Cable Woodchop", "Landmine Rotation", "Medicine Ball Slam",
             "GHD Sit Up":
            return .plank
        // Cardio & full-body
        case "Treadmill", "Sprints", "Jump Rope", "Burpee", "Battle Ropes",
             "Cycling", "Assault Bike", "Rowing Machine", "Elliptical",
             "Swimming", "Stair Climber", "Ski Erg", "Bear Crawl",
             "Thruster", "Power Clean", "Clean and Jerk", "Snatch",
             "Kettlebell Swing", "Turkish Get-Up", "Farmer's Walk",
             "Sled Push", "Sled Pull", "Tire Flip", "Man Maker", "Box Jump":
            return .run
        default:
            switch muscleGroup {
            case .chest:     return .benchPress
            case .back:      return .row
            case .shoulders: return .shoulderPress
            case .biceps:    return .curl
            case .triceps:   return .tricepExtension
            case .legs:      return .squat
            case .glutes:    return .deadlift
            case .core:      return .plank
            case .cardio:    return .run
            case .fullBody:  return .generic
            }
        }
    }

    var movementCue: String {
        switch animationType {
        case .benchPress:       return "Push · Lower with control"
        case .shoulderPress:    return "Drive overhead · Lock out"
        case .curl:             return "Curl up · Squeeze at top"
        case .tricepExtension:  return "Extend fully · Control down"
        case .squat:            return "Sit back · Drive through heels"
        case .deadlift:         return "Hinge at hips · Flat back"
        case .row:              return "Pull to hip · Lead with elbow"
        case .pullUp:           return "Pull to chest · Control descent"
        case .lunge:            return "Step forward · 90° both knees"
        case .legCurl:          return "Curl up · Squeeze hamstrings"
        case .plank:            return "Brace core · Neutral spine"
        case .run:              return "Find your rhythm · Stay loose"
        case .generic:          return "Control the weight · Full range"
        }
    }
}

// MARK: - Pose (design space: 160 × 190 pts)

private struct Pose {
    var head, neck: CGPoint
    var shL, shR, elL, elR, hnL, hnR: CGPoint
    var hipC, hipL, hipR: CGPoint
    var knL, knR, ftL, ftR: CGPoint

    /// Linear interpolation between two poses
    func lerp(to b: Pose, t: CGFloat) -> Pose {
        func lp(_ a: CGPoint, _ c: CGPoint) -> CGPoint {
            .init(x: a.x + (c.x - a.x) * t, y: a.y + (c.y - a.y) * t)
        }
        return Pose(
            head: lp(head, b.head), neck: lp(neck, b.neck),
            shL: lp(shL, b.shL),   shR: lp(shR, b.shR),
            elL: lp(elL, b.elL),   elR: lp(elR, b.elR),
            hnL: lp(hnL, b.hnL),   hnR: lp(hnR, b.hnR),
            hipC: lp(hipC, b.hipC), hipL: lp(hipL, b.hipL), hipR: lp(hipR, b.hipR),
            knL: lp(knL, b.knL),   knR: lp(knR, b.knR),
            ftL: lp(ftL, b.ftL),   ftR: lp(ftR, b.ftR)
        )
    }

    /// Scale from design space to the given canvas size, centered
    func fit(to size: CGSize) -> Pose {
        let scale = min(size.width / 160, size.height / 190)
        let ox = (size.width  - 160 * scale) / 2
        let oy = (size.height - 190 * scale) / 2
        func s(_ p: CGPoint) -> CGPoint { .init(x: p.x * scale + ox, y: p.y * scale + oy) }
        return Pose(
            head: s(head), neck: s(neck),
            shL: s(shL),   shR: s(shR),
            elL: s(elL),   elR: s(elR),
            hnL: s(hnL),   hnR: s(hnR),
            hipC: s(hipC), hipL: s(hipL), hipR: s(hipR),
            knL: s(knL),   knR: s(knR),
            ftL: s(ftL),   ftR: s(ftR)
        )
    }
}

// MARK: - Pose Library

private enum Poses {
    // Neutral standing
    static let stand = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 46, y: 78), elR:  .init(x: 114, y: 78),
        hnL:  .init(x: 46, y: 108), hnR: .init(x: 114, y: 108),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Squat bottom — hips low, knees wide, arms out for balance
    static let squat = Pose(
        head: .init(x: 80, y: 52), neck: .init(x: 80, y: 66),
        shL:  .init(x: 60, y: 76), shR:  .init(x: 100, y: 76),
        elL:  .init(x: 44, y: 98), elR:  .init(x: 116, y: 98),
        hnL:  .init(x: 40, y: 120), hnR: .init(x: 120, y: 120),
        hipC: .init(x: 80, y: 122), hipL: .init(x: 65, y: 122), hipR: .init(x: 95, y: 122),
        knL:  .init(x: 50, y: 152), knR:  .init(x: 110, y: 152),
        ftL:  .init(x: 46, y: 172), ftR:  .init(x: 114, y: 172)
    )

    // Shoulder press start — elbows at ear height
    static let pressStart = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 36, y: 56), elR:  .init(x: 124, y: 56),
        hnL:  .init(x: 44, y: 38), hnR:  .init(x: 116, y: 38),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Shoulder press top — arms overhead
    static let pressTop = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 54, y: 28), elR:  .init(x: 106, y: 28),
        hnL:  .init(x: 54, y: 8),  hnR:  .init(x: 106, y: 8),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Bench press / fly — arms wide open (eccentric)
    static let chestOpen = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 26, y: 62), elR:  .init(x: 134, y: 62),
        hnL:  .init(x: 12, y: 48), hnR:  .init(x: 148, y: 48),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Bench press / fly — arms contracted in (concentric)
    static let chestClose = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 56, y: 58), elR:  .init(x: 104, y: 58),
        hnL:  .init(x: 64, y: 42), hnR:  .init(x: 96, y: 42),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Bicep curl bottom
    static let curlDown = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 50, y: 80), elR:  .init(x: 110, y: 80),
        hnL:  .init(x: 50, y: 112), hnR: .init(x: 110, y: 112),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Bicep curl top — forearms raised to shoulder height
    static let curlUp = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 50, y: 80), elR:  .init(x: 110, y: 80),
        hnL:  .init(x: 60, y: 52), hnR:  .init(x: 100, y: 52),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Tricep extension — arms bent, hands behind head
    static let triStart = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 55, y: 26), elR:  .init(x: 105, y: 26),
        hnL:  .init(x: 62, y: 50), hnR:  .init(x: 98, y: 50),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Tricep extension — arms fully overhead
    static let triTop = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 55, y: 26), elR:  .init(x: 105, y: 26),
        hnL:  .init(x: 53, y: 6),  hnR:  .init(x: 107, y: 6),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Row — arms extended
    static let rowOut = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 26, y: 58), elR:  .init(x: 134, y: 58),
        hnL:  .init(x: 6,  y: 66), hnR:  .init(x: 154, y: 66),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Row — arms pulled to torso
    static let rowIn = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 38, y: 66), elR:  .init(x: 122, y: 66),
        hnL:  .init(x: 58, y: 76), hnR:  .init(x: 102, y: 76),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Pull-up hanging — arms stretched up
    static let hangDown = Pose(
        head: .init(x: 80, y: 32), neck: .init(x: 80, y: 46),
        shL:  .init(x: 62, y: 56), shR:  .init(x: 98, y: 56),
        elL:  .init(x: 56, y: 30), elR:  .init(x: 104, y: 30),
        hnL:  .init(x: 50, y: 8),  hnR:  .init(x: 110, y: 8),
        hipC: .init(x: 80, y: 116), hipL: .init(x: 70, y: 116), hipR: .init(x: 90, y: 116),
        knL:  .init(x: 68, y: 148), knR:  .init(x: 92, y: 148),
        ftL:  .init(x: 65, y: 178), ftR:  .init(x: 95, y: 178)
    )

    // Pull-up top — chin clears bar
    static let hangTop = Pose(
        head: .init(x: 80, y: 14), neck: .init(x: 80, y: 28),
        shL:  .init(x: 60, y: 38), shR:  .init(x: 100, y: 38),
        elL:  .init(x: 42, y: 20), elR:  .init(x: 118, y: 20),
        hnL:  .init(x: 50, y: 8),  hnR:  .init(x: 110, y: 8),
        hipC: .init(x: 80, y: 98), hipL: .init(x: 68, y: 98), hipR: .init(x: 92, y: 98),
        knL:  .init(x: 65, y: 130), knR:  .init(x: 95, y: 130),
        ftL:  .init(x: 62, y: 160), ftR:  .init(x: 98, y: 160)
    )

    // Deadlift / hinge standing — bar in hand
    static let deadStand = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 52, y: 80), elR:  .init(x: 108, y: 80),
        hnL:  .init(x: 58, y: 112), hnR: .init(x: 102, y: 112),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 172), ftR:  .init(x: 98, y: 172)
    )

    // Deadlift / hinge — hinged forward at hip
    static let deadHinge = Pose(
        head: .init(x: 42, y: 55), neck: .init(x: 56, y: 70),
        shL:  .init(x: 62, y: 82), shR:  .init(x: 76, y: 70),
        elL:  .init(x: 68, y: 108), elR: .init(x: 80, y: 96),
        hnL:  .init(x: 68, y: 136), hnR: .init(x: 80, y: 122),
        hipC: .init(x: 92, y: 82), hipL: .init(x: 86, y: 86), hipR: .init(x: 100, y: 78),
        knL:  .init(x: 84, y: 120), knR:  .init(x: 100, y: 120),
        ftL:  .init(x: 78, y: 156), ftR:  .init(x: 100, y: 156)
    )

    // Lunge bottom — one leg forward, one back
    static let lungeDown = Pose(
        head: .init(x: 80, y: 32), neck: .init(x: 80, y: 46),
        shL:  .init(x: 62, y: 58), shR:  .init(x: 98, y: 58),
        elL:  .init(x: 52, y: 84), elR:  .init(x: 108, y: 84),
        hnL:  .init(x: 52, y: 110), hnR: .init(x: 108, y: 110),
        hipC: .init(x: 80, y: 112), hipL: .init(x: 72, y: 112), hipR: .init(x: 88, y: 112),
        knL:  .init(x: 52, y: 148), knR:  .init(x: 96, y: 148),
        ftL:  .init(x: 40, y: 172), ftR:  .init(x: 112, y: 172)
    )

    // Leg curl top — lower legs curl back/up
    static let legCurlTop = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 38),
        shL:  .init(x: 58, y: 50), shR:  .init(x: 102, y: 50),
        elL:  .init(x: 46, y: 78), elR:  .init(x: 114, y: 78),
        hnL:  .init(x: 46, y: 108), hnR: .init(x: 114, y: 108),
        hipC: .init(x: 80, y: 108), hipL: .init(x: 68, y: 108), hipR: .init(x: 92, y: 108),
        knL:  .init(x: 65, y: 140), knR:  .init(x: 95, y: 140),
        ftL:  .init(x: 62, y: 112), ftR:  .init(x: 98, y: 112)
    )

    // Plank — horizontal body, viewed from the side
    static let plank = Pose(
        head: .init(x: 18, y: 82),  neck: .init(x: 34, y: 90),
        shL:  .init(x: 50, y: 90),  shR:  .init(x: 50, y: 102),
        elL:  .init(x: 72, y: 90),  elR:  .init(x: 72, y: 102),
        hnL:  .init(x: 92, y: 90),  hnR:  .init(x: 92, y: 102),
        hipC: .init(x: 112, y: 92), hipL: .init(x: 110, y: 88), hipR: .init(x: 110, y: 100),
        knL:  .init(x: 134, y: 88), knR:  .init(x: 134, y: 100),
        ftL:  .init(x: 152, y: 88), ftR:  .init(x: 152, y: 100)
    )

    // Run A — one stride
    static let runA = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 36),
        shL:  .init(x: 62, y: 48), shR:  .init(x: 98, y: 48),
        elL:  .init(x: 46, y: 68), elR:  .init(x: 112, y: 62),
        hnL:  .init(x: 36, y: 50), hnR:  .init(x: 124, y: 78),
        hipC: .init(x: 80, y: 102), hipL: .init(x: 72, y: 102), hipR: .init(x: 88, y: 102),
        knL:  .init(x: 58, y: 130), knR:  .init(x: 100, y: 126),
        ftL:  .init(x: 50, y: 162), ftR:  .init(x: 112, y: 154)
    )

    // Run B — opposite stride
    static let runB = Pose(
        head: .init(x: 80, y: 22), neck: .init(x: 80, y: 36),
        shL:  .init(x: 62, y: 48), shR:  .init(x: 98, y: 48),
        elL:  .init(x: 50, y: 62), elR:  .init(x: 108, y: 68),
        hnL:  .init(x: 40, y: 78), hnR:  .init(x: 120, y: 50),
        hipC: .init(x: 80, y: 102), hipL: .init(x: 72, y: 102), hipR: .init(x: 88, y: 102),
        knL:  .init(x: 68, y: 126), knR:  .init(x: 90, y: 130),
        ftL:  .init(x: 70, y: 154), ftR:  .init(x: 88, y: 162)
    )
}

// MARK: - Animated Stick Figure (Canvas)

struct AnimatedStickFigure: View {
    let animType: ExerciseAnimationType
    let muscleColor: Color
    let phase: CGFloat

    var body: some View {
        Canvas { ctx, size in
            let pair = posePair
            let p = pair.0.lerp(to: pair.1, t: phase).fit(to: size)
            let scale = min(size.width / 160, size.height / 190)
            let lw = 3.0 * scale
            let hr = 14.0 * scale
            let ls = StrokeStyle(lineWidth: lw, lineCap: .round, lineJoin: .round)
            let glowLS = StrokeStyle(lineWidth: lw * 4.5, lineCap: .round, lineJoin: .round)

            let white = Color.white.opacity(0.8)
            let ac    = muscleColor

            // Which segments glow with muscle colour
            let glowArm  = (animType == .benchPress || animType == .shoulderPress ||
                            animType == .curl       || animType == .tricepExtension ||
                            animType == .row        || animType == .pullUp)
            let glowLeg  = (animType == .squat  || animType == .lunge ||
                            animType == .legCurl || animType == .run)
            let glowCore = (animType == .plank || animType == .deadlift)

            let armC  = glowArm  ? ac : white
            let legC  = glowLeg  ? ac : white
            let coreC = glowCore ? ac : white

            // Helper — build a two-point path
            func seg(_ a: CGPoint, _ b: CGPoint) -> Path {
                var path = Path(); path.move(to: a); path.addLine(to: b); return path
            }

            // ── Equipment props ─────────────────────────────────────────────
            switch animType {
            case .pullUp:
                let barY = (p.hnL.y + p.hnR.y) / 2
                ctx.stroke(
                    seg(CGPoint(x: p.hnL.x - lw * 6, y: barY),
                        CGPoint(x: p.hnR.x + lw * 6, y: barY)),
                    with: .color(white.opacity(0.55)),
                    style: StrokeStyle(lineWidth: lw * 2.5, lineCap: .round)
                )
            case .benchPress, .squat, .deadlift:
                let barY = (p.hnL.y + p.hnR.y) / 2
                ctx.stroke(
                    seg(CGPoint(x: p.hnL.x - lw * 8, y: barY),
                        CGPoint(x: p.hnR.x + lw * 8, y: barY)),
                    with: .color(white.opacity(0.4)),
                    style: StrokeStyle(lineWidth: lw * 1.8, lineCap: .round)
                )
            default: break
            }

            // ── Glow pass (highlight active muscles) ────────────────────────
            if glowArm {
                ctx.stroke(seg(p.shL, p.elL), with: .color(ac.opacity(0.22)), style: glowLS)
                ctx.stroke(seg(p.elL, p.hnL), with: .color(ac.opacity(0.22)), style: glowLS)
                ctx.stroke(seg(p.shR, p.elR), with: .color(ac.opacity(0.22)), style: glowLS)
                ctx.stroke(seg(p.elR, p.hnR), with: .color(ac.opacity(0.22)), style: glowLS)
            }
            if glowLeg {
                ctx.stroke(seg(p.hipL, p.knL), with: .color(ac.opacity(0.22)), style: glowLS)
                ctx.stroke(seg(p.knL,  p.ftL), with: .color(ac.opacity(0.22)), style: glowLS)
                ctx.stroke(seg(p.hipR, p.knR), with: .color(ac.opacity(0.22)), style: glowLS)
                ctx.stroke(seg(p.knR,  p.ftR), with: .color(ac.opacity(0.22)), style: glowLS)
            }
            if glowCore {
                ctx.stroke(seg(p.neck, p.hipC), with: .color(ac.opacity(0.3)), style: glowLS)
            }

            // ── Skeleton ────────────────────────────────────────────────────

            // Head
            ctx.stroke(
                Path(ellipseIn: CGRect(x: p.head.x - hr, y: p.head.y - hr,
                                       width: hr * 2,   height: hr * 2)),
                with: .color(white), style: ls
            )
            // Neck
            ctx.stroke(seg(p.neck, p.head),  with: .color(white), style: ls)
            // Spine
            ctx.stroke(seg(p.neck, p.hipC),  with: .color(coreC), style: ls)
            // Shoulders
            ctx.stroke(seg(p.shL,  p.shR),   with: .color(white), style: ls)
            // Arms
            ctx.stroke(seg(p.shL,  p.elL),   with: .color(armC),  style: ls)
            ctx.stroke(seg(p.elL,  p.hnL),   with: .color(armC),  style: ls)
            ctx.stroke(seg(p.shR,  p.elR),   with: .color(armC),  style: ls)
            ctx.stroke(seg(p.elR,  p.hnR),   with: .color(armC),  style: ls)
            // Hips
            ctx.stroke(seg(p.hipL, p.hipR),  with: .color(white), style: ls)
            // Legs
            ctx.stroke(seg(p.hipL, p.knL),   with: .color(legC),  style: ls)
            ctx.stroke(seg(p.knL,  p.ftL),   with: .color(legC),  style: ls)
            ctx.stroke(seg(p.hipR, p.knR),   with: .color(legC),  style: ls)
            ctx.stroke(seg(p.knR,  p.ftR),   with: .color(legC),  style: ls)
        }
    }

    private var posePair: (Pose, Pose) {
        switch animType {
        case .benchPress:       return (Poses.chestOpen,   Poses.chestClose)
        case .shoulderPress:    return (Poses.pressStart,  Poses.pressTop)
        case .curl:             return (Poses.curlDown,    Poses.curlUp)
        case .tricepExtension:  return (Poses.triStart,    Poses.triTop)
        case .squat:            return (Poses.stand,       Poses.squat)
        case .deadlift:         return (Poses.deadStand,   Poses.deadHinge)
        case .row:              return (Poses.rowOut,      Poses.rowIn)
        case .pullUp:           return (Poses.hangDown,    Poses.hangTop)
        case .lunge:            return (Poses.stand,       Poses.lungeDown)
        case .legCurl:          return (Poses.stand,       Poses.legCurlTop)
        case .plank:            return (Poses.plank,       Poses.plank)
        case .run:              return (Poses.runA,        Poses.runB)
        case .generic:          return (Poses.curlDown,    Poses.curlUp)
        }
    }
}

// MARK: - Demo Card View

struct ExerciseDemoView: View {
    let exercise: Exercise
    @State private var phase: CGFloat = 0

    var body: some View {
        VStack(alignment: .leading, spacing: VoltSpacing.sm) {
            // Header row
            HStack(alignment: .center) {
                Text("How To Do It")
                    .font(VoltFont.display(13, weight: .semibold))
                    .foregroundStyle(VoltColor.labelSecondary)
                Spacer()
                HStack(spacing: 4) {
                    Circle()
                        .fill(VoltColor.accent)
                        .frame(width: 6, height: 6)
                    Text("Live Demo")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(VoltColor.accent)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(VoltColor.accentDim)
                .clipShape(Capsule())
            }

            // Animation card
            ZStack {
                RoundedRectangle(cornerRadius: VoltSpacing.radius)
                    .fill(VoltColor.surfaceHigh)
                    .overlay(
                        RoundedRectangle(cornerRadius: VoltSpacing.radius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        VoltColor.muscle(exercise.muscleGroup).opacity(0.35),
                                        VoltColor.border
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )

                VStack(spacing: 0) {
                    AnimatedStickFigure(
                        animType: exercise.animationType,
                        muscleColor: VoltColor.muscle(exercise.muscleGroup),
                        phase: phase
                    )
                    .frame(width: 160, height: 190)
                    .padding(.top, VoltSpacing.md)

                    Divider()
                        .background(VoltColor.border)
                        .padding(.horizontal, VoltSpacing.md)
                        .padding(.top, VoltSpacing.sm)

                    Text(exercise.movementCue)
                        .font(VoltFont.display(12, weight: .medium))
                        .foregroundStyle(VoltColor.labelSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, VoltSpacing.md)
                        .padding(.vertical, VoltSpacing.sm)
                }
            }
        }
        .onAppear {
            let duration: Double = exercise.animationType == .run ? 0.65 : 1.35
            withAnimation(.easeInOut(duration: duration).repeatForever(autoreverses: true)) {
                phase = 1
            }
        }
    }
}
