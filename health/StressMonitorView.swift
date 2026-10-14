import SwiftUI
import Charts
import SwiftData

struct StressMonitorView: View {
    @ObservedObject var ble: BluetoothManager
    // Fetch all heart rate entries from SwiftData
    @Query(sort: \HeartRateEntry.timestamp, order: .forward) var allReadings: [HeartRateEntry]
    
    // Fixed X-Axis for the full day (12 AM to 11:59 PM)
    var dayBounds: ClosedRange<Date> {
        let start = Calendar.current.startOfDay(for: Date())
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!.addingTimeInterval(-1)
        return start...end
    }
    let stressGradient = LinearGradient(
        stops: [
            .init(color: .blue, location: 0.1),    // Low Stress
            .init(color: .orange, location: 1.5),  // Moderate Stress
            .init(color: .red, location: 2.3)     // High Stress
        ],
        startPoint: .bottom,
        endPoint: .top
    )

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Stress Gauge
                currentStressGauge
                
                Spacer()

                // Middle: High-Precision Line Graph
                VStack(alignment: .leading) {
                    Text("STRESS TREND")
                        .font(.caption).bold().foregroundColor(.gray)
                        .padding(.leading)
                    
                    Chart {
                        ForEach(todaysStressPoints) { point in
                            // Smoothly colored "Glow"
                            AreaMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Stress", point.score)
                            )
                            .foregroundStyle(stressGradient.opacity(0.2)) // Faded version of the gradient
                            .interpolationMethod(.catmullRom)
                            
                            // The Thin, Smoothly Changing Line
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Stress", point.score)
                            )
                            .foregroundStyle(stressGradient) // Applies the color based on height
                            .lineStyle(StrokeStyle(lineWidth: 1.2)) // Thinner line as requested
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .frame(height: 250)
                    .chartYScale(domain: 0...3.0)
                    .chartXScale(domain: dayBounds)
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                            AxisGridLine().foregroundStyle(.white.opacity(0.1))
                            AxisValueLabel(format: .dateTime.hour())
                        }
                    }
                    .padding()
                }
                
                Spacer()

                // Info Section using custom corner modifier
                infoSection
            }
        }
        .foregroundColor(.white)
        .navigationTitle("STRESS")
    }
    
    var todaysStressPoints: [StressPoint] {
        let rhr = 55.0
        let startOfToday = Calendar.current.startOfDay(for: Date())
        let readings = allReadings.filter { $0.timestamp >= startOfToday }
        
        // Grouping by 5-minute intervals to prevent the "bar" look
        let grouped = Dictionary(grouping: readings) { entry in
            let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: entry.timestamp)
            let minute = (components.minute ?? 0) / 5 * 5
            return Calendar.current.date(bySettingHour: components.hour ?? 0, minute: minute, second: 0, of: startOfToday)!
        }
        
        return grouped.map { (date, entries) in
            let avgBPM = Double(entries.reduce(0) { $0 + $1.bpm }) / Double(entries.count)
            let diff = avgBPM - rhr
            let score = max(0.0, min(3.0, diff / 15.0))
            return StressPoint(timestamp: date, score: score)
        }.sorted { $0.timestamp < $1.timestamp }
    }

    private var currentStressGauge: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.1), lineWidth: 15).frame(width: 140, height: 140)
            Circle()
                .trim(from: 0, to: ble.stressScore / 3.0)
                .stroke(stressColor, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))
            VStack {
                Text(String(format: "%.1f", ble.stressScore)).font(.system(size: 40, weight: .bold))
                Text(stressLabel).font(.caption2).bold().foregroundColor(stressColor)
            }
        }.padding(.top, 20)
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "bolt.shield.fill").foregroundColor(.orange)
                Text("Physiological Stress").font(.headline)
            }
            Text("This data reflects sympathetic nervous system activity derived from your heart rate history.")
                .font(.footnote).foregroundColor(.gray)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.05))
        .cornerRadius(24, corners: [.topLeft, .topRight]) // Error fixed by helper above
    }

    var stressColor: Color {
        ble.stressScore < 1.0 ? .blue : (ble.stressScore < 2.0 ? .orange : .red)
    }
    
    var stressLabel: String {
        ble.stressScore < 1.0 ? "LOW" : (ble.stressScore < 2.0 ? "MODERATE" : "HIGH")
    }
}
