import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<Plan> { $0.isActive }) private var activePlans: [Plan]
    @State private var recoveryViewModel: OnboardingViewModel?

    var body: some View {
        if let profile = profiles.first {
            if activePlans.first != nil {
                MainTabView()
            } else {
                PlanGenerationView(
                    viewModel: recoveryViewModel(for: profile),
                    existingProfile: profile
                )
            }
        } else {
            OnboardingContainerView()
        }
    }

    private func recoveryViewModel(for profile: UserProfile) -> OnboardingViewModel {
        if let existing = recoveryViewModel {
            return existing
        }
        let vm = OnboardingViewModel()
        vm.name = profile.name
        vm.heightCm = profile.heightCm
        vm.weightKg = profile.weightKg
        vm.age = profile.age
        vm.biologicalSex = profile.biologicalSex
        vm.activityLevel = ActivityLevel(rawValue: profile.activityLevel) ?? .moderatelyActive
        vm.goal = GoalType(rawValue: profile.goal) ?? .recomposition
        vm.availableDays = profile.availableDaysPerWeek
        vm.sessionLength = profile.sessionLengthMinutes
        vm.dietaryRestrictions = Set(
            profile.dietaryRestrictions.compactMap { DietaryRestriction(rawValue: $0) }
        )
        recoveryViewModel = vm
        return vm
    }
}

// MARK: - Main Tab View

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

// MARK: - Previews

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
