# Build Configuration Guide

## Build Environment Setup

This Android project requires specific configuration for successful builds.

### Prerequisites

1. **Android SDK** - Must be installed and configured
2. **Java/JDK** - JDK 17 or compatible version
3. **Network Access** - Access to Google's Maven repository (`dl.google.com`) is required for downloading Android Gradle Plugin and dependencies

### Configuration Files

#### 1. `local.properties` (Not in version control)
Create this file in the project root with your Android SDK location:
```properties
sdk.dir=/path/to/your/Android/Sdk
```

Example paths:
- Windows: `C:\\Users\\{username}\\AppData\\Local\\Android\\Sdk`
- Linux: `/home/{username}/Android/Sdk` or `/usr/local/lib/android/sdk`
- macOS: `/Users/{username}/Library/Android/sdk`

#### 2. `gradle.properties` (Not in version control)
Create this file in the project root:
```properties
android.overridePathCheck=true
android.useAndroidX=true
org.gradle.jvmargs=-Xmx4G -Dfile.encoding=UTF-8
```

Optionally, you can specify a custom JDK path:
```properties
org.gradle.java.home=/path/to/your/jdk
```

### Building the Project

#### Using Android Studio (Recommended)
1. Open Android Studio
2. Open the project directory
3. Wait for Gradle sync to complete
4. Build > Make Project or Run the app

#### Using Command Line
```bash
# Using gradlew (if wrapper is configured)
./gradlew build

# Or using system gradle
gradle build
```

### Common Build Issues

#### Issue: "SDK Location not found"
**Solution**: Create `local.properties` file with correct `sdk.dir` path

#### Issue: "Could not resolve com.android.tools.build:gradle"  
**Solution**: Ensure you have network access to `dl.google.com` (Google's Maven Repository)
- This domain hosts Android Gradle Plugin and Android dependencies
- Corporate/restricted networks may block this domain
- Alternative: Use Android Studio which handles downloads better

#### Issue: "Plugin [id: 'com.android.application'] was not found"
**Solution**: The Android Gradle Plugin requires access to Google's Maven repository
- Verify network connectivity to `maven.google.com` and `dl.google.com`
- Check firewall/proxy settings
- In restricted environments, consider using a proxy or VPN

### Repository Configuration

The project uses these repositories:
- **Google Maven**: `https://maven.google.com` (redirects to `dl.google.com`)
- **Maven Central**: `https://repo1.maven.org/maven2/`

If you're in a restricted network environment, you may need to:
1. Configure a proxy in `gradle.properties`
2. Use a mirror repository (e.g., Aliyun mirror for China)
3. Request network administrator to whitelist `dl.google.com`

### Dependencies

Key dependencies and their versions:
- Android Gradle Plugin: 8.5.1+ (from Google Maven)
- Kotlin: 1.9.0+ (from Maven Central)
- Hilt (Dependency Injection): 2.48
- Room (Database): 2.6.1
- Jetpack Compose: BOM 2023.08.00

All dependencies are declared in `build.gradle.kts` and `app/build.gradle.kts`.
