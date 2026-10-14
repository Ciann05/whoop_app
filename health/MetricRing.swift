import SwiftUI

struct MetricRing: View {
    let title: String
    let value: String
    let color: Color
 
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progressAmount(from: value))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(width: 90, height: 90)

            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
        }
    }

    // Attempts to derive a 0...1 progress from a value string like "81%" or "4.3"
    private func progressAmount(from value: String) -> CGFloat {
        // If it ends with %, treat as percentage
        if value.hasSuffix("%") {
            let number = value.dropLast()
            if let pct = Double(number) {
                return max(0, min(1, pct / 100.0))
            }
        }
        // Otherwise, try to map a numeric value to a nominal range (e.g., strain 0-21)
        if let numeric = Double(value) {
            // Heuristic: assume 0...21 (WHOOP strain range); clamp to 0...1
            return max(0, min(1, numeric / 21.0))
        }
        return 0
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        HStack(spacing: 20) {
            MetricRing(title: "SLEEP", value: "81%", color: .blue)
            MetricRing(title: "RECOVERY", value: "89%", color: .green)
            MetricRing(title: "STRAIN", value: "4.3", color: .orange)
        }
        .padding()
    }
}
