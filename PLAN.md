# REFORGE — Implementation Plan

> AI-Powered Body Recomposition iOS App
> Native Swift/SwiftUI · Claude API · SceneKit 3D Models
> Refer to `reforge-concept.docx` for full product context.

---

## Architecture Overview

```
ReforgeApp/
├── App/
│   ├── ReforgeApp.swift              # @main entry, WindowGroup, SwiftData container setup
│   └── ContentView.swift             # Root view — routes between Onboarding and MainTabView
├── Models/
│   ├── UserProfile.swift
│   ├── Plan.swift
│   ├── WorkoutDay.swift
│   ├── Exercise.swift
│   ├── MealPlan.swift
│   ├── Meal.swift
│   ├── WorkoutSession.swift
│   ├── SetLog.swift
│   ├── WeightEntry.swift
│   ├── MeasurementEntry.swift
│   └── StreakRecord.swift
├── ViewModels/
│   ├── OnboardingViewModel.swift
│   ├── DashboardViewModel.swift
│   ├── WorkoutSessionViewModel.swift
│   ├── MealPlanViewModel.swift
│   ├── ProgressViewModel.swift
│   └── AdaptationViewModel.swift
├── Views/
│   ├── Onboarding/
│   ├── Dashboard/
│   ├── Workout/
│   ├── Nutrition/
│   ├── Progress/
│   ├── Settings/
│   └── Components/
├── Services/
│   ├── ClaudeAPIService.swift
│   ├── NotificationService.swift
│   ├── StreakService.swift
│   └── AdaptationEngine.swift
├── ThreeDee/
│   ├── ExerciseModelView.swift
│   ├── ModelCatalog.swift
│   └── Models/                       # .usdz files
├── Resources/
│   ├── Assets.xcassets
│   └── Fonts/
└── Utilities/
    ├── Extensions/
    ├── Constants.swift
    └── JSONSchemas.swift
```

---

## Phase 1 — Foundation (Weeks 1–4)

### Step 1.1: Project Setup & Configuration

**Goal:** Empty Xcode project that builds and runs on simulator.

- [ ] Create new Xcode project: iOS App, SwiftUI, Swift, bundle ID `com.reforge.app`
- [ ] Set minimum deployment target: iOS 17.0
- [ ] Set up folder structure matching architecture above
- [ ] Create `Constants.swift` with:
  - `enum AppConstants` — static let `claudeAPIBaseURL = "https://api.anthropic.com/v1/messages"`, `claudeModel = "claude-sonnet-4-20250514"`, `maxTokens = 4096`
  - `enum ExerciseType: String, Codable, CaseIterable` — cases: `upperPush, upperPull, lowerBody, core, cardio, fullBodyHIIT, warmup, cooldown`
  - `enum GoalType: String, Codable, CaseIterable` — cases: `loseFat, buildMuscle, recomposition`
  - `enum ActivityLevel: String, Codable, CaseIterable` — cases: `sedentary, lightlyActive, moderatelyActive, active`
  - `enum DietaryRestriction: String, Codable, CaseIterable` — cases: `none, vegetarian, vegan, glutenFree, dairyFree, lowCarb`
  - `enum DifficultyLevel: Int, Codable` — cases: `beginner = 1, intermediate = 2, advanced = 3, elite = 4`
- [ ] Add a placeholder `ContentView` that displays "Reforge" text — confirm it runs on simulator

### Step 1.2: SwiftData Models

**Goal:** All data models defined and persisting locally. Testable via Xcode previews.

**`UserProfile.swift`**
- `@Model class UserProfile`
- Properties: `id: UUID`, `name: String`, `heightCm: Double`, `weightKg: Double`, `age: Int`, `biologicalSex: String`, `activityLevel: String` (raw value of ActivityLevel), `goal: String` (raw value of GoalType), `dietaryRestrictions: [String]`, `availableDaysPerWeek: Int`, `sessionLengthMinutes: Int`, `createdAt: Date`, `updatedAt: Date`
- Relationship: `activePlan: Plan?` (optional, inverse)
- Computed property: `bmi: Double` — weightKg / (heightCm/100)^2

**`Plan.swift`**
- `@Model class Plan`
- Properties: `id: UUID`, `startDate: Date`, `endDate: Date`, `difficulty: Int` (raw value of DifficultyLevel), `weekCount: Int`, `isActive: Bool`, `rawJSON: String` (stores the full Claude response for reference), `createdAt: Date`
- Relationships: `workoutDays: [WorkoutDay]`, `mealPlan: MealPlan?`, `userProfile: UserProfile?`

**`WorkoutDay.swift`**
- `@Model class WorkoutDay`
- Properties: `id: UUID`, `dayOfWeek: Int` (1=Monday, 7=Sunday), `title: String`, `type: String` (raw value of ExerciseType), `orderIndex: Int`, `estimatedMinutes: Int`
- Relationships: `exercises: [Exercise]`, `plan: Plan?`

**`Exercise.swift`**
- `@Model class Exercise`
- Properties: `id: UUID`, `name: String`, `sets: Int`, `targetReps: String` (string to support "30s" or "10 each"), `restSeconds: Int`, `formCues: String`, `modelId: String` (maps to 3D model filename), `orderIndex: Int`, `muscleGroups: [String]`
- Relationship: `workoutDay: WorkoutDay?`

**`MealPlan.swift`**
- `@Model class MealPlan`
- Properties: `id: UUID`, `dailyCalories: Int`, `dailyProteinG: Int`, `dailyCarbsG: Int`, `dailyFatG: Int`
- Relationships: `meals: [Meal]`, `plan: Plan?`

