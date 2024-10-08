import 'package:mixpanel_flutter/mixpanel_flutter.dart';
import 'package:example/options.dart';
import 'package:flutter/material.dart';
import 'package:flutter_auth/flutter_auth_controller.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:flutter_login/login_utils.dart';
import 'package:flutter_utils/models.dart';
import 'package:flutter_utils/network_status/network_status_controller.dart';
import 'package:flutter_utils/offline_http_cache/offline_http_cache.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import 'internalization/translate.dart';

void main() async {
  Get.put<APIConfig>(APIConfig(
      apiEndpoint: "https://dukapi.roometo.com",
      version: "api/v1",
      clientId: "NUiCuG59zwZJR14tIdWD7iQ5ILFnpxbdrO2epHIG",
      tokenUrl: 'o/token/',
      grantType: "password",
      revokeTokenUrl: 'o/revoke_token/'));
  await GetStorage.init();
  await GetStorage.init(offline_login_storage_container);
  Get.put(NetworkStatusController());
  Get.put(OfflineHttpCacheController());
  Get.lazyPut(() => AuthController());
  // StoreBinding();
  // WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class StoreBinding implements Bindings {
// default dependency
  @override
  void dependencies() {
    Get.lazyPut(() => AuthController());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // initialBinding: ,
      title: 'Flutter Demo',
      translations: AppTranslations(),
      locale: const Locale('swa', 'KE'),
      theme: ThemeData(
        useMaterial3: true,
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatelessWidget {
  late String title;

  AuthController authController = Get.find<AuthController>();

  MyHomePage({super.key, this.title = "Hello world !"});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Obx(() => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (authController.isAuthenticated$.value) ...[
                HomePage(),
              ] else
                LoginWidget(
                  enableOfflineLogin: true,
                  override_options: options,
                ),
            ],
          )),
    );
  }
}

class HomePage extends StatelessWidget {
  HomePage({super.key});
  AuthController authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("Logged in"),
        ElevatedButton(
          onPressed: logout,
          child: Text("Logout"),
        ),
        SizedBox(
          height: 40,
        ),
        ElevatedButton(
          onPressed: lock,
          child: Text("Lock"),
        )
      ],
    );
  }

  lock() async {
    await authController.lock();
  }

  logout() async {
    await authController.logout();
  }
}
