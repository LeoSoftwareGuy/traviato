import 'dart:ui';

/// Parses the absolute SVG path data the Neon Night spec writes its shapes
/// in (#363): `M`, `L`, `C`, `Q` and `Z`, with numbers separated by spaces
/// or commas. A command letter may be followed by several coordinate sets
/// (an implicit repeat; after `M` they are line-tos). Anything else throws,
/// so a typo in a path fails a test instead of drawing a wrong shape.
Path parseNeonSvgPath(String data) {
  final tokens = RegExp(
    r'[A-Za-z]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
  ).allMatches(data).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  String? command;

  double number() {
    if (i >= tokens.length) throw FormatException('path ends early: $data');
    final value = double.tryParse(tokens[i]);
    if (value == null) {
      throw FormatException('expected a number at "${tokens[i]}": $data');
    }
    i++;
    return value;
  }

  bool nextIsNumber() =>
      i < tokens.length && double.tryParse(tokens[i]) != null;

  while (i < tokens.length) {
    if (!nextIsNumber()) {
      command = tokens[i++];
    } else if (command == null || command == 'Z') {
      throw FormatException('a number without a command: $data');
    }
    switch (command) {
      case 'M':
        path.moveTo(number(), number());
        // Further pairs after a move-to are line-tos.
        command = 'L';
      case 'L':
        path.lineTo(number(), number());
      case 'C':
        path.cubicTo(
          number(),
          number(),
          number(),
          number(),
          number(),
          number(),
        );
      case 'Q':
        path.quadraticBezierTo(number(), number(), number(), number());
      case 'Z':
        path.close();
      default:
        throw FormatException('unsupported path command "$command": $data');
    }
  }
  return path;
}
