import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:llama_flutter_android/llama_flutter_android.dart';
import 'package:path_provider/path_provider.dart';

class LocalAiService {
  static final LlamaController _controller = LlamaController();

  static const String _modelFileName = 'Qwen3.5-0.8B-Q4_K_M.gguf';

  static bool _loaded = false;
  static String? _loadedModelPath;

  static Future<String> getModelPath() async {
    final directory = await getApplicationSupportDirectory();

    final modelPath = '${directory.path}/models/$_modelFileName';

    debugPrint('MODEL SUPPORT DIRECTORY: ${directory.path}');
    debugPrint('MODEL PATH: $modelPath');

    return modelPath;
  }

  static Future<String?> importModel() async {
    debugPrint('Opening model picker...');

    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['gguf'],
    );

    if (picked == null) {
      debugPrint('Model selection cancelled.');
      return null;
    }

    debugPrint('Selected model: ${picked.name}');

    final sourceSize = await picked.length();

    debugPrint(
      'Selected size: '
      '${(sourceSize / (1024 * 1024)).toStringAsFixed(2)} MB',
    );

    final supportDirectory = await getApplicationSupportDirectory();

    final modelDirectory = Directory('${supportDirectory.path}/models');

    if (!await modelDirectory.exists()) {
      await modelDirectory.create(recursive: true);
    }

    final destinationPath = '${modelDirectory.path}/$_modelFileName';

    final destination = File(destinationPath);

    if (await destination.exists()) {
      await destination.delete();
    }

    debugPrint('Copying model into EduEdge private storage...');
    debugPrint('Destination: $destinationPath');

    final stopwatch = Stopwatch()..start();

    final sink = destination.openWrite();

    try {
      await for (final chunk in picked.readAsByteStream()) {
        sink.add(chunk);
      }

      await sink.flush();
      await sink.close();
    } catch (error) {
      await sink.close();

      if (await destination.exists()) {
        await destination.delete();
      }

      rethrow;
    }

    stopwatch.stop();

    final copiedSize = await destination.length();

    if (copiedSize != sourceSize) {
      await destination.delete();

      throw Exception(
        'Model copy incomplete. '
        'Expected $sourceSize bytes but copied $copiedSize bytes.',
      );
    }

    debugPrint(
      'MODEL IMPORT COMPLETE IN: '
      '${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} seconds',
    );

    debugPrint(
      'IMPORTED SIZE: '
      '${(copiedSize / (1024 * 1024)).toStringAsFixed(2)} MB',
    );

    debugPrint('MODEL PATH: $destinationPath');

    return destinationPath;
  }

  static Future<void> checkModel() async {
    try {
      final modelPath = await getModelPath();
      final file = File(modelPath);

      if (!await file.exists()) {
        throw Exception('Model not found at: $modelPath');
      }

      final bytes = await file.length();
      final mb = bytes / (1024 * 1024);

      debugPrint('MODEL PATH: $modelPath');
      debugPrint('MODEL EXISTS: true');
      debugPrint('MODEL SIZE: ${mb.toStringAsFixed(2)} MB');
    } catch (error) {
      debugPrint('MODEL CHECK FAILED: $error');
      rethrow;
    }
  }

  static Future<void> initialize() async {
    if (_loaded) {
      debugPrint('Local AI model already loaded.');
      return;
    }

    debugPrint('');
    debugPrint('=============== LOCAL AI INIT ==================');

    final modelPath = await getModelPath();
    final file = File(modelPath);

    if (!await file.exists()) {
      throw Exception('Model not found before loading: $modelPath');
    }

    final bytes = await file.length();
    final mb = bytes / (1024 * 1024);

    debugPrint('Loading model: $modelPath');
    debugPrint('Model size: ${mb.toStringAsFixed(2)} MB');
    debugPrint('Threads: 4');
    debugPrint('Context size: 1024');
    debugPrint('GPU layers: 0');

    final stopwatch = Stopwatch()..start();

    try {
      await _controller.loadModel(
        modelPath: modelPath,
        threads: 4,
        contextSize: 1024,
        gpuLayers: 0,
      );
    } catch (error, stackTrace) {
      stopwatch.stop();

      debugPrint('MODEL LOAD FAILED: $error');
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }

    stopwatch.stop();

    _loaded = true;
    _loadedModelPath = modelPath;

    debugPrint(
      'MODEL LOADED IN: '
      '${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} seconds',
    );

    debugPrint('================================================');
    debugPrint('');
  }

  static Stream<String> generate(String question) {
    if (!_loaded) {
      throw StateError(
        'Local AI model has not been initialized. '
        'Call LocalAiService.initialize() first.',
      );
    }

    debugPrint('');
    debugPrint('=============== GENERATION =====================');
    debugPrint('Model: $_loadedModelPath');
    debugPrint('Question: $question');

    return _controller.generateChat(
      messages: [
        ChatMessage(
          role: 'system',
          content: '''
You are EduEdge, a concise CBSE Class 9 and 10 tutor.

Answer accurately and directly.
Use simple language suitable for a school student.
Use no more than three short sentences unless more detail is explicitly requested.
Do not include unnecessary explanations.
''',
        ),
        ChatMessage(role: 'user', content: question),
      ],
      maxTokens: 100,
      temperature: 1.0,
      topP: 1.0,
      topK: 20,
    );
  }

  static Future<String> generateComplete(String question) async {
    if (!_loaded) {
      await initialize();
    }

    final stopwatch = Stopwatch()..start();
    final buffer = StringBuffer();

    await for (final token in generate(question)) {
      buffer.write(token);
    }

    stopwatch.stop();

    var answer = buffer.toString().trim();

    answer = answer
        .replaceAll(
          RegExp(r'<think>.*?</think>', dotAll: true, caseSensitive: false),
          '',
        )
        .trim();

    debugPrint('');
    debugPrint('ANSWER:');
    debugPrint(answer);

    debugPrint(
      'GENERATION COMPLETED IN: '
      '${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} seconds',
    );

    debugPrint('================================================');
    debugPrint('');

    return answer;
  }

  static Future<void> stop() async {
    if (!_loaded) {
      return;
    }

    await _controller.stop();
  }

  static Future<void> dispose() async {
    if (!_loaded) {
      return;
    }

    await _controller.dispose();

    _loaded = false;
    _loadedModelPath = null;

    debugPrint('Local AI model disposed.');
  }

  static Future<String> summarizeLesson(String lessonText) async {
    final prompt =
        '''
Summarize the following CBSE lesson for a Class 9 or 10 student.

Rules:
- Use only the lesson content provided.
- Keep the explanation accurate.
- Use simple language.
- Include only the most important concepts.
- Write 4 to 6 short bullet points.
- Do not add information that is not in the lesson.

LESSON:
$lessonText
''';

    return generateComplete(prompt);
  }
}
