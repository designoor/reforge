# HealthCoach — Implementation Plan

## What We're Building

HealthCoach is an iOS app that acts as a personal AI health coach. It reads the user's health and fitness data from Apple HealthKit, aggregates it into meaningful daily summaries, and sends those summaries to the Anthropic Claude API for personalized analysis and actionable health suggestions.

The app collects 49 HealthKit metrics across activity, heart, respiratory, body, mobility, sleep, and workout categories. Each day it queries HealthKit for the previous day's data, aggregates it into a `DailySummary`, stores it locally in SwiftData, and computes trend comparisons (day-of-week medians, weekly totals, monthly totals) from the historical store.

## Why

Health data is abundant but overwhelming. Apple Watch and iPhone collect dozens of metrics daily — steps, heart rate, sleep stages, HRV, VO2 max, and more — but most people never look at it beyond glancing at their rings. HealthCoach bridges the gap between raw data and actionable insight by using Claude to interpret patterns, spot anomalies, and provide personalized recommendations grounded in the user's actual data and trends.

## How It Works

### Daily Flow

1. **Trigger**: Every day at 00:01 (via `BGProcessingTask`), or when the user opens the app (whichever comes first), the app checks if yesterday's data has been processed.
2. **Query**: The app queries HealthKit for yesterday's data only (00:00–23:59).
3. **Aggregate**: Raw samples are aggregated into a single `DailySummary` — sums for cumulative metrics (steps, energy), averages for rate-based metrics (HR, HRV), min/max where clinically meaningful.
4. **Store**: The `DailySummary` is persisted in SwiftData. Data is stored indefinitely.
5. **Compute Trends**: From the local store, the app computes:
   - Day-of-week median (median of all stored Tuesdays, Wednesdays, etc.)
   - This week total/avg, last week total/avg, week median (past year)
   - This month total/avg, last month total/avg, month median (past year)
6. **Build Prompt**: Yesterday's data + trends + user profile (age, sex, weight) are formatted into a compact, structured prompt.
7. **Call Claude**: The prompt is sent to the Anthropic API (direct from device, API key stored in Keychain).
8. **Parse & Store**: Claude's JSON response is parsed into `HealthInsight` objects and stored in SwiftData.
9. **Notify**: A local notification is posted: "Your daily health insights are ready."

### First Launch

On first launch, the app performs a one-time backfill by querying HealthKit for all available historical data. This bootstraps the trend calculations (medians, averages) so Claude has context from day one.

### Architecture

```
┌─────────────┐     ┌──────────────────────────────────┐     ┌─────────────────┐
│  HealthKit   │────▶│           iOS App                 │────▶│  Anthropic API  │
│  (on device) │     │                                    │     │  (Claude)       │
└─────────────┘     │  ┌────────────┐ ┌───────────────┐ │     └─────────────────┘
                     │  │ SwiftData  │ │   Keychain    │ │
                     │  │ (history)  │ │ (API key)     │ │
                     │  └────────────┘ └───────────────┘ │
                     └──────────────────────────────────┘
```

### API Key Strategy

For v1, the user provides their own Anthropic API key during onboarding. It is stored in the iOS Keychain. In a future version, we will move to a lightweight backend proxy so the key never lives on the device.

### Estimated Cost Per User

Using Claude Sonnet with ~1,000–1,500 tokens input and ~800 tokens output per daily call: approximately $0.01–0.03/day.

---

## Tracked HealthKit Metrics (49 items)

### Quantity Types — Activity & Fitness (14)

| # | Identifier | Unit | Aggregation |
|---|---|---|---|
| 1 | `stepCount` | count | sum |
| 2 | `distanceWalkingRunning` | m | sum |
| 3 | `distanceCycling` | m | sum |
| 4 | `distanceSwimming` | m | sum |
| 7 | `basalEnergyBurned` | kcal | sum |
| 8 | `activeEnergyBurned` | kcal | sum |
| 9 | `flightsClimbed` | count | sum |
| 10 | `appleExerciseTime` | min | sum |
| 11 | `appleMoveTime` | min | sum |
| 12 | `appleStandTime` | min | sum |
| 14 | `swimmingStrokeCount` | count | sum |
| 16 | `physicalEffort` | kcal/(kg·hr) | avg |
| 17 | `vo2Max` | mL/(kg·min) | avg |

### Quantity Types — Running Metrics (5)

| # | Identifier | Unit | Aggregation |
|---|---|---|---|
| 18 | `runningSpeed` | m/s | avg |
| 19 | `runningPower` | W | avg |
| 20 | `runningStrideLength` | m | avg |
| 21 | `runningVerticalOscillation` | cm | avg |
| 22 | `runningGroundContactTime` | ms | avg |

### Quantity Types — Cycling Metrics (4)

| # | Identifier | Unit | Aggregation |
|---|---|---|---|
| 23 | `cyclingSpeed` | m/s | avg |
| 24 | `cyclingPower` | W | avg |
| 25 | `cyclingFunctionalThresholdPower` | W | avg |
| 26 | `cyclingCadence` | count/min | avg |

### Quantity Types — Heart (7)

| # | Identifier | Unit | Aggregation |
|---|---|---|---|
| 32 | `heartRate` | bpm | avg, min, max |
| 33 | `restingHeartRate` | bpm | avg |
| 34 | `walkingHeartRateAverage` | bpm | avg |
| 35 | `heartRateVariabilitySDNN` | ms | avg |
| 36 | `heartRateRecoveryOneMinute` | bpm | avg |
| 37 | `atrialFibrillationBurden` | % | avg |
| 38 | `peripheralPerfusionIndex` | % | avg |

### Quantity Types — Respiratory (2)

| # | Identifier | Unit | Aggregation |
|---|---|---|---|
| 39 | `respiratoryRate` | breaths/min | avg, min, max |
| 40 | `oxygenSaturation` | % | avg, min |

### Quantity Types — Body Measurements (4)

| # | Identifier | Unit | Aggregation |
|---|---|---|---|
| 45 | `height` | m | most recent |
| 46 | `bodyMass` | kg | most recent |
| 47 | `bodyMassIndex` | count | most recent |
| 53 | `appleSleepingWristTemperature` | °C | avg, min, max |

### Quantity Types — Mobility (7)

| # | Identifier | Unit | Aggregation |
|---|---|---|---|
| 94 | `walkingSpeed` | m/s | avg |
| 95 | `walkingStepLength` | m | avg |
| 96 | `walkingAsymmetryPercentage` | % | avg |
| 97 | `walkingDoubleSupportPercentage` | % | avg |
| 98 | `stairAscentSpeed` | m/s | avg |
| 99 | `stairDescentSpeed` | m/s | avg |
| 100 | `sixMinuteWalkTestDistance` | m | most recent |

### Category Types (6)

| # | Identifier | Aggregation |
|---|---|---|
| 110 | `sleepAnalysis` | total hours + breakdown: inBed, awake, core, deep, REM |
| 111 | `appleStandHour` | count of "stood" hours in the day |
| 112 | `mindfulSession` | total minutes |
| 113 | `highHeartRateEvent` | count of events |
| 114 | `lowHeartRateEvent` | count of events |
| 115 | `irregularHeartRhythmEvent` | count of events |

### Workouts (1)

| # | Identifier | Aggregation |
|---|---|---|
| 164 | HKWorkout | count, total duration (min), total energy (kcal), breakdown by workout type |

---

## Data Storage Strategy

### Why Store Locally

- HealthKit queries across 365 days of raw samples are expensive, especially for high-frequency types like heart rate (thousands of samples/day).
- HealthKit data can be deleted by the user at any time — local storage preserves aggregated history.
- Computing medians across 365 stored daily rows is trivial (sorting ~365 numbers).
- The nightly job becomes: "query HealthKit for yesterday only → store one new row → recompute aggregates from local store."

