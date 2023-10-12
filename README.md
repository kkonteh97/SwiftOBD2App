# OBD2 Swift App

Welcome to the OBD2 Swift App! This app will allow you to read error codes and view Parameter IDs (PIDs) from your vehicle's OBD2 system using Swift and CoreBluetooth.
<div style="width:60px ; height:60px">
![IMG_1826](https://github.com/kkonteh97/SmartOBD2/assets/55326260/3449cc92-82eb-4dc5-a31d-a7008758740e)
<div>
<div style="width:60px ; height:60px">
![IMG_1827](https://github.com/kkonteh97/SmartOBD2/assets/55326260/52dbd5d4-261c-43da-9e74-69b3bca8b01d)
</div>
<div style="width:60px ; height:60px">
![IMG_1828](https://github.com/kkonteh97/SmartOBD2/assets/55326260/f3dd2720-f4c9-40ed-a197-4b44e5afe3a7)
</div>


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

