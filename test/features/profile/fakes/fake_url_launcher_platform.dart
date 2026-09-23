import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Test double for `UrlLauncherPlatform.instance`, so
/// `SubscriptionSection`'s "Manage subscription" button can be exercised
/// without a real platform channel (#142).
class FakeUrlLauncherPlatform extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  bool launchResult = true;
  String? lastLaunchedUrl;
  var launchCallCount = 0;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchCallCount++;
    lastLaunchedUrl = url;
    return launchResult;
  }
}
