import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../services/api_service.dart';
import '../../lesson/models/lesson.dart';
import '../../lesson/providers/lesson_provider.dart';

class AiHubScreen extends StatefulWidget {
  final String? lessonId;

  const AiHubScreen({super.key, this.lessonId});

  @override
  State<AiHubScreen> createState() => _AiHubScreenState();
}

class _AiHubScreenState extends State<AiHubScreen> {
  final TextEditingController _topicController = TextEditingController();

  String? _selectedLessonId;
  String? _summary;
  String? _summaryError;
  bool _loadingSummary = false;
  bool _checkingStatus = true;
  bool _backendOnline = false;
  bool _aiOnline = false;
  double? _responseTime;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _selectedLessonId = widget.lessonId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _initialize();
  }

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    await Future.wait([
      _checkServices(),
      context.read<LessonProvider>().loadLessons(),
    ]);

    if (!mounted) return;
    _ensureSelectedLesson(context.read<LessonProvider>().lessons);
  }

  Future<void> _checkServices() async {
    if (mounted) {
      setState(() => _checkingStatus = true);
    }

    final results = await Future.wait([
      ApiService.isBackendUp(),
      ApiService.isAiEngineUp(),
    ]);

    if (!mounted) return;
    setState(() {
      _backendOnline = results[0];
      _aiOnline = results[1];
      _checkingStatus = false;
    });
  }

  void _ensureSelectedLesson(List<Lesson> lessons) {
    if (lessons.isEmpty) {
      if (_selectedLessonId != null) {
        setState(() => _selectedLessonId = null);
      }
      return;
    }

    final requestedExists = lessons.any(
      (lesson) => lesson.id == _selectedLessonId,
    );

    if (!requestedExists) {
      setState(() => _selectedLessonId = lessons.first.id);
    }
  }

  Future<void> _refresh() async {
    await Future.wait([
      _checkServices(),
      context.read<LessonProvider>().loadLessons(force: true),
    ]);

    if (!mounted) return;
    _ensureSelectedLesson(context.read<LessonProvider>().lessons);
  }

  Future<void> _summarize() async {
    final lessonId = _selectedLessonId;
    if (lessonId == null) {
      setState(() => _summaryError = 'Select a lesson before summarizing.');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loadingSummary = true;
      _summary = null;
      _summaryError = null;
      _responseTime = null;
    });

    final stopwatch = Stopwatch()..start();

    try {
      final result = await ApiService.summarize(
        lessonId,
        topic: _topicController.text,
      );
      stopwatch.stop();

      if (!mounted) return;
      setState(() {
        _summary = result;
        _responseTime = stopwatch.elapsedMilliseconds / 1000;
        _aiOnline = true;
      });
    } on ApiException catch (error) {
      stopwatch.stop();
      if (!mounted) return;
      setState(() {
        _summaryError = error.message;
        _responseTime = stopwatch.elapsedMilliseconds / 1000;
        if (error.statusCode == 503) {
          _aiOnline = false;
        }
      });
    } finally {
      if (mounted) {
        setState(() => _loadingSummary = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lessonProvider = context.watch<LessonProvider>();
    final selectedLesson = _selectedLesson(lessonProvider.lessons);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Hub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadingSummary ? null : _refresh,
            tooltip: 'Refresh services and lessons',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: [
            _ServiceStatusCard(
              checking: _checkingStatus,
              backendOnline: _backendOnline,
              aiOnline: _aiOnline,
            ),
            const SizedBox(height: 24),
            Text(
              'Select Lesson',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildLessonSelector(lessonProvider),
            const SizedBox(height: 16),
            TextField(
              controller: _topicController,
              enabled: !_loadingSummary && selectedLesson != null,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                if (!_loadingSummary && selectedLesson != null) {
                  _summarize();
                }
              },
              decoration: const InputDecoration(
                labelText: 'Focus topic (optional)',
                hintText: 'e.g. colloids, concentration, Tyndall effect',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.filter_alt_outlined),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'AI Tools',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              childAspectRatio: 2.2,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _HubButton(
                  icon: Icons.auto_awesome,
                  label: 'Summarize',
                  color: scheme.primary,
                  loading: _loadingSummary,
                  onTap: selectedLesson == null ? null : _summarize,
                ),
                _HubButton(
                  icon: Icons.quiz,
                  label: 'Quiz',
                  color: Colors.teal,
                  onTap: selectedLesson == null
                      ? null
                      : () => context.push('/quiz/${selectedLesson.id}'),
                ),
                _HubButton(
                  icon: Icons.account_tree,
                  label: 'Mind Map',
                  color: Colors.purple,
                  onTap: selectedLesson == null
                      ? null
                      : () => context.push('/mindmap/${selectedLesson.id}'),
                ),
                _HubButton(
                  icon: Icons.style,
                  label: 'Flashcards',
                  color: Colors.orange,
                  onTap: selectedLesson == null
                      ? null
                      : () => context.push('/flashcards/${selectedLesson.id}'),
                ),
                _HubButton(
                  icon: Icons.chat,
                  label: 'Ask AI',
                  color: Colors.deepPurple,
                  onTap: selectedLesson == null
                      ? null
                      : () => context.push('/chat/${selectedLesson.id}'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_loadingSummary) _GeneratingSummary(lesson: selectedLesson),
            if (_summaryError != null && !_loadingSummary)
              _SummaryError(
                message: _summaryError!,
                responseTime: _responseTime,
                onRetry: selectedLesson == null ? null : _summarize,
              ),
            if (_summary != null && !_loadingSummary)
              _SummaryCard(
                lesson: selectedLesson,
                summary: _summary!,
                responseTime: _responseTime,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonSelector(LessonProvider provider) {
    if (provider.loading && provider.lessons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: LinearProgressIndicator(),
      );
    }

    if (provider.errorMessage != null && provider.lessons.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Lessons unavailable',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(provider.errorMessage!),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (provider.lessons.isEmpty) {
      return const Text('No lessons are available yet.');
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedLessonId,
      isExpanded: true,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      items: provider.lessons
          .map(
            (lesson) => DropdownMenuItem<String>(
              value: lesson.id,
              child: Text(
                '${lesson.icon} ${lesson.title}',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      onChanged: _loadingSummary
          ? null
          : (value) {
              setState(() {
                _selectedLessonId = value;
                _summary = null;
                _summaryError = null;
                _responseTime = null;
                _topicController.clear();
              });
            },
    );
  }

  Lesson? _selectedLesson(List<Lesson> lessons) {
    final id = _selectedLessonId;
    if (id == null) return null;
    for (final lesson in lessons) {
      if (lesson.id == id) return lesson;
    }
    return null;
  }
}

class _ServiceStatusCard extends StatelessWidget {
  final bool checking;
  final bool backendOnline;
  final bool aiOnline;

  const _ServiceStatusCard({
    required this.checking,
    required this.backendOnline,
    required this.aiOnline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Service status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _StatusRow(
            label: 'Backend',
            online: backendOnline,
            checking: checking,
          ),
          const SizedBox(height: 8),
          _StatusRow(label: 'AI engine', online: aiOnline, checking: checking),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final String label;
  final bool online;
  final bool checking;

  const _StatusRow({
    required this.label,
    required this.online,
    required this.checking,
  });

  @override
  Widget build(BuildContext context) {
    final color = checking
        ? Colors.grey
        : online
        ? Colors.green
        : Colors.red;

    return Row(
      children: [
        if (checking)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        else
          Icon(
            online ? Icons.check_circle : Icons.error_outline,
            size: 18,
            color: color,
          ),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        Text(
          checking
              ? 'Checking'
              : online
              ? 'Online'
              : 'Offline',
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _GeneratingSummary extends StatelessWidget {
  final Lesson? lesson;

  const _GeneratingSummary({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              lesson == null
                  ? 'Generating summary...'
                  : 'Summarizing ${lesson!.title}...',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryError extends StatelessWidget {
  final String message;
  final double? responseTime;
  final VoidCallback? onRetry;

  const _SummaryError({
    required this.message,
    required this.responseTime,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 8),
              Text(
                'Summary failed',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message),
          if (responseTime != null) ...[
            const SizedBox(height: 6),
            Text(
              'Failed after ${responseTime!.toStringAsFixed(1)}s',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final Lesson? lesson;
  final String summary;
  final double? responseTime;

  const _SummaryCard({
    required this.lesson,
    required this.summary,
    required this.responseTime,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_awesome, size: 16),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                lesson == null ? 'AI Summary' : '${lesson!.title} Summary',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            if (responseTime != null)
              Text(
                '${responseTime!.toStringAsFixed(1)}s',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Copy summary',
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: summary));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Summary copied to clipboard'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.copy, size: 18),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SelectableText(
            summary,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }
}

class _HubButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;

  const _HubButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;

    return Material(
      color: color.withValues(alpha: enabled ? 0.1 : 0.04),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: enabled ? color : Colors.grey, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: enabled ? color : Colors.grey,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
