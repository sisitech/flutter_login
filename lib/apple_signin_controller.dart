import 'package:flutter_auth/flutter_auth_controller.dart';
import 'package:flutter_utils/flutter_utils.dart';
import 'package:get/get.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'google_signin_controller.dart';

/// Signs a user in with Apple and exchanges the result for an app session.
///
/// The backend contract mirrors Google's: POST `{token, first_name, last_name, ...extraBody}`
/// to [signinPath], where `token` is Apple's **identity token** (a JWT the server verifies
/// against Apple's published keys and the app's bundle id). The response is the same
/// `{access_token, refresh_token, ...}` shape, so it feeds [AuthController.getSaveProfile].
///
/// Apple hands over the user's name **only on the first authorization** and never puts it in
/// the identity token, so it is forwarded here or lost; on later sign-ins it is null and the
/// server keeps what it already has.
class AppleSignInController extends GetxController {
  AppleSignInController({
    this.signinPath = 'api/v1/users/apple-signin/',
    this.extraBody,
  });

  /// Backend path that trades an Apple identity token for an app session.
  final String signinPath;

  /// Extra body fields merged into the POST (e.g. `{'is_vet': true}`).
  final Map<String, dynamic>? extraBody;

  /// True from the moment the flow starts until it settles either way.
  final RxBool isLoading = false.obs;

  /// Last failure, for display. Null when idle, successful, **or cancelled by the user**.
  final Rx<String?> error = Rx<String?>(null);

  /// Runs the full flow. Returns true when the user is signed in.
  ///
  /// [onLoginChange] runs only on success, after the session is persisted, and is passed the
  /// token response so callers can interpolate it.
  Future<bool> signInWithApple({Future<void> Function(dynamic res)? onLoginChange}) async {
    isLoading.value = true;
    error.value = null;

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      final token = credential.identityToken;
      if (token == null) {
        error.value = 'Apple did not return a sign-in token.';
        return false;
      }

      final authController = Get.find<AuthController>();
      // The controller's own provider, so the request shares its base URL and modifiers.
      final res = await authController.authProv.formPost(signinPath, {
        'token': token,
        if (credential.givenName != null) 'first_name': credential.givenName,
        if (credential.familyName != null) 'last_name': credential.familyName,
        ...?extraBody,
      });

      if (res.statusCode != 200) {
        error.value = GoogleSignInController.serverError(res.body) ??
            'Sign-in failed. Please try again.';
        dprint('Apple sign-in rejected (${res.statusCode}): ${res.body}');
        return false;
      }

      await authController.getSaveProfile(res.body);
      // See GoogleSignInController: getSaveProfile does not await checkloggedIn().
      await authController.checkloggedIn();

      if (onLoginChange != null) await onLoginChange(res.body);
      return true;
    } catch (e) {
      final message = messageFor(e);
      if (message != null) {
        error.value = message;
        dprint('Apple sign-in error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// The GetX tag a login surface registers its controller under — keyed on path and body
  /// for the reason [GoogleSignInController.tagFor] gives.
  static String tagFor(String signinPath, Map<String, dynamic>? extraBody) =>
      GoogleSignInController.tagFor(signinPath, 'apple', extraBody);

  /// Maps a thrown error to a user-facing message, or **null when it should stay silent**:
  /// dismissing Apple's sheet throws `canceled`, a normal outcome rather than a failure.
  static String? messageFor(Object error) {
    if (error is SignInWithAppleAuthorizationException) {
      if (error.code == AuthorizationErrorCode.canceled) return null;
      return error.message.isNotEmpty ? error.message : 'Apple sign-in failed.';
    }
    return 'Apple sign-in failed.';
  }
}
