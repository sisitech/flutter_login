library flutter_login;

import 'package:flutter/material.dart';
import 'package:flutter_auth/flutter_auth_controller.dart';
import 'package:flutter_form/flutter_form.dart';
import 'package:flutter_form/models.dart';
import 'package:flutter_utils/flutter_utils.dart';
import 'package:flutter_utils/models.dart';
import 'package:get/get.dart';
import './options.dart';

class LoginWidget extends StatelessWidget {
  final Function? onLoginChange;
  const LoginWidget({super.key, this.onLoginChange});

  @override
  Widget build(BuildContext context) {
    APIConfig config = Get.find<APIConfig>();
    AuthController authController = Get.find<AuthController>();

    return MyCustomForm(
      formItems: options,
      url: "o/token/",
      submitButtonText: "Login",
      submitButtonPreText: "",
      loadingMessage: "Signing in...",
      handleErrors: (value) {
        dprint(value);
        return "Your password might be wrong".tr;
      },
      contentType: ContentType.form_url_encoded,
      extraFields: {
        "client_id": config.clientId,
        "grant_type": config.grantType,
      },
      onSuccess: (res) async {
        dprint("Logged in");
        dprint(res);
        await authController.getSaveProfile(res);
        if (onLoginChange != null) {
          onLoginChange!(res);
        }
      },
      formGroupOrder: const [
        ["username"],
        ["password"]
      ],
      formTitle: "Signup",
    );
  }
}
