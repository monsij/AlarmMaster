# Alarm Master ⏰👑

A sleek iOS alarm app with a **master kill switch** to turn off all alarms instantly.

![iOS 16+](https://img.shields.io/badge/iOS-16%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![SwiftUI](https://img.shields.io/badge/SwiftUI-4.0-green)
![Built with Opus 4.5](https://img.shields.io/badge/Built%20with-Opus%204.5-purple)

## Features

- 🎯 **One-tap kill switch** - Disable all alarms instantly
- 📅 **Date & time scheduling** - Set alarms for specific days
- 🌙 **Dark theme** - Easy on the eyes
- 💾 **Persistent storage** - Alarms saved locally
- 🔔 **Native notifications** - Uses iOS notification system

## Screenshots

The app features a sleek dark interface with:
- A prominent master toggle at the top
- Clean alarm cards with swipe-to-delete
- Beautiful graphical date picker
- Smooth animations throughout

## Setup Instructions

### Option 1: Using XcodeGen (Recommended)

1. Install XcodeGen if you haven't:
   ```bash
   brew install xcodegen
   ```

2. Navigate to the project folder:
   ```bash
   cd ~/AlarmMaster
   ```

3. Generate the Xcode project:
   ```bash
   xcodegen generate
   ```

4. Open the project:
   ```bash
   open AlarmMaster.xcodeproj
   ```

### Option 2: Manual Xcode Setup

1. Open Xcode and create a new project:
   - Select **iOS > App**
   - Product Name: `AlarmMaster`
   - Interface: **SwiftUI**
   - Language: **Swift**

2. Delete the default `ContentView.swift` and `AlarmMasterApp.swift`

3. Drag and drop the files from `~/AlarmMaster/AlarmMaster/` into your Xcode project:
   - `AlarmMasterApp.swift`
   - `Models/Alarm.swift`
   - `Views/ContentView.swift`
   - `Views/AddAlarmView.swift`
   - `Views/AlarmRowView.swift`
   - `ViewModels/AlarmManager.swift`

4. Copy `Info.plist` contents to your project's Info tab or merge with existing plist

5. Build and run!

## Project Structure

```
AlarmMaster/
├── AlarmMasterApp.swift      # App entry point
├── Models/
│   └── Alarm.swift           # Alarm data model
├── Views/
│   ├── ContentView.swift     # Main screen with kill switch
│   ├── AddAlarmView.swift    # New alarm creation
│   └── AlarmRowView.swift    # Individual alarm card
├── ViewModels/
│   └── AlarmManager.swift    # Business logic & notifications
├── Assets.xcassets/          # App icons & colors
└── Info.plist                # Notification permissions
```

## How It Works

### Notifications
The app uses `UNUserNotificationCenter` to schedule local notifications that act as alarms. When you:
- **Create an alarm**: A notification is scheduled for that exact date/time
- **Toggle an alarm off**: The pending notification is cancelled
- **Hit the kill switch**: All pending notifications are cancelled

### Persistence
Alarms are stored in `UserDefaults` using `Codable` serialization, so they persist between app launches.

## Weather Feature Setup

The app includes a weather bar showing temperature and precipitation chance. To enable it:

1. Get a free API key from [OpenWeatherMap](https://openweathermap.org/api) (free tier available)
2. Create a `Config.plist` file in the `AlarmMaster/` folder:
   - Copy `Config.plist.example` to `Config.plist`
   - Replace `YOUR_API_KEY_HERE` with your actual API key
3. Add `Config.plist` to your Xcode project (make sure it's included in the target)

**Alternative:** You can also directly edit `WeatherService.swift` and replace `"YOUR_API_KEY_HERE"` with your API key (line 21).

**Note:** `Config.plist` is gitignored to keep your API key private.

## Requirements

- iOS 16.0+
- Xcode 15.0+
- Swift 5.9+

## Limitations

⚠️ **Important**: This app cannot control the built-in iOS Clock app alarms. It manages its own alarms using the notification system.

Notifications may not wake the device from sleep like the system Clock app does. For critical alarms, keep your device unlocked or use the built-in Clock app.

## License

MIT License - Feel free to use and modify!


