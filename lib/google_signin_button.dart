import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'google_signin_controller.dart';
import 'social_signin_button.dart';

/// A "Continue with Google" button wired to [GoogleSignInController].
///
/// Reactive on the controller: disabled and spinning while the flow runs, showing
/// "Continuing as <name>…" once Google reports the account, and surfacing
/// [GoogleSignInController.error] underneath. A user-cancelled sign-in leaves `error` null,
/// so backing out of the account picker shows nothing.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.controller,
    this.label = 'Continue with Google',
    this.icon,
    this.onLoginChange,
    this.style,
  });

  final GoogleSignInController controller;

  /// Idle label. While signing in it becomes "Continuing as <name>…" once known.
  final String label;

  /// Leading widget — pass the caller's own Google mark. Packages should not bundle
  /// Google's trademarked logo, so this is deliberately not defaulted to one.
  final Widget? icon;

  final Future<void> Function(dynamic res)? onLoginChange;

  /// Overrides the default outlined styling.
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final loading = controller.isLoading.value;
      final who = controller.name.value;
      return SocialSignInButton(
        label: loading && who != null ? 'Continuing as $who...' : label,
        loading: loading,
        onPressed: () => controller.signInWithGoogle(onLoginChange: onLoginChange),
        icon: icon,
        error: controller.error.value,
        style: style,
      );
    });
  }
}
