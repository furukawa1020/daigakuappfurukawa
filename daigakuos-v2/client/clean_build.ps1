$projectPath = "c:\Users\hatake\OneDrive\画像\デスクトップ\.vscode\daigakuOSfurukawa\daigakuos-v2\client"
cd $projectPath

Write-Host "Cleaning project..."
& "C:\Users\hatake\Downloads\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat" clean

Write-Host "Removing pubspec.lock..."
if (Test-Path pubspec.lock) { Remove-Item pubspec.lock -Force }

Write-Host "Running pub get..."
& "C:\Users\hatake\Downloads\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat" pub get

Write-Host "Building..."
& "C:\Users\hatake\Downloads\flutter_windows_3.38.5-stable\flutter\bin\flutter.bat" run -d emulator-5554
