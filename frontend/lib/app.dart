// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'core/router/app_router.dart';
// import 'core/theme/app_theme.dart';
// import 'features/auth/providers/auth_provider.dart';
// import 'features/lesson/providers/lesson_provider.dart';

// class EduEdgeApp extends StatelessWidget {
//   const EduEdgeApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthProvider()),
//         ChangeNotifierProvider(create: (_) => LessonProvider()),
//       ],
//       child: MaterialApp.router(
//         title: 'EduEdge',
//         theme: AppTheme.light(),
//         debugShowCheckedModeBanner: false,
//         routerConfig: AppRouter.router,
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/lesson/providers/lesson_provider.dart';

class EduEdgeApp extends StatefulWidget {
  const EduEdgeApp({super.key});

  @override
  State<EduEdgeApp> createState() => _EduEdgeAppState();
}

class _EduEdgeAppState extends State<EduEdgeApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider();

    // Built once here, using the same AuthProvider instance the rest of the
    // app uses below — so the router's redirect logic and refreshListenable
    // see the real, live login state instead of a separate copy of it.
    _router = AppRouter.router(_authProvider);

    // Reads any saved profile from disk. When this finishes, it calls
    // notifyListeners(), which (via refreshListenable in AppRouter) makes
    // the router immediately re-run its redirect and send the user to the
    // right screen — no manual navigation call needed here.
    _authProvider.init();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => LessonProvider()),
      ],
      child: MaterialApp.router(
        title: 'EduEdge',
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
      ),
    );
  }
}