**`Meal.swift`**
- `@Model class Meal`
- Properties: `id: UUID`, `name: String` (e.g. "Breakfast"), `timeSlot: String` (e.g. "7:00 AM"), `orderIndex: Int`, `optionsJSON: String` (JSON array of MealOption structs — see below)
- Relationship: `mealPlan: MealPlan?`
- Helper struct (not @Model, just Codable): `MealOption` — `title: String`, `ingredients: [String]`, `calories: Int`, `proteinG: Int`, `carbsG: Int`, `fatG: Int`, `preparationNotes: String`

**`WorkoutSession.swift`**
- `@Model class WorkoutSession`
- Properties: `id: UUID`, `date: Date`, `workoutDayId: UUID` (reference to which WorkoutDay), `durationSeconds: Int`, `completed: Bool`, `difficultyRating: Int?` (1–5, optional post-workout), `notes: String?`
- Relationship: `setLogs: [SetLog]`

**`SetLog.swift`**
- `@Model class SetLog`
- Properties: `id: UUID`, `exerciseName: String`, `exerciseId: UUID`, `setNumber: Int`, `targetReps: String`, `actualReps: Int`, `completedAt: Date`
- Relationship: `workoutSession: WorkoutSession?`

**`WeightEntry.swift`**
- `@Model class WeightEntry`
- Properties: `id: UUID`, `date: Date`, `weightKg: Double`, `notes: String?`

**`MeasurementEntry.swift`**
- `@Model class MeasurementEntry`
- Properties: `id: UUID`, `date: Date`, `waistCm: Double?`, `chestCm: Double?`, `leftArmCm: Double?`, `rightArmCm: Double?`, `leftThighCm: Double?`, `rightThighCm: Double?`

**`StreakRecord.swift`**
- `@Model class StreakRecord`
- Properties: `id: UUID`, `currentStreak: Int`, `longestStreak: Int`, `lastWorkoutDate: Date?`, `freezesAvailable: Int`, `graceUsedThisWeek: Bool`

**Setup in `ReforgeApp.swift`:**
- Create a `ModelContainer` with all model types
- Inject into environment via `.modelContainer(container)`

**Test:** Write a SwiftUI preview that creates a sample `UserProfile`, saves it, fetches it, displays the name. Confirm data persists between simulator launches.

---

### Step 1.3: Onboarding Flow

**Goal:** 5-screen onboarding that collects all user data and stores it in SwiftData.

**`OnboardingViewModel.swift`**
- `@Observable class OnboardingViewModel`
- Published properties (bound to form fields):
  - `name: String = ""`
  - `heightCm: Double = 175.0`
  - `weightKg: Double = 80.0`
  - `age: Int = 30`
  - `biologicalSex: String = "male"`
  - `activityLevel: ActivityLevel = .sedentary`
  - `goal: GoalType = .recomposition`
  - `dietaryRestrictions: Set<DietaryRestriction> = [.none]`
  - `availableDays: Int = 5`
  - `sessionLength: Int = 30`
  - `currentStep: Int = 0` (0–4)
- Computed: `canProceed: Bool` — validates current step's required fields are filled
- Method: `func saveProfile(context: ModelContext) -> UserProfile` — creates and inserts UserProfile, returns it
- Method: `func toPromptPayload() -> OnboardingPayload` — packages all data into a Codable struct for the API call

**`OnboardingPayload` (Codable struct in `JSONSchemas.swift`):**
```
struct OnboardingPayload: Codable {
    let name: String
    let heightCm: Double
    let weightKg: Double
    let age: Int
    let biologicalSex: String
    let activityLevel: String
    let goal: String
    let dietaryRestrictions: [String]
    let availableDaysPerWeek: Int
    let sessionLengthMinutes: Int
}
```

**Screens (in `Views/Onboarding/`):**

1. **`WelcomeView.swift`** — App logo, tagline "Your plan evolves with you", subtitle explaining the value prop, "Get Started" button. No data collection.

2. **`BodyStatsView.swift`** — Sliders or steppers for: height (140–220 cm), weight (40–200 kg), age (16–80). Segmented picker for biological sex (Male / Female). Show computed BMI live.

3. **`GoalsView.swift`** — Three tappable cards for goal selection (loseFat, buildMuscle, recomposition). Each card has an icon, title, and one-line description. Optional target weight field (number input).

4. **`LifestyleView.swift`** — Activity level picker (4 options as tappable cards). Days per week stepper (3–6). Session length segmented control (20, 30, 45 min). Dietary restrictions multi-select (toggleable chips).

5. **`PlanGenerationView.swift`** — Shows a loading animation with "Building your plan..." text. Triggers `ClaudeAPIService.generatePlan()`. On success, navigates to `MainTabView`. On failure, shows retry button with error message.

**`OnboardingContainerView.swift`:**
- Wraps all 5 steps in a `TabView` with `.tabViewStyle(.page)` for swipe navigation
- "Next" / "Back" buttons at bottom
- Progress dots at top
- Injects `OnboardingViewModel` as `@State`

**`ContentView.swift` routing logic:**
- Query SwiftData for existing `UserProfile`
- If none exists → show `OnboardingContainerView`
- If profile exists but no active plan → show `PlanGenerationView`
- If profile + active plan exist → show `MainTabView`

**Test:** Complete the full onboarding flow on simulator. Verify the `UserProfile` persists. Kill and relaunch the app — should skip onboarding and go to main view.

---

### Step 1.4: Claude API Service

**Goal:** Working API integration that sends onboarding data and receives a structured plan.

**`ClaudeAPIService.swift`**
- `actor ClaudeAPIService` (actor for thread safety)
- Property: `private let apiKey: String` (loaded from environment or config)
- Property: `private let session = URLSession.shared`

