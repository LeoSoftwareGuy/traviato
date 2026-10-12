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
      isEmailQuota: e.code == 'over_email_send_rate_limit',
      message: e.message,
    );
  }
  return AuthenticationException(message: e.message);
}

/// Session-restore error codes gotrue reports on the auth-state stream at
/// startup — not caused by a link, so they must not read as one.
const _sessionRestoreCodes = {'session_expired', 'session_not_found'};

/// Whether an error on `onAuthStateChange` came from handling an incoming
/// auth deep link (#157). supabase_flutter funnels every failed
/// `getSessionFromUrl` — error params in the link (`otp_expired`,
/// `access_denied`), a missing PKCE code verifier, a rejected code exchange —
/// into the stream as an [AuthException]. The only other errors on that
/// stream are retryable token-refresh failures and session-restore errors,
/// which are excluded here.
bool isAuthLinkError(Object error) =>
    error is AuthException &&
    error is! AuthRetryableFetchException &&
    !_sessionRestoreCodes.contains(error.code);
