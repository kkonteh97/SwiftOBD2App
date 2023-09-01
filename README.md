# OBD2 Swift App

Welcome to the OBD2 Swift App! This app will allow you to read error codes and view Parameter IDs (PIDs) from your vehicle's OBD2 system using Swift and CoreBluetooth.

## MileStones

- Connect to an OBD2 adapter via Bluetooth Low Energy (BLE) (completed)
- Retrieve error codes (DTCs) stored in the vehicle's OBD2 system (in progress...)
- View various OBD2 Parameter IDs (PIDs) for monitoring vehicle parameters (in progress...)
- Clean and intuitive user interface (in progress...)

## Current Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.5+

## Setup

1. Clone this repository to your local machine.
2. Open the Xcode project file (`SmartOBD2.xcodeproj`).
3. Build and run the app on a compatible iOS device.

## Usage

1. Launch the app on your iOS device.
2. Make sure your OBD2 adapter is powered on and discoverable.


## Async and Await

Write messages are sent to the adapter and using continuations operations are paused until the ecu characterics updates or timeouts after a designated time