**Method: `func generatePlan(from payload: OnboardingPayload) async throws -> PlanResponse`**
- Builds the HTTP request:
  - URL: `AppConstants.claudeAPIBaseURL`
  - Method: POST
  - Headers: `x-api-key`, `anthropic-version: 2023-06-01`, `content-type: application/json`
  - Body: `{ model, max_tokens, system, messages }`
- System prompt (stored in `Constants.swift` or a separate `Prompts.swift`):
  ```
  You are an expert certified personal trainer and nutritionist.
  Generate a personalised 4-week bodyweight exercise plan and daily meal plan.
  Respond with ONLY valid JSON matching the schema below. No markdown, no preamble.
  [full PlanResponseSchema as JSON Schema]
  ```
- User message: `"Generate a plan for this user: \(payload as JSON string)"`
- Parses response: extracts `content[0].text`, decodes as `PlanResponse`
- Error handling: throws typed errors — `APIError.invalidResponse`, `.decodingFailed`, `.rateLimited`, `.serverError(statusCode)`

**Method: `func adaptPlan(currentPlan: PlanResponse, performance: PerformanceLog, profile: OnboardingPayload) async throws -> PlanAdaptationResponse`**
- Similar structure, different prompt (see Phase 3 for full detail)
- Returns only the diff/changes, not a full plan

**Method: `func generateWeeklyRecap(performance: WeeklyPerformanceSummary) async throws -> String`**
- Returns a 2–3 sentence personalised commentary string

**Method: `func swapMeal(currentMeal: MealOption, constraints: MealConstraints) async throws -> MealOption`**
- Returns a single replacement meal option with similar macros

**`PlanResponse` (Codable struct in `JSONSchemas.swift`):**
```
struct PlanResponse: Codable {
    let exercisePlan: ExercisePlanData
    let mealPlan: MealPlanData
    let metadata: PlanMetadata
}

struct ExercisePlanData: Codable {
    let days: [WorkoutDayData]
}

struct WorkoutDayData: Codable {
    let dayOfWeek: Int
    let title: String
    let type: String
    let estimatedMinutes: Int
    let exercises: [ExerciseData]
}

struct ExerciseData: Codable {
    let name: String
    let sets: Int
    let targetReps: String
    let restSeconds: Int
    let formCues: String
    let modelId: String
    let muscleGroups: [String]
}

struct MealPlanData: Codable {
    let dailyCalories: Int
    let dailyProteinG: Int
    let dailyCarbsG: Int
    let dailyFatG: Int
    let meals: [MealData]
}

struct MealData: Codable {
    let name: String
    let timeSlot: String
    let options: [MealOptionData]
}

struct MealOptionData: Codable {
    let title: String
    let ingredients: [String]
    let calories: Int
    let proteinG: Int
    let carbsG: Int
    let fatG: Int
    let preparationNotes: String
}

struct PlanMetadata: Codable {
    let difficulty: Int
    let weeklyProgressionNotes: String
}
```

**`PlanMapper.swift` (in `Utilities/`):**
- `static func mapToPlan(from response: PlanResponse, for profile: UserProfile, context: ModelContext) -> Plan`
- Creates all SwiftData model objects from the API response
- Links relationships (Plan → WorkoutDays → Exercises, Plan → MealPlan → Meals)
- Sets `plan.isActive = true`, deactivates any previous active plan
- Inserts into `ModelContext`

**API Key Storage:**
- For development: store in a `.xcconfig` file excluded from git via `.gitignore`
- For production: store in Keychain via a small `KeychainService` helper
- Never hardcode the key in source files

**Test:** Call `generatePlan()` with sample onboarding data. Print the raw JSON response. Verify it decodes into `PlanResponse`. Verify `PlanMapper` creates correct SwiftData objects. Display the plan title on the dashboard.

---

### Step 1.5: Dashboard (Basic)

**Goal:** Main tab view with a functional dashboard showing today's workout.

**`MainTabView.swift`**
- `TabView` with 4 tabs: Dashboard, Nutrition, Progress, Settings
- Each tab has an icon (SF Symbols: `house.fill`, `fork.knife`, `chart.line.uptrend.xyaxis`, `gearshape.fill`)
- Uses `@Environment(\.modelContext)` for data access

**`DashboardViewModel.swift`**
- `@Observable class DashboardViewModel`
- Properties:
  - `todaysWorkout: WorkoutDay?` — fetched based on current day of week
  - `streak: StreakRecord?`
  - `userName: String`
  - `dayNumber: Int` — days since plan start
  - `weeklyCompletion: [Bool]` — array of 5 booleans for Mon–Fri completion status
  - `isLevelUpAvailable: Bool` — from AdaptationEngine (Phase 3, stub as false for now)
- Method: `func loadDashboard(context: ModelContext)` — queries SwiftData for active plan, today's workout day, streak record
- Method: `func todayDayOfWeek() -> Int` — returns 1–7 based on Calendar

**`DashboardView.swift`**
- Greeting section: "Good morning, [name]. Day [N]." with streak flame if streak ≥ 1
- Today's Workout Card: large card with workout title, type icon, exercise count, estimated duration. `NavigationLink` to `WorkoutSessionView`
- Weekly Progress Dots: 5 circles (filled = completed, outlined = not done, pulsing = today)
- Streak Banner: conditional, shows if streak ≥ 3 with flame icon and count
- Level-Up Banner: conditional placeholder (hidden for now, enabled in Phase 3)

**Test:** Launch app after completing onboarding. Dashboard shows today's workout correctly based on day of week. Tapping the workout card navigates (even if destination is placeholder).

---

### Step 1.6: Workout Session (Basic — No 3D)

**Goal:** Complete a workout, log reps per set, see a summary. No 3D models yet.

