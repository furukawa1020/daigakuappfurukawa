# University OS (DaigakuOS) - Installation Guide

This project is a native Android application built with **Jetpack Compose** and **Room Database**.

## Prerequisites
- **Android Studio** (Hedgehog or newer recommended)
- **Android Device** (Android 8.0 Oreo / API 26 or higher)
- **USB Cable** (for real device debugging)

## How to Install on Real Device

Since this project was generated from scratch, it needs to be initialized by Android Studio to download the Gradle Wrapper and SDK dependencies.

1. **Open Android Studio**.
2. Select **Open** and navigate to:
   `c:\Users\hatake\OneDrive\画像\デスクトップ\.vscode\daigakuOSfurukawa`
3. Wait for the **Gradle Sync** to complete.
   - *Note: Android Studio might ask to update the Gradle plugin or download SDK 34. Accept these.*
4. **Enable USB Debugging** on your Android phone:
   - Settings > About Phone > Tap "Build Number" 7 times.
   - Settings > System > Developer Options > Enable "USB Debugging".
5. **Connect your phone** via USB.
   - Accept the "Allow USB Debugging" prompt on the phone screen.
6. In Android Studio, select your device from the dropdown menu in the toolbar.
7. Click the green **Run** button (▶).

## Troubleshooting

### "SDK Location not found"
Create a file named `local.properties` in the project root with the path to your SDK:
```properties
sdk.dir=C:\\Users\\hatake\\AppData\\Local\\Android\\Sdk
```
(Android Studio usually does this automatically).

### "Geofencing not working"
- Ensure you grant **"Allow all the time"** location permission when prompted.
- Geofencing requires you to actually move (or simulate movement) across the boundary.

## Architecture

- **Domain**: `PointCalculator.kt` (Calculates scores based on your formula)
- **Data**: `AppDatabase` (Room), `GeofenceManager` (Location)
- **UI**: Jetpack Compose (`HomeScreen`, `NowScreen`)

## License
Private / Personal Use (Furukawa Only)
