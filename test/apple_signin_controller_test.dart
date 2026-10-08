import 'package:flutter_login/apple_signin_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// The pure decisions in [AppleSignInController]: what a failed sign-in shows, and which
/// controller a login surface gets.
void main() {
  group('messageFor — cancellation must stay silent', () {
    test('dismissing Apple\'s sheet produces no message', () {
      const cancelled = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.canceled,
        message: 'The user canceled the authorization attempt.',
      );
      expect(AppleSignInController.messageFor(cancelled), isNull);
    });

    test('a real authorization failure surfaces its message', () {
      const failure = SignInWithAppleAuthorizationException(
        code: AuthorizationErrorCode.failed,
        message: 'Authorization failed',
      );
      expect(AppleSignInController.messageFor(failure), 'Authorization failed');
    });

    test('a non-plugin error is reported generically', () {
      expect(AppleSignInController.messageFor(StateError('boom')), 'Apple sign-in failed.');
    });
  });

  group('tagFor', () {
    test('a vet and a farmer sheet get separate controllers', () {
      const path = 'api/v1/users/apple-signin/';
      expect(
        AppleSignInController.tagFor(path, {'is_vet': true}),
        isNot(AppleSignInController.tagFor(path, {'is_vet': false})),
      );
    });
  });
}
