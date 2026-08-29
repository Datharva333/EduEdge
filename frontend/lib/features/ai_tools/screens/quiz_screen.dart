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
            'q': 'What are the three states of matter?',
            'options': [
              'Solid, Liquid, Gas',
              'Hot, Cold, Warm',
              'Hard, Soft, Medium',
              'Heavy, Light, Medium',
            ],
            'answer': 0,
          },
          {
            'q': 'What is the process of solid converting to liquid called?',
            'options': ['Evaporation', 'Condensation', 'Melting', 'Freezing'],
            'answer': 2,
          },
          {
            'q': 'In which state are particles most tightly packed?',
            'options': ['Gas', 'Liquid', 'Plasma', 'Solid'],
            'answer': 3,
          },
        ];
      case '5':
        return [
          {
            'q': 'What is the formula for speed?',
            'options': [
              'Speed = Distance x Time',
              'Speed = Distance / Time',
              'Speed = Time / Distance',
              'Speed = Mass / Time',
            ],
            'answer': 1,
          },
          {
            'q': 'What is displacement?',
            'options': [
              'Total path length',
              'Shortest distance between start and end',
              'Speed x Time',
              'None of these',
            ],
            'answer': 1,
          },
          {
            'q': 'What does the equation v = u + at represent?',
            'options': [
              'First equation of motion',
              'Second equation of motion',
              'Third equation of motion',
              'Law of gravity',
            ],
            'answer': 0,
          },
        ];
      case '6':
        return [
          {
            'q': "Newton's First Law is also called?",
            'options': [
              'Law of Force',
              'Law of Inertia',
              'Law of Motion',
              'Law of Action',
            ],
            'answer': 1,
          },
          {
            'q': 'What is the formula F = ma?',
            'options': [
              "Newton's First Law",
              "Newton's Second Law",
              "Newton's Third Law",
              'Law of Conservation',
            ],
            'answer': 1,
          },
          {
            'q': 'What is momentum?',
            'options': [
              'Mass / Velocity',
              'Mass x Acceleration',
              'Mass x Velocity',
              'Force x Time',
            ],
            'answer': 2,
          },
        ];
      case '7':
        return [
          {
            'q': 'When did the French Revolution begin?',
            'options': ['1776', '1789', '1799', '1804'],
            'answer': 1,
          },
          {
            'q': 'What was stormed on July 14, 1789?',
            'options': [
              'The Palace of Versailles',
              'The Bastille prison',
              'The Louvre',
              'Notre Dame',
            ],
            'answer': 1,
          },
          {
            'q': 'What were the three ideals of the French Revolution?',
            'options': [
              'Faith, Hope, Charity',
              'Liberty, Equality, Fraternity',
              'Power, Glory, Honor',
              'Land, Bread, Peace',
            ],
            'answer': 1,
          },
        ];
      case '9':
        return [
          {
            'q': 'When did India gain independence?',
            'options': [
              'August 15, 1945',
              'August 15, 1947',
              'January 26, 1950',
              'June 3, 1947',
            ],
            'answer': 1,
          },
          {
            'q': 'What was the Dandi March about?',
            'options': [
              'Protesting salt tax',
              'Demanding voting rights',
              'Fighting for land rights',
              'Boycotting cloth',
            ],
            'answer': 0,
          },
          {
            'q': 'When was the Indian National Congress founded?',
            'options': ['1857', '1875', '1885', '1905'],
            'answer': 2,
          },
        ];
      default:
        return [
          {
            'q': 'What is the main topic of this lesson?',
            'options': ['Science', 'History', 'English', 'Mathematics'],
            'answer': 0,
          },
          {
            'q': 'Which platform are you using to study?',
            'options': ['EduEdge', 'Other app', 'Textbook', 'YouTube'],
            'answer': 0,
          },
          {
            'q': 'Is offline learning important for rural students?',
            'options': ['No', 'Sometimes', 'Never', 'Yes, very important'],
            'answer': 3,
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
