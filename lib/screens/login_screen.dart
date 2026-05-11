import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await context.read<AuthProvider>().login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
      
      if (!mounted) return;
      // Success is handled by AuthProvider state change listener or StreamBuilder in main
      
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'VELOCITY\nMATH',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        fontSize: 48,
                      ),
                ),
                const SizedBox(height: 48),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: InputDecoration(
                    labelText: 'USERNAME',
                    prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.text.withOpacity(0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: const TextStyle(color: AppTheme.text),
                  decoration: InputDecoration(
                    labelText: 'PASSWORD',
                    prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primary),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.text.withOpacity(0.3)),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: AppTheme.error),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: AppTheme.primary),
                          )
                        : const Text('LOGIN'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () async {
                      setState(() => _isLoading = true);
                      try {
                        await context.read<AuthProvider>().signInWithGoogle();
                      } catch (e) {
                         debugPrint("Login Error: $e");
                         if (mounted) {
                            showDialog(
                              context: context, 
                              builder: (c) => AlertDialog(
                                title: const Text("Sign In Failed", style: TextStyle(color: Colors.red)),
                                // Show the cleaned error message from provider
                                content: Text(e.toString().replaceAll("Exception: ", "")),
                                actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("OK"))]
                              )
                            );
                         }
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    icon: const Icon(Icons.g_mobiledata, size: 32, color: AppTheme.text),
                    label: const Text("SIGN IN WITH GOOGLE", style: TextStyle(color: AppTheme.text)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.text.withOpacity(0.3)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => context.read<AuthProvider>().signInWithGoogleRedirect(),
                  child: const Text("Having trouble? Try Redirect Mode", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                     Navigator.of(context).push(
                       MaterialPageRoute(builder: (_) => const RegisterScreen()),
                     );
                  },
                  child: const Text('CREATE ACCOUNT'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
