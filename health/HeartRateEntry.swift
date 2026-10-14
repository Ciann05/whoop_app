import Foundation
import SwiftData

@Model
final class HeartRateEntry: Identifiable {
    var timestamp: Date
    var bpm: Int

    init(timestamp: Date = .now, bpm: Int) {
        self.timestamp = timestamp
        self.bpm = bpm
    } 
}

// Example logic for your Data Manager
func calculateThirtyDayAverage(allReadings: [HeartRateEntry]) -> Double {
    let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
    
    // Filter for only the readings from the last 30 days
    let recentReadings = allReadings.filter { $0.timestamp >= thirtyDaysAgo }
    
    guard !recentReadings.isEmpty else { return 0.0 }
    
    let totalHRV = recentReadings.reduce(0.0) { $0 + Double($1.bpm) } // Or your calculated rMSSD
    return totalHRV / Double(recentReadings.count)
}
