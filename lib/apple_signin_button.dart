import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'apple_signin_controller.dart';
import 'social_signin_button.dart';

/// A "Continue with Apple" button wired to [AppleSignInController], styled like the Google
/// one. A user-cancelled sign-in leaves `error` null, so dismissing Apple's sheet shows nothing.
class AppleSignInButton extends StatelessWidget {
  const AppleSignInButton({
    super.key,
    required this.controller,
    this.label = 'Continue with Apple',
    this.icon,
    this.onLoginChange,
    this.style,
  });

  final AppleSignInController controller;
  final String label;

  /// Leading widget — pass the caller's own Apple mark, as for Google.
  final Widget? icon;

  final Future<void> Function(dynamic res)? onLoginChange;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return Obx(() => SocialSignInButton(
          label: label,
          loading: controller.isLoading.value,
          onPressed: () => controller.signInWithApple(onLoginChange: onLoginChange),
          icon: icon,
          error: controller.error.value,
          style: style,
        ));
  }
}
