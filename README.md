# OBD2 Swift App

Welcome to the OBD2 Swift App! This app allows you to read error codes and view Parameter IDs (PIDs) from your vehicle's OBD2 system using Swift and CoreBluetooth.

## Features

- Connect to an OBD2 adapter via Bluetooth Low Energy (BLE).
- Retrieve error codes (DTCs) stored in the vehicle's OBD2 system.
- View various OBD2 Parameter IDs (PIDs) for monitoring vehicle parameters.
- Clean and intuitive user interface.

## Requirements

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
3. In the app, navigate to the Home screen to read error codes and view PIDs.
4. Connect to your OBD2 adapter via Bluetooth.
5. Choose the desired functionality (read error codes, view PIDs, etc.).
6. View the results on the screen.

## Async and Await

The app uses Swift's async and await features to send commands to the OBD2 adapter asynchronously. This allows for responsive UI while communicating with the adapter. Here's how it works:

1. The `BLEManager` class provides asynchronous methods, such as `sendMessageAsync`, using async and await.
2. When you call these methods in your app, the execution is paused until the awaited task is completed.
3. Meanwhile, the UI remains responsive, and you can handle other tasks.
4. Once the awaited task completes (e.g., Bluetooth message sent and response received), the app continues executing from where it was paused.

For example:
```swift
func readErrorCodes() async {
    do {
        let response = try await bleManager.sendMessageAsync(message: "03")
        // Process the response, display error codes, etc.
    } catch {
        // Handle errors
    }
}

Contributing

Contributions are welcome! If you find any issues or have ideas for improvements, please feel free to submit a pull request or open an issue.


License

This project is licensed under the MIT License.
