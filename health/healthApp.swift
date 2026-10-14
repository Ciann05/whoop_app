import SwiftUI
import SwiftData

@main
struct healthApp: App {
    // Initialize the database container for HeartRateEntry
    var container: ModelContainer = {
        let schema = Schema([HeartRateEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try! ModelContainer(for: schema, configurations: [config])
    }()

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(container) // Provides the database context to the whole app
    } 
}
