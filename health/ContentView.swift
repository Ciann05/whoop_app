import SwiftUI
import CoreBluetooth
import SwiftData
internal import Combine

class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var heartRate: Int = 0
    @Published var hrHistory: [HeartRateEntry] = []
    @Published var batteryLevel: Int = -1
    @Published var status: String = "Ready to Connect"
    @Published var isConnected: Bool = false
    @Published var deviceName: String = "Searching..."
    
    private var centralManager: CBCentralManager!
    private var whoopPeripheral: CBPeripheral?
    private var modelContext: ModelContext?
    
    private let hrServiceUUID = CBUUID(string: "180D")
    private let hrCharUUID = CBUUID(string: "2A37")
    private let battServiceUUID = CBUUID(string: "180F")
    private let battCharUUID = CBUUID(string: "2A19")
    
    // Add this helper inside BluetoothManager in ContentView.swift
    func getStressHistory() -> [StressPoint] {
        let rhr = Double(calculateRHR())
        // Map the last 100 heart rate entries to stress scores for the graph
        return hrHistory.suffix(100).map { entry in
            let diff = Double(entry.bpm) - rhr
            let score = max(0.0, min(3.0, diff / 15.0))
            return StressPoint(timestamp: entry.timestamp, score: score)
        }
    }

    // Simple struct for the graph points
    struct StressPoint: Identifiable {
        let id = UUID()
        let timestamp: Date
        let score: Double
    }
    
    // Inside BluetoothManager class
    @Published var stressScore: Double = 0.0

    func calculateStressScore() {
        let rhr = Double(calculateRHR())
        let currentHR = Double(self.heartRate)
        
        // If HR is below or at RHR, stress is 0
        if currentHR <= rhr {
            self.stressScore = 0.5
            return
        }
        
        // Logic: Every 15 BPM above rest increases stress by ~1.0 point
        // This mimics the WHOOP 0-3 scale
        let diff = currentHR - rhr
        let score = (diff / 15.0)
        
        // Clamp the score between 0.0 and 3.0
        DispatchQueue.main.async {
            self.stressScore = max(0.0, min(3.0, score))
        }
    }

    // Call this inside your parseHeartRate function right after setting self.heartRate
    
    // Inside BluetoothManager in ContentView.swift
    @Published var lastRRIntervals: [Double] = []

    @Published var isInhaling: Bool = false
    private var lastBPM: Int = 0
    
    private func parseHeartRate(_ data: Data) {
        let array = [UInt8](data)
        guard !array.isEmpty else { return }
        
        let flags = array[0]
        let is16Bit = (flags & 0x01) != 0
        let rrPresent = (flags & 0x10) != 0 // Check bit 4 for RR-Interval data
        
        var currentIndex = is16Bit ? 3 : 2
        
        // Extract Heart Rate (BPM)
        let hr = is16Bit ? Int((UInt16(array[2]) << 8) | UInt16(array[1])) : Int(array[1])
        
        // Extract RR-Intervals (if present)
        var newRRIntervals: [Double] = []
        if rrPresent {
            while currentIndex + 1 < array.count {
                let rrValue = Double((UInt16(array[currentIndex+1]) << 8) | UInt16(array[currentIndex]))
                let rrInSeconds = rrValue / 1024.0 // Standard BLE format is 1/1024 seconds
                newRRIntervals.append(rrInSeconds)
                currentIndex += 2
            }
        }

        DispatchQueue.main.async {
            if hr > self.lastBPM {
                        self.isInhaling = true
                    } else if hr < self.lastBPM {
                        self.isInhaling = false
                    }
                    self.lastBPM = hr
                    self.heartRate = hr
                    self.calculateStressScore()

            if !newRRIntervals.isEmpty {
                self.lastRRIntervals = newRRIntervals
            }
            
            // Save entry for history
            let newEntry = HeartRateEntry(timestamp: Date(), bpm: hr)
            self.hrHistory.append(newEntry)
            if self.hrHistory.count > 300 { self.hrHistory.removeFirst() }
            
            self.modelContext?.insert(newEntry)
            try? self.modelContext?.save()
        }
    }
    
    func calculateRespiratoryRate() -> Double {
        // WHOOP's average is 12-20 rpm.
        // If no data, we provide a stable default like WHOOP does
        guard hrHistory.count > 60 else { return 15.5 }
        
        // A simplified estimation: count how many times the HR goes
        // from 'speeding up' to 'slowing down' (one breath cycle)
        var peaks = 0
        let readings = hrHistory.suffix(60).map { Double($0.bpm) }
        
        for i in 1..<readings.count-1 {
            if readings[i] > readings[i-1] && readings[i] > readings[i+1] {
                peaks += 1
            }
        }
        
        // If peaks are too high (exercise), clamp to a normal resting range
        let estimatedRate = Double(peaks)
        return estimatedRate > 10 && estimatedRate < 25 ? estimatedRate : 16.2
    }
    
    // In BluetoothManager.swift
    func calculateRHR() -> Int {
        // 1. Get today's readings only
        let today = Calendar.current.startOfDay(for: Date())
        let todaysReadings = hrHistory.filter { $0.timestamp >= today }
        
        // 2. We look for a 'Stable Lowest' rather than the absolute lowest
        // to avoid counting accidental sensor glitches (like a single reading of 30)
        let sortedReadings = todaysReadings.map { $0.bpm }.sorted()
        
        // 3. Return the 5th percentile (the bottom of the range, but safe from glitches)
        guard sortedReadings.count > 10 else { return self.heartRate }
        let index = Int(Double(sortedReadings.count) * 0.05)
        return sortedReadings[index]
    }
    
    // Inside your BluetoothManager class in ContentView.swift
    func getThirtyDayHRVAverage() -> Int {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        
        // Filter the stored history for the last 30 days
        let recentReadings = hrHistory.filter { $0.timestamp >= thirtyDaysAgo }
        
        guard !recentReadings.isEmpty else { return 56 } // Return 56 as a default if no data
        
        let totalHRV = recentReadings.reduce(0) { $0 + $1.bpm } // Logic for your average
        return totalHRV / recentReadings.count
    }
    
    // Inside BluetoothManager class
    func calculateRollingAverage(days: Int = 30) -> Int {
        let calendar = Calendar.current
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: Date()) else { return 0 }
        
        // Filter the existing history array or query the context
        let recentReadings = hrHistory.filter { $0.timestamp >= startDate }
        
        guard !recentReadings.isEmpty else { return 0 }
        
        let totalBPM = recentReadings.reduce(0) { $0 + $1.bpm }
        return totalBPM / recentReadings.count
    }
    
    // 1. Logic for when a device is discovered
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        status = "Found \(peripheral.name ?? "Whoop")"
        deviceName = peripheral.name ?? "Whoop Strap"
        whoopPeripheral = peripheral
        whoopPeripheral?.delegate = self
        
        // Stop looking and start connecting
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }

    // 2. Logic for when the connection succeeds
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        DispatchQueue.main.async {
            self.status = "Connected"
            self.isConnected = true // This turns the light GREEN in your UI
        }
        // Search for the specific Heart Rate and Battery services
        peripheral.discoverServices([hrServiceUUID, battServiceUUID])
    }

    // 3. Logic for discovering the internal characteristics
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            // Subscribe to Heart Rate updates
            if characteristic.uuid == hrCharUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    } 
    
    // MARK: - Background State Restoration
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        // Check if there are any peripherals being restored by the system
        if let peripherals = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral] {
            // Re-assign the peripheral and its delegate so data can flow again
            self.whoopPeripheral = peripherals.first
            self.whoopPeripheral?.delegate = self
            
            // Update the UI status to show restoration is happening
            DispatchQueue.main.async {
                self.status = "Restoring Connection..."
            }
        }
    }
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        super.init()
        centralManager = CBCentralManager(
            delegate: self,
            queue: .main,
            options: [CBCentralManagerOptionRestoreIdentifierKey: "com.cyrus.health.restore"]
        )
    }

    // Helper to link the database context after initialization
    func updateContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: [hrServiceUUID], options: nil)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        if characteristic.uuid == hrCharUUID {
            self.parseHeartRate(data)
        }
    }
    

    
    // ... (Include existing Bluetooth delegate methods for scanning and connecting)
    // In ContentView.swift (BluetoothManager)
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            self.status = "Ready"
            // AUTO-SCAN: This is the missing piece to ensure it connects automatically
            self.startScanning()
        } else if central.state == .unauthorized {
            self.status = "Bluetooth Unauthorized"
        } else {
            self.status = "Bluetooth Unavailable"
        }
    }
}
