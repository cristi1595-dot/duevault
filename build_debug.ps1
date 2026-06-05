# Workaround for Flutter 3.44.x Windows PathExistsException bug
# Only deletes the Flutter asset cache (not Kotlin/Gradle), keeping incremental builds fast
Write-Host "Clearing Flutter asset cache..." -ForegroundColor Yellow
if (Test-Path .\build\app\intermediates\flutter) {
    Remove-Item -Recurse -Force .\build\app\intermediates\flutter
}
Write-Host "Building debug APK..." -ForegroundColor Green
flutter build apk --debug
