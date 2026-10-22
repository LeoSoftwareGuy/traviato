abstract class RoutePaths {
  static const splash = '/splash';
  static const guestLanding = '/guest';
  static const login = '/login';
  static const signup = '/signup';
  static const home = '/home';
  static const expenses = '/expenses';
  static const expensesCompare = '/expenses/compare';
  static const profile = '/profile';
  static const bonusTasks = '/bonus-tasks';
  static const bonusStarsByMemory = '/bonus-tasks/memories';
  static const createMemory = '/create-memory';
  static const keptMemory = '/memory/:tripId';
  static const tripPlan = '/memory/:tripId/plan';
  static const tripChecklist = '/memory/:tripId/checklist';
  static const tripJournal = '/memory/:tripId/journal';
  static const tripBonusTasks = '/memory/:tripId/bonus-tasks';
  static const tripWrapUp = '/memory/:tripId/wrap-up';
  static const subscriptionOfferings = '/subscription/offerings';
}

abstract class RouteNames {
  static const splash = 'splash';
  static const guestLanding = 'guestLanding';
  static const login = 'login';
  static const signup = 'signup';
  static const home = 'home';
  static const expenses = 'expenses';
  static const expensesCompare = 'expensesCompare';
  static const profile = 'profile';
  static const bonusTasks = 'bonusTasks';
  static const bonusStarsByMemory = 'bonusStarsByMemory';
  static const createMemory = 'createMemory';
  static const keptMemory = 'keptMemory';
  static const tripPlan = 'tripPlan';
  static const tripChecklist = 'tripChecklist';
  static const tripJournal = 'tripJournal';
  static const tripBonusTasks = 'tripBonusTasks';
  static const tripWrapUp = 'tripWrapUp';
  static const subscriptionOfferings = 'subscriptionOfferings';
}

/// Query parameters shared between routes.
abstract class RouteQuery {
  /// On [RouteNames.tripWrapUp]: `from=memory` when the film was opened
  /// from the Kept Memory page, so it ends on "Back to memory" (#279).
  static const from = 'from';
  static const fromMemory = 'memory';
}
