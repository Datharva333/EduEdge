import 'package:go_router/go_router.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/lesson/screens/lesson_screen.dart';
import '../../features/ai_tools/screens/ai_screen.dart';
import '../../features/progress/screens/progress_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(
        path: '/lesson/:id',
        builder: (_, state) =>
            LessonScreen(lessonId: state.pathParameters['id'] ?? '1'),
      ),
      GoRoute(path: '/ai', builder: (_, __) => const AiScreen()),
      GoRoute(
        path: '/ai/:lessonId',
        builder: (_, state) =>
            AiScreen(lessonId: state.pathParameters['lessonId']),
      ),
      GoRoute(path: '/progress', builder: (_, __) => const ProgressScreen()),
    ],
  );
}
