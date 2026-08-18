import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../../../trip/presentation/widgets/memory_text_field.dart';
import '../../domain/entities/quest_entity.dart';
import '../mutations/quest_mutations.dart';
import 'quest_time_format.dart';

/// Add/edit bottom sheet reusing the old design's interaction pattern: name
/// → time → save; editing shows the same fields plus Save/Delete (the new
/// Figma file has no sheet for this frame — see issue #15).
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
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
    if ((value ?? '').trim().isEmpty) return 'Give this plan a name.';
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
          message: presentationFailureMessage(next.error),
        );
      }
    });
    ref.listen<MutationState<void>>(deleteQuestMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });
    final isSaving = ref.watch(saveMutation) is MutationPending;
    final isDeleting = ref.watch(deleteQuestMutation) is MutationPending;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
          border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.base,
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
              Text(
                _isEditing ? 'Edit plan' : 'Add plan',
                style: AppTypography.headlineSerif,
              ),
              const SizedBox(height: AppSpacing.lg),
              MemoryTextField(
                label: 'Name this plan',
                controller: _title,
                icon: Icons.edit_outlined,
                iconTint: AppColors.primaryTint,
                iconColor: AppColors.primary,
                hintText: 'e.g. Pack the car',
                textInputAction: TextInputAction.next,
                validator: _validateTitle,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Time (optional)', style: AppTypography.fieldLabel),
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
                            ? 'No time set'
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
              MemoryTextField(
                label: 'Detail (optional)',
                controller: _detail,
                icon: Icons.notes_outlined,
                iconTint: AppColors.accentPurpleTint,
                iconColor: AppColors.accentPurple,
                hintText: 'e.g. Cooler, blankets, hiking boots',
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  if (_isEditing) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isSaving || isDeleting ? null : _delete,
                        icon: isDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.delete_outline),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.accentCoral,
                          side: const BorderSide(color: AppColors.accentCoral),
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSaving || isDeleting ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
