import Foundation
import SwiftData

@MainActor
enum PlanMapper {

    static func mapToPlan(
        from response: PlanResponse,
        for profile: UserProfile,
        context: ModelContext
    ) throws -> Plan {
        // Deactivate any existing active plans
        let descriptor = FetchDescriptor<Plan>(predicate: #Predicate { $0.isActive })
        let activePlans = try context.fetch(descriptor)
        for plan in activePlans {
            plan.isActive = false
        }

        // Store raw JSON
        let rawJSON: String
        if let data = try? JSONEncoder().encode(response) {
            rawJSON = String(data: data, encoding: .utf8) ?? ""
        } else {
            rawJSON = ""
        }

        // Create Plan
        let exerciseData = response.exercisePlan
        let now = Date()
        let endDate = Calendar.current.date(
            byAdding: .weekOfYear,
            value: exerciseData.weekCount,
            to: now
        ) ?? now

        let plan = Plan(
            startDate: now,
            endDate: endDate,
            difficulty: exerciseData.difficulty,
            weekCount: exerciseData.weekCount,
            isActive: true,
            rawJSON: rawJSON
        )
        context.insert(plan)
        plan.userProfile = profile

        // Create WorkoutDays and Exercises
        for (dayIndex, dayData) in exerciseData.workoutDays.enumerated() {
            let workoutDay = WorkoutDay(
                dayOfWeek: dayData.dayOfWeek,
                title: dayData.title,
                type: dayData.type,
                orderIndex: dayIndex,
                estimatedMinutes: dayData.estimatedMinutes
            )
            context.insert(workoutDay)
            workoutDay.plan = plan

            for (exIndex, exData) in dayData.exercises.enumerated() {
                let exercise = Exercise(
                    name: exData.name,
                    sets: exData.sets,
                    targetReps: exData.targetReps,
                    restSeconds: exData.restSeconds,
                    formCues: exData.formCues,
                    modelId: exData.modelId,
                    orderIndex: exIndex,
                    muscleGroups: exData.muscleGroups
                )
                context.insert(exercise)
                exercise.workoutDay = workoutDay
            }
        }

        // Create MealPlan and Meals
        let mealPlanData = response.mealPlan
        let mealPlan = MealPlan(
            dailyCalories: mealPlanData.dailyCalories,
            dailyProteinG: mealPlanData.dailyProteinG,
            dailyCarbsG: mealPlanData.dailyCarbsG,
            dailyFatG: mealPlanData.dailyFatG
        )
        context.insert(mealPlan)
        mealPlan.plan = plan

        for (mealIndex, mealItem) in mealPlanData.meals.enumerated() {
            let options = mealItem.options.map { opt in
                MealOption(
                    title: opt.title,
                    ingredients: opt.ingredients,
                    calories: opt.calories,
                    proteinG: opt.proteinG,
                    carbsG: opt.carbsG,
                    fatG: opt.fatG,
                    preparationNotes: opt.preparationNotes
                )
            }

            let optionsJSON: String
            if let data = try? JSONEncoder().encode(options) {
                optionsJSON = String(data: data, encoding: .utf8) ?? "[]"
            } else {
                optionsJSON = "[]"
            }

            let meal = Meal(
                name: mealItem.name,
                timeSlot: mealItem.timeSlot,
                orderIndex: mealIndex,
                optionsJSON: optionsJSON
            )
            context.insert(meal)
            meal.mealPlan = mealPlan
        }

        try context.save()
        return plan
    }
}
