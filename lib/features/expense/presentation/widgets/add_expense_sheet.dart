import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../domain/entities/expense_category.dart';
import '../../domain/entities/expense_summary_entity.dart';
import '../mutations/expense_mutations.dart';
import 'expense_category_chip_group.dart';
import 'expense_trip_selector.dart';

final _dateFormat = DateFormat('MMM d, y');

/// Bottom sheet to log a new expense against one memory (Figma
/// "add expenses"), same chrome as `ToDoSheet`.
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
    return showModalBottomSheet<void>(
      context: context,
      // The Expenses tab's Scaffold sets extendBody (so its own content
      // scrolls under the shell's bottom nav) — without the root navigator,
      // this sheet would be inserted below that nav bar instead of over it.
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
  DateTime? _spentOn;
  String? _dateError;

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
    if ((value ?? '').trim().isEmpty) return 'What was it?';
    return null;
  }

  String? _validateAmount(String? value) {
    final parsed = double.tryParse((value ?? '').trim());
    if (parsed == null || parsed <= 0) return 'Enter an amount greater than 0.';
    return null;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _spentOn ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() {
        _spentOn = picked;
        _dateError = null;
      });
    }
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.always);
    final formValid = _formKey.currentState?.validate() ?? false;
    final dateValid = _spentOn != null;
    setState(() => _dateError = dateValid ? null : 'Pick a date.');
    if (!formValid || !dateValid || _tripId == null) return;

    try {
      await runAddExpense(
        ref: ref,
        tripId: _tripId!,
        title: _title.text.trim(),
        amount: double.parse(_amount.text.trim()),
        category: _category,
        spentOn: _spentOn!,
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
          message: presentationFailureMessage(next.error),
        );
      }
    });
    final isLoading = ref.watch(addExpenseMutation) is MutationPending;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.base,
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
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: AppRadius.pillRadius,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Add expense', style: AppTypography.headlineSerif),
              const SizedBox(height: AppSpacing.lg),
              ExpenseTripSelector(
                trips: widget.trips,
                value: _tripId,
                onChanged: (value) => setState(() => _tripId = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('What was it?', style: AppTypography.fieldLabel),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _title,
                style: AppTypography.bodyInput,
                textInputAction: TextInputAction.next,
                validator: _validateTitle,
                decoration: const InputDecoration(
                  hintText: 'e.g. Sunset dinner in Oia',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Amount', style: AppTypography.fieldLabel),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _amount,
                style: AppTypography.bodyInput,
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
              const SizedBox(height: AppSpacing.lg),
              Text('Category', style: AppTypography.fieldLabel),
              const SizedBox(height: AppSpacing.sm),
              ExpenseCategoryChipGroup(
                selected: _category,
                onSelect: (category) => setState(() => _category = category),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Date', style: AppTypography.fieldLabel),
              const SizedBox(height: AppSpacing.sm),
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
                          _spentOn == null
                              ? 'Pick a date'
                              : _dateFormat.format(_spentOn!),
                          style: AppTypography.bodyInput.copyWith(
                            color: _spentOn == null
                                ? AppColors.textTertiary
                                : AppColors.textPrimary,
                          ),
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
              if (_dateError != null) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _dateError!,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.accentCoral,
                    letterSpacing: 0,
                  ),
                ),
              ],
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
                  label: const Text('Save expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
