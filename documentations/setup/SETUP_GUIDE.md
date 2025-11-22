# Flutter Setup Guide

## Prerequisites

Before integrating the Django REST Framework API with your Flutter application, ensure you have:

- Flutter SDK (3.0 or higher)
- Dart SDK (3.0 or higher)
- Android Studio / VS Code with Flutter extensions
- Basic understanding of Flutter and Dart

## Step 1: Create Flutter Project

```bash
flutter create hotel_management_app
cd hotel_management_app
```

## Step 2: Add Required Dependencies

Add the following dependencies to your `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # HTTP Client
  dio: ^5.4.0
  
  # State Management (choose one)
  provider: ^6.1.1
  # OR
  # bloc: ^8.1.3
  # OR
  # riverpod: ^2.4.9
  
  # Local Storage
  shared_preferences: ^2.2.2
  flutter_secure_storage: ^9.0.0
  
  # Network Connectivity
  connectivity_plus: ^5.0.2
  
  # JSON Serialization
  json_annotation: ^4.8.1
  
  # Environment Variables
  flutter_dotenv: ^5.1.0
  
  # UI Components
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  
  # Utilities
  intl: ^0.19.0
  uuid: ^4.2.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  
  # Code Generation
  build_runner: ^2.4.7
  json_serializable: ^6.7.1
```

Run:
```bash
flutter pub get
```

## Step 3: Project Structure

Create the following folder structure:

```
lib/
├── main.dart
├── config/
│   ├── api_config.dart
│   └── app_config.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart
│   │   ├── api_service.dart
│   │   └── interceptors/
│   │       ├── auth_interceptor.dart
│   │       └── error_interceptor.dart
│   ├── models/
│   │   ├── user.dart
│   │   ├── order.dart
│   │   └── ...
│   ├── services/
│   │   ├── auth_service.dart
│   │   ├── storage_service.dart
│   │   └── ...
│   └── utils/
│       ├── error_handler.dart
│       └── validators.dart
├── features/
│   ├── auth/
│   │   ├── models/
│   │   ├── services/
│   │   ├── screens/
│   │   └── widgets/
│   ├── home/
│   ├── orders/
│   └── ...
└── shared/
    ├── widgets/
    └── themes/
```

## Step 4: Environment Configuration

Create a `.env` file in the root directory:

```env
API_BASE_URL=http://localhost:8000/api
API_TIMEOUT=30000
ENVIRONMENT=development
```

Create `lib/config/app_config.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';
  static int get apiTimeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
  static String get environment => dotenv.env['ENVIRONMENT'] ?? 'development';
  
  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
}
```

Load environment in `main.dart`:

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(MyApp());
}
```

## Step 5: Configure Android Permissions

Add to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
```

## Step 6: Configure iOS Permissions

Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Note:** For production, configure proper network security settings.

## Step 7: Initialize HTTP Client

See [HTTP_CLIENT_SETUP.md](./HTTP_CLIENT_SETUP.md) for detailed HTTP client configuration.

## Step 8: Set Up State Management

Choose a state management solution:

### Option 1: Provider

```dart
// main.dart
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: MyApp(),
    ),
  );
}
```

### Option 2: BLoC

```dart
// main.dart
import 'package:flutter_bloc/flutter_bloc.dart';

void main() {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthBloc()),
        BlocProvider(create: (_) => CartBloc()),
      ],
      child: MyApp(),
    ),
  );
}
```

## Step 9: Create Base Models

Create base model classes for API responses. See [API_SERVICE_EXAMPLE.dart](./API_SERVICE_EXAMPLE.dart) for examples.

## Step 10: Implement Authentication

See [AUTHENTICATION_EXAMPLE.dart](./AUTHENTICATION_EXAMPLE.dart) for complete authentication implementation.

## Step 11: Test API Connection

Create a simple test to verify API connectivity:

```dart
void testApiConnection() async {
  try {
    final response = await dio.get('${AppConfig.apiBaseUrl}/test/');
    print('API Connection: ${response.statusCode}');
  } catch (e) {
    print('API Connection Error: $e');
  }
}
```

## Step 12: Error Handling Setup

Implement global error handling. See [COMMON_ISSUES.md](./COMMON_ISSUES.md) for error handling patterns.

## Next Steps

1. **Configure HTTP Client** - Follow [HTTP_CLIENT_SETUP.md](./HTTP_CLIENT_SETUP.md)
2. **Implement Authentication** - Follow [AUTHENTICATION_EXAMPLE.dart](./AUTHENTICATION_EXAMPLE.dart)
3. **Create API Services** - Follow [API_SERVICE_EXAMPLE.dart](./API_SERVICE_EXAMPLE.dart)
4. **Review Examples** - Check [REQUEST_RESPONSE_EXAMPLES.md](./REQUEST_RESPONSE_EXAMPLES.md)

## Troubleshooting

### Common Issues

1. **Network Error**
   - Check internet connection
   - Verify API base URL
   - Check CORS settings on server

2. **SSL Certificate Error**
   - For development, allow insecure connections
   - For production, configure proper SSL certificates

3. **Build Errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check Dart version compatibility

See [COMMON_ISSUES.md](./COMMON_ISSUES.md) for more troubleshooting tips.

## Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dio Package](https://pub.dev/packages/dio)
- [Django REST Framework](https://www.django-rest-framework.org/)

---

**Ready to proceed?** Continue with [HTTP_CLIENT_SETUP.md](./HTTP_CLIENT_SETUP.md)

