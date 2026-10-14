import SwiftUI
import Charts

struct HealthMonitorView: View {
    @ObservedObject var ble: BluetoothManager
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        ZStack { 
            Color.black.edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading) {
                        Text("HEART RATE")
                            .font(.caption).bold().foregroundColor(.gray)
                        
                        HStack(alignment: .bottom) {
                            // Displays live HR from the manager
                            Text("\(ble.heartRate)")
                                .font(.system(size: 60, weight: .bold))
                            Text("BPM")
                                .font(.headline).foregroundColor(.gray).padding(.bottom, 10)
                            
                            Spacer()
                            
                            // UPDATED: Dynamic Status Indicator
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(ble.isConnected ? .green : .red) // Changes color based on actual connection
                                    .frame(width: 8, height: 8)
                                
                                Text(ble.isConnected ? "LIVE" : "DISCONNECTED") // Changes text based on actual connection
                                    .font(.caption2)
                                    .foregroundColor(.gray)
                            }
                            .padding(.bottom, 12)
                        }
                        
                        // Live Chart
                        Chart(ble.hrHistory) { entry in
                            LineMark(
                                x: .value("Time", entry.timestamp),
                                y: .value("BPM", entry.bpm)
                            )
                            .interpolationMethod(.catmullRom)
                            .foregroundStyle(.blue)
                        }
                        .frame(height: 150)
                        .chartYScale(domain: 40...180)
                    }
                    .padding()
                    
                    // Inside HealthMonitorView.swift
                    LazyVGrid(columns: gridItems, spacing: 12) {
                        // In HealthMonitorView.swift
                        // Inside HealthMonitorView.swift
                        NavigationLink(destination: LiveBreathingView(ble: ble)) {
                            DetailMetricCard(
                                label: "RESPIRATORY RATE",
                                value: String(format: "%.1f", ble.calculateRespiratoryRate()),
                                unit: "rpm",
                                status: "LIVE VIEW", // Changed status to invite the click
                                icon: "wind"
                            )
                        }
                        .buttonStyle(PlainButtonStyle()) // Keeps the card looking like a card
                        DetailMetricCard(label: "BLOOD OXYGEN (SPO2)", value: "95", unit: "%", status: "within 95% - 100%", icon: "drop.fill")
                        // In HealthMonitorView.swift
                        DetailMetricCard(
                            label: "RHR",
                            value: "\(ble.calculateRHR())", // NEW: Dynamic RHR calculation
                            unit: "bpm",
                            status: ble.calculateRHR() < 60 ? "optimal" : "within range",
                            icon: "heart.fill"
                        )
                        // UPDATED: Now uses the live 30-day average from your manager
                        DetailMetricCard(
                            label: "HRV",
                            value: "\(ble.getThirtyDayHRVAverage())",
                            unit: "ms",
                            status: "30-day avg",
                            icon: "waveform.path.ecg"
                        )
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("HEALTH MONITOR")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Triggers a scan if the app lost the connection in the background
            if !ble.isConnected {
                ble.startScanning()
            }
        }
    }
}
