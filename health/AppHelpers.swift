import SwiftUI

// 1. Explicit data model for the chart to fix the 'Inferred' error
struct StressPoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let score: Double
}

// 2. Custom Shape to fix 'topLeft' and 'topRight' errors
struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(roundedRect: rect, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
        return Path(path.cgPath)
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
