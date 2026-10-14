import SwiftUI

struct DetailMetricCard: View {
    let label: String
    let value: String
    let unit: String
    let status: String
    let icon: String
 
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.blue)
                    Text(label)
                        .font(.caption)
                        .bold()
                        .foregroundStyle(.gray)
                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(value)
                        .font(.system(size: 32, weight: .bold))
                    Text(unit)
                        .font(.subheadline)
                        .foregroundStyle(.gray)
                }

                Text(status)
                    .font(.footnote)
                    .foregroundStyle(.green)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity, minHeight: 110)
    }
}

#Preview("DetailMetricCard Grid") {
    ScrollView {
        let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
        LazyVGrid(columns: gridItems, spacing: 12) {
            DetailMetricCard(label: "RESPIRATORY RATE", value: "17.9", unit: "rpm", status: "within 17.6 - 18.0", icon: "wind")
            DetailMetricCard(label: "BLOOD OXYGEN (SPO2)", value: "95", unit: "%", status: "within 95% - 100%", icon: "drop.fill")
            DetailMetricCard(label: "RHR", value: "55", unit: "bpm", status: "low < 56", icon: "heart.fill")
            DetailMetricCard(label: "HRV", value: "56", unit: "ms", status: "elevated > 55", icon: "waveform.path.ecg")
        }
        .padding()
    }
}
