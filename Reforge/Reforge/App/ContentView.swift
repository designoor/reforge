import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if profiles.first != nil {
            MainTabView()
        } else {
            OnboardingContainerView()
        }
    }
}

// Placeholder — built out in Step 1.5
struct MainTabView: View {
    var body: some View {
        TabView {
            Text("Dashboard")
                .tabItem { Label("Home", systemImage: "house.fill") }
            Text("Nutrition")
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }
            Text("Progress")
                .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            Text("Settings")
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }
}

#Preview("Onboarding") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, Plan.self, WorkoutDay.self, Exercise.self,
        MealPlan.self, Meal.self, WorkoutSession.self, SetLog.self,
        WeightEntry.self, MeasurementEntry.self, StreakRecord.self,
        configurations: config
    )

    ContentView()
        .modelContainer(container)
}

#Preview("Main App") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(
        for: UserProfile.self, Plan.self, WorkoutDay.self, Exercise.self,
        MealPlan.self, Meal.self, WorkoutSession.self, SetLog.self,
        WeightEntry.self, MeasurementEntry.self, StreakRecord.self,
        configurations: config
    )

    let sampleProfile = UserProfile(
        name: "Test User",
        heightCm: 180.0,
        weightKg: 80.0,
        age: 28,
        biologicalSex: "male",
        activityLevel: ActivityLevel.moderatelyActive.rawValue,
        goal: GoalType.recomposition.rawValue,
        dietaryRestrictions: [DietaryRestriction.none.rawValue],
        availableDaysPerWeek: 5,
        sessionLengthMinutes: 30
    )
    container.mainContext.insert(sampleProfile)

    return ContentView()
        .modelContainer(container)
}
