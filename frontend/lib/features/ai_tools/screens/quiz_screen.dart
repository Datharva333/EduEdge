import 'package:flutter/material.dart';
import '../../../services/mock_service.dart';

class QuizScreen extends StatefulWidget {
  final String lessonId;
  const QuizScreen({super.key, required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late List<Map<String, dynamic>> _questions;
  int _current = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _questions = _getQuestionsForLesson(widget.lessonId);
  }

  List<Map<String, dynamic>> _getQuestionsForLesson(String lessonId) {
    switch (lessonId) {
      case '1':
        return [
          {
            'q': 'What is the main purpose of photosynthesis?',
            'options': [
              'To absorb water',
              'To convert sunlight into food',
              'To release CO2',
              'To grow roots',
            ],
            'answer': 1,
          },
          {
            'q': 'What does chlorophyll do?',
            'options': [
              'Absorbs water',
              'Produces oxygen only',
              'Captures light energy',
              'Breaks down glucose',
            ],
            'answer': 2,
          },
          {
            'q': 'What gas do plants absorb during photosynthesis?',
            'options': ['Oxygen', 'Nitrogen', 'Carbon Dioxide', 'Hydrogen'],
            'answer': 2,
          },
        ];
      case '2':
        return [
          {
            'q': "What does Newton's first law describe?",
            'options': ['Gravity', 'Inertia', 'Acceleration', 'Friction'],
            'answer': 1,
          },
          {
            'q': 'What is the formula for Newton\'s second law?',
            'options': ['F=mv', 'F=ma', 'F=m/a', 'F=a/m'],
            'answer': 1,
          },
          {
            'q': "Newton's third law states every action has?",
            'options': [
              'No reaction',
              'A bigger reaction',
              'An equal and opposite reaction',
              'A smaller reaction',
            ],
            'answer': 2,
          },
        ];
      case '3':
        return [
          {
            'q': 'When did World War II begin?',
            'options': ['1935', '1937', '1939', '1941'],
            'answer': 2,
          },
          {
            'q': 'Which country did Germany invade to start WWII?',
            'options': ['France', 'Poland', 'Russia', 'Britain'],
            'answer': 1,
          },
          {
            'q': 'When did World War II end?',
            'options': ['1943', '1944', '1945', '1946'],
            'answer': 2,
          },
        ];
      default:
        return [
          {
            'q': 'This lesson has no quiz yet.',
            'options': ['OK', 'Got it', 'Understood', 'Fine'],
            'answer': 0,
          },
        ];
    }
  }

  void _answer(int index) {
    if (_answered) return;
    setState(() {
      _selected = index;
      _answered = true;
      if (index == _questions[_current]['answer']) _score++;
    });
  }

  void _next() {
    if (_current < _questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lesson = MockService.lessons.firstWhere(
      (l) => l['id'] == widget.lessonId,
      orElse: () => MockService.lessons.first,
    );

    if (_done) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz Complete')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.emoji_events_rounded,
                  size: 80,
                  color: scheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  '$_score / ${_questions.length}',
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _score == _questions.length
                      ? 'Perfect score! 🎉'
                      : _score >= _questions.length / 2
                      ? 'Good job! 👍'
                      : 'Keep practicing! 💪',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 40),
                FilledButton(
                  onPressed: () => setState(() {
                    _current = 0;
                    _score = 0;
                    _selected = null;
                    _answered = false;
                    _done = false;
                  }),
                  child: const Text('Try Again'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final q = _questions[_current];
    final options = List<String>.from(q['options']);

    return Scaffold(
      appBar: AppBar(title: Text('${lesson['subject']} Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: (_current + 1) / _questions.length,
              backgroundColor: scheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${_current + 1} of ${_questions.length}',
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Text(
              q['q'],
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ...List.generate(options.length, (i) {
              Color? color;
              if (_answered) {
                if (i == q['answer'])
                  color = Colors.green.shade50;
                else if (i == _selected)
                  color = Colors.red.shade50;
              }
              return GestureDetector(
                onTap: () => _answer(i),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color ?? scheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _answered && i == q['answer']
                          ? Colors.green
                          : _answered && i == _selected
                          ? Colors.red
                          : Colors.grey.shade300,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(options[i])),
                      if (_answered && i == q['answer'])
                        const Icon(Icons.check_circle, color: Colors.green),
                      if (_answered && i == _selected && i != q['answer'])
                        const Icon(Icons.cancel, color: Colors.red),
                    ],
                  ),
                ),
              );
            }),
            const Spacer(),
            if (_answered)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(
                    _current < _questions.length - 1
                        ? 'Next Question'
                        : 'See Results',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
