import SwiftUI

struct LiveBreathingView: View {
    @ObservedObject var ble: BluetoothManager
    
    var body: some View {
        VStack(spacing: 40) {
            Text(ble.isInhaling ? "Breathe In" : "Breathe Out")
                .font(.title).bold()
                .foregroundColor(ble.isInhaling ? .blue : .green)
            
            ZStack {
                // Outer glow
                Circle()
                    .fill(ble.isInhaling ? Color.blue.opacity(0.3) : Color.green.opacity(0.3))
                    .frame(width: 250, height: 250)
                    .scaleEffect(ble.isInhaling ? 1.2 : 0.8)
                
                // Main Lung Circle
                Circle()
                    .fill(LinearGradient(colors: ble.isInhaling ? [.blue, .cyan] : [.green, .mint],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 200, height: 200)
                    .scaleEffect(ble.isInhaling ? 1.1 : 0.9)
                
                Image(systemName: "wind")
                    .font(.system(size: 60))
                    .foregroundColor(.white)
            }
            .animation(.easeInOut(duration: 1.5), value: ble.isInhaling)
            
            Text("\(String(format: "%.1f", ble.calculateRespiratoryRate())) RPM")
                .font(.headline).foregroundColor(.gray)
        }
        .navigationTitle("Live Breathing")
    }
}
