# whoop_app

A SwiftUI app that connects to a WHOOP strap over Bluetooth and shows live heart rate, a stress estimate, breathing, and saved readings.

This is an independent project. It is not affiliated with WHOOP. The numbers on screen are estimates from heart-rate samples, not medical measurements.

## Features

- **Home.** Sleep, recovery, and strain rings, plus shortcuts into the monitors. Sleep, recovery, and strain are placeholder values.
- **Health Monitor.** Live heart rate (BPM), a connection indicator, and a chart of recent samples. Also shows estimated respiratory rate, resting heart rate, and a heart-rate average labeled HRV. Blood oxygen is a placeholder.
- **Stress Monitor.** A 0–3 stress score and an all-day trend. The score rises as heart rate sits above the day’s resting heart rate (about 1 point for every 15 BPM).
- **Live Breathing.** A breathing animation that follows whether heart rate is rising or falling, plus an estimated breaths-per-minute value.
- **History.** Every saved reading, newest first. Swipe a row to delete it.

Readings are stored on device with SwiftData and kept while the app runs in the background (`bluetooth-central`).

## Requirements

- Xcode with the iOS 26.2 SDK
- An iPhone (or iPad) with Bluetooth
- A WHOOP strap, or another heart-rate monitor that advertises the standard Bluetooth Heart Rate service (`180D`)

The app looks for the Heart Rate Measurement characteristic (`2A37`). The simulator has no Bluetooth radio, so use a physical device to see live data.

## Run

1. Open `health.xcodeproj` in Xcode.
2. Select the **health** scheme and your iPhone.
3. Trust the developer certificate on the phone if iOS asks.
4. Build and run.
5. Allow Bluetooth when prompted, then wear the strap. The app scans automatically and connects to the first heart-rate peripheral it finds.

Bundle identifier: `com.ciannamalan.health`.

## Project layout

```
health/
  healthApp.swift          App entry and SwiftData container
  ContentView.swift        Bluetooth scanning, connection, and metric estimates
  HomeView.swift           Home screen
  HealthMonitorView.swift  Live heart rate and metric cards
  StressMonitorView.swift  Stress gauge and daily trend
  LiveBreathingView.swift  Breathing animation
  DataHistory.swift        Saved readings list
  HeartRateEntry.swift     Stored heart-rate sample
  MetricRing.swift         Home rings
  MonitorCard.swift        Home cards
  DetailMetricCard.swift   Health Monitor cards
  AppHelpers.swift         Chart point type and corner helper
```

## How a reading is saved

1. Core Bluetooth scans for the Heart Rate service.
2. On connect, the app subscribes to heart-rate notifications.
3. Each notification is parsed for BPM (and RR intervals when the strap sends them).
4. The sample is appended to the in-memory history and inserted into SwiftData.

Stress, resting heart rate, respiratory rate, and the HRV card are all derived from those BPM samples. Resting heart rate is the 5th percentile of today’s readings, which avoids a single bad sample pulling the number down.
