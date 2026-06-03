# Workaround for Flutter Windows PathExistsException bug
# Always clean stale build artifacts before building
Write-Host "Cleaning build directory..." -ForegroundColor Yellow
if (Test-Path .\build) { Remove-Item -Recurse -Force .\build }
Write-Host "Building debug APK..." -ForegroundColor Green
flutter build apk --debug
