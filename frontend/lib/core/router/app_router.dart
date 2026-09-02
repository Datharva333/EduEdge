// ignore_for_file: unnecessary_underscores

import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/lesson/screens/lesson_screen.dart';
import '../../features/ai_tools/screens/ai_hub_screen.dart';
import '../../features/ai_tools/screens/quiz_screen.dart';
import '../../features/ai_tools/screens/mindmap_screen.dart';
import '../../features/ai_tools/screens/flashcard_screen.dart';
import '../../features/progress/screens/progress_screen.dart';
import '../../features/ai_tools/screens/chat_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
      GoRoute(path: '/home', builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: '/lesson/:id',
        builder: (_, state) =>
            LessonScreen(lessonId: state.pathParameters['id'] ?? '1'),
      ),
      GoRoute(path: '/ai', builder: (_, _) => const AiHubScreen()),
      GoRoute(
        path: '/ai/:lessonId',
        builder: (_, state) =>
            AiHubScreen(lessonId: state.pathParameters['lessonId']),
      ),
      GoRoute(path: '/aihub', builder: (_, _) => const AiHubScreen()),
      GoRoute(
        path: '/aihub/:lessonId',
        builder: (_, state) =>
            AiHubScreen(lessonId: state.pathParameters['lessonId']),
      ),
      GoRoute(
        path: '/quiz/:lessonId',
        builder: (_, state) =>
            QuizScreen(lessonId: state.pathParameters['lessonId'] ?? '1'),
      ),
      GoRoute(
        path: '/mindmap/:lessonId',
        builder: (_, state) =>
            MindMapScreen(lessonId: state.pathParameters['lessonId'] ?? '1'),
      ),
      GoRoute(
        path: '/flashcards/:lessonId',
        builder: (_, state) =>
            FlashcardScreen(lessonId: state.pathParameters['lessonId'] ?? '1'),
      ),
      GoRoute(path: '/progress', builder: (_, _) => const ProgressScreen()),
      GoRoute(
        path: '/chat/:lessonId',
        builder: (_, state) =>
            ChatScreen(lessonId: state.pathParameters['lessonId'] ?? '1'),
      ),
    ],
  );
}
