import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/mock_service.dart';

class FlashcardScreen extends StatefulWidget {
  final String lessonId;
  const FlashcardScreen({super.key, required this.lessonId});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  int _current = 0;
  bool _flipped = false;
  bool _done = false;

  List<Map<String, String>> _getCards(String id) {
    switch (id) {
      case '1':
        return [
          {
            'front': 'What is the standard form of a quadratic equation?',
            'back': 'ax² + bx + c = 0, where a ≠ 0.',
          },
          {
            'front': 'What is the discriminant?',
            'back': 'D = b² - 4ac. It determines the nature of the roots.',
          },
          {
            'front': 'What is the quadratic formula?',
            'back': 'x = (-b ± √(b² - 4ac)) / (2a)',
          },
          {
            'front': 'What does D = 0 mean?',
            'back': 'The quadratic equation has two equal real roots.',
          },
        ];
      case '2':
        return [
          {
            'front': 'What is a mixture?',
            'back':
                'Two or more substances physically combined in any proportion without a chemical change.',
          },
          {
            'front': 'What is a solution?',
            'back':
                'A homogeneous mixture consisting of a solute dissolved in a solvent.',
          },
          {
            'front': 'What is the Tyndall effect?',
            'back':
                'The scattering of light by particles in a colloid or suspension.',
          },
          {
            'front': 'How is a compound different from a mixture?',
            'back':
                'A compound has elements chemically combined in a fixed proportion; a mixture does not.',
          },
        ];
      case '3':
        return [
          {
            'front': 'What does a tense show?',
            'back': 'The time of an action, event, or state.',
          },
          {
            'front': 'When is the simple present used?',
            'back': 'For habits, routines, repeated actions, and general truths.',
          },
          {
            'front': 'When is the simple past used?',
            'back': 'For actions that were completed in the past.',
          },
          {
            'front': 'How is the simple future commonly formed?',
            'back': 'With will followed by the base form of the verb.',
          },
        ];
      default:
        return [
          {
            'front': 'No flashcards available',
            'back': 'Return to the AI Hub and select an available lesson.',
          },
        ];
    }
  }

  void _rate(String rating) {
    if (rating == 'Again') {
      // don't count score
    } else {}

    final cards = _getCards(widget.lessonId);
    if (_current < cards.length - 1) {
      setState(() {
        _current++;
        _flipped = false;
      });
    } else {
      setState(() => _done = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = _getCards(widget.lessonId);
    final lesson = MockService.lessons.firstWhere(
      (l) => l['id'] == widget.lessonId,
      orElse: () => MockService.lessons.first,
    );

    if (_done) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(title: const Text('Session Complete')),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Session Complete',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reviewed all ${cards.length} cards',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => setState(() {
                      _current = 0;
                      _flipped = false;
                      _done = false;
                    }),
                    child: const Text('Review Again'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final card = cards[_current];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text('${lesson['subject']} Flashcards')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Card ${_current + 1} of ${cards.length}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  card['topic'] ?? lesson['subject'],
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (_current + 1) / cards.length,
              backgroundColor: AppTheme.borderSubtle,
              valueColor: const AlwaysStoppedAnimation(AppTheme.textPrimary),
              minHeight: 2,
            ),
            const SizedBox(height: 24),

            // Card
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _flipped = !_flipped),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    key: ValueKey(_flipped),
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _flipped
                            ? AppTheme.textPrimary
                            : AppTheme.border,
                        width: _flipped ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Icon(
                              Icons.rotate_right,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _flipped ? 'Answer' : 'Prompt',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              _flipped ? card['back']! : card['front']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: _flipped ? 14 : 18,
                                fontWeight: _flipped
                                    ? FontWeight.w400
                                    : FontWeight.w500,
                                color: AppTheme.textPrimary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          _flipped ? 'Rate your recall below' : 'Tap to reveal',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Rating buttons
            if (_flipped) ...[
              Row(
                children: [
                  Expanded(
                    child: _RatingButton(
                      label: 'Again',
                      onTap: () => _rate('Again'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RatingButton(
                      label: 'Hard',
                      onTap: () => _rate('Hard'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RatingButton(
                      label: 'Good',
                      filled: true,
                      onTap: () => _rate('Good'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RatingButton(
                      label: 'Easy',
                      onTap: () => _rate('Easy'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => setState(() => _flipped = true),
                  child: const Text('Reveal Answer'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _RatingButton({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? AppTheme.textPrimary : AppTheme.borderSubtle,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: filled ? Colors.white : AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}
