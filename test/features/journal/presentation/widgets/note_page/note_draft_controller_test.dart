import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traviato/core/theme/app_colors.dart';
import 'package:traviato/features/journal/presentation/widgets/note_page/note_draft_controller.dart';

void main() {
  testWidgets('renders the pending range at 60% ink', (tester) async {
    final draft = NoteDraftController()
      ..applyDictation(
        const TextEditingValue(text: 'Woke early. then the'),
        pending: const TextRange(start: 12, end: 20),
      );
    addTearDown(draft.dispose);
    late TextSpan span;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          span = draft.buildTextSpan(
            context: context,
            style: const TextStyle(color: AppColors.paperInk),
            withComposing: false,
          );
          return const SizedBox();
        },
      ),
    );

    final parts = span.children!.cast<TextSpan>();
    expect(parts.map((p) => p.text), ['Woke early. ', 'then the', '']);
    expect(parts[1].style!.color, AppColors.tint(AppColors.paperInk, .6));
  });

  test('typing clears the pending range', () {
    final draft = NoteDraftController()
      ..applyDictation(
        const TextEditingValue(text: 'then the'),
        pending: const TextRange(start: 0, end: 8),
      );
    addTearDown(draft.dispose);

    draft.text = 'then the!';
    expect(draft.pending.isValid, isFalse);
  });
}
