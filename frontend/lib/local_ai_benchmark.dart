import 'package:flutter/material.dart';

import 'services/local_ai_service.dart';

void main() {
  runApp(const LocalAiBenchmarkApp());
}

class LocalAiBenchmarkApp extends StatelessWidget {
  const LocalAiBenchmarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LocalAiBenchmarkScreen(),
    );
  }
}

class LocalAiBenchmarkScreen extends StatefulWidget {
  const LocalAiBenchmarkScreen({super.key});

  @override
  State<LocalAiBenchmarkScreen> createState() => _LocalAiBenchmarkScreenState();
}

class _LocalAiBenchmarkScreenState extends State<LocalAiBenchmarkScreen> {
  String _status = 'Ready';
  String _answer = '';
  bool _running = false;

  Future<void> _runBenchmark() async {
    if (_running) return;

    setState(() {
      _running = true;
      _status = 'Loading model...';
      _answer = '';
    });

    try {
      final loadWatch = Stopwatch()..start();

      await LocalAiService.initialize();

      loadWatch.stop();

      debugPrint('');
      debugPrint('===============================================');
      debugPrint(
        'MODEL LOAD TIME: '
        '${(loadWatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} sec',
      );

      setState(() {
        _status = 'Generating...';
      });

      final generationWatch = Stopwatch()..start();

      final answer = await LocalAiService.generateComplete(
        'Explain quadratic equations in three short sentences for a Class 10 student.',
      );

      generationWatch.stop();

      debugPrint(
        'GENERATION TIME: '
        '${(generationWatch.elapsedMilliseconds / 1000).toStringAsFixed(2)} sec',
      );

      debugPrint('');
      debugPrint('ANSWER:');
      debugPrint(answer);
      debugPrint('===============================================');
      debugPrint('');

      setState(() {
        _status = 'Completed';
        _answer = answer;
      });
    } catch (e, stackTrace) {
      debugPrint('LOCAL AI ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _running = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EduEdge Local AI Benchmark')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _status,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _running
                  ? null
                  : () async {
                      try {
                        setState(() {
                          _status = 'Choose the GGUF model...';
                        });

                        final path = await LocalAiService.importModel();

                        if (!mounted) return;

                        setState(() {
                          _status = path == null
                              ? 'Model import cancelled'
                              : 'Model imported successfully';
                        });
                      } catch (e) {
                        if (!mounted) return;

                        setState(() {
                          _status = 'Import failed: $e';
                        });

                        debugPrint('MODEL IMPORT ERROR: $e');
                      }
                    },
              child: const Text('Import GGUF Model'),
            ),
            ElevatedButton(
              onPressed: _running ? null : _runBenchmark,
              child: Text(_running ? 'Running...' : 'Run Local AI Test'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_answer, style: const TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
