import 'package:flutter_auth/flutter_auth_controller.dart';
import 'package:flutter_utils/flutter_utils.dart';
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Signs a user in with Google and exchanges the result for an app session.
///
/// The backend contract is the one Sisitech's DRF projects expose: POST
/// `{token, ...extraBody}` to [signinPath], where `token` is the Google **OAuth access
/// token** (not the id token — the server verifies it by calling Google's
/// `oauth2/v3/userinfo` with it as a bearer). The response is the same
/// `{access_token, refresh_token, token_type, expires_in}` shape `o/token/` returns, so it
/// feeds straight into [AuthController.getSaveProfile].
///
/// The request goes through [AuthProvider], so it inherits the configured base URL, the
/// bearer/refresh modifier and the client timeout rather than reimplementing them.
///
/// Uses google_sign_in **v7**, whose API is a singleton (`initialize` → `authenticate` →
/// `authorizationClient`), not the pre-7 `GoogleSignIn(scopes:).signIn()`.
class GoogleSignInController extends GetxController {
  GoogleSignInController({
    required this.serverClientId,
    this.clientId,
    this.signinPath = 'api/v1/users/google-signin/',
    this.extraBody,
    this.scopes = const ['email'],
  });

  /// The **web** OAuth client id from the Google project. The backend needs a token minted
  /// for this audience, so it is required even on Android/iOS.
  final String serverClientId;

  /// Platform OAuth client id. Required on iOS/macOS unless `GIDClientID` is set in
  /// `Info.plist`; ignored on Android, which resolves the client from the signing SHA-1.
  final String? clientId;

  /// Backend path that trades a Google token for an app session.
  final String signinPath;

  /// Extra body fields merged into the POST (e.g. `{'is_vet': true}`).
  final Map<String, dynamic>? extraBody;

  /// Scopes to request an access token for.
  final List<String> scopes;

  /// True from the moment the flow starts until it settles either way.
  final RxBool isLoading = false.obs;

  /// The signed-in account's display name, as soon as Google reports it — so the UI can say
  /// "Continuing as Jane…" during the (slower) token exchange.
  final Rx<String?> name = Rx<String?>(null);

  /// Last failure, for display. Null when idle, successful, **or cancelled by the user**.
  final Rx<String?> error = Rx<String?>(null);

  bool _initialized = false;

  /// `initialize()` is idempotent per process but not free; only call it once.
  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: serverClientId,
      clientId: clientId,
    );
    _initialized = true;
  }

  /// Runs the full flow. Returns true when the user is signed in.
  ///
  /// [onLoginChange] runs only on success, after the session is persisted, and is passed the
  /// token response so callers can interpolate it.
  Future<bool> signInWithGoogle({Future<void> Function(dynamic res)? onLoginChange}) async {
    isLoading.value = true;
    name.value = null;
    error.value = null;

    try {
      await _ensureInitialized();
      // Without this a previously chosen account is reused silently, so a user who picked the
      // wrong one can never switch.
      await GoogleSignIn.instance.signOut();

      final GoogleSignInAccount account = await GoogleSignIn.instance.authenticate();
      name.value = account.displayName;

      final authorization =
          await account.authorizationClient.authorizationForScopes(scopes);
      final String? accessToken = authorization?.accessToken;
      if (accessToken == null) {
        // The user authenticated but declined the scope, so there is nothing to send.
        error.value = 'Google did not grant access to your account details.';
        return false;
      }

      final authController = Get.find<AuthController>();
      // The controller's own provider, so the request shares its base URL and modifiers.
      final res = await authController.authProv.formPost(signinPath, {
        'token': accessToken,
        ...?extraBody,
      });

      if (res.statusCode != 200) {
        error.value = serverError(res.body) ?? 'Sign-in failed. Please try again.';
        dprint('Google sign-in rejected (${res.statusCode}): ${res.body}');
        return false;
      }

      await authController.getSaveProfile(res.body);
      // getSaveProfile calls checkloggedIn() without awaiting it, so the flag can still be
      // false when this returns. Await it here rather than force-setting isAuthenticated$.
      await authController.checkloggedIn();

      if (onLoginChange != null) await onLoginChange(res.body);
      return true;
    } catch (e) {
      final message = messageFor(e);
      if (message != null) {
        error.value = message;
        dprint('Google sign-in error: $e');
      }
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// Maps a thrown error to a user-facing message, or **null when it should stay silent**.
  ///
  /// Backing out of the account picker throws
  /// `GoogleSignInException(code: canceled)`, which is a normal outcome rather than a
  /// failure: reporting it would show an error every time someone changes their mind.
  static String? messageFor(Object error) {
    if (error is GoogleSignInException) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      return error.description ?? 'Google sign-in failed.';
    }
    return 'Google sign-in failed.';
  }

  /// Pulls a human-readable message out of a DRF error body
  /// (`{"error": "..."}`, or `{"field": ["..."]}`).
  static String? serverError(dynamic body) {
    if (body is! Map) return null;
    final direct = body['error'] ?? body['detail'];
    if (direct is String && direct.isNotEmpty) return direct;
    for (final value in body.values) {
      if (value is String && value.isNotEmpty) return value;
      if (value is List && value.isNotEmpty && value.first is String) {
        return value.first as String;
      }
    }
    return null;
  }
}
