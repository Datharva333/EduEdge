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
            'front': 'What is Matter?',
            'back':
                'Anything that has mass and occupies space. Exists in three states: solid, liquid, and gas.',
          },
          {
            'front': 'What is the process of solid converting to liquid?',
            'back':
                'Melting. The temperature at which this occurs is called the melting point.',
          },
          {
            'front': 'What happens to particles in a gas?',
            'back':
                'Particles are very far apart, move rapidly, and have neither fixed shape nor volume.',
          },
          {
            'front': 'What is evaporation?',
            'back':
                'The conversion of liquid to gas. Occurs at the surface of a liquid at any temperature.',
          },
        ];
      case '4':
        return [
          {
            'front': 'What is a cell?',
            'back':
                'The basic structural and functional unit of life. All living things are made of cells.',
          },
          {
            'front': 'Who discovered cells?',
            'back':
                'Robert Hooke in 1665, when he observed cork under a microscope.',
          },
          {
            'front': 'What is the powerhouse of the cell?',
            'back':
                'Mitochondria. It produces energy through cellular respiration.',
          },
          {
            'front': 'What do plant cells have that animal cells don\'t?',
            'back': 'Cell wall, chloroplasts, and a large central vacuole.',
          },
        ];
      case '5':
        return [
          {
            'front': 'What is Speed?',
            'back':
                'Distance covered per unit time. Speed = Distance / Time. It is a scalar quantity.',
          },
          {
            'front': 'What is Velocity?',
            'back':
                'Displacement per unit time. It has both magnitude and direction — a vector quantity.',
          },
          {
            'front': 'First equation of motion',
            'back':
                'v = u + at\nwhere v = final velocity, u = initial velocity, a = acceleration, t = time',
          },
          {
            'front': 'What is Acceleration?',
            'back':
                'Rate of change of velocity. a = (v - u) / t. Can be positive (speeding up) or negative (slowing down).',
          },
        ];
      case '7':
        return [
          {
            'front': 'When did the French Revolution begin?',
            'back':
                '1789. The storming of the Bastille on July 14, 1789 is considered the symbolic start.',
          },
          {
            'front': 'What were the three estates of French society?',
            'back':
                'First Estate: Clergy\nSecond Estate: Nobility\nThird Estate: Everyone else (peasants, merchants, workers)',
          },
          {
            'front': 'What were the ideals of the French Revolution?',
            'back':
                'Liberty, Equality, Fraternity (Liberté, Égalité, Fraternité)',
          },
          {
            'front': 'Who rose to power after the French Revolution?',
            'back':
                'Napoleon Bonaparte, who used the revolutionary chaos to become Emperor of France.',
          },
        ];
      case '9':
        return [
          {
            'front': 'When did India gain independence?',
            'back':
                'August 15, 1947. The partition of India and Pakistan also occurred on this date.',
          },
          {
            'front': 'What was the Dandi March?',
            'back':
                'Gandhi\'s 240-mile walk to the sea in 1930 to make salt and protest the British salt tax. It launched the Civil Disobedience Movement.',
          },
          {
            'front': 'What was the Quit India Movement?',
            'back':
                'Launched in 1942, it demanded immediate end to British rule in India. Gandhi gave the "Do or Die" call.',
          },
          {
            'front': 'When was the Indian National Congress founded?',
            'back':
                '1885. It became the primary organization leading India\'s independence movement.',
          },
        ];
      case '11':
        return [
          {
            'front': 'Who wrote "The Fun They Had"?',
            'back':
                'Isaac Asimov. It is a science fiction short story set in the year 2157.',
          },
          {
            'front': 'Who are the main characters in "The Fun They Had"?',
            'back':
                'Margie and Tommy — two children in the future who learn about old-style schools.',
          },
          {
            'front': 'What is the main theme of "The Fun They Had"?',
            'back':
                'The contrast between cold, isolated future learning (mechanical teachers) and the warm, social learning of the past (human teachers in classrooms).',
          },
          {
            'front': 'What did Tommy find in "The Fun They Had"?',
            'back':
                'A real printed book — something extraordinary in 2157 when all learning was digital.',
          },
        ];
      default:
        return [
          {
            'front': 'What is EduEdge?',
            'back':
                'An offline-first AI learning platform for rural students that works without internet.',
          },
          {
            'front': 'What subjects does EduEdge cover?',
            'back':
                'Science, History, and English for CBSE Class 9-10 students.',
          },
          {
            'front': 'What AI features does EduEdge have?',
            'back':
                'AI Summarizer, Quiz Generator, Flashcards, Mind Maps, and Socratic Tutor chat.',
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
