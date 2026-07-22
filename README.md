# flutter_login

An OAuth2 login widget for Flutter, built on top of Sisitech packages (`flutter_auth`, `flutter_form`, `flutter_utils`). Provides a ready-to-use login form with support for offline login, custom form fields, and internationalization.

## Installation

Add `flutter_login` and its sibling packages as git dependencies in your `pubspec.yaml`:

```yaml
dependencies:
  flutter_login:
    git:
      url: git@github.com:sisitech/flutter_login.git

  flutter_auth:
    git:
      url: git@github.com:sisitech/flutter_auth.git

  flutter_utils:
    git:
      url: git@github.com:sisitech/flutter_utils.git

  flutter_form:
    git:
      url: git@github.com:sisitech/flutter-forms.git

  get: ^4.6.5
  get_storage: ^2.1.1
```

## Setup

Before using `LoginWidget`, register the required dependencies with GetX. This is typically done in your `main()` function:

```dart
import 'package:flutter_auth/flutter_auth_controller.dart';
import 'package:flutter_login/login_utils.dart';
import 'package:flutter_utils/models.dart';
import 'package:flutter_utils/network_status/network_status_controller.dart';
import 'package:flutter_utils/offline_http_cache/offline_http_cache.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  // 1. Configure the API
  Get.put<APIConfig>(APIConfig(
    apiEndpoint: "https://your-api.example.com",
    version: "api/v1",
    clientId: "your-client-id",
    tokenUrl: 'o/token/',
    grantType: "password",
    revokeTokenUrl: 'o/revoke_token/',
  ));

  // 2. Initialize storage
  await GetStorage.init();
  await GetStorage.init(offline_login_storage_container); // Required for offline login

  // 3. Register controllers
  Get.put(NetworkStatusController());
  Get.put(OfflineHttpCacheController());
  Get.lazyPut(() => AuthController());

  runApp(const MyApp());
}
```

Use `GetMaterialApp` instead of `MaterialApp` in your app widget:

```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'My App',
      home: MyHomePage(),
    );
  }
}
```

## Usage

Use `LoginWidget` and observe `AuthController.isAuthenticated$` to switch between login and authenticated views:

```dart
import 'package:flutter_auth/flutter_auth_controller.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:get/get.dart';

class MyHomePage extends StatelessWidget {
  final AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() => authController.isAuthenticated$.value
          ? Center(child: Text("Logged in"))
          : LoginWidget(),
      ),
    );
  }
}
```

## Parameters

| Parameter | Type | Default | Description |
|---|---|---|---|
| `onLoginChange` | `Function?` | `null` | Callback invoked after a successful login (both online and offline). Receives the login response. |
| `enableOfflineLogin` | `bool` | `false` | Enables offline login using previously saved credentials. |
| `override_options` | `Map<String, dynamic>?` | `null` | Custom form schema to replace the default username/password fields. |

## Offline Login

When `enableOfflineLogin` is set to `true`, the widget will:

1. Save encrypted credentials on the first successful online login.
2. Allow the user to log in offline using those saved credentials.
3. Validate the offline credentials against the stored username and password.

```dart
LoginWidget(
  enableOfflineLogin: true,
  onLoginChange: (res) async {
    // Navigate or update state after login
  },
)
```

The user can also lock/unlock the session via `AuthController`:

```dart
AuthController authController = Get.find<AuthController>();
await authController.lock();   // Lock the session
await authController.unlock(); // Unlock with offline credentials
await authController.logout(); // Full logout
```

## Custom Form Fields

Use `override_options` to customize the login form schema. The schema follows the `flutter_form` OPTIONS format:

```dart
const customOptions = {
  "name": "Login",
  "description": "",
  "renders": ["application/json", "text/html"],
  "parses": [
    "application/json",
    "application/x-www-form-urlencoded",
    "multipart/form-data"
  ],
  "actions": {
    "POST": {
      "username": {
        "type": "string",
        "required": true,
        "read_only": false,
        "label": "Username",
        "max_length": 45,
        "placeholder": ""
      },
      "password": {
        "type": "string",
        "required": true,
        "read_only": false,
        "label": "Password",
        "obscure": true,
        "max_length": 25
      }
    }
  }
};

LoginWidget(
  override_options: customOptions,
)
```

## Internationalization

The widget supports translations via GetX's `.tr` extension. Add translations for the following keys in your `Translations` class:

```dart
class AppTranslations extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'en_US': {
      'Login': 'Login',
      'Username': 'Username',
      'Password': 'Password',
      'Signing in...': 'Signing in...',
      'Your password might be wrong': 'Your password might be wrong',
      'No offline credentials found': 'No offline credentials found',
      'Confirm username and password': 'Confirm username and password',
    },
    'swa_KE': {
      'Login': 'Ingia',
      'Username': 'Kitambulisho',
      'Password': 'Neno Siri',
      'Signing in...': 'Naingia...',
      'Your password might be wrong': 'Kuna uwezo umekose neno siri lako',
    },
  };
}
```

Then set the locale in `GetMaterialApp`:

```dart
GetMaterialApp(
  translations: AppTranslations(),
  locale: const Locale('en', 'US'),
  // ...
)
```

## Dependencies

- [flutter_auth](https://github.com/sisitech/flutter_auth) - Authentication controller and token management
- [flutter_form](https://github.com/sisitech/flutter-forms) - Dynamic form generation from OPTIONS schema
- [flutter_utils](https://github.com/sisitech/flutter_utils) - API configuration, network utilities, and helpers
- [get](https://pub.dev/packages/get) - State management and dependency injection
- [get_storage](https://pub.dev/packages/get_storage) - Local storage for credentials and tokens
