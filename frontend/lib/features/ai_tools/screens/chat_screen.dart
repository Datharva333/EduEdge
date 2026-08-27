import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/mock_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  final String lessonId;
  const ChatScreen({super.key, required this.lessonId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scroll = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _addWelcome();
  }

  void _addWelcome() {
    final lesson = MockService.lessons.firstWhere(
      (l) => l['id'] == widget.lessonId,
      orElse: () => MockService.lessons.first,
    );
    _messages.add(
      ChatMessage(
        text:
            'Hi! I\'m your AI tutor for "${lesson['title']}". Ask me anything about this lesson!',
        isUser: false,
        time: DateTime.now(),
      ),
    );
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add(
        ChatMessage(text: text, isUser: true, time: DateTime.now()),
      );
      _loading = true;
      _ctrl.clear();
    });

    _scrollToBottom();

    final reply = await ApiService.chat(text, widget.lessonId);

    if (mounted) {
      setState(() {
        _messages.add(
          ChatMessage(
            text:
                reply ??
                'Sorry, I could not get a response. Make sure the backend is running.',
            isUser: false,
            time: DateTime.now(),
          ),
        );
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lesson = MockService.lessons.firstWhere(
      (l) => l['id'] == widget.lessonId,
      orElse: () => MockService.lessons.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('AI Tutor'),
            Text(
              lesson['title'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _TypingIndicator();
                }
                final msg = _messages[index];
                return _MessageBubble(message: msg, scheme: scheme);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    decoration: InputDecoration(
                      hintText: 'Ask about ${lesson['subject']}...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _send(),
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _send,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final ColorScheme scheme;

  const _MessageBubble({required this.message, required this.scheme});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? scheme.primary : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? scheme.onPrimary : scheme.onSurface,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 40,
              child: Text(
                '...',
                style: TextStyle(
                  fontSize: 20,
                  letterSpacing: 2,
                  color: Colors.grey,
                ),
              ),
            ),
            Text(
              'AI is thinking',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
