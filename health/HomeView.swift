import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject var ble: BluetoothManager
    @Query var allReadings: [HeartRateEntry]

    init() {
        _ble = StateObject(wrappedValue: BluetoothManager(modelContext: nil))
    }
     
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 32) {
                        HStack(spacing: 14) {
                            MetricRing(title: "SLEEP", value: "81%", color: .blue)
                            MetricRing(title: "RECOVERY", value: "89%", color: .green)
                            MetricRing(title: "STRAIN", value: "4.3", color: .orange)
                        }
                        .padding(.top)

                        VStack(alignment: .leading, spacing: 16) {
                            Text("My Day").font(.title2).bold().foregroundColor(.white)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                NavigationLink(destination: HealthMonitorView(ble: ble)) {
                                    MonitorCard(title: "HEALTH MONITOR", subtitle: "LIVE", icon: "checkmark.seal.fill", iconColor: .green)
                                }
                                // Inside the LazyVGrid in HomeView.swift
                                NavigationLink(destination: StressMonitorView(ble: ble)) {
                                    MonitorCard(
                                        title: "STRESS MONITOR",
                                        subtitle: ble.stressScore < 1.0 ? "LOW" : (ble.stressScore < 2.0 ? "MODERATE" : "HIGH"),
                                        icon: "bolt.fill",
                                        iconColor: ble.stressScore < 1.0 ? .blue : (ble.stressScore < 2.0 ? .orange : .red)
                                    )
                                }
                                NavigationLink(destination: DataHistoryView()) {
                                    MonitorCard(title: "ALL DATA", subtitle: "\(allReadings.count) READINGS", icon: "list.bullet.rectangle.portrait", iconColor: .orange)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            // In HomeView.swift
            // Inside HomeView.swift
            .onAppear {
                // 1. Link the database context
                ble.updateContext(modelContext)
                
                // 2. Trigger a scan if it didn't start automatically
                if !ble.isConnected && ble.status != "Scanning for Whoop..." {
                    ble.startScanning()
                }
            }
        }
    }
}
