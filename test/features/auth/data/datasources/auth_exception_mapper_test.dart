import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:traviato/core/errors/exceptions.dart';
import 'package:traviato/core/errors/failures.dart';
import 'package:traviato/features/auth/data/datasources/auth_exception_mapper.dart';

void main() {
  group('mapAuthException', () {
    test('a 429 becomes RateLimitedException with the wait parsed out', () {
      final mapped = mapAuthException(
        const AuthException(
          'For security purposes, you can only request this after 43 '
          'seconds.',
          statusCode: '429',
          code: 'over_request_rate_limit',
        ),
      );

      expect(mapped, isA<RateLimitedException>());
      expect((mapped as RateLimitedException).retryAfterSeconds, 43);
    });

    test('parses a singular "1 second"', () {
      final mapped = mapAuthException(
        const AuthException(
          'For security purposes, you can only request this after 1 second.',
          statusCode: '429',
        ),
      );
      expect((mapped as RateLimitedException).retryAfterSeconds, 1);
    });

    test('each Supabase rate-limit code is recognised without a 429', () {
      for (final code in [
        'over_request_rate_limit',
        'over_email_send_rate_limit',
        'over_sms_send_rate_limit',
      ]) {
        final mapped = mapAuthException(
          AuthException('email rate limit exceeded', code: code),
        );
        expect(mapped, isA<RateLimitedException>(), reason: code);
        expect(
          (mapped as RateLimitedException).retryAfterSeconds,
          isNull,
          reason: 'no "after N seconds" in the message',
        );
      }
    });

    test('any other auth error stays an AuthenticationException', () {
      final mapped = mapAuthException(
        const AuthException(
          'Invalid login credentials',
          statusCode: '400',
          code: 'invalid_credentials',
        ),
      );
      expect(mapped, isA<AuthenticationException>());
      expect(mapped.message, 'Invalid login credentials');
    });
  });

  group('RateLimitedFailure', () {
    test('tells the user how long to wait when known', () {
      expect(
        RateLimitedFailure(retryAfterSeconds: 43).message,
        'Too many attempts. Please wait 43 seconds and try again.',
      );
      expect(
        RateLimitedFailure(retryAfterSeconds: 1).message,
        'Too many attempts. Please wait 1 second and try again.',
      );
    });

    test('falls back to a friendly generic line otherwise', () {
      expect(
        RateLimitedFailure().message,
        'Too many attempts. Please wait a bit and try again.',
      );
    });
  });
}
