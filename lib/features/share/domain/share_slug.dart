import '../../../core/constants/app_constants.dart';

final _slugPattern = RegExp(r'^[A-Za-z0-9]{10}$');

/// Whether [value] is a share-link slug's shape (#309): 10 base62 chars.
bool isShareSlug(String value) => _slugPattern.hasMatch(value);

/// The slug in a share link (#310): `https://storyni.app/m/{slug}`, the
/// same without the scheme (pasted), or the app's own
/// `com.leo.storyni://m/{slug}` (the web page's "Open in the app"). Query,
/// fragment and a trailing slash are ignored; anything else is null.
String? parseShareSlug(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null) return null;

  final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
  final String? slug;
  if (uri.scheme == AppConstants.authRedirectScheme && uri.host == 'm') {
    slug = segments.length == 1 ? segments.single : null;
  } else if ((uri.scheme == 'https' || uri.scheme == 'http') &&
      (uri.host == AppConstants.shareHost ||
          uri.host == 'www.${AppConstants.shareHost}')) {
    slug = segments.length == 2 && segments.first == 'm' ? segments[1] : null;
  } else {
    slug = null;
  }
  return slug != null && isShareSlug(slug) ? slug : null;
}

/// The slug in a Play Store install referrer (#310): the web page's Play
/// button sends `referrer=storyni_slug={slug}`; other referrer keys are
/// ignored.
String? parseReferrerSlug(String? referrer) {
  if (referrer == null || referrer.isEmpty) return null;
  final Map<String, String> params;
  try {
    params = Uri.splitQueryString(referrer);
  } on FormatException {
    return null;
  }
  final slug = params['storyni_slug'];
  return slug != null && isShareSlug(slug) ? slug : null;
}
