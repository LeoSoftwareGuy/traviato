import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/errors/failure_message.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/core/errors/presentation_failure_exception.dart';
import 'package:traviato/l10n/app_localizations.dart';

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final ru = lookupAppLocalizations(const Locale('ru'));

  group('presentationFailureMessage', () {
    test('unwraps a PresentationFailureException to its failure message', () {
      final error = PresentationFailureException(
        const AuthenticationFailure(message: 'Bad credentials'),
      );

      expect(presentationFailureMessage(error, en), 'Bad credentials');
    });

    test('returns the message of a bare Failure', () {
      expect(
        presentationFailureMessage(const NetworkFailure(), en),
        'Please check your connection.',
      );
    });

    test('falls back to toString for an unknown error object', () {
      expect(presentationFailureMessage('boom', en), 'boom');
    });

    test('English copy matches each failure default message', () {
      final failures = <Failure>[
        const NetworkFailure(),
        const PermissionFailure(),
        const NotFoundFailure(),
        const UnknownFailure(),
        const AuthLinkFailure(),
        const FreeTierLimitFailure(),
        const PhotoLimitFailure(),
        const QuestPlanningClosedFailure(),
        RateLimitedFailure(),
        RateLimitedFailure(retryAfterSeconds: 1),
        RateLimitedFailure(retryAfterSeconds: 30),
        RateLimitedFailure(isEmailQuota: true),
      ];
      for (final failure in failures) {
        expect(
          presentationFailureMessage(failure, en),
          failure.message,
          reason: '${failure.runtimeType}',
        );
      }
    });

    test('translates app-written failures', () {
      expect(
        presentationFailureMessage(const NetworkFailure(), ru),
        'Проверьте подключение к интернету.',
      );
    });

    test('uses Russian plural forms for the rate-limit wait', () {
      String wait(int s) => presentationFailureMessage(
        RateLimitedFailure(retryAfterSeconds: s),
        ru,
      );
      expect(wait(1), contains('1 секунду'));
      expect(wait(3), contains('3 секунды'));
      expect(wait(5), contains('5 секунд '));
      expect(wait(21), contains('21 секунду'));
    });

    test('passes exception-provided messages through untranslated', () {
      expect(
        presentationFailureMessage(
          const UnknownFailure(message: 'socket closed'),
          ru,
        ),
        'socket closed',
      );
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
