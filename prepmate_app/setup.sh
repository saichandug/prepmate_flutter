#!/bin/sh
# One-time setup for macOS/Linux. Run from the prepmate_app folder.
set -e

flutter create --platforms=android,ios,web --project-name prepmate_app .

MANIFEST="android/app/src/main/AndroidManifest.xml"
if [ -f "$MANIFEST" ] && ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  sed -i.bak 's#\(<manifest[^>]*>\)#\1\n    <uses-permission android:name="android.permission.INTERNET"/>#' "$MANIFEST"
  rm -f "$MANIFEST.bak"
  echo "Added INTERNET permission to AndroidManifest.xml"
fi

flutter pub get
echo "Done. Run the app with:  flutter run"
