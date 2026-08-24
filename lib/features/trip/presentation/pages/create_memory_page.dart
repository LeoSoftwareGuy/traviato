import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../mutations/trip_mutations.dart';
import '../widgets/cover_options.dart';
import '../widgets/cover_picker.dart';
import '../widgets/create_memory_field.dart';
import '../widgets/memory_date_range_field.dart';
import '../widgets/vibe_chip_group.dart';
import 'validate_memory_dates.dart';

class CreateMemoryPage extends ConsumerStatefulWidget {
  const CreateMemoryPage({super.key});

  @override
  ConsumerState<CreateMemoryPage> createState() => _CreateMemoryPageState();
}

class _CreateMemoryPageState extends ConsumerState<CreateMemoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _destination = TextEditingController();
  var _autovalidate = AutovalidateMode.disabled;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _dateError;
  final _vibes = <String>{};
  String? _selectedCoverId;

  @override
  void dispose() {
    _name.dispose();
    _destination.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Give this memory a name.';
    return null;
  }

  bool _validateDates() {
    final error = validateMemoryDates(_startDate, _endDate);
    setState(() => _dateError = error);
    return error == null;
  }

  Future<void> _submit() async {
    setState(() => _autovalidate = AutovalidateMode.always);
    final formValid = _formKey.currentState?.validate() ?? false;
    final datesValid = _validateDates();
    if (!formValid || !datesValid) return;

    final coverId = _selectedCoverId ?? suggestedCover(_vibes).id;

    try {
      await runCreateMemory(
        ref: ref,
        name: _name.text.trim(),
        destination: _destination.text.trim().isEmpty
            ? null
            : _destination.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        vibes: _vibes.toList(),
        coverImagePath: assetCoverImagePath(coverId),
      );
    } catch (_) {
      // Surfaced to the user via the mutation's MutationError state below.
      return;
    }
    if (!mounted) return;
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<MutationState<dynamic>>(createMemoryMutation, (previous, next) {
      if (next is MutationError) {
        showErrorSnackbar(
          context,
          message: presentationFailureMessage(next.error),
        );
      }
    });
    final isLoading = ref.watch(createMemoryMutation) is MutationPending;

    return Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.screenGroundRadial(
            AppGradients.groundTopLandingAuth,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(onCancel: () => context.pop()),
                const SizedBox(height: AppSpacing.base),
                CoverPicker(
                  selectedCoverId: _selectedCoverId,
                  selectedVibes: _vibes,
                  onSelect: (id) => setState(() => _selectedCoverId = id),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'What deserves',
                  style: AppTypography.screenTitle.copyWith(fontSize: 30),
                ),
                Text(
                  'a memory?',
                  style: AppTypography.screenTitle.copyWith(
                    fontSize: 30,
                    fontStyle: FontStyle.italic,
                    color: AppColors.primaryLight,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Form(
                  key: _formKey,
                  autovalidateMode: _autovalidate,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CreateMemoryField(
                        label: 'Name it',
                        controller: _name,
                        hintText: 'e.g. Summer in Tokyo',
                        valueStyle: AppTypography.screenTitle.copyWith(
                          fontSize: 19,
                        ),
                        textInputAction: TextInputAction.next,
                        validator: _validateName,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      CreateMemoryField(
                        label: 'Where did it happen?',
                        controller: _destination,
                        hintText: 'Where did this happen?',
                        textInputAction: TextInputAction.done,
                        trailing: const Icon(
                          Icons.my_location,
                          color: AppColors.primary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      MemoryDateRangeField(
                        startDate: _startDate,
                        endDate: _endDate,
                        onStartDateChanged: (date) {
                          setState(() => _startDate = date);
                          _validateDates();
                        },
                        onEndDateChanged: (date) {
                          setState(() => _endDate = date);
                          _validateDates();
                        },
                        errorText: _dateError,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      VibeChipGroup(
                        selected: _vibes,
                        onToggle: (vibe) => setState(() {
                          if (!_vibes.remove(vibe)) _vibes.add(vibe);
                        }),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      const _RewardNudgeCard(),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Create memory'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkWell(
          onTap: onCancel,
          borderRadius: AppRadius.badgeRadius,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.close,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text('Cancel', style: AppTypography.chipLabel),
              ],
            ),
          ),
        ),
        Text(
          'NEW MEMORY',
          style: AppTypography.mono.copyWith(color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

class _RewardNudgeCard extends StatelessWidget {
  const _RewardNudgeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.tint(AppColors.accentPurple, .1),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: AppColors.tint(AppColors.accentPurple, .32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.accentPurpleTint,
              borderRadius: AppRadius.badgeRadius,
            ),
            child: Text(
              '✦',
              style: AppTypography.bodyInput.copyWith(
                color: AppColors.accentPurple,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTypography.chipLabel.copyWith(
                  color: AppColors.textSecondary,
                ),
                children: [
                  const TextSpan(text: 'Creating this earns '),
                  TextSpan(
                    text: '10 stars',
                    style: AppTypography.chipLabel.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const TextSpan(
                    text:
                        ". Log a note each day and you'll unlock "
                        'Storyteller.',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
