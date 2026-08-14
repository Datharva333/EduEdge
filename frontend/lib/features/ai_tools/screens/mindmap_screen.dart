import 'package:flutter/material.dart';
import '../../../../services/mock_service.dart';

class MindMapScreen extends StatelessWidget {
  final String lessonId;
  const MindMapScreen({super.key, required this.lessonId});

  Map<String, List<String>> _getMindMap(String id) {
    switch (id) {
      case '1':
        return {
          'Photosynthesis': [
            'Sunlight → Energy',
            'CO2 + Water → Glucose',
            'Chlorophyll captures light',
            'Produces Oxygen',
            'Happens in leaves',
          ],
        };
      case '2':
        return {
          "Newton's Laws": [
            'Law 1: Inertia',
            'Law 2: F = ma',
            'Law 3: Action = Reaction',
            'Foundation of mechanics',
            'Applies to all objects',
          ],
        };
      case '3':
        return {
          'World War II': [
            '1939 - 1945',
            'Germany invaded Poland',
            'Battle of Britain',
            'D-Day 1944',
            'Atomic bombs 1945',
          ],
        };
      default:
        return {
          'Topic': ['No mind map available yet'],
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lesson = MockService.lessons.firstWhere(
      (l) => l['id'] == lessonId,
      orElse: () => MockService.lessons.first,
    );
    final mindMap = _getMindMap(lessonId);
    final center = mindMap.keys.first;
    final nodes = mindMap.values.first;

    return Scaffold(
      appBar: AppBar(title: Text('${lesson['subject']} Mind Map')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Text(
                center,
                style: TextStyle(
                  color: scheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(width: 2, height: 20, color: scheme.primary),
            ...nodes.asMap().entries.map((entry) {
              return Column(
                children: [
                  Container(width: 2, height: 16, color: Colors.grey.shade300),
                  Row(
                    children: [
                      Expanded(
                        child: entry.index % 2 == 0
                            ? _buildNode(context, entry.value, scheme, true)
                            : const SizedBox(),
                      ),
                      Container(
                        width: 40,
                        height: 2,
                        color: Colors.grey.shade300,
                      ),
                      Expanded(
                        child: entry.index % 2 != 0
                            ? _buildNode(context, entry.value, scheme, false)
                            : const SizedBox(),
                      ),
                    ],
                  ),
                ],
              );
            }),
            const SizedBox(height: 40),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Key Points',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...nodes.map(
                    (n) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: scheme.primary),
                          const SizedBox(width: 8),
                          Expanded(child: Text(n)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNode(
    BuildContext context,
    String text,
    ColorScheme scheme,
    bool isLeft,
  ) {
    return Align(
      alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.secondaryContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: scheme.onSecondaryContainer,
            fontWeight: FontWeight.w500,
          ),
          textAlign: isLeft ? TextAlign.right : TextAlign.left,
        ),
      ),
    );
  }
}

extension on MapEntry<int, String> {
  get index => null;
}
