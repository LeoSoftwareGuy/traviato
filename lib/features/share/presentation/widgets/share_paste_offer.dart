import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prefs/pending_share_slug_prefs.dart';
import '../controllers/pending_share_slug_controller.dart';
import '../providers/share_providers.dart';
import 'have_link_sheet.dart';

/// iOS's deferred deep link (#310). The web page copied the link before
/// sending the user to the App Store, so a new account (no memories yet)
/// is offered "Opening a shared memory?" once, if the clipboard holds
/// anything. `Clipboard.hasStrings` doesn't trigger iOS's paste prompt;
/// pasting goes through the sheet's system edit menu. Wraps Home's content.
class SharePasteOffer extends ConsumerStatefulWidget {
  const SharePasteOffer({
    required this.isNewAccount,
    required this.child,
    super.key,
  });

  final bool isNewAccount;
  final Widget child;

  @override
  ConsumerState<SharePasteOffer> createState() => _SharePasteOfferState();
}

class _SharePasteOfferState extends ConsumerState<SharePasteOffer> {
  bool _considered = false;

  @override
  void initState() {
    super.initState();
    _consider();
  }

  @override
  void didUpdateWidget(SharePasteOffer oldWidget) {
    super.didUpdateWidget(oldWidget);
    _consider();
  }

  void _consider() {
    if (_considered || !widget.isNewAccount) return;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    _considered = true;
    unawaited(_offer());
  }

  Future<void> _offer() async {
    try {
      if (ref.read(pendingShareSlugControllerProvider) != null) return;
      final offered = await ref
          .read(pendingShareSlugPrefsProvider)
          .testAndSet(PendingShareSlugPrefs.pasteOfferedKey);
      if (offered || !await Clipboard.hasStrings()) return;
      if (!mounted) return;
      await HaveLinkSheet.show(context, isPasteOffer: true);
    } catch (e) {
      debugPrint('Share paste offer skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
