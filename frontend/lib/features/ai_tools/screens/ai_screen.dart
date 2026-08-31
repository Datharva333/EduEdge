import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../services/api_service.dart';
import '../../../services/mock_service.dart';

class AiScreen extends StatefulWidget {
  final String? lessonId;
  const AiScreen({super.key, this.lessonId});

  @override
  State<AiScreen> createState() => _AiScreenState();
}

class _AiScreenState extends State<AiScreen> {
  String? _summary;
  bool _loading = false;
  late String _selectedLessonId;
  bool _autoTriggered = false;

  @override
  void initState() {
    super.initState();
    _selectedLessonId = widget.lessonId ?? '1';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_autoTriggered && widget.lessonId != null) {
      _autoTriggered = true;
      _summarize();
    }
  }

  Future<void> _summarize() async {
    setState(() {
      _loading = true;
      _summary = null;
    });
    final result = await ApiService.summarize(_selectedLessonId);
    if (mounted) {
      setState(() {
        _summary = result;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lessons = MockService.lessons;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('AI Tools')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              initialValue: _selectedLessonId,
              decoration: const InputDecoration(
                labelText: 'Select Lesson',
                border: OutlineInputBorder(),
              ),
              items: lessons
                  .map(
                    (l) => DropdownMenuItem(
                      value: l['id'] as String,
                      child: Text(l['title']),
                    ),
                  )
                  .toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() {
                    _selectedLessonId = val;
                    _summary = null;
                  });
                }
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Summarize'),
                    onPressed: _loading ? null : _summarize,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.quiz),
                    label: const Text('Take Quiz'),
                    onPressed: _loading
                        ? null
                        : () => context.push('/quiz/$_selectedLessonId'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loading) const Center(child: CircularProgressIndicator()),
            if (_summary != null && !_loading)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'AI Summary',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _summary!,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(height: 1.6),
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
