import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';

class ForgotPasswordOtpPage extends StatefulWidget {
  final ColorScheme dync;

  const ForgotPasswordOtpPage({required this.dync, super.key});

  @override
  State<ForgotPasswordOtpPage> createState() => _ForgotPasswordOtpPageState();
}

class _ForgotPasswordOtpPageState extends State<ForgotPasswordOtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _focusEmail = FocusNode();
  final _focusOtp = FocusNode();
  final _focusPassword = FocusNode();
  final _focusConfirmPassword = FocusNode();

  bool _otpSent = false;
  bool _loading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  String? _info;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _focusEmail.dispose();
    _focusOtp.dispose();
    _focusPassword.dispose();
    _focusConfirmPassword.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showSnack('Please enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _info = null;
    });

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        shouldCreateUser: false,
      );

      if (!mounted) return;
      setState(() {
        _otpSent = true;
        _info = 'We sent the 8 digit OTP number to your email.';
      });
    } on AuthException catch (e) {
      _showSnack(e.message);
    } catch (_) {
      _showSnack('Could not send OTP. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _verifyOtpAndResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final otp = _otpController.text.trim();
    final password = _newPasswordController.text;

    setState(() {
      _loading = true;
      _info = null;
    });

    try {
      try {
        await Supabase.instance.client.auth.verifyOTP(
          email: email,
          token: otp,
          type: OtpType.email,
        );
      } on AuthException {
        await Supabase.instance.client.auth.verifyOTP(
          email: email,
          token: otp,
          type: OtpType.recovery,
        );
      }

      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: password),
      );

      if (!mounted) return;
      _showSnack('Password updated successfully. Please log in.');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => LoginPage(dync: widget.dync),
        ),
        (route) => false,
      );
    } on AuthException catch (e) {
      final lower = e.message.toLowerCase();
      if (lower.contains('expired') || lower.contains('invalid')) {
        _showSnack('OTP expired/invalid. Tap Resend OTP and use the latest code.');
      } else {
        _showSnack(e.message);
      }
    } catch (_) {
      _showSnack('Could not reset password. Please check OTP and try again.');
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusEmail.unfocus();
        _focusOtp.unfocus();
        _focusPassword.unfocus();
        _focusConfirmPassword.unfocus();
      },
      child: Scaffold(
        backgroundColor: widget.dync.onPrimaryContainer,
        body: SingleChildScrollView(
          child: Column(
            children: [
              _topHead(context),
              SizedBox(height: MediaQuery.of(context).size.height / 18),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _inputBox(
                      child: TextFormField(
                        controller: _emailController,
                        focusNode: _focusEmail,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !_otpSent,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.only(left: 15),
                          hintText: 'Enter your email id',
                          hintStyle: TextStyle(fontSize: 16, color: widget.dync.primary),
                          focusedBorder: InputBorder.none,
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.black),
                        validator: (value) {
                          final v = value?.trim() ?? '';
                          if (v.isEmpty || !v.contains('@')) {
                            return 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                    ),
                    if (_info != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: Text(
                          _info!,
                          style: TextStyle(
                            color: widget.dync.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (_otpSent) ...[
                      _inputBox(
                        child: TextFormField(
                          controller: _otpController,
                          focusNode: _focusOtp,
                          keyboardType: TextInputType.number,
                          maxLength: 8,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.only(left: 15),
                            hintText: 'Enter 8-digit OTP',
                            counterText: '',
                            hintStyle: TextStyle(fontSize: 16, color: widget.dync.primary),
                            focusedBorder: InputBorder.none,
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.length != 8) {
                              return 'Enter 8 digit OTP';
                            }
                            return null;
                          },
                        ),
                      ),
                      _inputBox(
                        child: TextFormField(
                          controller: _newPasswordController,
                          focusNode: _focusPassword,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.only(left: 15),
                            hintText: 'New Password',
                            hintStyle: TextStyle(fontSize: 16, color: widget.dync.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                                color: widget.dync.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            focusedBorder: InputBorder.none,
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (value) {
                            final v = value ?? '';
                            if (v.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                      ),
                      _inputBox(
                        child: TextFormField(
                          controller: _confirmPasswordController,
                          focusNode: _focusConfirmPassword,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.only(left: 15),
                            hintText: 'Confirm Password',
                            hintStyle: TextStyle(fontSize: 16, color: widget.dync.primary),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                color: widget.dync.primary,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            focusedBorder: InputBorder.none,
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: Colors.black),
                          validator: (value) {
                            if ((value ?? '') != _newPasswordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _actionButton(
                      label: !_otpSent ? 'Send OTP' : 'Verify OTP & Reset Password',
                      onTap: _loading
                          ? null
                          : (!_otpSent ? _sendOtp : _verifyOtpAndResetPassword),
                    ),
                    if (_otpSent)
                      TextButton(
                        onPressed: _loading ? null : _sendOtp,
                        child: const Text('Resend OTP'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Container _topHead(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 20),
      height: MediaQuery.of(context).size.height / 3.4,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: widget.dync.primary,
        image: const DecorationImage(
          image: AssetImage('assets/Studentbackpack.png'),
          scale: 1.4,
          alignment: Alignment.bottomRight,
        ),
      ),
      child: const Text(
        'Reset\nPassword',
        style: TextStyle(fontSize: 36, color: Colors.white),
      ),
    );
  }

  Container _inputBox({required Widget child}) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: widget.dync.inversePrimary,
        border: Border.all(color: Colors.black),
        borderRadius: const BorderRadius.all(Radius.circular(20)),
      ),
      child: child,
    );
  }

  GestureDetector _actionButton({
    required String label,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: MediaQuery.of(context).size.height / 17,
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.dync.primary,
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        width: 100,
        child: Center(
          child: _loading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(color: Colors.white),
                ),
        ),
      ),
    );
  }
}