### What Gets Stored

Each day produces one `DailySummary` row containing all 49 metrics' aggregated values. This row is stored forever in SwiftData (with CloudKit sync for device migration in a future version).

### Trend Computations (from local store)

For each metric, the app computes on-demand from stored `DailySummary` rows:

- **Day-of-week median**: Median of all stored values for the same weekday (e.g., all Fridays).
- **This week**: Sum or avg of last 7 days.
- **Last week**: Sum or avg of days 8–14 ago.
- **Week median**: Median of all stored weekly totals/avgs (up to past year).
- **This month**: Sum or avg of current calendar month so far.
- **Last month**: Sum or avg of previous calendar month.
- **Month median**: Median of all stored monthly totals/avgs (up to past year).

---

## Onboarding Flow

```
Screen 1: Welcome → value prop
Screen 2: Personal info → DOB, biological sex, weight, height, unit preference
Screen 3: Schedule → time zone (auto-detect + override), typical wake time
Screen 4: HealthKit → pre-permission explanation, then system permission dialog
Screen 5: API key → text field, stored in Keychain
Screen 6: Notifications → pre-permission explanation, then system permission dialog
Screen 7: Backfill → progress screen while importing historical HealthKit data
```

---

## Project Structure

```
HealthCoach/
├── App/
│   ├── HealthCoachApp.swift                 // Entry point, SwiftData container, tab routing
│   └── AppState.swift                       // Global app state (onboarding complete, etc.)
├── Models/
│   ├── UserProfile.swift                    // DOB, sex, height, weight, units, wake time, timezone
│   ├── DailySummary.swift                   // One row per day, all 49 metrics aggregated
│   ├── WorkoutSummary.swift                 // Individual workout records for the day
│   ├── HealthInsight.swift                  // Claude's parsed response for a given day
│   └── MetricDefinition.swift              // Enum of all 49 metrics with units, aggregation type
├── Services/
│   ├── HealthKitManager.swift               // Auth + raw queries
│   ├── HealthDataAggregator.swift           // Raw HK samples → DailySummary
│   ├── TrendCalculator.swift                // DailySummary history → trend values
│   ├── DailyDataService.swift               // Orchestrates daily data collection
│   ├── KeychainService.swift                // API key storage/retrieval
│   ├── ClaudeService.swift                  // Anthropic API calls (future phase)
│   ├── PromptBuilder.swift                  // Aggregated data → Claude prompt (future phase)
│   ├── BackgroundTaskManager.swift          // BGProcessingTask scheduling + execution
│   └── NotificationManager.swift            // Local notification permissions + posting
├── Views/
│   ├── Onboarding/
│   │   ├── OnboardingContainerView.swift    // Manages onboarding page flow
│   │   ├── WelcomeView.swift                // Screen 1
│   │   ├── PersonalInfoView.swift           // Screen 2
│   │   ├── ScheduleView.swift               // Screen 3
│   │   ├── HealthKitPermissionView.swift    // Screen 4
│   │   ├── APIKeyView.swift                 // Screen 5
│   │   ├── NotificationPermissionView.swift // Screen 6
│   │   └── BackfillProgressView.swift       // Screen 7
│   ├── Dashboard/
│   │   └── DashboardView.swift              // Daily view with date navigation
│   ├── Profile/
│   │   ├── ProfileView.swift                // Main settings screen
│   │   └── EditSheets/                      // Modal editors for each setting
│   │       ├── DOBEditSheet.swift
│   │       ├── SexEditSheet.swift
│   │       ├── HeightEditSheet.swift
│   │       ├── WeightEditSheet.swift
│   │       ├── TimezoneEditSheet.swift
│   │       ├── WakeTimeEditSheet.swift
│   │       └── APIKeyEditSheet.swift
│   └── Debug/
│       ├── DebugDataView.swift              // Container with tabs/segments
│       ├── DailySummaryBrowserView.swift     // Browse daily data by date
│       ├── AggregatedDataView.swift          // Data payload that will be sent to Claude
│       └── DataStatsView.swift              // Storage statistics + maintenance
└── Utilities/
    ├── DateHelpers.swift                    // Date range builders, weekday extraction
    └── UnitConverter.swift                  // Metric ↔ imperial conversions
```

---

## Implementation Phases

---

### Phase 1: Project Skeleton

#### ~~Step 1.1 — Create Xcode Project~~ ✅

- Create new Xcode project: iOS App, SwiftUI, Swift, SwiftData.
- Bundle ID: `com.healthcoach.app`
- Deployment target: iOS 17.0
- Enable HealthKit capability in Signing & Capabilities.
- Enable Background Modes capability (Background fetch, Background processing).
- Add `NSHealthShareUsageDescription` to Info.plist: "HealthCoach reads your health data to provide personalized AI-powered health insights and recommendations."
- Add `NSHealthUpdateUsageDescription` to Info.plist: "HealthCoach may store health-related notes back to Apple Health."

**Verify**: Project builds and runs on simulator. HealthKit entitlement visible in project settings.

#### ~~Step 1.2 — App Entry Point & State~~ ✅

- `HealthCoachApp.swift`: Set up SwiftData `ModelContainer` with all model types. Root view checks `AppState` to decide whether to show onboarding or dashboard.
- `AppState.swift`: Observable class that tracks `isOnboardingComplete` (persisted via `@AppStorage`). Tracks current onboarding step index.

**Verify**: App launches and shows a placeholder view. `isOnboardingComplete` state persists across launches.

---

### Phase 2: Data Models

#### Step 2.1 — MetricDefinition Enum ✅

Define `MetricDefinition` enum with a case for each of the 49 tracked metrics. Each case provides:

- `hkIdentifier`: The `HKQuantityTypeIdentifier` or `HKCategoryTypeIdentifier` string.
- `displayName`: Human-readable name (e.g., "Steps", "Resting Heart Rate").
- `unit`: The `HKUnit` to query with (e.g., `.count()`, `.kilocalorie()`, `.meterPerSecond()`).
- `aggregation`: Enum value — `.sum`, `.avg`, `.mostRecent`, `.avgMinMax`, `.avgMin`.
- `category`: Grouping — `.activity`, `.running`, `.cycling`, `.heart`, `.respiratory`, `.body`, `.mobility`, `.sleep`, `.events`, `.workout`.
- `isCategory`: Bool — whether this is a `HKCategoryType` vs `HKQuantityType`.

**Verify**: All 49 metrics are represented. Can iterate `MetricDefinition.allCases` and get correct identifiers and units for each.

#### Step 2.2 — UserProfile Model ✅

SwiftData `@Model` class with properties:

- `dateOfBirth: Date`
- `biologicalSex: String` (male / female / other)
- `height: Double` (always stored in meters internally)
- `weight: Double` (always stored in kg internally)
- `unitPreference: String` (metric / imperial)
- `timeZone: String` (timezone identifier, e.g., "Europe/Prague")
- `wakeTime: Date` (just the time component)
- `createdAt: Date`
- `updatedAt: Date`

Internal storage is always metric. Display conversion handled by `UnitConverter`.

**Verify**: Can create, save, and fetch a `UserProfile` from SwiftData. Persists across app restarts.

#### Step 2.3 — DailySummary Model ✅

SwiftData `@Model` class. One row per day. Properties:

- `date: Date` (normalized to midnight of the day)
- `dayOfWeek: Int` (1=Sunday … 7=Saturday, from Calendar)

