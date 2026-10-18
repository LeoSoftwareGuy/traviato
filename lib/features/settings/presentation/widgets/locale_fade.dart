import 'package:flutter/widgets.dart';

/// Softly fades the app back in whenever [locale] changes (#236 / spec 1c),
/// so a language switch reads as a 200ms crossfade.
///
/// It fades the *same* subtree in place rather than swapping it out with a
/// keyed `AnimatedSwitcher`: re-keying the app root would remount the
/// Navigator and drop the user's place in the app.
class LocaleFade extends StatefulWidget {
  const LocaleFade({required this.locale, required this.child, super.key});

  final Locale locale;
  final Widget child;

  static const duration = Duration(milliseconds: 200);

  @override
  State<LocaleFade> createState() => _LocaleFadeState();
}

class _LocaleFadeState extends State<LocaleFade>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: LocaleFade.duration,
    value: 1,
  );
  late final _opacity = Tween<double>(
    begin: .2,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

  @override
  void didUpdateWidget(LocaleFade oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locale != widget.locale &&
        !(MediaQuery.maybeDisableAnimationsOf(context) ?? false)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _opacity, child: widget.child);
}
