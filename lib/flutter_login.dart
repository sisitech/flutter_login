library flutter_login;

import 'package:flutter/material.dart';
import 'package:flutter_auth/flutter_auth_controller.dart';
import 'package:flutter_form/flutter_form.dart';
import 'package:flutter_form/form_controller.dart';
import 'package:flutter_form/models.dart';
import 'package:flutter_login/login_utils.dart';
import 'package:flutter_utils/flutter_utils.dart';
import 'package:flutter_utils/models.dart';
import 'package:flutter_utils/text_view/text_view_extensions.dart';
import 'package:get/get.dart';
import './options.dart';

class LoginWidget extends StatelessWidget {
  final Function? onLoginChange;
  final bool enableOfflineLogin;

  final Map<String, dynamic>? override_options;

  const LoginWidget(
      {super.key,
      this.onLoginChange,
      this.override_options,
      this.enableOfflineLogin = false});

  @override
  Widget build(BuildContext context) {
    APIConfig config = Get.find<APIConfig>();
    AuthController authController = Get.find<AuthController>();
    Map<String, dynamic>? offlineCred;

    return MyCustomForm(
      formItems: override_options ?? options,
      url: "o/token/",
      submitButtonText: "Login",
      submitButtonPreText: "",
      enableOfflineMode: enableOfflineLogin,
      enableOfflineSave: false,
      loadingMessage: "Signing in...",
      validateOfflineData: !enableOfflineLogin
          ? null
          : (data) async {
              var res = await authController.confirmOfflineCreds(data);

              if (res == null) {
                return {"detail": "No offline credentials found".tr};
              }
              if (!res) {
                var offlineCred = authController.offlineCred.value;
                var loginForm = authController.loginForm.value;
                // dprint(loginForm);
                // dprint(offlineCred);
                if (offlineCred == null || loginForm == null) {
                  return {"details": "Confirm username and password".tr};
                } else {
                  if (loginForm?["username"] == offlineCred?["username"]) {
                    return {
                      "password": "Wrong password for @username#"
                          .tr
                          .interpolate(loginForm)
                    };
                  }
                  return {
                    "username": "Only @username can login offline"
                        .tr
                        .interpolate(offlineCred)
                  };
                }
              } else {
                // dprint("Offline Authenticated $res");
                // dprint("${authController.offlineCred}");
                return null;
              }
            },
      // instance: {
      //   "username": "micha@sisitech.com",
      //   "password": "mm",
      // },
      handleErrors: (value) {
        dprint(value);
        if (value != null) {
          return "Your pformassword might be wrong".tr;
        }
        return null;
      },
      onOfflineSuccess: !enableOfflineLogin
          ? null
          : (res) async {
              dprint("Login offline successful");
              await authController.unLock();
              if (onLoginChange != null) {
                await onLoginChange!(res);
              }
            },
      contentType: ContentType.form_url_encoded,
      extraFields: {
        "client_id": config.clientId,
        "grant_type": config.grantType,
      },
      PreSaveData: (res) {
        dprint("PResave data");
        authController.loginForm.value = res;
        return res;
      },
      onSuccess: (res) async {
        dprint("Logged in");
        dprint(res);
        dprint("creds");
        dprint(authController.loginForm.value);
        if (enableOfflineLogin) {
          await authController.saveOfflineCreds();
        }
        await authController.getSaveProfile(res);
        if (onLoginChange != null) {
          await onLoginChange!(res);
        }
        return null;
      },
      formGroupOrder: const [
        ["username"],
        ["password"]
      ],
      // formTitle: "",
      name: "Login",
    );
  }
}