Activity fields:
- `steps: Int?`
- `distanceWalkingRunning: Double?`
- `distanceCycling: Double?`
- `distanceSwimming: Double?`
- `basalEnergyBurned: Double?`
- `activeEnergyBurned: Double?`
- `flightsClimbed: Int?`
- `appleExerciseTime: Double?`
- `appleMoveTime: Double?`
- `appleStandTime: Double?`
- `swimmingStrokeCount: Int?`
- `physicalEffort: Double?`
- `vo2Max: Double?`

Running fields:
- `runningSpeed: Double?`
- `runningPower: Double?`
- `runningStrideLength: Double?`
- `runningVerticalOscillation: Double?`
- `runningGroundContactTime: Double?`

Cycling fields:
- `cyclingSpeed: Double?`
- `cyclingPower: Double?`
- `cyclingFTP: Double?`
- `cyclingCadence: Double?`

Heart fields:
- `heartRateAvg: Double?`
- `heartRateMin: Double?`
- `heartRateMax: Double?`
- `restingHeartRate: Double?`
- `walkingHeartRateAvg: Double?`
- `hrv: Double?`
- `heartRateRecovery: Double?`
- `atrialFibrillationBurden: Double?`
- `peripheralPerfusionIndex: Double?`

Respiratory fields:
- `respiratoryRateAvg: Double?`
- `respiratoryRateMin: Double?`
- `respiratoryRateMax: Double?`
- `oxygenSaturationAvg: Double?`
- `oxygenSaturationMin: Double?`

Body fields:
- `height: Double?`
- `bodyMass: Double?`
- `bmi: Double?`
- `sleepingWristTempAvg: Double?`
- `sleepingWristTempMin: Double?`
- `sleepingWristTempMax: Double?`

Mobility fields:
- `walkingSpeed: Double?`
- `walkingStepLength: Double?`
- `walkingAsymmetry: Double?`
- `walkingDoubleSupport: Double?`
- `stairAscentSpeed: Double?`
- `stairDescentSpeed: Double?`
- `sixMinWalkDistance: Double?`

Sleep fields:
- `sleepTotalHours: Double?`
- `sleepInBedHours: Double?`
- `sleepAwakeHours: Double?`
- `sleepCoreHours: Double?`
- `sleepDeepHours: Double?`
- `sleepREMHours: Double?`

Event fields:
- `standHoursCount: Int?`
- `mindfulMinutes: Double?`
- `highHeartRateEvents: Int?`
- `lowHeartRateEvents: Int?`
- `irregularRhythmEvents: Int?`

Metadata:
- `createdAt: Date`
- `updatedAt: Date`

All health fields are optional (`nil` = no data for that day). Unique constraint on `date` to prevent duplicate days.

**Verify**: Can create a `DailySummary` with partial data (some fields nil). Can save, fetch, and query by date range. No duplicate dates allowed.

#### Step 2.4 — WorkoutSummary Model ✅

SwiftData `@Model` class. Multiple rows per day (one per workout). Properties:

- `date: Date` (day the workout occurred)
- `workoutType: String` (e.g., "running", "cycling", "yoga" — from `HKWorkoutActivityType`)
- `duration: Double` (minutes)
- `totalEnergyBurned: Double?` (kcal)
- `totalDistance: Double?` (meters)
- `startTime: Date`
- `endTime: Date`
- `createdAt: Date`

Can be queried by date to associate with a `DailySummary`.

**Verify**: Can create multiple workouts for the same day. Can query all workouts for a given date range.

#### Step 2.5 — HealthInsight Model (stub) ✅

SwiftData `@Model` class. One row per day (when Claude responds). Properties:

- `date: Date` (the day this insight covers)
- `overallScore: Int?` (1–10)
- `suggestionsJSON: String` (raw JSON string of suggestions array — parsed on read)
- `promptTokens: Int?`
- `responseTokens: Int?`
- `createdAt: Date`

This is a stub for now — will be fully implemented when Claude integration is built.

**Verify**: Model compiles and can be included in the SwiftData container.

---

### Phase 3: Utility Services ✅

#### Step 3.1 — DateHelpers ✅

`DateHelpers.swift` — static utility functions:

- `startOfDay(for date: Date) -> Date` — normalize to midnight.
- `dateRange(for date: Date) -> (start: Date, end: Date)` — midnight to 23:59:59.
- `dayOfWeek(for date: Date) -> Int` — 1=Sunday to 7=Saturday.
- `yesterday() -> Date` — yesterday's midnight.
- `daysAgo(_ n: Int, from date: Date) -> Date`
- `startOfWeek(for date: Date) -> Date`
- `startOfMonth(for date: Date) -> Date`
- `dateRangeForWeek(containing date: Date) -> (start: Date, end: Date)`
- `dateRangeForMonth(containing date: Date) -> (start: Date, end: Date)`

**Verify**: Unit-testable. Correct at edge cases: start of year, daylight saving transitions, different calendar locales.

#### Step 3.2 — UnitConverter ✅

`UnitConverter.swift` — static utility for metric ↔ imperial:

- `displayWeight(_ kg: Double, unit: UnitPreference) -> String` — "70.0 kg" or "154.3 lbs"
- `displayHeight(_ m: Double, unit: UnitPreference) -> String` — "1.75 m" or "5'9\""
- `displayDistance(_ m: Double, unit: UnitPreference) -> String` — "5.2 km" or "3.2 mi"
- `displayTemperature(_ celsius: Double, unit: UnitPreference) -> String` — "36.5°C" or "97.7°F"
- `kgFromLbs(_ lbs: Double) -> Double`
- `metersFromFeetInches(feet: Int, inches: Int) -> Double`
- Input conversion helpers for the onboarding form (user enters in their preferred unit, we convert to metric for storage).

**Verify**: Conversion accuracy. Round-trip conversions (kg → lbs → kg) return original value within floating-point tolerance.

#### Step 3.3 — KeychainService ✅

`KeychainService.swift` — wrapper around Security framework:

- `saveAPIKey(_ key: String) throws`
- `getAPIKey() throws -> String?`
- `deleteAPIKey() throws`
- Uses `kSecClassGenericPassword` with a fixed service identifier.
- Handles error cases: duplicate items, item not found.

**Verify**: Can save a key, retrieve it, delete it. Persists across app restarts. Cannot be read from outside the app sandbox.

---

### Phase 4: HealthKit Service

#### Step 4.1 — HealthKitManager: Availability & Authorization

`HealthKitManager.swift` — singleton or environment object.

- `isAvailable() -> Bool` — wraps `HKHealthStore.isHealthDataAvailable()`.
- Define `allReadTypes: Set<HKObjectType>` — the full set of 49 metric types to request read access for:
  - All 43 `HKQuantityType` identifiers.
  - `HKCategoryType` for: `sleepAnalysis`, `appleStandHour`, `mindfulSession`, `highHeartRateEvent`, `lowHeartRateEvent`, `irregularHeartRhythmEvent`.
  - `HKWorkoutType.workoutType()`.
- `requestAuthorization() async throws` — calls `healthStore.requestAuthorization(toShare: nil, read: allReadTypes)`.
- Note: HealthKit does not reveal if the user denied specific types — queries just return empty. The app must gracefully handle nil/empty data for any metric.

**Verify**: Calling `requestAuthorization()` triggers the HealthKit permission sheet on a real device. All 49 types + workout type are listed.

#### Step 4.2 — HealthKitManager: Characteristic Queries

- `getDateOfBirth() throws -> Date?` — reads `healthStore.dateOfBirthComponents()`.
- `getBiologicalSex() throws -> HKBiologicalSex?` — reads `healthStore.biologicalSex()`.
- Used during onboarding as pre-fill suggestions (if the user has set them in the Health app). The user can override.

