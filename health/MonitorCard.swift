import SwiftUI

struct MonitorCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let iconColor: Color
 
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(iconColor)
                .padding(8)
                .background(.white.opacity(0.06), in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .textCase(.uppercase)

                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.4), radius: 10, x: 0, y: 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()

        VStack(spacing: 16) {
            MonitorCard(
                title: "Heart rate",
                subtitle: "69 BPM",
                icon: "heart.fill",
                iconColor: .red
            )
            MonitorCard(
                title: "Stress",
                subtitle: "Low",
                icon: "bolt.fill",
                iconColor: .yellow
            )
        }
        .padding()
    }
}
