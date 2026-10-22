/// Base URL of the PrepMate API (the Express + MongoDB backend).
///
/// Override at run/build time:
///   flutter run --dart-define=API_URL=http://10.0.2.2:5000     (Android emulator -> your PC)
///   flutter build web --dart-define=API_URL=https://your-api.example.com
const String apiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'https://prepmate-aity.onrender.com',
);
