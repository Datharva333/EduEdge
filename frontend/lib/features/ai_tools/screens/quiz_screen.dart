import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/mock_service.dart';

class QuizScreen extends StatefulWidget {
  final String lessonId;
  const QuizScreen({super.key, required this.lessonId});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  List<Map<String, dynamic>> _questions = [];
  bool _loading = true;
  int _current = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _loadQuiz();
  }

  Future<void> _loadQuiz() async {
    setState(() {
      _loading = true;
    });

    final questions = await ApiService.getQuiz(widget.lessonId);

    if (mounted) {
      if (questions != null && questions.isNotEmpty) {
        setState(() {
          _questions = questions;
          _loading = false;
        });
      } else {
        // fallback to mock questions
        setState(() {
          _questions = _getMockQuestions(widget.lessonId);
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getMockQuestions(String lessonId) {
    switch (lessonId) {
      case '1':
        return [
          {
            'q': 'What is the standard form of a quadratic equation?',
            'options': [
              'ax² + bx + c = 0',
              'ax + b = 0',
              'a/x + b = 0',
              'ax³ + bx² + c = 0',
            ],
            'answer': 0,
          },
          {
            'q': 'What is the discriminant of ax² + bx + c = 0?',
            'options': ['b² + 4ac', 'b² - 4ac', '2a + b', 'a² - bc'],
            'answer': 1,
          },
          {
            'q': 'If the discriminant is zero, the roots are:',
            'options': [
              'Two distinct real roots',
              'Two equal real roots',
              'Always complex',
              'Undefined',
            ],
            'answer': 1,
          },
        ];
      case '2':
        return [
          {
            'q': 'A solution is what type of mixture?',
            'options': [
              'Homogeneous',
              'Heterogeneous only',
              'Pure element',
              'Pure compound',
            ],
            'answer': 0,
          },
          {
            'q': 'Which can show the Tyndall effect?',
            'options': [
              'A true solution only',
              'A colloid',
              'A pure element only',
              'A compound only',
            ],
            'answer': 1,
          },
          {
            'q': 'Which statement about a compound is correct?',
            'options': [
              'Its composition can vary freely',
              'Its elements are chemically combined in a fixed proportion',
              'It can always be separated by filtration',
              'It is always heterogeneous',
            ],
            'answer': 1,
          },
        ];
      case '3':
        return [
          {
            'q': 'Which tense is normally used for habits and routines?',
            'options': [
              'Simple present',
              'Simple past',
              'Past continuous',
              'Future continuous',
            ],
            'answer': 0,
          },
          {
            'q': 'Which sentence is in the simple past?',
            'options': [
              'She reads every day.',
              'She is reading now.',
              'She visited Delhi last year.',
              'She will visit Delhi.',
            ],
            'answer': 2,
          },
          {
            'q': 'The simple future is commonly formed using:',
            'options': [
              'was + verb',
              'will + base verb',
              'has + verb',
              'did + -ing',
            ],
            'answer': 1,
          },
        ];
      default:
        return [
          {
            'q': 'No quiz is currently available for this lesson.',
            'options': ['Return', 'Retry', 'Refresh', 'Continue'],
            'answer': 1,
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

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text('${lesson['subject']} Quiz')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Generating quiz questions...'),
            ],
          ),
        ),
      );
    }

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
                if (i == q['answer']) {
                  color = Colors.green.shade50;
                } else if (i == _selected) {
                  color = Colors.red.shade50;
                }
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
