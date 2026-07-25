library flutter_login;

import 'package:flutter/material.dart';
import 'package:flutter_auth/flutter_auth_controller.dart';
import 'package:flutter_form/flutter_form.dart';
import 'package:flutter_form/form_controller.dart';
import 'package:flutter_form/models.dart';
import 'package:flutter_login/google_signin_button.dart';
import 'package:flutter_login/google_signin_controller.dart';
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

  /// Show a "Continue with Google" button under (or instead of) the credential form.
  ///
  /// Off by default, so existing apps are unaffected — but note that adding
  /// `google_sign_in` makes this a plugin-bearing package, so every consumer inherits the
  /// native setup requirements (see README).
  final bool enableGoogleSignIn;

  /// The **web** OAuth client id. Required when [enableGoogleSignIn] is true.
  final String? googleServerClientId;

  /// Platform OAuth client id — needed on iOS/macOS unless `GIDClientID` is in Info.plist.
  final String? googleClientId;

  /// Backend path that trades a Google token for an app session.
  final String googleSigninPath;

  /// Extra body fields for that POST (e.g. `{'is_vet': true}`).
  final Map<String, dynamic>? googleExtraBody;

  /// Leading widget for the Google button — pass your own Google mark. Not defaulted,
  /// because a package should not bundle Google's trademarked logo.
  final Widget? googleIcon;

  /// Render **only** the social button, hiding the username/password form. For apps whose
  /// sign-in is social-only.
  final bool socialOnly;

  const LoginWidget(
      {super.key,
      this.onLoginChange,
      this.override_options,
      this.enableOfflineLogin = false,
      this.enableGoogleSignIn = false,
      this.googleServerClientId,
      this.googleClientId,
      this.googleSigninPath = 'api/v1/users/google-signin/',
      this.googleExtraBody,
      this.googleIcon,
      this.socialOnly = false})
      : assert(!enableGoogleSignIn || googleServerClientId != null,
            'enableGoogleSignIn requires googleServerClientId'),
        assert(!socialOnly || enableGoogleSignIn,
            'socialOnly hides the credential form, so a social provider must be enabled');

  @override
  Widget build(BuildContext context) {
    final form = socialOnly ? null : _buildForm(context);
    if (!enableGoogleSignIn) return form!;

    // Tagged by path+audience so two differently-configured login surfaces in one app do not
    // share a controller.
    final google = Get.put(
      GoogleSignInController(
        serverClientId: googleServerClientId!,
        clientId: googleClientId,
        signinPath: googleSigninPath,
        extraBody: googleExtraBody,
      ),
      tag: '$googleSigninPath::$googleServerClientId',
    );

    final button = GoogleSignInButton(
      controller: google,
      icon: googleIcon,
      onLoginChange:
          onLoginChange == null ? null : (res) async => await onLoginChange!(res),
    );

    if (form == null) return button;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        form,
        const SizedBox(height: 20),
        button,
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
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
          return "Your password might be wrong".tr;
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
