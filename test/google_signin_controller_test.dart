import 'package:flutter_login/google_signin_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Tests for the two decisions in [GoogleSignInController] that decide what a user sees when
/// sign-in does not succeed. Both are pure, so they need neither the native plugin nor a
/// network.
void main() {
  group('messageFor — cancellation must stay silent', () {
    test('a user backing out produces no message', () {
      // The single most important case: `canceled` is what google_sign_in throws when someone
      // dismisses the account picker. Reporting it would flash an error every time a user
      // changes their mind, which is what the hand-written app did.
      const cancelled = GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
      expect(GoogleSignInController.messageFor(cancelled), isNull);
    });

    test('a real plugin failure surfaces its description', () {
      const failure = GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
        description: 'Missing serverClientId',
      );
      expect(
        GoogleSignInController.messageFor(failure),
        'Missing serverClientId',
      );
    });

    test('a plugin failure with no description still says something', () {
      const failure = GoogleSignInException(
        code: GoogleSignInExceptionCode.unknownError,
      );
      expect(GoogleSignInController.messageFor(failure), isNotNull);
    });

    test('a non-plugin error is reported generically', () {
      expect(
        GoogleSignInController.messageFor(StateError('boom')),
        'Google sign-in failed.',
      );
    });
  });

  group('serverError — reading DRF error bodies', () {
    test('reads the {"error": ...} shape the google-signin view returns', () {
      // e.g. {"error": "Invalid or expired access token"} from client/google.py.
      expect(
        GoogleSignInController.serverError({'error': 'Invalid or expired access token'}),
        'Invalid or expired access token',
      );
    });

    test('reads DRF detail', () {
      expect(
        GoogleSignInController.serverError({'detail': 'Not found.'}),
        'Not found.',
      );
    });

    test('falls back to the first field error from a serializer', () {
      // Serializer errors are {field: [messages]}.
      expect(
        GoogleSignInController.serverError({
          'token': ['Token cannot be empty.'],
        }),
        'Token cannot be empty.',
      );
    });

    test('returns null for a body it cannot read, so the caller can use its own wording', () {
      expect(GoogleSignInController.serverError(null), isNull);
      expect(GoogleSignInController.serverError('plain text'), isNull);
      expect(GoogleSignInController.serverError(const {}), isNull);
      expect(GoogleSignInController.serverError(const {'a': 1}), isNull);
    });
  });

  group('construction', () {
    test('defaults to the Sisitech google-signin path and the email scope', () {
      final controller = GoogleSignInController(serverClientId: 'abc.apps.googleusercontent.com');
      expect(controller.signinPath, 'api/v1/users/google-signin/');
      // The backend verifies the token against Google's userinfo endpoint, which needs email.
      expect(controller.scopes, ['email']);
      expect(controller.isLoading.value, isFalse);
      expect(controller.error.value, isNull);
    });

    test('extra body fields are carried for app-specific flags', () {
      final controller = GoogleSignInController(
        serverClientId: 'abc',
        extraBody: const {'is_vet': true},
      );
      expect(controller.extraBody, containsPair('is_vet', true));
    });
  });
}