**`WorkoutSessionViewModel.swift`**
- `@Observable class WorkoutSessionViewModel`
- Properties:
  - `workoutDay: WorkoutDay`
  - `exercises: [Exercise]` — sorted by orderIndex
  - `currentExerciseIndex: Int = 0`
  - `currentSetNumber: Int = 1`
  - `isResting: Bool = false`
  - `restTimeRemaining: Int = 0`
  - `sessionStartTime: Date?`
  - `setLogs: [SetLog] = []`
  - `isComplete: Bool = false`
- Computed:
  - `currentExercise: Exercise?`
  - `progress: Double` — fraction of total sets completed
  - `totalSets: Int` — sum of all exercises' set counts
  - `completedSets: Int`
- Methods:
  - `func startSession()` — records sessionStartTime
  - `func logSet(actualReps: Int, context: ModelContext)` — creates SetLog, advances currentSetNumber or moves to next exercise. If last set of last exercise, triggers `completeSession()`
  - `func startRestTimer()` — sets isResting=true, counts down restSeconds using a Timer
  - `func skipRest()` — cancels timer, sets isResting=false
  - `func completeSession(context: ModelContext)` — creates WorkoutSession record, updates StreakRecord, sets isComplete=true
  - `func sessionSummary() -> SessionSummary` — total duration, exercises completed, total reps, any personal bests

**`SessionSummary` struct:**
- `duration: TimeInterval`, `exercisesCompleted: Int`, `totalReps: Int`, `personalBests: [String]` (e.g. "New best: 18 push-ups")

**Screens:**

**`WorkoutSessionView.swift`** — Full-screen workout experience:
- Top bar: exercise name, "Set X of Y", overall progress bar
- Center: placeholder for 3D model (Phase 2) — for now, show exercise name in large text + formCues below
- Rep input: a number stepper or quick-tap buttons (–1, target, +1) to input actual reps
- "Done" button → logs set → if more sets, starts rest timer. If last set, moves to next exercise
- Rest timer overlay: countdown circle, "Skip" button
- "End Workout" button (top right) with confirmation dialog

**`WorkoutSummaryView.swift`** — Shown after session completes:
- Duration, exercises done, total reps
- Personal bests highlighted
- Difficulty rating: 5 tappable icons (1=too easy, 5=brutal)
- "Done" button → navigates back to dashboard

**Streak Update Logic (in `StreakService.swift`):**
- `static func updateStreak(context: ModelContext)`
- Fetch or create `StreakRecord`
- If `lastWorkoutDate` is today → no change (already worked out today)
- If `lastWorkoutDate` is yesterday or today → increment currentStreak
- If `lastWorkoutDate` is 2 days ago and `graceUsedThisWeek == false` → mark grace used, keep streak
- Else → reset currentStreak to 1
- Update `longestStreak` if currentStreak exceeds it
- Set `lastWorkoutDate` to today
- Reset `graceUsedThisWeek` on Mondays

**Test:** Start a workout session. Log reps for every set of every exercise. Rest timer counts down between sets. Summary screen shows correct totals. Streak increments. Repeat next day — streak is 2. Skip a day — grace day applies. Skip two days — streak resets.

---

## Phase 2 — 3D Models & Nutrition (Weeks 5–8)

### Step 2.1: 3D Model System

**Goal:** SceneKit renders animated USDZ models in the workout session screen.

**`ModelCatalog.swift`**
- `enum ModelCatalog` with static properties
- `static let models: [String: ModelInfo]` — dictionary mapping `modelId` to model metadata
- `ModelInfo` struct: `filename: String`, `displayName: String`, `muscleGroups: [String]`, `animationDuration: Double`
- `static func url(for modelId: String) -> URL?` — returns Bundle URL for the .usdz file
- Start with 5 placeholder models (basic geometric shapes animating) to prove the pipeline, then replace with real models

**`ExerciseModelView.swift`** — SwiftUI wrapper for SceneKit:
- `struct ExerciseModelView: UIViewRepresentable`
- Creates `SCNView` with `SCNScene` loaded from .usdz file
- Properties: `modelId: String`, `isPlaying: Bool`, `allowsRotation: Bool = true`
- Configuration:
  - `scnView.allowsCameraControl = true` (enables touch rotation/zoom)
  - `scnView.autoenablesDefaultLighting = true`
  - `scnView.backgroundColor = UIColor(named: "ModelBackground")` — dark
  - Set camera to a good default angle
- Animation control: `scnView.scene?.rootNode.animationPlayer(forKey:)` — play/pause based on `isPlaying`
- Muscle highlight: find child nodes by name matching muscleGroup, apply emissive material with accent colour

**Integration in `WorkoutSessionView.swift`:**
- Replace the placeholder text with `ExerciseModelView(modelId: currentExercise.modelId, isPlaying: !isResting)`
- Model pauses during rest, resumes during active set
- Size: roughly 60% of screen height

**3D Model Production (External to Xcode — Blender workflow documented separately):**
- Base humanoid mesh with armature (skeleton) rig
- One .blend file per exercise animation
- Export as .usdz via Blender or Apple's Reality Converter
- File naming convention: `exercise_pushup_standard.usdz`, `exercise_squat_bodyweight.usdz`, etc.
- Place all .usdz files in `ThreeDee/Models/` and add to Xcode target

**Test:** Workout session shows an animated 3D model for each exercise. Model rotates on touch. Animation loops during active set, pauses during rest.

---

### Step 2.2: Meal Plan Screen

**Goal:** Full meal plan UI with daily view, quick-log, and nutrition tracking.

**`MealPlanViewModel.swift`**
- `@Observable class MealPlanViewModel`
- Properties:
  - `meals: [Meal]` — today's meals sorted by orderIndex
  - `loggedMeals: Set<UUID>` — IDs of meals marked as eaten today
  - `dailyCaloriesConsumed: Int`
  - `dailyProteinConsumed: Int`
  - `dailyCarbsConsumed: Int`
  - `dailyFatConsumed: Int`
  - `dailyTargets: (cal: Int, protein: Int, carbs: Int, fat: Int)`
