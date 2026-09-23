// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:provider/provider.dart';
// import '../providers/auth_provider.dart';

// class LoginScreen extends StatefulWidget {
//   const LoginScreen({super.key});

//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final _emailCtrl = TextEditingController(text: 'student@eduedge.com');
//   final _passCtrl = TextEditingController(text: 'test1234');
//   bool _loading = false;

//   Future<void> _login() async {
//     setState(() => _loading = true);

//     final ok = await context.read<AuthProvider>().login(
//       _emailCtrl.text.trim(),
//       _passCtrl.text.trim(),
//     );

//     if (!mounted) return;

//     setState(() => _loading = false);

//     if (ok) {
//       context.go('/home');
//     }
//   }

//   @override
//   void dispose() {
//     _emailCtrl.dispose();
//     _passCtrl.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final scheme = Theme.of(context).colorScheme;
//     final error = context.watch<AuthProvider>().error;

//     return Scaffold(
//       backgroundColor: scheme.surface,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(28),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Spacer(),
//               Text(
//                 'EduEdge',
//                 style: Theme.of(context).textTheme.displaySmall?.copyWith(
//                   fontWeight: FontWeight.bold,
//                   color: scheme.primary,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 'Learn anywhere, even offline.',
//                 style: Theme.of(
//                   context,
//                 ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
//               ),
//               const SizedBox(height: 48),
//               TextField(
//                 controller: _emailCtrl,
//                 keyboardType: TextInputType.emailAddress,
//                 decoration: const InputDecoration(
//                   labelText: 'Email',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _passCtrl,
//                 obscureText: true,
//                 decoration: const InputDecoration(
//                   labelText: 'Password',
//                   border: OutlineInputBorder(),
//                 ),
//               ),
//               if (error.isNotEmpty) ...[
//                 const SizedBox(height: 12),
//                 Text(
//                   error,
//                   style: TextStyle(color: scheme.error, fontSize: 13),
//                 ),
//               ],
//               const SizedBox(height: 28),
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: FilledButton(
//                   onPressed: _loading ? null : _login,
//                   child: _loading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text('Sign in'),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: OutlinedButton(
//                   onPressed: () => context.push('/register'),
//                   child: const Text('Create Account'),
//                 ),
//               ),
//               const Spacer(flex: 2),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// One-time local onboarding: name + class, no email/password, no backend.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameCtrl = TextEditingController();
  String? _selectedClass;
  bool _loading = false;

  Future<void> _continue() async {
    setState(() => _loading = true);

    final ok = await context.read<AuthProvider>().setupProfile(
      _nameCtrl.text.trim(),
      _selectedClass ?? '',
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (ok) {
      context.go('/home');
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final error = context.watch<AuthProvider>().error;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Text(
                'EduEdge',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Learn anywhere, even offline.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 48),
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Your name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Select your class',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _ClassOption(
                      label: 'Class 9',
                      selected: _selectedClass == 'Class 9',
                      onTap: () => setState(() => _selectedClass = 'Class 9'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ClassOption(
                      label: 'Class 10',
                      selected: _selectedClass == 'Class 10',
                      onTap: () => setState(() => _selectedClass = 'Class 10'),
                    ),
                  ),
                ],
              ),
              if (error.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  error,
                  style: TextStyle(color: scheme.error, fontSize: 13),
                ),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _loading ? null : _continue,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Continue'),
                ),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClassOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ClassOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? scheme.primary : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? scheme.onPrimaryContainer : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}