**Verify**: Returns correct values if set in Health app. Returns nil gracefully if not set or access denied.

---

### Phase 5: Onboarding UI

Each screen is a separate SwiftUI view. The `OnboardingContainerView` manages navigation between screens using a step index.

#### Step 5.1 — OnboardingContainerView

- Manages an `@State` variable `currentStep: Int` (0–6 mapping to screens 1–7).
- Uses a `TabView` with `.tabViewStyle(.page(indexDisplayMode: .never))` or a custom transition for smooth screen-to-screen navigation.
- Provides "Next" and "Back" navigation (except screen 1 has no back, screen 7 has no manual navigation).
- Validates that required fields are filled before allowing "Next" on data-entry screens.
- On final step completion, sets `AppState.isOnboardingComplete = true`.

**Verify**: Can navigate forward and backward through all 7 screens. Cannot skip required fields. State is maintained when navigating back.

#### Step 5.2 — Screen 1: WelcomeView

- App logo / icon at top.
- Headline: "Your AI Health Coach"
- 3–4 concise points explaining what the app does:
  - Reads your Apple Health data.
  - Analyzes trends and patterns with AI.
  - Provides daily personalized suggestions.
  - All data stays on your device.
- Single "Get Started" button → advances to screen 2.
- No inputs, no permissions, no state to manage.

**Verify**: Renders correctly. Button advances to next screen.

#### Step 5.3 — Screen 2: PersonalInfoView

Fields:
- **Date of birth**: Date picker (wheels or compact style). Max date = today. Required.
- **Biological sex**: Segmented picker — Male / Female / Other. Required.
- **Unit preference**: Segmented picker — Metric / Imperial. Default from device locale.
- **Height**: If metric → single field in cm. If imperial → two fields: feet + inches.
- **Weight**: If metric → field in kg. If imperial → field in lbs.

Behavior:
- Pre-fill DOB and sex from HealthKit characteristics if available (via `HealthKitManager.getDateOfBirth()` and `getBiologicalSex()`). Show a subtle note: "Pre-filled from Apple Health. You can change these."
- Validate: All fields required. Height and weight must be positive numbers.
- On "Next": Create and save `UserProfile` to SwiftData (converting imperial input to metric for storage).

**Verify**: Unit preference toggle switches height/weight input fields between metric/imperial. Pre-fill works when HealthKit data exists. Validation prevents advancing with empty/invalid fields. UserProfile is saved correctly in metric units regardless of display preference.

#### Step 5.4 — Screen 3: ScheduleView

Fields:
- **Time zone**: Text display of auto-detected `TimeZone.current.identifier` (e.g., "Europe/Prague"). Button/link to "Change" which presents a searchable picker of all time zones.
- **Typical wake time**: Time picker (hour + minute). Default 7:00 AM.

On "Next": Update `UserProfile` with timezone and wake time.

**Verify**: Time zone is correctly auto-detected. Can override via searchable picker. Wake time picker works. Values saved to UserProfile.

#### Step 5.5 — Screen 4: HealthKitPermissionView

Pre-permission screen:
- Explanation of what data we'll access and why.
- "HealthCoach needs access to your health data to provide personalized insights."
- Brief list of categories: Activity, Heart, Sleep, Workouts, etc.
- "Your data never leaves your device without your knowledge."

