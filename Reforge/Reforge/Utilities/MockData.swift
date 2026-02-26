import Foundation

#if DEBUG
enum MockData {
    static let planResponse = PlanResponse(
        exercisePlan: ExercisePlanData(
            weekCount: 4,
            difficulty: 2,
            workoutDays: [
                // Monday — Upper Push
                WorkoutDayData(
                    dayOfWeek: 1,
                    title: "Upper Push",
                    type: "upperPush",
                    estimatedMinutes: 30,
                    exercises: [
                        ExerciseData(
                            name: "Push-Ups",
                            sets: 4,
                            targetReps: "12-15",
                            restSeconds: 60,
                            formCues: "Keep core tight, elbows at 45 degrees, full range of motion",
                            muscleGroups: ["chest", "triceps", "anterior deltoids"]
                        ),
                        ExerciseData(
                            name: "Diamond Push-Ups",
                            sets: 3,
                            targetReps: "8-12",
                            restSeconds: 60,
                            formCues: "Hands form a diamond under chest, elbows stay close to body",
                            muscleGroups: ["triceps", "chest"]
                        ),
                        ExerciseData(
                            name: "Pike Push-Ups",
                            sets: 3,
                            targetReps: "8-10",
                            restSeconds: 90,
                            formCues: "Hips high, head between arms, lower crown of head toward floor",
                            muscleGroups: ["shoulders", "triceps"]
                        ),
                        ExerciseData(
                            name: "Tricep Dips (on chair)",
                            sets: 3,
                            targetReps: "10-12",
                            restSeconds: 60,
                            formCues: "Keep back close to the edge, lower until elbows at 90 degrees",
                            muscleGroups: ["triceps", "chest", "anterior deltoids"]
                        )
                    ]
                ),
                // Wednesday — Lower Body
                WorkoutDayData(
                    dayOfWeek: 3,
                    title: "Lower Body",
                    type: "lowerBody",
                    estimatedMinutes: 35,
                    exercises: [
                        ExerciseData(
                            name: "Bodyweight Squats",
                            sets: 4,
                            targetReps: "15-20",
                            restSeconds: 60,
                            formCues: "Chest up, knees track over toes, squat to parallel or below",
                            muscleGroups: ["quadriceps", "glutes", "hamstrings"]
                        ),
                        ExerciseData(
                            name: "Bulgarian Split Squats",
                            sets: 3,
                            targetReps: "10-12 each leg",
                            restSeconds: 60,
                            formCues: "Rear foot elevated on chair, front knee stays behind toes",
                            muscleGroups: ["quadriceps", "glutes"]
                        ),
                        ExerciseData(
                            name: "Glute Bridges",
                            sets: 3,
                            targetReps: "15-20",
                            restSeconds: 45,
                            formCues: "Drive through heels, squeeze glutes at top, pause 2 seconds",
                            muscleGroups: ["glutes", "hamstrings"]
                        ),
                        ExerciseData(
                            name: "Calf Raises",
                            sets: 3,
                            targetReps: "20-25",
                            restSeconds: 30,
                            formCues: "Full range of motion, pause at top, slow descent",
                            muscleGroups: ["calves"]
                        )
                    ]
                ),
                // Friday — Upper Pull & Core
                WorkoutDayData(
                    dayOfWeek: 5,
                    title: "Upper Pull & Core",
                    type: "upperPull",
                    estimatedMinutes: 30,
                    exercises: [
                        ExerciseData(
                            name: "Inverted Rows (under table)",
                            sets: 4,
                            targetReps: "8-12",
                            restSeconds: 60,
                            formCues: "Body straight like a plank, pull chest to edge of table",
                            muscleGroups: ["back", "biceps", "rear deltoids"]
                        ),
                        ExerciseData(
                            name: "Superman Holds",
                            sets: 3,
                            targetReps: "30s",
                            restSeconds: 45,
                            formCues: "Lift arms and legs simultaneously, squeeze lower back",
                            muscleGroups: ["lower back", "glutes"]
                        ),
                        ExerciseData(
                            name: "Plank",
                            sets: 3,
                            targetReps: "45s",
                            restSeconds: 45,
                            formCues: "Straight line from head to heels, engage core, don't sag hips",
                            muscleGroups: ["core", "shoulders"]
                        ),
                        ExerciseData(
                            name: "Dead Bug",
                            sets: 3,
                            targetReps: "10 each side",
                            restSeconds: 45,
                            formCues: "Press lower back into floor, extend opposite arm and leg slowly",
                            muscleGroups: ["core", "hip flexors"]
                        )
                    ]
                ),
                // Saturday — Full Body HIIT
                WorkoutDayData(
                    dayOfWeek: 6,
                    title: "Full Body HIIT",
                    type: "fullBodyHIIT",
                    estimatedMinutes: 25,
                    exercises: [
                        ExerciseData(
                            name: "Burpees",
                            sets: 4,
                            targetReps: "10",
                            restSeconds: 45,
                            formCues: "Chest to floor, explosive jump at top, land softly",
                            muscleGroups: ["full body"]
                        ),
                        ExerciseData(
                            name: "Mountain Climbers",
                            sets: 3,
                            targetReps: "30s",
                            restSeconds: 30,
                            formCues: "Hands under shoulders, drive knees quickly, keep hips level",
                            muscleGroups: ["core", "hip flexors", "shoulders"]
                        ),
                        ExerciseData(
                            name: "Jump Squats",
                            sets: 3,
                            targetReps: "12",
                            restSeconds: 45,
                            formCues: "Squat deep then explode up, land softly with bent knees",
                            muscleGroups: ["quadriceps", "glutes", "calves"]
                        ),
                        ExerciseData(
                            name: "High Knees",
                            sets: 3,
                            targetReps: "30s",
                            restSeconds: 30,
                            formCues: "Drive knees above hip height, pump arms, stay on balls of feet",
                            muscleGroups: ["hip flexors", "calves", "core"]
                        )
                    ]
                )
            ]
        ),
        mealPlan: MealPlanData(
            dailyCalories: 2200,
            dailyProteinG: 165,
            dailyCarbsG: 220,
            dailyFatG: 73,
            meals: [
                MealData(
                    name: "Breakfast",
                    timeSlot: "Breakfast",
                    options: [
                        MealOptionData(
                            title: "Greek Yogurt Power Bowl",
                            ingredients: ["Greek yogurt (200g)", "Mixed berries (100g)", "Granola (40g)", "Honey (1 tbsp)", "Chia seeds (1 tbsp)"],
                            calories: 480,
                            proteinG: 35,
                            carbsG: 55,
                            fatG: 14,
                            preparationNotes: "Layer yogurt, top with berries and granola. Drizzle honey and sprinkle chia seeds."
                        ),
                        MealOptionData(
                            title: "Scrambled Eggs & Toast",
                            ingredients: ["Eggs (3 large)", "Whole wheat toast (2 slices)", "Avocado (1/4)", "Spinach (handful)", "Cherry tomatoes (5)"],
                            calories: 500,
                            proteinG: 32,
                            carbsG: 38,
                            fatG: 24,
                            preparationNotes: "Scramble eggs with spinach. Serve on toast with sliced avocado and tomatoes."
                        )
                    ]
                ),
                MealData(
                    name: "Lunch",
                    timeSlot: "Lunch",
                    options: [
                        MealOptionData(
                            title: "Chicken & Quinoa Bowl",
                            ingredients: ["Grilled chicken breast (150g)", "Quinoa (100g cooked)", "Mixed greens", "Cherry tomatoes", "Cucumber", "Lemon tahini dressing"],
                            calories: 620,
                            proteinG: 48,
                            carbsG: 52,
                            fatG: 18,
                            preparationNotes: "Grill chicken, cook quinoa. Assemble bowl with greens, veggies, and dressing."
                        ),
                        MealOptionData(
                            title: "Turkey Wrap",
                            ingredients: ["Whole wheat wrap", "Turkey slices (120g)", "Hummus (2 tbsp)", "Mixed greens", "Bell pepper strips", "Feta cheese (30g)"],
                            calories: 580,
                            proteinG: 42,
                            carbsG: 48,
                            fatG: 20,
                            preparationNotes: "Spread hummus on wrap, layer turkey, greens, peppers, and feta. Roll tightly."
                        ),
                        MealOptionData(
                            title: "Tuna Salad",
                            ingredients: ["Canned tuna (1 can)", "Mixed greens", "Cannellini beans (80g)", "Red onion", "Olive oil (1 tbsp)", "Whole wheat bread (1 slice)"],
                            calories: 550,
                            proteinG: 45,
                            carbsG: 42,
                            fatG: 16,
                            preparationNotes: "Drain tuna, mix with beans, onion, and greens. Dress with olive oil. Serve with bread."
                        )
                    ]
                ),
                MealData(
                    name: "Dinner",
                    timeSlot: "Dinner",
                    options: [
                        MealOptionData(
                            title: "Salmon with Sweet Potato",
                            ingredients: ["Salmon fillet (150g)", "Sweet potato (200g)", "Steamed broccoli (150g)", "Olive oil (1 tsp)", "Lemon wedge"],
                            calories: 620,
                            proteinG: 42,
                            carbsG: 52,
                            fatG: 22,
                            preparationNotes: "Bake salmon at 200C for 15 min. Roast sweet potato cubes. Steam broccoli."
                        ),
                        MealOptionData(
                            title: "Lean Beef Stir-Fry",
                            ingredients: ["Lean beef strips (140g)", "Brown rice (100g cooked)", "Mixed stir-fry veggies", "Soy sauce (1 tbsp)", "Ginger", "Garlic"],
                            calories: 600,
                            proteinG: 40,
                            carbsG: 58,
                            fatG: 18,
                            preparationNotes: "Stir-fry beef with garlic and ginger. Add veggies. Serve over rice with soy sauce."
                        )
                    ]
                ),
                MealData(
                    name: "Snack",
                    timeSlot: "Snack",
                    options: [
                        MealOptionData(
                            title: "Protein Shake",
                            ingredients: ["Whey protein (1 scoop)", "Banana (1 medium)", "Almond milk (250ml)", "Peanut butter (1 tbsp)"],
                            calories: 380,
                            proteinG: 35,
                            carbsG: 32,
                            fatG: 12,
                            preparationNotes: "Blend all ingredients with ice until smooth."
                        ),
                        MealOptionData(
                            title: "Cottage Cheese & Fruit",
                            ingredients: ["Cottage cheese (150g)", "Pineapple chunks (80g)", "Almonds (15g)"],
                            calories: 280,
                            proteinG: 25,
                            carbsG: 18,
                            fatG: 10,
                            preparationNotes: "Top cottage cheese with pineapple and almonds."
                        ),
                        MealOptionData(
                            title: "Hard-Boiled Eggs & Veggies",
                            ingredients: ["Hard-boiled eggs (2)", "Carrot sticks", "Celery sticks", "Hummus (2 tbsp)"],
                            calories: 300,
                            proteinG: 20,
                            carbsG: 15,
                            fatG: 16,
                            preparationNotes: "Boil eggs for 10 min. Serve with veggie sticks and hummus."
                        )
                    ]
                )
            ]
        ),
        metadata: PlanMetadata(
            estimatedWeeklyMinutes: 120,
            focusAreas: ["Upper body strength", "Lower body power", "Core stability", "Cardiovascular fitness"],
            notes: "This 4-week bodyweight plan balances push, pull, lower body, and HIIT sessions across 4 training days. Progressive overload is achieved by increasing reps and hold times each week. Rest days (Tue, Thu, Sun) allow adequate recovery."
        )
    )
}
#endif
