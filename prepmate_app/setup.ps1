# One-time setup for Windows (PowerShell). Run from the prepmate_app folder.
# Generates the android/ios/web/windows platform folders, allows internet access
# on Android release builds, then installs packages.
$ErrorActionPreference = "Stop"

flutter create --platforms=android,ios,web,windows --project-name prepmate_app .

$manifest = "android/app/src/main/AndroidManifest.xml"
if (Test-Path $manifest) {
  $text = Get-Content $manifest -Raw
  if ($text -notmatch "android.permission.INTERNET") {
    $text = $text -replace '(<manifest[^>]*>)', "`$1`n    <uses-permission android:name=`"android.permission.INTERNET`"/>"
    Set-Content -Path $manifest -Value $text -NoNewline
    Write-Host "Added INTERNET permission to AndroidManifest.xml"
  }
}

flutter pub get
Write-Host "`nDone. Run the app with:  flutter run"
