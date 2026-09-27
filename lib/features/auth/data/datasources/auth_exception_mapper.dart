import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/errors/exceptions.dart';

/// Supabase Auth error codes that mean "slow down" rather than "wrong".
/// https://supabase.com/docs/guides/auth/debugging/error-codes
const _rateLimitCodes = {
  'over_request_rate_limit',
  'over_email_send_rate_limit',
  'over_sms_send_rate_limit',
};

final _retryAfterPattern = RegExp(r'after (\d+) seconds?');

/// Translates a Supabase [AuthException] into this app's data-layer
/// exception — the single mapping every Supabase Auth call site uses, so a
/// rate limit (HTTP 429) surfaces as a [RateLimitedException] with a clear
/// "wait N seconds" message wherever Auth is called (#155), and everything
/// else stays an [AuthenticationException] carrying Supabase's message.
AppException mapAuthException(AuthException e) {
  if (e.statusCode == '429' || _rateLimitCodes.contains(e.code)) {
    final seconds = _retryAfterPattern.firstMatch(e.message)?.group(1);
    return RateLimitedException(
      retryAfterSeconds: seconds == null ? null : int.parse(seconds),
      message: e.message,
    );
  }
  return AuthenticationException(message: e.message);
}
