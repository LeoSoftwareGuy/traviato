import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/l10n/l10n_dates.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_date_picker_sheet.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../mutations/expense_mutations.dart';
import 'expense_category_chip_group.dart';
import 'expense_money_format.dart';
import 'expense_trip_selector.dart';

/// Bottom sheet to log a new expense against one memory.
/// `docs/design/README.md` § Shared: Add-expense sheet.
class AddExpenseSheet extends ConsumerStatefulWidget {
  const AddExpenseSheet({
    required this.trips,
    required this.initialTripId,
    super.key,
  });

  final List<ExpenseSummaryEntity> trips;
  final String? initialTripId;

  static Future<void> show(
    BuildContext context, {
    required List<ExpenseSummaryEntity> trips,
    String? initialTripId,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      // The Expenses tab's Scaffold sets extendBody (so its own content
      // scrolls under the shell's bottom nav) — the root navigator keeps
      // this sheet above that nav bar instead of inserting it below.
      builder: (context) =>
          AddExpenseSheet(trips: trips, initialTripId: initialTripId),
    );
  }

  @override
  ConsumerState<AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _amount = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;
  String? _tripId;
  var _category = ExpenseCategory.foodDrinks;
  var _spentOn = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tripId =
        widget.initialTripId ??
        (widget.trips.isEmpty ? null : widget.trips.first.tripId);
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if ((value ?? '').trim().isEmpty) {
      return context.l10n.expense_descriptionRequired;
    }
    return null;
  }

  String? _validateAmount(String? value) {
    final parsed = parseEuroAmount(value ?? '');
    if (parsed == null || parsed <= 0) {
      return context.l10n.expense_amountInvalid;
    }
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showAppDatePicker(
      context: context,
      label: context.l10n.expense_spentOn,
      initialDate: _spentOn,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) setState(() => _spentOn = picked);
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.always);
    final formValid = _formKey.currentState?.validate() ?? false;
    if (!formValid || _tripId == null) return;

    try {
      await runAddExpense(
        ref: ref,
        tripId: _tripId!,
        title: _title.text.trim(),
        // Validated above, so this is non-null.
        amount: parseEuroAmount(_amount.text)!,
        category: _category,
        spentOn: _spentOn,
      );
    } catch (_) {
      // Surfaced to the user via the mutation's MutationError state below.
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<dynamic>>(addExpenseMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      }
    });
    final isLoading = ref.watch(addExpenseMutation) is MutationPending;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.sm,
        AppSpacing.xl,
        MediaQuery.viewInsetsOf(context).bottom + AppSpacing.xl,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.l10n.expense_newExpense,
                      style: AppTypography.displaySerif,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.l10n.common_cancel),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.base),
              ExpenseTripSelector(
                trips: widget.trips,
                value: _tripId,
                onChanged: (value) => setState(() => _tripId = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 8,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.expense_descriptionLabel,
                          style: AppTypography.fieldLabel,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _title,
                          style: AppTypography.bodyInput,
                          textInputAction: TextInputAction.next,
                          validator: _validateTitle,
                          decoration: InputDecoration(
                            hintText: context.l10n.expense_descriptionHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.expense_amountLabel,
                          style: AppTypography.fieldLabel,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          controller: _amount,
                          style: AppTypography.headlineSerif.copyWith(
                            fontSize: 19,
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.done,
                          validator: _validateAmount,
                          decoration: const InputDecoration(
                            prefixText: '€ ',
                            hintText: '0',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.expense_categoryHeader.toUpperCase(),
                style: AppTypography.mono,
              ),
              const SizedBox(height: AppSpacing.sm),
              ExpenseCategoryChipGroup(
                selected: _category,
                onSelect: (category) => setState(() => _category = category),
              ),
              const SizedBox(height: AppSpacing.lg),
              InkWell(
                onTap: _pickDate,
                borderRadius: AppRadius.cardRadius,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.base,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.surfaceBorder),
                    borderRadius: AppRadius.cardRadius,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _dateChipDescription(context.l10n, _spentOn),
                          style: AppTypography.bodyInput,
                        ),
                      ),
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add),
                  label: Text(context.l10n.expense_saveExpense),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _dateChipDescription(AppLocalizations l10n, DateTime date) {
    final locale = l10n.localeName;
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    return isToday
        ? l10n.expense_todayDate(L10nDates.monthDay(locale).format(date))
        : (locale == 'en'
                  ? DateFormat('MMM d, y', locale)
                  : DateFormat.yMMMd(locale))
              .format(date);
  }
}
