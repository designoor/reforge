import SwiftUI

struct BodyStatsView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("About You")
                    .font(.title2)
                    .fontWeight(.bold)

                // Name
                VStack(alignment: .leading, spacing: 4) {
                    Text("Name").font(.headline)
                    TextField("Your name", text: $viewModel.name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.givenName)
                }

                // Height
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Height").font(.headline)
                        Spacer()
                        Text("\(Int(viewModel.heightCm)) cm")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.heightCm, in: 140...220, step: 1)
                }

                // Weight
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("Weight").font(.headline)
                        Spacer()
                        Text(String(format: "%.1f kg", viewModel.weightKg))
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $viewModel.weightKg, in: 40...200, step: 0.5)
                }

                // Age
                Stepper("Age: \(viewModel.age)", value: $viewModel.age, in: 16...80)
                    .font(.headline)

                // Biological Sex
                VStack(alignment: .leading, spacing: 4) {
                    Text("Biological Sex").font(.headline)
                    Picker("Sex", selection: $viewModel.biologicalSex) {
                        Text("Male").tag("male")
                        Text("Female").tag("female")
                    }
                    .pickerStyle(.segmented)
                }

                // BMI
                HStack {
                    Text("BMI").font(.headline)
                    Spacer()
                    Text(String(format: "%.1f", viewModel.bmi))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(bmiColor)
                }
                .padding()
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 12))
            }
            .padding()
        }
    }

    private var bmiColor: Color {
        switch viewModel.bmi {
        case ..<18.5: return .orange
        case 18.5..<25: return .green
        case 25..<30: return .orange
        default: return .red
        }
    }
}

#Preview {
    BodyStatsView(viewModel: OnboardingViewModel())
}
