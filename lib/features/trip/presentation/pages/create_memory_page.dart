import 'package:flutter/material.dart';
import 'package:flutter_riverpod/experimental/mutation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/failure_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/show_error_snackbar.dart';
import '../mutations/trip_mutations.dart';
import '../widgets/memory_date_range_field.dart';
import '../widgets/memory_text_field.dart';
import '../widgets/trip_images.dart';
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('New memory'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.base,
            vertical: AppSpacing.base,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _MemoryPrompt(),
              const SizedBox(height: AppSpacing.xl),
              Form(
                key: _formKey,
                autovalidateMode: _autovalidate,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MemoryTextField(
                      label: 'Name this memory',
                      controller: _name,
                      icon: Icons.edit_outlined,
                      iconTint: AppColors.primaryTint,
                      iconColor: AppColors.primary,
                      hintText: 'e.g. Summer in Tokyo',
                      textInputAction: TextInputAction.next,
                      validator: _validateName,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    MemoryTextField(
                      label: 'Where was it?',
                      controller: _destination,
                      icon: Icons.place_outlined,
                      iconTint: AppColors.accentCoralTint,
                      iconColor: AppColors.accentCoral,
                      hintText: 'Where did this happen?',
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: AppSpacing.lg),
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
                    const SizedBox(height: AppSpacing.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: isLoading ? null : _submit,
                        icon: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Create memory'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Static decorative prompt above the form — no photo upload in this issue
/// (that lands with #M3-1/#M3-6).
class _MemoryPrompt extends StatelessWidget {
  const _MemoryPrompt();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.mediaRadius,
      child: Container(
        height: 198,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(TripImages.newMemory, fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, AppColors.backgroundScrim],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            const Positioned(
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Icon(
                Icons.auto_awesome,
                color: AppColors.textOnPhoto,
                size: 28,
              ),
            ),
            Positioned(
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Something worth remembering?',
                    style: AppTypography.chipLabel.copyWith(
                      color: AppColors.textOnPhotoMuted,
                    ),
                  ),
                  Text(
                    'What deserves a memory?',
                    style: AppTypography.headlineSerif.copyWith(
                      color: AppColors.textOnPhoto,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
