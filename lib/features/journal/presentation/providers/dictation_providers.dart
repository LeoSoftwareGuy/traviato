import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/datasources/speech_to_text_dictation_service.dart';
import '../../domain/dictation/dictation_service.dart';

part 'dictation_providers.g.dart';

/// Kept alive: the platform recogniser is initialised once per app run.
@Riverpod(keepAlive: true)
DictationService dictationService(Ref ref) => SpeechToTextDictationService();
