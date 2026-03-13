import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


class ResetPasswordPage extends StatefulWidget {
  final String accessToken;
  final String refreshToken;
  const ResetPasswordPage({Key? key, required this.accessToken, required this.refreshToken}) : super(key: key);

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _error;
  bool _sessionReady = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setSessionIfNeeded();
  }

  Future<void> _setSessionIfNeeded() async {
    if (widget.accessToken.isNotEmpty && widget.refreshToken.isNotEmpty) {
      try {
        final supabase = Supabase.instance.client;
        await supabase.auth.setSession(
          AccessTokenResponse(
            accessToken: widget.accessToken,
            refreshToken: widget.refreshToken,
            tokenType: 'bearer',
            expiresIn: 3600,
            user: null,
          ),
        );
        setState(() {
          _sessionReady = true;
        });
      } catch (e) {
        setState(() {
          _error = 'Could not authenticate reset session.';
        });
      }
    } else {
      setState(() {
        _error = 'Invalid reset link.';
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
        // This will update the password for the currently authenticated user (after magic link/session from reset email)
        await supabase.auth.updateUser(
          UserAttributes(password: _passwordController.text),
        );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated! Please log in.')),
        );
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } on AuthException catch (e) {
      setState(() {
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _error = 'Unexpected error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Password')),
      body: Center(
        child: _sessionReady
            ? SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Enter your new password',
                          style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'New Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          } else if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(_error!, style: const TextStyle(color: Colors.red)),
                        ),
                      ElevatedButton(
                        onPressed: _loading ? null : _resetPassword,
                        child: _loading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Set New Password'),
                      ),
                    ],
                  ),
                ),
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!, style: const TextStyle(color: Colors.red)),
                  )
                : const CircularProgressIndicator(),
      ),
    );
  }
}
