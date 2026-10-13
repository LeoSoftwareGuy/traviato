import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// The note page's text controller. While dictating, the words the
/// recogniser hasn't settled on yet ([pending]) render at 60% ink; they
/// switch to full ink once final (docs/design/JOURNAL_NOTE_PAGETURN_SPEC.md
/// §4).
class NoteDraftController extends TextEditingController {
  TextRange _pending = TextRange.empty;
  var _applying = false;

  TextRange get pending => _pending;

  /// Sets [value] and the pending range in one notification.
  void applyDictation(TextEditingValue value, {required TextRange pending}) {
    _pending = pending;
    _applying = true;
    try {
      this.value = value;
    } finally {
      _applying = false;
    }
  }

  void clearPending() {
    if (!_pending.isValid || _pending.isCollapsed) return;
    _pending = TextRange.empty;
    notifyListeners();
  }

  @override
  set value(TextEditingValue newValue) {
    // Any edit that doesn't come through [applyDictation] (typing, paste)
    // invalidates the range.
    if (newValue.text != text && !_applying) _pending = TextRange.empty;
    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final range = _pending;
    if (!range.isValid ||
        range.isCollapsed ||
        range.end > text.length ||
        (withComposing && value.isComposingRangeValid)) {
      return super.buildTextSpan(
        context: context,
        style: style,
        withComposing: withComposing,
      );
    }
    return TextSpan(
      style: style,
      children: [
        TextSpan(text: range.textBefore(text)),
        TextSpan(
          text: range.textInside(text),
          style: style?.copyWith(color: AppColors.tint(AppColors.paperInk, .6)),
        ),
        TextSpan(text: range.textAfter(text)),
      ],
    );
  }
}