- Methods:
  - `func loadMeals(context: ModelContext)` — fetches active plan's meal plan
  - `func logMeal(meal: Meal, optionIndex: Int, context: ModelContext)` — adds macros from the selected option to daily totals, adds to loggedMeals set, persists a `MealLogEntry` (simple model: date, mealId, optionIndex, macros)
  - `func unlogMeal(meal: Meal, context: ModelContext)` — reverses a log
  - `func requestSwap(meal: Meal, optionIndex: Int) async throws -> MealOptionData` — calls `ClaudeAPIService.swapMeal()`

**Additional Model: `MealLogEntry.swift`**
- `@Model class MealLogEntry`
- Properties: `id: UUID`, `date: Date`, `mealId: UUID`, `optionIndex: Int`, `calories: Int`, `proteinG: Int`, `carbsG: Int`, `fatG: Int`

**Screens:**

**`MealPlanView.swift`** — Daily meal list:
- Date header with left/right arrows to browse days
- Vertical scroll of `MealCard` views
- Bottom summary bar: consumed / target for calories and protein

**`MealCard.swift`** — Individual meal:
- Collapsed: meal name, time, calorie range, checkmark if logged
- Expanded (tap to toggle): list of 2–3 options, each showing title, ingredients, macros
- "Log this" button on each option
- "Swap" button on each option → loading state → shows new option from Claude

**`ShoppingListView.swift`** — Accessible from a toolbar button:
- Aggregates all ingredients from the active meal plan
- Groups by category (protein, carbs, vegetables, etc.)
- Checkable items for shopping

**`NutritionRingView.swift`** — Reusable circular progress component:
- Parameters: `consumed: Int`, `target: Int`, `color: Color`, `label: String`
- Draws an arc from 0 to consumed/target ratio
- Displays number in center
- Used on Dashboard and MealPlanView

**Test:** Meal plan shows all meals for the day. Tap to expand shows options with macros. Log a meal — nutrition ring updates. Dashboard ring reflects logged meals. Swap a meal — Claude returns a new option.

---

### Step 2.3: Weight & Measurement Logging

**Goal:** Users can log weight and body measurements. Data persists and is queryable for charts.

**`WeightLogView.swift`**
- Prompted weekly (configurable day) via notification
- Input: weight (decimal stepper or number field), optional notes
- Shows last 5 entries in a mini list below the input
- Save button creates `WeightEntry` in SwiftData

**`MeasurementLogView.swift`**
- Prompted biweekly
- Inputs: waist, chest, left arm, right arm, left thigh, right thigh (all optional, in cm)
- Visual body diagram with tappable measurement points (nice to have)
- Save button creates `MeasurementEntry`

**Integration:**
- Add a "Log Weight" quick action button on the Dashboard
- Add measurement logging in Progress tab

**Test:** Log 5 weight entries across different dates. Log 2 measurement entries. Verify all data persists and can be fetched sorted by date.

---

### Step 2.4: Progress Charts

**Goal:** Swift Charts visualisations for weight trend, workout consistency, and strength.

**`ProgressViewModel.swift`**
- `@Observable class ProgressViewModel`
- Properties:
  - `weightEntries: [WeightEntry]`
  - `measurementEntries: [MeasurementEntry]`
  - `workoutSessions: [WorkoutSession]`
  - `selectedTimeRange: TimeRange = .month` (enum: `.week, .month, .threeMonths, .all`)
- Methods:
  - `func loadAll(context: ModelContext)`
  - `func weightTrendData() -> [(date: Date, weight: Double, movingAvg: Double)]` — raw values + 7-day moving average
  - `func workoutConsistencyData() -> [(date: Date, completed: Bool)]` — for heatmap
  - `func strengthProgressionData(exerciseName: String) -> [(date: Date, totalReps: Int)]` — sum of actualReps per session for a given exercise
  - `func weeklyVolume() -> [(weekStart: Date, totalSets: Int, totalReps: Int)]`

**Screens:**

**`ProgressView.swift`** — Tab with segmented control:
- Segment 1: Weight — `WeightChartView`
- Segment 2: Workouts — `WorkoutConsistencyView`
- Segment 3: Strength — `StrengthChartView`
- Segment 4: Body — `MeasurementsView`

**`WeightChartView.swift`**
- Swift Charts `Chart` with:
  - `LineMark` for raw weight (light, thin)
  - `LineMark` for 7-day moving average (bold, accent colour)
  - `RuleMark` for target weight (dashed horizontal)
- Time range picker at top
- Shows delta from start: "–2.3 kg from start"

**`WorkoutConsistencyView.swift`**
- Grid of small squares (GitHub-style heatmap), 7 columns (days) × N rows (weeks)
- Green = completed, gray = missed, accent = today
- Summary: "X workouts in the last 30 days"

**`StrengthChartView.swift`**
- Exercise picker (dropdown of all exercises in the plan)
- `LineMark` chart showing total reps per session over time
- Highlights personal bests with annotation

**`MeasurementsView.swift`**
- Spider/radar chart overlay: starting measurements vs current
- Or simpler: grouped bar chart comparing start vs latest for each measurement
- Table of all measurement entries

**Test:** Add sample data (10 weight entries, 15 sessions with set logs, 3 measurement entries). All 4 chart views render correctly with real data. Time range filter works.

---

### Step 2.5: Rest Timer Enhancement

**Goal:** Polished rest timer with haptic feedback and optional sound.

**`RestTimerView.swift`**
- Circular countdown animation (360° arc shrinking)
- Large seconds display in center
- "Skip" button below
- Haptic feedback: `UIImpactFeedbackGenerator(style: .heavy).impactOccurred()` when timer hits 0
- Optional sound: short chime using `AudioServicesPlaySystemSound`

