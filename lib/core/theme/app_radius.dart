import 'package:flutter/material.dart';

/// Corner-radius scale observed across the Figma "Leo's team library" frames.
abstract class AppRadius {
  static const double badge = 12;
  static const double card = 16;
  static const double media = 24;
  static const double pill = 9999;

  static const BorderRadius badgeRadius = BorderRadius.all(
    Radius.circular(badge),
  );
  static const BorderRadius cardRadius = BorderRadius.all(
    Radius.circular(card),
  );
  static const BorderRadius mediaRadius = BorderRadius.all(
    Radius.circular(media),
  );
  static const BorderRadius pillRadius = BorderRadius.all(
    Radius.circular(pill),
  );
}
