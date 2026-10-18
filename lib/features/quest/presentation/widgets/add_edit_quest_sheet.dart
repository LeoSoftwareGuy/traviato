import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/l10n/context_l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/adaptive_button_pair.dart';
import '../../../../core/widgets/bottom_sheet_chrome.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../trip/presentation/widgets/create_memory_field.dart';
import '../../domain/entities/quest_entity.dart';
import '../mutations/quest_mutations.dart';
import 'quest_time_format.dart';

/// Add/edit bottom sheet for a quest, on the R-1 sheet chrome. If [quest]
/// is provided, the sheet will be in edit mode.
class AddEditQuestSheet extends ConsumerStatefulWidget {
  const AddEditQuestSheet({
    required this.tripId,
    required this.dayDate,
    this.quest,
    super.key,
  });

  final String tripId;
  final DateTime dayDate;
  final QuestEntity? quest;

  static Future<void> show(
    BuildContext context, {
    required String tripId,
    required DateTime dayDate,
    QuestEntity? quest,
  }) {
    return showAppBottomSheet<void>(
      context: context,
      builder: (context) =>
          AddEditQuestSheet(tripId: tripId, dayDate: dayDate, quest: quest),
    );
  }

  @override
  ConsumerState<AddEditQuestSheet> createState() => _AddEditQuestSheetState();
}

class _AddEditQuestSheetState extends ConsumerState<AddEditQuestSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.quest?.title ?? '');
  late final _detail = TextEditingController(
    text: widget.quest?.placeText ?? '',
  );
  var _autovalidate = AutovalidateMode.disabled;
  TimeOfDay? _time;

  bool get _isEditing => widget.quest != null;

  @override
  void initState() {
    super.initState();
    final time = widget.quest?.time;
    _time = time == null
        ? null
        : TimeOfDay(hour: time.inHours, minute: time.inMinutes % 60);
  }

  @override
  void dispose() {
    _title.dispose();
    _detail.dispose();
    super.dispose();
  }

  String? _validateTitle(String? value) {
    if ((value ?? '').trim().isEmpty) return context.l10n.plan_nameRequired;
    return null;
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    setState(() => _autovalidate = AutovalidateMode.always);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final time = _time == null
        ? null
        : Duration(hours: _time!.hour, minutes: _time!.minute);
    final title = _title.text.trim();
    final detail = _detail.text.trim().isEmpty ? null : _detail.text.trim();

    try {
      if (_isEditing) {
        await runUpdateQuest(
          ref: ref,
          tripId: widget.tripId,
          questId: widget.quest!.id,
          title: title,
          time: time,
          placeText: detail,
        );
      } else {
        await runAddQuest(
          ref: ref,
          tripId: widget.tripId,
          dayDate: widget.dayDate,
          title: title,
          time: time,
          placeText: detail,
        );
      }
    } catch (_) {
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    try {
      await runDeleteQuest(
        ref: ref,
        tripId: widget.tripId,
        questId: widget.quest!.id,
      );
    } catch (_) {
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final saveMutation = _isEditing ? updateQuestMutation : addQuestMutation;
    ref.listen<MutationState<dynamic>>(saveMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      }
    });
    ref.listen<MutationState<void>>(deleteQuestMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error, context.l10n),
        );
      }
    });
    final isSaving = ref.watch(saveMutation) is MutationPending;
    final isDeleting = ref.watch(deleteQuestMutation) is MutationPending;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: _autovalidate,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing
                    ? context.l10n.plan_editTitle
                    : context.l10n.plan_addTitle,
                style: AppTypography.screenTitle.copyWith(fontSize: 21),
              ),
              const SizedBox(height: AppSpacing.lg),
              CreateMemoryField(
                label: context.l10n.plan_nameLabel,
                controller: _title,
                hintText: context.l10n.plan_nameHint,
                textInputAction: TextInputAction.next,
                validator: _validateTitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                context.l10n.plan_timeLabel,
                style: AppTypography.fieldLabel,
              ),
              const SizedBox(height: AppSpacing.sm),
              InkWell(
                onTap: _pickTime,
                borderRadius: AppRadius.cardRadius,
                child: Container(
                  width: double.infinity,
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
                      const Icon(
                        Icons.schedule,
                        color: AppColors.textTertiary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _time == null
                            ? context.l10n.plan_noTime
                            : formatQuestTime(
                                Duration(
                                  hours: _time!.hour,
                                  minutes: _time!.minute,
                                ),
                              ),
                        style: AppTypography.bodyInput.copyWith(
                          color: _time == null
                              ? AppColors.textTertiary
                              : AppColors.textPrimary,
                        ),
                      ),
                      if (_time != null) ...[
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() => _time = null),
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.textTertiary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CreateMemoryField(
                label: context.l10n.plan_detailLabel,
                controller: _detail,
                hintText: context.l10n.plan_detailHint,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xl),
              _ActionButtons(
                isEditing: _isEditing,
                isSaving: isSaving,
                isDeleting: isDeleting,
                onSave: _save,
                onDelete: _delete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Delete · Save while editing, Save alone when adding. The pair stacks
/// (Save on top) if a translation won't fit at half width (spec 4t, #241).
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.isEditing,
    required this.isSaving,
    required this.isDeleting,
    required this.onSave,
    required this.onDelete,
  });

  final bool isEditing;
  final bool isSaving;
  final bool isDeleting;
  final VoidCallback onSave;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final busy = isSaving || isDeleting;
    final save = ElevatedButton(
      onPressed: busy ? null : onSave,
      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      child: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(l10n.common_save),
    );
    if (!isEditing) return SizedBox(width: double.infinity, child: save);
    final delete = OutlinedButton.icon(
      onPressed: busy ? null : onDelete,
      icon: isDeleting
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.delete_outline),
      label: Text(l10n.common_delete),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.accentCoral,
        side: const BorderSide(color: AppColors.accentCoral),
        minimumSize: const Size.fromHeight(48),
      ),
    );
    return AdaptiveButtonPair(
      primary: save,
      secondary: delete,
      primaryLabel: l10n.common_save,
      secondaryLabel: l10n.common_delete,
      labelStyle: AppTypography.buttonLabel,
      gap: AppSpacing.md,
      // Delete also carries an icon.
      labelPadding: 56,
    );
  }
}
