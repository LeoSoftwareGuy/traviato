/// Centralized Supabase identifiers — table, view, bucket, RPC and error-code
/// names. Never hard-code these strings in feature code (guidelines doc 04).
///
/// Stub: entries are filled in as the corresponding migrations land (see
/// data-model.md). Tables/views referenced here may not exist in the database
/// yet; a name appearing in this file is not a guarantee the object is migrated.
library;

abstract class Tables {
  static const profiles = 'profiles';
  static const trips = 'trips';
  static const quests = 'quests';
  static const dayNotes = 'day_notes';
  static const photos = 'photos';
  static const checklistItems = 'checklist_items';
  static const checklistSuggestions = 'checklist_suggestions';
  static const bonusTaskTemplates = 'bonus_task_templates';
  static const bonusTaskAssignments = 'bonus_task_assignments';
  static const pointsLedger = 'points_ledger';
  static const expenses = 'expenses';
  static const memories = 'memories';
}

abstract class Views {
  static const tripCardView = 'trip_card_view';
  static const expenseSummaryView = 'expense_summary_view';
}

abstract class Storage {
  static const tripPhotos = 'trip-photos';
  static const avatars = 'avatars';
}

abstract class DBFunctions {
  static const awardPoints = 'award_points';
  static const shiftTripDates = 'shift_trip_dates';
}

/// Postgres / PostgREST error codes surfaced via `PostgrestException.code`.
abstract class PostgresErrors {
  static const insufficientPrivilege = '42501';
  static const moreThanOneOrNoItemsReturned = 'PGRST116';
}

abstract class Roles {
  static const user = 'user';
  static const admin = 'admin';
}
