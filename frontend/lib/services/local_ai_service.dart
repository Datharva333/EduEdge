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
Do not reveal internal reasoning.
Give only the final answer.
Keep the answer concise.
''',
        ),
        ChatMessage(role: 'user', content: question),
      ],
      maxTokens: 100,
      temperature: 0.3,
      topP: 0.9,
      topK: 20,
    );
  }

  static Future<String> generateComplete(
    String question, {
    int maxTokens = 100,
  }) async {
    if (!_loaded) {
      await initialize();
    }

    await _controller.clearContext();

    final prompt =
        '''
<|im_start|>system
You are EduEdge, a concise CBSE Class 9 and 10 tutor.
Answer accurately using only the information provided by the user.
Use simple language suitable for a school student.
Give only the final answer.
Do not explain your reasoning.
Do not output thinking steps.
<|im_end|>
<|im_start|>user
$question
<|im_end|>
<|im_start|>assistant
<think>

</think>

''';

    debugPrint('');
    debugPrint('=============== GENERATION =====================');
    debugPrint('Model: $_loadedModelPath');
    debugPrint('Max output tokens: $maxTokens');

    final stopwatch = Stopwatch()..start();
    final buffer = StringBuffer();

    await for (final token in _controller.generate(
      prompt: prompt,
      maxTokens: maxTokens,
      temperature: 0.3,
      topP: 0.9,
      topK: 20,
      minP: 0.0,
      presencePenalty: 0.0,
      repeatPenalty: 1.05,
    )) {
      buffer.write(token);
    }

    stopwatch.stop();

    var answer = buffer.toString().trim();

    answer = _cleanGeneratedAnswer(answer);

    debugPrint('');
    debugPrint('ANSWER:');
    debugPrint(answer);

    debugPrint(
      'GENERATION COMPLETED IN: '
      '${(stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} seconds',
    );

    debugPrint('================================================');
    debugPrint('');

    if (answer.isEmpty) {
      throw Exception('The local AI did not produce a final answer.');
    }

    return answer;
  }

  static String _cleanGeneratedAnswer(String answer) {
    var cleaned = answer
        .replaceAll(
          RegExp(r'<think>.*?</think>', dotAll: true, caseSensitive: false),
          '',
        )
        .replaceAll(
          RegExp(r'<think>.*$', dotAll: true, caseSensitive: false),
          '',
        )
        .trim();

    cleaned = cleaned
        .replaceAll('**', '')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\times', '×');

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\\sqrt\{([^{}]+)\}'),
      (match) => '√(${match.group(1)})',
    );

    cleaned = cleaned.replaceAllMapped(
      RegExp(r'\\frac\{([^{}]+)\}\{([^{}]+)\}'),
      (match) => '(${match.group(1)})/(${match.group(2)})',
    );

    cleaned = cleaned
        .replaceAll('^2', '²')
        .replaceAll('^3', '³')
        .replaceAll(r'\(', '')
        .replaceAll(r'\)', '')
        .replaceAll(r'\[', '')
        .replaceAll(r'\]', '')
        .replaceAll('\$', '')
        .trim();

    return cleaned;
  }

  static Future<String> summarizeLesson(String lessonText) async {
    var content = lessonText.trim();

    if (content.length > 1600) {
      content = content.substring(0, 1600);

      final lastSpace = content.lastIndexOf(' ');

      if (lastSpace > 1200) {
        content = content.substring(0, lastSpace);
      }
    }

    final prompt =
        '''
Create a short summary of the CBSE lesson below.

Rules:
- Return exactly 4 bullet points.
- Each bullet must be one short sentence.
- Use only facts explicitly stated in the lesson.
- Do not infer, invent, or add information.
- Use simple Class 9 or 10 language.
- Include only the most important concepts.
- Give only the four bullet points.
- Use plain text.
- Do not use Markdown bold.
- Do not use LaTeX.
- Do not use dollar signs or backslashes.
- Write mathematics using normal symbols such as x², ±, √ and ≠.

LESSON:
$content
''';

    return generateComplete(prompt, maxTokens: 90);
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

  static Future<String> answerQuestion({
    required String lessonText,
    required String question,
    String style = 'concise',
  }) async {
    var content = lessonText.trim();

    if (content.length > 1600) {
      content = content.substring(0, 1600);

      final lastSpace = content.lastIndexOf(' ');
      if (lastSpace > 1200) {
        content = content.substring(0, lastSpace);
      }
    }

    String styleInstruction;

    switch (style) {
      case 'socratic':
        styleInstruction =
            'Explain briefly, then end with one helpful question for the student.';
        break;

      case 'feynman':
        styleInstruction =
            'Explain the answer in very simple language as if teaching a beginner.';
        break;

      default:
        styleInstruction =
            'Give a short and direct answer in 2 to 4 sentences.';
    }

    final prompt =
        '''
Answer the student's question using the lesson below.

Rules:
- Use only facts stated in the lesson.
- If the lesson does not contain enough information, say: "This lesson does not contain enough information to answer that."
- Do not invent facts.
- Use simple Class 9 or 10 language.
- $styleInstruction
- Give only the final answer.
- Do not show reasoning.
- Do not use LaTeX.

LESSON:
$content

STUDENT QUESTION:
$question
''';

    return generateComplete(prompt, maxTokens: 100);
  }
}
