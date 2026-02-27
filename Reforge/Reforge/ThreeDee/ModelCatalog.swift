import Foundation

struct ModelInfo {
    let filename: String
    let displayName: String
    let muscleGroups: [String]
    let animationDuration: TimeInterval
}

enum ModelCatalog {

    static let models: [String: ModelInfo] = [
        "pushup": ModelInfo(
            filename: "pushup", displayName: "Push-Up",
            muscleGroups: ["chest", "triceps", "anterior deltoids"], animationDuration: 2.0
        ),
        "diamond_pushup": ModelInfo(
            filename: "diamond_pushup", displayName: "Diamond Push-Up",
            muscleGroups: ["triceps", "chest"], animationDuration: 2.0
        ),
        "pike_pushup": ModelInfo(
            filename: "pike_pushup", displayName: "Pike Push-Up",
            muscleGroups: ["shoulders", "triceps"], animationDuration: 2.5
        ),
        "tricep_dip": ModelInfo(
            filename: "tricep_dip", displayName: "Tricep Dip",
            muscleGroups: ["triceps", "chest", "anterior deltoids"], animationDuration: 2.0
        ),
        "squat": ModelInfo(
            filename: "squat", displayName: "Squat",
            muscleGroups: ["quadriceps", "glutes", "hamstrings"], animationDuration: 2.5
        ),
        "split_squat": ModelInfo(
            filename: "split_squat", displayName: "Split Squat",
            muscleGroups: ["quadriceps", "glutes"], animationDuration: 2.5
        ),
        "glute_bridge": ModelInfo(
            filename: "glute_bridge", displayName: "Glute Bridge",
            muscleGroups: ["glutes", "hamstrings"], animationDuration: 2.0
        ),
        "calf_raise": ModelInfo(
            filename: "calf_raise", displayName: "Calf Raise",
            muscleGroups: ["calves"], animationDuration: 1.5
        ),
        "inverted_row": ModelInfo(
            filename: "inverted_row", displayName: "Inverted Row",
            muscleGroups: ["back", "biceps", "rear deltoids"], animationDuration: 2.0
        ),
        "superman": ModelInfo(
            filename: "superman", displayName: "Superman",
            muscleGroups: ["lower back", "glutes"], animationDuration: 3.0
        ),
        "plank": ModelInfo(
            filename: "plank", displayName: "Plank",
            muscleGroups: ["core", "shoulders"], animationDuration: 1.0
        ),
        "dead_bug": ModelInfo(
            filename: "dead_bug", displayName: "Dead Bug",
            muscleGroups: ["core", "hip flexors"], animationDuration: 3.0
        ),
        "burpee": ModelInfo(
            filename: "burpee", displayName: "Burpee",
            muscleGroups: ["full body"], animationDuration: 2.0
        ),
        "mountain_climber": ModelInfo(
            filename: "mountain_climber", displayName: "Mountain Climber",
            muscleGroups: ["core", "hip flexors", "shoulders"], animationDuration: 1.0
        ),
        "jump_squat": ModelInfo(
            filename: "jump_squat", displayName: "Jump Squat",
            muscleGroups: ["quadriceps", "glutes", "calves"], animationDuration: 2.0
        ),
        "high_knees": ModelInfo(
            filename: "high_knees", displayName: "High Knees",
            muscleGroups: ["hip flexors", "calves", "core"], animationDuration: 1.0
        ),
    ]

    static func url(for modelId: String) -> URL? {
        guard let info = models[modelId] else { return nil }
        return Bundle.main.url(forResource: info.filename, withExtension: "usdz")
    }

    static func hasModel(_ modelId: String) -> Bool {
        url(for: modelId) != nil
    }
}
