import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/failure_message.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/errors/presentation_failure_exception.dart';

void main() {
  group('presentationFailureMessage', () {
    test('unwraps a PresentationFailureException to its failure message', () {
      final error = PresentationFailureException(
        const AuthenticationFailure(message: 'Bad credentials'),
      );

      expect(presentationFailureMessage(error), 'Bad credentials');
    });

    test('returns the message of a bare Failure', () {
      expect(
        presentationFailureMessage(const NetworkFailure()),
        'Please check your connection.',
      );
    });

    test('falls back to toString for an unknown error object', () {
      expect(presentationFailureMessage('boom'), 'boom');
    });
  });

  group('Failure equality', () {
    test('two failures with the same message are equal (Equatable)', () {
      expect(
        const ServerFailure(message: 'x'),
        const ServerFailure(message: 'x'),
      );
    });
  });
}
