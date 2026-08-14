import 'package:flutter/material.dart';
import '../../../../services/mock_service.dart';

class FlashcardScreen extends StatefulWidget {
  final String lessonId;
  const FlashcardScreen({super.key, required this.lessonId});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _current = 0;
  bool _flipped = false;

  List<Map<String, String>> _getCards(String id) {
    switch (id) {
      case '1':
        return [
          {
            'front': 'What is Photosynthesis?',
            'back':
                'The process by which plants convert sunlight into glucose using CO2 and water.',
          },
          {
            'front': 'What is Chlorophyll?',
            'back':
                'The green pigment in plants that captures light energy for photosynthesis.',
          },
          {
            'front': 'What is the equation for Photosynthesis?',
            'back': '6CO2 + 6H2O + light → C6H12O6 + 6O2',
          },
          {
            'front': 'Where does photosynthesis occur?',
            'back': 'In the chloroplasts of plant cells, mainly in the leaves.',
          },
        ];
      case '2':
        return [
          {
            'front': "What is Newton's First Law?",
            'back':
                'An object stays at rest or in motion unless acted upon by an external force. (Law of Inertia)',
          },
          {
            'front': "What is Newton's Second Law?",
            'back': 'Force equals mass times acceleration. F = ma',
          },
          {
            'front': "What is Newton's Third Law?",
            'back': 'For every action there is an equal and opposite reaction.',
          },
          {
            'front': 'What is Inertia?',
            'back':
                "The tendency of an object to resist changes in its state of motion.",
          },
        ];
      case '3':
        return [
          {
            'front': 'When did World War II start?',
            'back': 'September 1, 1939, when Germany invaded Poland.',
          },
          {
            'front': 'When did World War II end?',
            'back': 'September 2, 1945, with Japan\'s formal surrender.',
          },
          {
            'front': 'What was D-Day?',
            'back': 'June 6, 1944 — the Allied invasion of Normandy, France.',
          },
          {
            'front': 'What ended the Pacific War?',
            'back':
                'The atomic bombings of Hiroshima and Nagasaki in August 1945.',
          },
        ];
      default:
        return [
          {
            'front': 'No flashcards yet',
            'back': 'Check back when more content is added.',
          },
        ];
    }
  }

  void _next() {
    final cards = _getCards(widget.lessonId);
    if (_current < cards.length - 1) {
      setState(() {
        _current++;
        _flipped = false;
      });
    }
  }

  void _prev() {
    if (_current > 0) {
      setState(() {
        _current--;
        _flipped = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cards = _getCards(widget.lessonId);
    final lesson = MockService.lessons.firstWhere(
      (l) => l['id'] == widget.lessonId,
      orElse: () => MockService.lessons.first,
    );
    final card = cards[_current];

    return Scaffold(
      appBar: AppBar(title: Text('${lesson['subject']} Flashcards')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '${_current + 1} / ${cards.length}',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _flipped = !_flipped),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey(_flipped),
                  width: double.infinity,
                  height: 280,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: _flipped ? scheme.primaryContainer : scheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _flipped ? scheme.primary : Colors.grey.shade300,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _flipped ? 'Answer' : 'Question',
                        style: TextStyle(
                          fontSize: 12,
                          color: _flipped ? scheme.primary : Colors.grey,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _flipped ? card['back']! : card['front']!,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              height: 1.5,
                              color: _flipped
                                  ? scheme.onPrimaryContainer
                                  : null,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tap card to flip',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                    onPressed: _current > 0 ? _prev : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Next'),
                    onPressed: _current < cards.length - 1 ? _next : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_current == cards.length - 1)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => setState(() {
                    _current = 0;
                    _flipped = false;
                  }),
                  child: const Text('Start Over'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