**Integration in `WorkoutSessionViewModel`:**
- Use `Timer.publish(every: 1, on: .main, in: .common)` for countdown
- `restTimeRemaining` decrements each second
- When hits 0: set `isResting = false`, fire haptic, play sound

**Test:** Complete a set. Rest timer appears with correct seconds. Counts down visually. Haptic buzz at 0. Skip button works.

---

## Phase 3 — Adaptation Engine & Motivation (Weeks 9–12)

### Step 3.1: Adaptation Engine

**Goal:** The app detects when the user is ready to level up and calls Claude for an upgraded plan.

**`AdaptationEngine.swift`**
- `class AdaptationEngine`
- Dependencies: `ModelContext`, `ClaudeAPIService`

**Method: `func evaluateReadiness(context: ModelContext) -> AdaptationTrigger?`**
- Fetches last 2 weeks of `WorkoutSession` + `SetLog` data
- Computes:
  - `hitRate: Double` — percentage of sets where actualReps >= target reps (parse target to compare)
  - `completionRate: Double` — percentage of scheduled workouts completed
  - `avgDifficultyRating: Double?` — average of post-workout ratings
- Returns an `AdaptationTrigger` if any condition is met:
  - `.hitRateHigh` — hitRate >= 0.80 for 2 consecutive weeks
  - `.allWorkoutsCompleted` — completionRate == 1.0 for 2 consecutive weeks
  - `.tooEasy` — avgDifficultyRating <= 2.0 for last 3+ sessions
  - `.userRequested` — user manually tapped "Make it harder"
  - Returns `nil` if no trigger

**`AdaptationTrigger` enum:**
- Cases: `hitRateHigh, allWorkoutsCompleted, tooEasy, userRequested`
- Property: `description: String` — human readable reason

**Method: `func requestAdaptation(trigger: AdaptationTrigger, context: ModelContext) async throws -> PlanAdaptationResponse`**
- Gathers: current plan JSON, performance log (last 4 weeks), user profile
- Calls `ClaudeAPIService.adaptPlan()`
- Returns the adaptation response

**`PerformanceLog` struct (for API payload):**
```
struct PerformanceLog: Codable {
    let weeks: [WeekLog]
    let weightTrend: [WeightDataPoint]
    let averageDifficultyRating: Double?
}
struct WeekLog: Codable {
    let weekNumber: Int
    let workoutsCompleted: Int
    let workoutsScheduled: Int
    let exercises: [ExercisePerformance]
}
struct ExercisePerformance: Codable {
    let name: String
    let averageRepsAchieved: Double
    let targetReps: String
    let completionRate: Double
}
struct WeightDataPoint: Codable {
    let date: String
    let weightKg: Double
}
```

**`PlanAdaptationResponse` struct:**
```
struct PlanAdaptationResponse: Codable {
    let changes: [PlanChange]
    let updatedMeals: MealPlanData?  // nil if no meal changes
    let summary: String              // human-readable "here's what changed"
    let newDifficulty: Int
}
struct PlanChange: Codable {
    let exerciseName: String
    let changeType: String           // "repsIncrease", "setsIncrease", "newExercise", "replaced", "tempoChange", "restDecrease"
    let oldValue: String
    let newValue: String
    let reason: String
}
```

**Claude Adaptation Prompt (in `Prompts.swift`):**
- System: "You are an adaptive fitness coach. Analyse the performance data and generate targeted improvements to the user's plan. Only change what needs changing. Return JSON matching the PlanAdaptationResponse schema."
- User message: includes profile, current plan, performance log, trigger reason
- Instruct Claude to return meal changes ONLY if weight loss has stalled or user has flagged meal fatigue

**Method: `func applyAdaptation(response: PlanAdaptationResponse, context: ModelContext)`**
- Applies changes to the active Plan's exercises in SwiftData
- Updates difficulty level
- If meal changes exist, updates MealPlan
- Stores the adaptation as a history record (for undo potential)

**`AdaptationViewModel.swift`**
- `@Observable class AdaptationViewModel`
- Properties:
  - `trigger: AdaptationTrigger?`
  - `adaptation: PlanAdaptationResponse?`
  - `isLoading: Bool = false`
  - `showLevelUpBanner: Bool`
  - `showDiffScreen: Bool = false`
