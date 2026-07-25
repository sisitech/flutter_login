import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'google_signin_controller.dart';

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
    final theme = Theme.of(context);

    return Obx(() {
      final loading = controller.isLoading.value;
      final who = controller.name.value;
      final err = controller.error.value;

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          OutlinedButton.icon(
            onPressed: loading
                ? null
                : () => controller.signInWithGoogle(onLoginChange: onLoginChange),
            icon: loading
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: theme.colorScheme.onSurface,
                    ),
                  )
                : (icon ?? const SizedBox.shrink()),
            label: Text(
              loading && who != null ? 'Continuing as $who...' : label,
            ),
            style: style ??
                OutlinedButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  foregroundColor: theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide(color: theme.colorScheme.outline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
          ),
          if (err != null) ...[
            const SizedBox(height: 8),
            Text(
              err,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          ],
        ],
      );
    });
  }
}
