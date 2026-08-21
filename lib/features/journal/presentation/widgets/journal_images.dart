/// Static day-tile photography for the Journal screen's day range row
/// (design provided separately from Figma, see the trip feature's
/// `TripImages` precedent). Cycled across however many days a memory spans.
abstract class JournalImages {
  static const dayTiles = [
    'assets/images/journal/balloon_1.jpg',
    'assets/images/journal/balloon_2.jpg',
    'assets/images/journal/balloon_3.jpg',
  ];

  static String forDayIndex(int index) => dayTiles[index % dayTiles.length];
}