- Methods:
  - `func checkForLevelUp(context: ModelContext)` — calls `AdaptationEngine.evaluateReadiness()`, sets `showLevelUpBanner` if trigger exists
  - `func requestLevelUp() async` — calls `requestAdaptation()`, sets adaptation, shows diff screen
  - `func acceptAdaptation(context: ModelContext)` — calls `applyAdaptation()`, dismisses
  - `func declineAdaptation()` — dismisses, sets a cooldown (don't ask again for 1 week)

**Screens:**

**`LevelUpBannerView.swift`** — Shown on dashboard when trigger detected:
- Animated gradient border, flame icon
- "You're crushing it! Ready to level up?"
- Tap → navigates to diff screen

**`PlanDiffView.swift`** — Shows what will change:
- List of `PlanChange` items, each showing: exercise name, old → new value, reason
- Meal changes section if applicable
- "Accept All" button
- "Customise" button (expands each change with a toggle to accept/reject individually) — nice to have
- "Not Now" button

**Integration:**
- `DashboardViewModel` calls `AdaptationViewModel.checkForLevelUp()` on appear
- After completing a workout session, also trigger a check

**Test:** Simulate 2 weeks of data where all reps are met. Adaptation engine returns `.hitRateHigh`. Banner appears on dashboard. Tap through to diff screen. Accept. Verify plan in SwiftData has updated values.

---

### Step 3.2: Notification Service

**Goal:** Local notifications for workouts, meals, weigh-ins, and streaks.

**`NotificationService.swift`**
- `class NotificationService`

**Method: `static func requestPermission() async -> Bool`**
- `UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])`

**Method: `static func scheduleWorkoutReminder(time: DateComponents, dayOfWeek: Int, workoutTitle: String)`**
- Creates `UNMutableNotificationContent` with title: "Time to train", body: "\(workoutTitle) is waiting for you"
- Trigger: `UNCalendarNotificationTrigger` with hour, minute, weekday
- Identifier: `"workout-reminder-\(dayOfWeek)"`

**Method: `static func scheduleMealReminder(time: DateComponents, mealName: String)`**
- Title: "Meal time", body: "\(mealName) — check your options"
- Identifier: `"meal-\(mealName)"`

**Method: `static func scheduleWeighInReminder(dayOfWeek: Int, time: DateComponents)`**
- Title: "Weekly check-in", body: "Time to log your weight"
- Weekly repeating trigger

**Method: `static func scheduleStreakAtRisk(time: DateComponents)`**
- Scheduled daily at e.g. 8 PM
- Only fires if no workout was logged today (check via app logic — schedule it, but remove it in `WorkoutSessionViewModel.completeSession()`)
- Title: "Don't break your streak!", body: "Your [N]-day streak is on the line"

**Method: `static func cancelAll()`** and **`static func cancelByIdentifier(_ id: String)`**

**`NotificationPreferences` (stored in `UserDefaults` or a small SwiftData model):**
- `workoutReminderEnabled: Bool`, `workoutReminderTime: Date`
- `mealRemindersEnabled: Bool`
- `weighInDay: Int`, `weighInTime: Date`
- `streakRemindersEnabled: Bool`

**Settings Integration:**
- Add a Notifications section in `SettingsView` with toggles and time pickers
- On change, cancel existing notifications and reschedule

**Test:** Enable workout reminders for 7:00 AM on weekdays. Put app in background. Verify notification fires at correct time. Complete a workout — streak-at-risk notification for today should be cancelled.

---

### Step 3.3: Weekly Recap

**Goal:** Sunday evening recap card with Claude-generated commentary.

**`WeeklyRecapView.swift`**
- Card showing:
  - Week number and date range
  - Workouts completed: "4/5"
  - Total reps this week
  - Weight change: "+0.2 kg" or "–0.5 kg" (compared to last week's entry)
  - Claude's 2–3 sentence commentary
- Shareable as image (render view to UIImage using `ImageRenderer`)

**`WeeklyPerformanceSummary` struct (for API call):**
```
struct WeeklyPerformanceSummary: Codable {
    let workoutsCompleted: Int
    let workoutsScheduled: Int
    let totalReps: Int
    let totalSets: Int
    let exerciseHighlights: [String]    // e.g. "Push-up reps up 20%"
    let weightChange: Double?
    let currentStreak: Int
    let difficultyRatings: [Int]
}
```

**Trigger:** Schedule a local notification for Sunday 7 PM. When user opens the recap (from notification or dashboard), the view calls `ClaudeAPIService.generateWeeklyRecap()` and displays the result.

**Test:** Add a full week of workout data. Open recap view. Claude returns a personalised comment. Card displays all stats correctly.

---

### Step 3.4: Streak Celebrations

**Goal:** Animated celebrations at milestone streaks.

**Milestone thresholds:** 7, 14, 30, 60, 100, 200, 365 days.

**`StreakCelebrationView.swift`**
- Full-screen overlay with:
  - Confetti particle animation (use `CAEmitterLayer` or a SwiftUI particle system)
  - Large streak number with flame icon
  - Claude-generated congratulatory message (short, 1 sentence)
  - "Keep Going" dismiss button
- Triggered from `StreakService.updateStreak()` when `currentStreak` hits a milestone

**Streak Freeze Award:**
- When user completes all 5 workouts in a week: `StreakRecord.freezesAvailable += 1` (max 3)
- Freeze button in Settings or streak section: "Use freeze to protect your streak for 1 week"
- When freeze is active: `graceUsedThisWeek` logic is extended to cover the full week

**Test:** Set streak to 6 via debug. Complete workout. Streak hits 7 → celebration overlay appears with confetti. Dismiss and verify streak is 7.

---

## Phase 4 — Polish & Launch (Weeks 13–16)

### Step 4.1: StoreKit 2 Subscription

**Goal:** Paywall, free trial, and subscription management.

**`SubscriptionService.swift`**
- Uses StoreKit 2 (`Product`, `Transaction`)
- Method: `func fetchProducts() async throws -> [Product]` — loads monthly and annual products
- Method: `func purchase(_ product: Product) async throws -> Transaction`
- Method: `func checkEntitlement() async -> Bool` — checks `Transaction.currentEntitlements`
- Method: `func restorePurchases() async`
- Property: `isSubscribed: Bool` (published, checked app-wide)

**`PaywallView.swift`**
- Shown after 7-day free trial expires
- Two cards: Monthly ($9.99/mo), Annual ($79.99/yr with "Save 33%" badge)
- Feature comparison list
- "Restore Purchases" link
- Terms of service and privacy policy links (required by Apple)

**App-wide gating:**
- Free trial: check `UserProfile.createdAt` — if < 7 days ago, full access
- After trial: check `SubscriptionService.isSubscribed`
- Gated features: Claude API calls (plan generation, adaptation, meal swap, weekly recap)
- Non-gated: workout tracking, logging, charts (so the app remains useful even expired)

**StoreKit Configuration:**
- Create StoreKit configuration file in Xcode for testing
- Product IDs: `com.reforge.monthly`, `com.reforge.annual`

**Test:** Launch app with fresh install. Use app for 7 days (adjust date in simulator). On day 8, paywall appears. Purchase in sandbox environment. Verify access restored.

---

### Step 4.2: CloudKit Sync

**Goal:** iCloud sync for multi-device usage.

**Implementation:**
- SwiftData with CloudKit integration:
  - Change `ModelContainer` configuration to use `CloudKitDatabase`
  - Ensure all `@Model` classes use only CloudKit-compatible types
  - No optional relationships pointing to non-optional models
  - No unique constraints (CloudKit doesn't support them)
- Requires: iCloud capability in Xcode, CloudKit container in Apple Developer portal

**Constraints:**
- All model properties must be optional or have defaults
- Arrays must be stored as Codable data (not direct relationships) — verify SwiftData+CloudKit compatibility
- If SwiftData+CloudKit doesn't work well, fallback: manual CloudKit records using `CKRecord` and `CKDatabase`

**Settings toggle:**
- `iCloudSyncEnabled: Bool` in `UserDefaults`
- When toggled on: migrate local container to CloudKit container
- When toggled off: keep local copy, stop syncing

**Test:** Install on two devices (or device + simulator). Create data on device A. Verify it appears on device B after a short delay.

---

### Step 4.3: Progress Photos

**Goal:** Camera integration with date overlay and side-by-side comparison.

**`ProgressPhotoView.swift`**
- Camera button → opens `UIImagePickerController` (or `PhotosPicker` for library)
- After capture:
  - Overlay: date stamp in corner, semi-transparent
  - Save to app storage (not Photo Library) — store in app's documents directory
  - Create a `ProgressPhoto` SwiftData model: `id, date, imagePath, notes`

**`PhotoComparisonView.swift`**
- Two image slots: "Before" and "After"
- Picker for each slot from stored progress photos (sorted by date)
- Swipe or slider overlay to compare

**Storage:** Save images as JPEG to `FileManager.default.urls(for: .documentDirectory)`. Store only the filename in SwiftData. On iCloud sync (v2), images would need `CKAsset`.

**Test:** Take 3 photos across different dates. Open comparison view. Select two photos. Side-by-side displays correctly.

---

### Step 4.4: Design Polish & Micro-Interactions

**Goal:** Refined visual design, animations, and transitions.

**Global Theme (`Theme.swift`):**
- `enum Theme` with static color properties matching the brand (dark primary, coral accent, teal success)
- Custom font loading: choose a distinctive display font (e.g. from Google Fonts, bundled as .ttf)
- `static func heading(_ text: String) -> some View` and similar convenience modifiers

**Animations to add:**
- Dashboard: stagger-in animation for cards on appear (offset + opacity, 0.1s delay between cards)
- Workout session: exercise card transition (slide left out, slide right in) when advancing
- Rest timer: pulsing circle animation
- Nutrition ring: animated fill on appear (from 0 to current value)
- Streak counter: flame icon subtle flicker animation (scale oscillation)
- Tab bar: custom icon bounce on selection
- Level-up banner: gradient shimmer animation

**Haptics throughout:**
- Light tap on button presses
- Medium impact on set completion
- Heavy impact + success notification on workout completion
- Warning notification if streak is about to break

**Transitions:**
- `.matchedGeometryEffect` between workout card on dashboard and workout session header
- Custom sheet presentations for logging overlays

**Test:** Full app walkthrough feeling polished. No jarring transitions. Animations feel natural at 60fps.

---

### Step 4.5: App Store Preparation

**Goal:** Everything needed for App Store submission.

**Assets needed:**
- App icon: 1024×1024 with variants auto-generated by Xcode
- Screenshots: 6.7" (iPhone 15 Pro Max), 6.1" (iPhone 15 Pro), 5.5" (iPhone 8 Plus — if supporting)
  - Screenshot 1: Dashboard with streak
  - Screenshot 2: Workout session with 3D model
  - Screenshot 3: Meal plan
  - Screenshot 4: Progress charts
  - Screenshot 5: Level-up diff screen
- App preview video (optional but recommended): 15–30 second screen recording showing the core flow
- App description: ~170 words, front-loaded with key features
- Keywords: "fitness, workout, bodyweight, AI, personal trainer, meal plan, body recomposition"
- Privacy policy URL (required)
- Terms of service URL (required)

**Pre-submission checklist:**
- [ ] All screens work on all supported iPhone sizes
- [ ] Dark mode support (or explicitly opt out)
- [ ] VoiceOver accessibility labels on interactive elements
- [ ] No crashes on first launch, onboarding, and core flows
- [ ] Subscription flows tested in sandbox
- [ ] Privacy nutrition labels filled in (App Store Connect)
- [ ] No hardcoded API keys
- [ ] Age rating: 4+ (fitness app, no objectionable content)

**TestFlight:**
- Archive build in Xcode → upload to App Store Connect
- Create internal testing group (yourself)
- Create external testing group (10–20 beta users)
- Collect feedback for 1–2 weeks before public submission

---

## Post-Launch Enhancements (Backlog)

These are out of scope for v1 but documented for future reference:

- [ ] Apple Watch companion app (workout tracking, haptic rest timer)
- [ ] Apple Health integration (import/export weight, workouts, nutrition)
- [ ] Social features: share workouts, challenge friends
- [ ] Equipment-based exercises (add "equipment available" to onboarding, unlock dumbbell/band exercises)
- [ ] AR mode: project 3D model into real space via ARKit
- [ ] Widget: today's workout + streak on home screen
- [ ] Siri Shortcuts: "Start my workout" voice command
- [ ] Android version via KMP (Kotlin Multiplatform) or separate native build
- [ ] Coach chat: in-app conversation with Claude for ad-hoc questions ("Can I substitute quinoa for rice?")
