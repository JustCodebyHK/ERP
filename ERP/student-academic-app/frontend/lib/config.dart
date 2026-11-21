// Build-time configuration via --dart-define
// Set at build time: flutter build apk --dart-define=API_BASE_URL=https://your-app.onrender.com/api

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:4000/api');
const String apiBaseUrlNoPrefix = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:4000');