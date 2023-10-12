# OBD2 Swift App

Welcome to the OBD2 Swift App! This app will allow you to read error codes and view Parameter IDs (PIDs) from your vehicle's OBD2 system using Swift and CoreBluetooth.

## current looK


https://github.com/kkonteh97/SmartOBD2/assets/55326260/fa31daaf-4f2d-4da9-9f6e-c27830d08980



## MileStones

- Connect to an OBD2 adapter via Bluetooth Low Energy (BLE) (completed)
- Retrieve error codes (DTCs) stored in the vehicle's OBD2 system (in progress...)
- View various OBD2 Parameter IDs (PIDs) for monitoring vehicle parameters (in progress...)
- Clean and intuitive user interface (in progress...)

## Current Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.5+

## Setup

1. Clone this repository to your local machine.
2. Navigate to project directory on the terminal
3. Run command "xcodegen"
4. Open the Xcode project file (`SmartOBD2.xcodeproj`).
5. Build and run the app on a compatible iOS device.

## Usage

1. Launch the app on your iOS device.
2. Make sure your OBD2 adapter is powered on and discoverable.


## Async and Await

Write messages are sent to the adapter and using continuations operations are paused until the ecu characterics updates or timeouts after a designated time