Behavior:
- "Grant Access" button → calls `HealthKitManager.requestAuthorization()`.
- After authorization completes (regardless of what the user selected — we can't know), advance to next screen.
- If HealthKit is not available (iPad), show an error message and do not allow proceeding.

**Verify**: Pre-permission screen renders. Button triggers HealthKit system dialog on real device. App handles both "allow all" and "deny all" gracefully (proceeds either way since we can't detect individual denials).

#### Step 5.6 — Screen 5: APIKeyView

- Explanation text: "HealthCoach uses Claude AI to analyze your health data. You'll need an Anthropic API key."
- Link: "Get your API key →" opening `https://console.anthropic.com/` in Safari.
- Secure text field for the API key (masked input like a password field).
- Optional "Validate" button — makes a minimal API call to verify the key works. Shows success/error state.
- On "Next": Store key in Keychain via `KeychainService.saveAPIKey()`.

**Verify**: Key is masked in the input field. Can paste a key. Key is stored in Keychain and retrievable via `getAPIKey()` after saving. Optional validation makes a real API call and shows result.

#### Step 5.7 — Screen 6: NotificationPermissionView

- Explanation text: "HealthCoach sends you a daily notification when your health insights are ready."
- "Enable Notifications" button → calls `UNUserNotificationCenter.requestAuthorization(options: [.alert, .badge, .sound])`.
- "Skip" option for users who don't want notifications.
- After authorization (or skip), advance to next screen.

**Verify**: Button triggers system notification permission dialog. Handles allow, deny, and skip. App proceeds regardless of choice.

#### Step 5.8 — Screen 7: BackfillProgressView

Behavior:
- Automatically begins processing on appear.
- Calls `HealthKitManager` to query historical data for all metrics.
- Shows progress: "Importing your health history… X days processed"
- Strategy:
  - Query HealthKit for the date range: (earliest available data) → yesterday.
  - Process day by day (or in weekly chunks for performance).
  - For each day, create a `DailySummary` via `HealthDataAggregator` and save to SwiftData.
- On completion: Set `AppState.isOnboardingComplete = true`, transition to `DashboardView`.
- Handle edge case: No historical data available → show "No historical data found. We'll start collecting from today." and proceed.

**Verify**: Progress indicator updates during processing. `DailySummary` rows are created in SwiftData for each historical day. Row count matches expected day range. Handles empty HealthKit gracefully. Transitions to dashboard on completion.

---

### Phase 6: HealthKit Queries & Aggregation

#### Step 6.1 — HealthKitManager: Quantity Queries

Query methods on `HealthKitManager`:

- `querySum(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async throws -> Double?`
  - Uses `HKStatisticsQuery` with `.cumulativeSum`.
  - For: steps, distance, energy, flights, exercise time, stroke count, etc.

- `queryAvg(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async throws -> Double?`
  - Uses `HKStatisticsQuery` with `.discreteAverage`.
  - For: heart rate avg, HRV, walking speed, running metrics, cycling metrics, etc.

- `queryMinMaxAvg(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, start: Date, end: Date) async throws -> (avg: Double?, min: Double?, max: Double?)`
  - Uses `HKStatisticsQuery` with `.discreteAverage`, `.discreteMin`, `.discreteMax`.
  - For: heartRate, respiratoryRate, oxygenSaturation, sleepingWristTemperature.

- `queryMostRecent(for identifier: HKQuantityTypeIdentifier, unit: HKUnit, before: Date) async throws -> Double?`
  - Uses `HKSampleQuery` sorted by end date descending, limit 1.
  - For: height, weight, BMI, sixMinuteWalkTestDistance.

**Verify**: Each query type returns correct values against known HealthKit data. Returns nil when no data exists for the date range.

#### Step 6.2 — HealthKitManager: Category Queries

- `querySleepAnalysis(start: Date, end: Date) async throws -> SleepBreakdown?`
  - Returns: `(total: Double, inBed: Double, awake: Double, core: Double, deep: Double, rem: Double)` in hours.
  - Queries `HKCategoryType(.sleepAnalysis)` and sums durations by `HKCategoryValueSleepAnalysis`.
  - Handles overlapping samples (e.g., iPhone + Watch both recording sleep).

- `queryCategoryCount(for identifier: HKCategoryTypeIdentifier, start: Date, end: Date) async throws -> Int`
  - Counts occurrences for: `appleStandHour` (count of `.stood` only), `highHeartRateEvent`, `lowHeartRateEvent`, `irregularHeartRhythmEvent`.

- `queryMindfulMinutes(start: Date, end: Date) async throws -> Double?`
  - Sums durations of `mindfulSession` category samples.

**Verify**: Sleep breakdown sums correctly. Stand hours count only "stood" values, not "idle". Event counts are accurate. Mindful minutes sum correctly.

#### Step 6.3 — HealthKitManager: Workout Queries

- `queryWorkouts(start: Date, end: Date) async throws -> [WorkoutSummary]`
  - Queries `HKWorkoutType.workoutType()` for the date range.
  - For each `HKWorkout`: extracts activity type, duration, total energy, total distance, start/end time.
  - Maps `HKWorkoutActivityType` to readable string.
  - Returns array of `WorkoutSummary` objects.

**Verify**: Returns correct workout list for a given day. Handles days with no workouts (empty array). Multiple workout types on the same day are all captured.

#### Step 6.4 — HealthDataAggregator

- `aggregateDay(date: Date) async throws -> DailySummary`
  - Takes a date, computes start/end range, calls all relevant `HealthKitManager` query methods, and assembles a `DailySummary`.
  - Calls the appropriate query method based on each metric's aggregation type (from `MetricDefinition`).
  - Returns a fully populated `DailySummary` (with nil for any metric that had no data).

- `backfillHistory(from startDate: Date, to endDate: Date, progress: (Int, Int) -> Void) async throws`
  - Iterates day by day from `startDate` to `endDate`.
  - Calls `aggregateDay()` for each day.
  - Saves each `DailySummary` to SwiftData.
  - Calls `progress(currentDay, totalDays)` for UI updates.
  - Skips days that already exist in SwiftData (idempotent).

**Verify**: `aggregateDay` produces a correct `DailySummary` for a known test day. `backfillHistory` creates the expected number of rows. Re-running backfill doesn't create duplicates.

---

### Phase 7: Dashboard UI

After completing onboarding, the user lands on the daily view. This is the main screen of the app. For now it will be a shell — the Claude-powered summaries and suggestions will be added in a future phase.

#### Step 7.1 — Tab Bar Structure

- Replace the single root view with a `TabView` containing two tabs:
  - **Tab 1: "Today"** — `DashboardView` (daily insights)
  - **Tab 2: "Profile"** — `ProfileView` (settings + debug)
- Use SF Symbols for tab icons (e.g., `heart.text.square` for Today, `person.circle` for Profile).
- After onboarding completes, the app always opens to the Today tab.

**Verify**: Two tabs render at the bottom. Tapping switches between them. Correct icons and labels.

#### Step 7.2 — DashboardView (empty shell)

- Top: Date display showing yesterday's date (since that's the day being analyzed), formatted per locale. Left/right arrows or swipe to navigate to previous days (reads from stored `DailySummary` history).
- Middle: Empty state message — "No insights yet. Your first daily analysis will appear here tomorrow morning." (shown when no `HealthInsight` exists for the selected date).
- Placeholder sections (visible but empty, ready for future content):
  - **Overall Score** — circular score indicator (placeholder showing "—").
  - **Suggestions** — empty list area with subtle text: "AI suggestions will appear here."
  - **Data Summary** — collapsed/expandable section header: "Health Data" (no content yet).
- Pull-to-refresh gesture (stub — will trigger data fetch + Claude call in future phase).

**Verify**: View renders with yesterday's date. Can navigate to previous dates. Empty state message shows when no insights exist. Pull-to-refresh gesture is recognized (even if it does nothing yet).

#### Step 7.3 — DashboardView: Date Navigation & Data Loading

- When the user navigates to a different date, the view queries SwiftData for that date's `DailySummary` and `HealthInsight`.
- If a `DailySummary` exists for the selected date, show a subtle indicator (e.g., a small dot or checkmark) confirming data was collected that day.
- If no `DailySummary` exists, show "No data recorded for this date."
- Limit backward navigation to the earliest stored `DailySummary` date. Disable forward navigation past yesterday.

**Verify**: Navigating dates loads the correct `DailySummary` from SwiftData. Days with data show the indicator. Days without data show the empty message. Cannot navigate into the future or before earliest data.

---

### Phase 8: Profile Tab

The Profile tab lets the user view and edit all settings they configured during onboarding, plus access debug tools.

#### Step 8.1 — ProfileView (main settings screen)

- SwiftUI `Form` or `List` with grouped sections:

**Section: Personal Info**
- Date of birth — tappable row showing current value, opens date picker to edit.
- Biological sex — tappable row showing current value, opens picker to edit.
- Height — tappable row showing current value in preferred units, opens input to edit.
- Weight — tappable row showing current value in preferred units, opens input to edit.

**Section: Preferences**
- Unit preference — toggle between Metric / Imperial. Changing this immediately updates all displayed values in the app.
- Time zone — tappable row showing current timezone, opens searchable picker to edit.
- Wake time — tappable row showing current time, opens time picker to edit.

**Section: API**
- API key — tappable row showing masked key (e.g., "sk-ant-...7x2f"). Tap to reveal/edit. Option to re-validate.
- API usage — placeholder row: "Usage stats coming soon" (will show token counts and estimated cost in a future phase).

**Section: Notifications**
- Notification status — shows current permission state (Enabled / Disabled). If disabled, "Enable" button opens system settings.

**Section: Data**
- Debug — navigation link to `DebugDataView` (Phase 9).

**Section: About**
- App version.
- "Built with Claude by Anthropic" (link to anthropic.com).

- All edits immediately update the `UserProfile` in SwiftData.

**Verify**: All current UserProfile values display correctly. Can edit each field. Changes persist after leaving and returning to the screen. Unit preference change updates height/weight display immediately. API key is masked by default.

#### Step 8.2 — ProfileView: Edit Sheets

- Each editable field opens a modal sheet or inline editor:
  - DOB: Date picker sheet.
  - Biological sex: Action sheet with options.
  - Height/Weight: Text input sheet with unit label matching current preference. Input validated (positive numbers only). Converted to metric on save.
  - Time zone: Searchable list sheet.
  - Wake time: Time picker sheet.
  - API key: Secure text field sheet with validate + save buttons.
- All sheets have "Cancel" and "Save" actions.

**Verify**: Each edit sheet opens, displays current value, allows modification, and saves correctly. Cancel discards changes. Invalid input shows error and prevents save.

---

### Phase 9: Debug View

The debug view shows exactly what data the app has collected and what would be sent to Claude. This is essential for development and for power users who want to see the raw data.

#### Step 9.1 — DebugDataView: Daily Summary Browser

- Accessible from Profile → Debug.
- Top: Date picker to select any date that has stored data.
- Main content: Displays the full `DailySummary` for the selected date, organized by category:

**Section: Activity & Fitness**
- Each metric shown as a row: label, value (in user's preferred units), unit label.
- Nil values shown as "—" (greyed out).

**Section: Running Metrics**
- Same row format.

**Section: Cycling Metrics**
- Same row format.

**Section: Heart**
- For heartRate: shows avg, min, max on the same row.
- Other heart metrics: single value per row.

**Section: Respiratory**
- respiratoryRate: avg, min, max.
- oxygenSaturation: avg, min.

**Section: Body**
- sleepingWristTemperature: avg, min, max.
- Others: single value.

**Section: Mobility**
- Single value per row.

**Section: Sleep**
- Total hours + breakdown: inBed, awake, core, deep, REM.
- Could use a simple horizontal stacked bar to visualize proportions.

**Section: Events**
- Stand hours, mindful minutes, heart rate events, irregular rhythm events.

**Section: Workouts**
- List of workouts for that day: type, duration, energy, distance.
- "No workouts" if empty.

**Verify**: All stored `DailySummary` fields display correctly for a selected date. Nil fields show "—". Units respect user preference (metric/imperial). All categories present and correctly grouped.

#### Step 9.2 — DebugDataView: Aggregated Data View

- A second tab or segment within the debug view: "Claude Data".
- Shows the complete aggregated data that will be sent to Claude for the selected date, organized as Claude will receive it:

**User Profile Context**
- Age (computed from DOB), biological sex, height, weight (in user's preferred units).

**Yesterday's Values**
- All non-nil metrics from the selected date's `DailySummary`, grouped by category with their values and units.

**Trend Comparisons (per metric)**
- Day-of-week median (e.g., "Friday median: 10,400 steps").
- This week total/avg vs last week total/avg.
- Week median.
- This month total/avg vs last month total/avg.
- Month median.

**Workouts**
- List of workouts for that day with type, duration, energy, distance.

Each row shows: metric name, the day's value, and each trend value side by side — making it easy to see exactly what context Claude will have.

Note: Trend computations require `TrendCalculator` (future phase). Until implemented, trend columns show "—" placeholder. The daily values and user profile sections work immediately.

"Copy as JSON" button — exports the full data structure as JSON to clipboard for debugging.

**Verify**: Daily values match the Daily Summary Browser for the same date. User profile info is correct. Trend columns show "—" until TrendCalculator is built. Copy as JSON produces valid JSON. All non-nil metrics are represented.

#### Step 9.3 — DebugDataView: Data Statistics

- A third tab or segment: "Stats".
- Shows aggregate information about the local data store:
  - Total days stored.
  - Date range: earliest → latest stored date.
  - Days with data vs days without (percentage).
  - Per-metric coverage: for each of the 49 metrics, show how many days have non-nil values (e.g., "stepCount: 342/365 days (93.7%)").
  - Total workouts stored.
  - Storage estimate (approximate SwiftData size).
- "Re-run Backfill" button — triggers a new backfill for any missing days between earliest stored date and yesterday. Useful if the user granted more HealthKit permissions after initial onboarding.
- "Delete All Data" button — with confirmation dialog. Clears all `DailySummary`, `WorkoutSummary`, and `HealthInsight` rows. Does not clear `UserProfile`.

**Verify**: Statistics are accurate against known data. Per-metric coverage percentages are correct. Re-run backfill fills in missing days without creating duplicates. Delete all data clears the correct tables and the UI reflects the empty state.

---

### Phase 10: Trend Calculator

The trend calculator computes all comparative values from the local `DailySummary` store. These are used both in the debug view's aggregated data and in the Claude prompt.

#### Step 10.1 — TrendCalculator: Core Median & Aggregation Functions

`TrendCalculator.swift` — operates on arrays of `DailySummary` fetched from SwiftData.

Helper functions:
- `median(_ values: [Double]) -> Double?` — returns median of non-nil values. Returns nil if array is empty.
- `sum(_ values: [Double]) -> Double?` — returns sum. Nil if empty.
- `average(_ values: [Double]) -> Double?` — returns mean. Nil if empty.

These are generic helpers used by all trend computations below.

**Verify**: `median([3, 1, 4, 1, 5])` returns 3.0. `median([1, 2])` returns 1.5. Empty array returns nil. Same for sum and average.

#### Step 10.2 — TrendCalculator: Day-of-Week Median

- `dayOfWeekMedian(for metric: KeyPath<DailySummary, Double?>, dayOfWeek: Int, from summaries: [DailySummary]) -> Double?`
  - Filters all stored `DailySummary` rows where `dayOfWeek` matches.
  - Extracts non-nil values for the given metric keypath.
  - Returns the median.
- Variant for sum-based metrics: `dayOfWeekMedianOfSums(...)` — for metrics like steps where the day-of-week median should be the median of daily totals, not individual samples.
- Works with whatever history is available — 2 weeks or 2 years.

**Verify**: Given 10 stored Fridays with step counts [8000, 9000, 10000, 11000, 12000, 7000, 9500, 10500, 11500, 8500], returns median of 9750. Handles days with nil values (skips them). Returns nil if no data exists for that weekday.

#### Step 10.3 — TrendCalculator: Weekly Aggregates

- `weeklyAggregate(for metric: KeyPath<DailySummary, Double?>, aggregation: AggregationType, weekStart: Date, from summaries: [DailySummary]) -> Double?`
  - Filters summaries within the 7-day window starting at `weekStart`.
  - Applies sum or avg depending on `aggregation` type.
- Convenience methods:
  - `thisWeek(for metric:, aggregation:, from:) -> Double?` — current calendar week.
  - `lastWeek(for metric:, aggregation:, from:) -> Double?` — previous calendar week.
- `weekMedian(for metric: KeyPath<DailySummary, Double?>, aggregation: AggregationType, from summaries: [DailySummary]) -> Double?`
  - Groups all stored summaries into calendar weeks.
  - Computes the sum or avg for each week.
  - Returns the median of all weekly values (up to past year of data).

**Verify**: Given 4 weeks of step data, `thisWeek` and `lastWeek` return correct sums. `weekMedian` returns the median of weekly totals. Partial weeks (e.g., current week only has 3 days so far) are handled correctly — still computed but not compared as if they were full weeks.

#### Step 10.4 — TrendCalculator: Monthly Aggregates

- `monthlyAggregate(for metric: KeyPath<DailySummary, Double?>, aggregation: AggregationType, monthStart: Date, from summaries: [DailySummary]) -> Double?`
  - Filters summaries within the calendar month starting at `monthStart`.
  - Applies sum or avg depending on `aggregation` type.
- Convenience methods:
  - `thisMonth(for metric:, aggregation:, from:) -> Double?` — current calendar month.
  - `lastMonth(for metric:, aggregation:, from:) -> Double?` — previous calendar month.
- `monthMedian(for metric: KeyPath<DailySummary, Double?>, aggregation: AggregationType, from summaries: [DailySummary]) -> Double?`
  - Groups all stored summaries into calendar months.
  - Computes the sum or avg for each month.
  - Returns the median of all monthly values (up to past year of data).

**Verify**: Given 3 months of data, `thisMonth` and `lastMonth` return correct values. `monthMedian` returns median of monthly totals. Months with varying day counts (28 vs 31) are handled. Partial current month is computed with available data.

#### Step 10.5 — TrendCalculator: Full Trend Report

- `computeTrends(for date: Date, from summaries: [DailySummary]) -> TrendReport`
- `TrendReport` struct containing, for each of the 49 metrics:
  - `dayValue: Double?` — the metric's value on the given date.
  - `dayOfWeekMedian: Double?`
  - `thisWeek: Double?`
  - `lastWeek: Double?`
  - `weekMedian: Double?`
  - `thisMonth: Double?`
  - `lastMonth: Double?`
  - `monthMedian: Double?`
- This is the single entry point called by both the debug view and the future Claude prompt builder.
- Internally iterates all metrics from `MetricDefinition`, applies the correct aggregation type per metric, and assembles the report.
- Performance consideration: fetches all summaries once, passes the array to each computation. Avoids repeated SwiftData queries.

**Verify**: `TrendReport` for a given date contains correct values across all metrics and all trend dimensions. Performance is acceptable (< 1 second) with 365 days of stored data. Nil metrics propagate correctly (if a metric has no data, all its trend values are nil).

#### Step 10.6 — Wire TrendCalculator into Debug View

- Update `AggregatedDataView` (Step 9.2) to call `TrendCalculator.computeTrends()` and display real trend values instead of "—" placeholders.
- Each metric row now shows: day value, day-of-week median, this week, last week, week median, this month, last month, month median.
- "Copy as JSON" now includes real trend data in the export.

**Verify**: Trend columns in the debug view show real computed values. Values match manual spot-check calculations. JSON export includes all trend data.

---

### Phase 11: Automated Daily Data Collection

This phase ensures that HealthKit data is collected and stored every day without user intervention. No Claude integration — purely local data pipeline.

#### Step 11.1 — DailyDataService: Orchestrator

`DailyDataService.swift` — coordinates daily data collection.

- `collectData(for date: Date) async throws -> DailySummary`
  - Steps:
    1. Check if a `DailySummary` already exists for this date in SwiftData. If yes, return it (idempotent).
    2. Call `HealthDataAggregator.aggregateDay(date:)` to query HealthKit and create the summary.
    3. Save the `DailySummary` to SwiftData.
    4. Query and save any `WorkoutSummary` records for the date.
    5. Return the `DailySummary`.
- `needsCollection(for date: Date) -> Bool` — checks if a `DailySummary` exists for the date.
- `collectMissedDays() async throws -> Int`
  - Finds the most recent stored `DailySummary` date.
  - For each day between that date and yesterday, calls `collectData()`.
  - Returns the number of days collected.
  - Caps at 30 missed days to avoid excessive HealthKit queries after long inactivity.

**Verify**: Collecting data for a date with HealthKit data creates and stores a `DailySummary`. Collecting the same date again returns the existing row without re-querying. `collectMissedDays` fills gaps correctly. Already-collected days are skipped.

#### Step 11.2 — BackgroundTaskManager: Registration

`BackgroundTaskManager.swift` — manages `BGProcessingTask` scheduling.

- Register the background task identifier in `HealthCoachApp.swift` on launch:
  - Identifier: `com.healthcoach.dailyCollection`
  - Register via `BGTaskScheduler.shared.register(forTaskWithIdentifier:using:launchHandler:)`.
- Add the identifier to `Info.plist` under `BGTaskSchedulerPermittedIdentifiers`.
- `scheduleNextCollection()`:
  - Creates a `BGProcessingTaskRequest` with the identifier.
  - Sets `earliestBeginDate` to today at 00:01 (using user's configured timezone).
  - Sets `requiresNetworkConnectivity = false` (purely local — no API call needed).
  - Sets `requiresExternalPower = false`.
  - Submits via `BGTaskScheduler.shared.submit()`.

**Verify**: Background task is registered on app launch. Task request is submitted with correct earliest begin date. `requiresNetworkConnectivity` is false. Identifier is in Info.plist.

#### Step 11.3 — BackgroundTaskManager: Task Execution

- `handleDailyCollection(task: BGProcessingTask)`:
  - Called by the system when the background task fires.
  - Sets `task.expirationHandler` to cancel gracefully if the system reclaims resources.
  - Determines yesterday's date (in the user's configured timezone).
  - Calls `DailyDataService.collectData(for: yesterday)`.
  - Also calls `DailyDataService.collectMissedDays()` to catch any gaps.
  - On completion (success or failure):
    - Calls `scheduleNextCollection()` to schedule tomorrow's task.
    - Calls `task.setTaskCompleted(success:)`.
  - No notification posted — this is silent background work. Notifications will be added when Claude integration arrives.

**Verify**: Task handler calls the data collection pipeline. Task is rescheduled regardless of outcome. No network required. Handles expiration gracefully without crashing.

#### Step 11.4 — App-Open Fallback Check

Since iOS doesn't guarantee background task execution, the app checks on every foreground entry.

- In `HealthCoachApp.swift` or `AppState`, add a `scenePhase` handler:
  - When the app enters foreground and onboarding is complete:
    - Call `DailyDataService.needsCollection(for: yesterday)`.
    - If true, run `DailyDataService.collectData(for: yesterday)` in a background Swift Task.
    - Also call `DailyDataService.collectMissedDays()` to fill any gaps.
    - Show a subtle indicator on the dashboard (e.g., small spinner or "Syncing health data…" text) while it runs.
    - On completion, refresh the dashboard and debug views.
- This is non-blocking — user can navigate the app while collection runs.

**Verify**: Opening the app when yesterday's data is missing triggers collection automatically. Dashboard updates when done. Multiple missed days are caught up. Already-collected days are skipped. App remains responsive during collection.

#### Step 11.5 — Schedule Initial Task After Onboarding

- At the end of onboarding (when `BackfillProgressView` completes), call `BackgroundTaskManager.scheduleNextCollection()` to queue the first background task.
- This ensures the daily cycle begins immediately after setup.

**Verify**: After completing onboarding, a background task is scheduled. Can verify via Xcode's background task debugger that the task is pending.

---

### Phase 12: Daily Data View & Manual Input

This phase builds out the main daily view with interactive date navigation and the ability to manually input health data.

#### Step 12.1 — Date Header & Navigation

- At the top of `DashboardView`, replace the simple date display with an interactive date header:
  - Shows the currently selected date in a clear format (e.g., "Friday, Feb 27, 2026").
  - **Tap** the date → opens a calendar date picker allowing the user to jump to any specific date.
  - **Swipe left** on the view → moves to the previous day (always available as long as stored data exists).
  - **Swipe right** on the view → moves to the next day. Disabled / no-op if already on yesterday (cannot go into the future past yesterday since today's data isn't complete yet).
- The date picker should highlight dates that have stored `DailySummary` data (e.g., with a dot indicator).
- Limit the date picker range: earliest stored `DailySummary` date → yesterday.
- Swipe gesture should have a smooth transition animation.

**Verify**: Tapping the date opens the calendar picker. Swiping left moves to previous day. Swiping right moves to next day. Cannot swipe past yesterday. Cannot select future dates in the picker. Dates with stored data are visually indicated in the picker.

#### Step 12.2 — Daily Data Placeholder Content

- Below the date header, show a scrollable view of the day's data (if a `DailySummary` exists for the selected date).
- For now, display a simple grouped list by category showing available metrics and their values (similar to debug view but styled for the user):
  - Category headers: Activity, Running, Cycling, Heart, Respiratory, Body, Mobility, Sleep, Events, Workouts.
  - Each metric: label + value in user's preferred units.
  - Nil metrics: hidden (don't show "—" rows to the user, unlike debug view).
  - Empty categories: hidden entirely.
- If no `DailySummary` exists for the selected date, show: "No data recorded for this date."
- This is placeholder content — will be replaced with Claude-powered insights and richer visualizations in a future phase.

**Verify**: Navigating to a date with data shows metrics grouped by category. Nil metrics and empty categories are hidden. Navigating to a date without data shows the empty message. Values respect unit preference.

#### Step 12.3 — Manual Input: Plus Button & Action Sheet

- Add a "+" button in the top-right corner of the `DashboardView` (or as a floating action button).
- Tapping it presents an action sheet or bottom sheet with a list of manually inputtable metrics.
- For now, the only option is: **"Log Weight"**.
- The list is designed to be extensible — future options could include: blood pressure, blood glucose, water intake, symptoms, etc.
- The action sheet shows the options with icons and labels.

**Verify**: Plus button is visible and tappable. Action sheet appears with "Log Weight" option. Sheet dismisses on cancel or outside tap.

#### Step 12.4 — Manual Input: Weight Entry View

- Selecting "Log Weight" opens a modal sheet:
  - **Date**: Pre-filled with the currently selected date on the dashboard. Tappable to change.
  - **Weight input**: Numeric text field with the appropriate unit label (kg or lbs based on preference).
  - **Keyboard**: Decimal number pad.
  - Pre-fill with the most recent stored weight (from `DailySummary` or `UserProfile`) as a reference, shown as placeholder text.
  - "Save" button:
    - Converts to metric (kg) if user is on imperial.
    - Writes the value to HealthKit via `HKHealthStore.save()` (this requires the `NSHealthUpdateUsageDescription` we added in Phase 1).
    - Updates the `UserProfile.weight` with the new value.
    - If a `DailySummary` exists for that date, updates its `bodyMass` field.
    - If no `DailySummary` exists, creates one with just the weight value (other fields nil).
    - Dismisses the sheet.
  - "Cancel" button: Dismisses without saving.
- Validation: Weight must be a positive number. Show inline error for invalid input.

**Verify**: Modal opens with correct unit label. Can enter a decimal weight. Pre-fills with last known weight as placeholder. Save writes to HealthKit and updates local store. Cancel discards. Invalid input (negative, zero, non-numeric) shows error and prevents save. `UserProfile.weight` is updated. Dashboard view refreshes to show the new weight.

#### Step 12.5 — HealthKitManager: Write Support

- Add write capability to `HealthKitManager`:
  - `saveWeight(_ kg: Double, date: Date) async throws`
    - Creates an `HKQuantitySample` for `bodyMass` with the given value and date.
    - Saves via `healthStore.save()`.
- Update `allShareTypes` (was previously `nil` in authorization):
  - Add `bodyMass` to the share (write) types set.
  - This means the HealthKit permission dialog will now also show write permissions for weight.
- Note: This requires updating the authorization request. Users who already completed onboarding may need to re-authorize via the Health app settings (the app can prompt them if a write fails due to missing permission).

**Verify**: Can write a weight sample to HealthKit. The sample appears in the Health app. Authorization request includes write access for body mass. Write failure due to missing permission is caught and shows a user-friendly message.

---

### Phase 13: Notifications

This phase implements a flexible notification system where users can configure which notifications they want, plus debug-specific notifications for development.

#### Step 13.1 — NotificationManager: Core Service

`NotificationManager.swift` — manages all notification types.

- `requestPermission() async -> Bool` — requests notification authorization, returns whether granted.
- `isPermissionGranted() async -> Bool` — checks current authorization status.
- `scheduleNotification(id: String, title: String, body: String, at dateComponents: DateComponents, repeats: Bool) async throws` — schedules a local notification.
- `cancelNotification(id: String)` — cancels a specific pending notification.
- `cancelAllNotifications()` — cancels all pending notifications.
- `getPendingNotifications() async -> [UNNotificationRequest]` — lists all scheduled notifications.
- Each notification type has a unique string identifier (used for scheduling and canceling).

**Verify**: Can schedule a notification and see it in `getPendingNotifications()`. Can cancel by ID. Permission request triggers system dialog. `isPermissionGranted()` returns correct status.

#### Step 13.2 — Notification Settings Model

- Add notification preferences to `UserProfile` (or a separate `NotificationSettings` SwiftData model):
  - `dailyCollectionNotification: Bool` (default: false) — debug: notifies when daily data collection succeeds.
  - `weightReminderEnabled: Bool` (default: false) — reminds user to log weight.
  - `weightReminderTime: Date` (default: 8:00 AM) — time of day for the weight reminder.
- Extensible design: new notification types can be added as new Bool + time properties.

**Verify**: Settings model saves and loads correctly. Default values are applied on first creation.

#### Step 13.3 — Notification Settings UI

- Add a **"Notifications"** section in `ProfileView`, replacing the simple status row from Phase 8:

**Subsection: System**
- Row showing current permission status (Enabled / Disabled).
- If disabled: "Enable in Settings" button that opens iOS Settings via `UIApplication.openSettings()`.

**Subsection: Reminders**
- **Weight Reminder**: Toggle (on/off) + time picker (visible when on).
  - When toggled on: calls `NotificationManager.scheduleNotification()` with a daily repeating trigger at the selected time.
  - When toggled off: calls `NotificationManager.cancelNotification()` for the weight reminder ID.
  - When time is changed: cancels and reschedules with new time.

**Subsection: Debug Notifications**
- **Data Collection Success**: Toggle (on/off).
  - When on: `DailyDataService` will post a notification after successful daily collection.
  - When off: collection runs silently.
- This section could be hidden behind a "Show Debug Options" toggle or only visible when accessed from the Debug view. For now, keep it visible in the Profile tab for development convenience.

**Verify**: All toggles save their state. Enabling weight reminder schedules a notification at the correct time. Disabling it cancels the pending notification. Changing time reschedules. Debug toggle persists. System permission status is accurate.

#### Step 13.4 — Weight Reminder Notification: Deep Link

- When the weight reminder notification fires and the user taps it, the app should open directly to the weight input view.
- Implementation:
  - Set a `userInfo` dictionary on the notification with a key like `"action": "logWeight"`.
  - In `HealthCoachApp.swift`, handle `UNUserNotificationCenterDelegate.userNotificationCenter(_:didReceive:)`.
  - When the response's `userInfo` contains `"action": "logWeight"`:
    - Set a flag in `AppState` (e.g., `pendingAction: .logWeight`).
    - The `DashboardView` observes this flag and presents the weight input sheet when it's set.
    - Clear the flag after the sheet is presented.
- Should work whether the app was in foreground, background, or terminated.

**Verify**: Tapping the weight reminder notification opens the app and immediately presents the weight input sheet. Works from terminated state (cold launch). Works from background. Works from foreground. The sheet shows today's date pre-filled. After dismissing the sheet, the app behaves normally.

#### Step 13.5 — Debug Notification: Data Collection Success

- Update `DailyDataService` (from Phase 11) to post a local notification after successful data collection, but only when the debug notification toggle is enabled.
- After `collectData()` completes successfully:
  - Check `NotificationSettings.dailyCollectionNotification`.
  - If true, post an immediate notification:
    - Title: "Data Collection Complete"
    - Body: "Successfully collected health data for [date]. [X] metrics recorded."
    - The body should include a count of non-nil metrics in the `DailySummary`.
  - If false, do nothing (silent).
- This fires from both the background task and the app-open fallback.

**Verify**: With debug toggle on: notification appears after successful data collection showing correct date and metric count. With toggle off: no notification. Works from background task execution. Works from app-open fallback.

#### Step 13.6 — Reschedule Notifications on Settings Change

- When the user changes their wake time (in Profile → Schedule settings), any time-based notifications should be re-evaluated:
  - Weight reminder: stays at its own configured time (independent of wake time).
  - Future notifications (like Claude insights) may depend on wake time — design the system so `NotificationManager` has a `rescheduleAll()` method that re-reads all settings and updates pending notifications accordingly.
- When the user changes timezone:
  - Reschedule all time-based notifications to fire at the correct local time in the new timezone.
- `rescheduleAll()` is called whenever `UserProfile.timeZone` or `UserProfile.wakeTime` is updated.

**Verify**: Changing timezone reschedules notifications to the correct new local time. Changing wake time triggers reschedule. Pending notifications in `getPendingNotifications()` reflect the updated schedule. No duplicate notifications are created.

---

### Future Phases (not in current scope)

Documented for reference but will not be implemented in this plan:

- **Phase 14: Claude Integration** — PromptBuilder, ClaudeService, API key validation, DailyAnalysisService orchestrator, response parsing and storage.
- **Phase 15: Dashboard Content** — Populate daily view with Claude suggestions, scores, data summaries, and trend charts.
- **Phase 16: Notification Refinement** — Claude insight ready notifications, summary previews in notification body, action buttons.
- **Phase 17: Additional Manual Inputs** — Blood pressure, blood glucose, water intake, symptoms, mood, and other manually logged metrics.
- **Phase 18: Settings Expansion** — View API usage/costs, export data, manage history, theme preferences.
- **Phase 19: Backend Migration** — Move API key to lightweight server proxy.
