import SwiftUI
import SwiftData

struct DataHistoryView: View {
    @Query(sort: \HeartRateEntry.timestamp, order: .reverse) var allReadings: [HeartRateEntry]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(allReadings) { entry in
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(entry.bpm) BPM").font(.headline)
                        Text(entry.timestamp.formatted()).font(.caption).foregroundColor(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets { modelContext.delete(allReadings[index]) }
            }
        }
        .navigationTitle("History")
    } 
}
