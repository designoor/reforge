import SwiftUI

struct WelcomeView: View {
    @Binding var canAdvance: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "heart.text.clipboard")
                .font(.system(size: 80))
                .foregroundStyle(Color.accentColor)

            Text("Your AI Health Coach")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)

            VStack(alignment: .leading, spacing: 16) {
                featureRow(icon: "applewatch", text: "Reads your Apple Health data")
                featureRow(icon: "chart.line.uptrend.xyaxis", text: "Analyzes trends and patterns with AI")
                featureRow(icon: "lightbulb", text: "Provides daily personalized suggestions")
                featureRow(icon: "lock.shield", text: "All data stays on your device")
            }
            .padding(.horizontal, 24)

            Spacer()
            Spacer()
        }
        .onAppear {
            canAdvance = true
        }
    }

    private func featureRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32)

            Text(text)
                .font(.body)
        }
    }
}

#Preview {
    WelcomeView(canAdvance: .constant(true))
}
