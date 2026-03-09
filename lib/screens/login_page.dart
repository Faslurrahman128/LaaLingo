import 'package:flutter/material.dart';
import 'package:LaaLingo/ResourcePage/Resource.dart';
import 'package:LaaLingo/admin/inshome.dart';
import 'package:LaaLingo/screens/register_page.dart';
import 'package:LaaLingo/utils/validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:LaaLingo/app_config.dart';
import 'package:LaaLingo/screens/language_select_page.dart';
import 'package:LaaLingo/supabase_langs.dart';
import '../supabase_auth.dart';

class LoginPage extends StatefulWidget {
  late ColorScheme dync;
  LoginPage({required this.dync});
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
      Future<void> _magicLinkDialog(BuildContext context) async {
        final emailController = TextEditingController();
        final result = await showDialog<String>(
          context: context,
          builder: (ctx) {
            return AlertDialog(
              title: const Text('Magic Link Login'),
              content: TextField(
                controller: emailController,
                decoration: const InputDecoration(hintText: 'Enter your email'),
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(emailController.text.trim()),
                  child: const Text('Send Link'),
                ),
              ],
            );
          },
        );
        final email = result?.trim() ?? '';
        if (email.isEmpty) return;
        try {
          await Supabase.instance.client.auth.signInWithOtp(email: email);
          displayMessage('Magic link sent to $email. Check your inbox.');
        } catch (e, stack) {
          displayMessage('Could not send magic link.\n${e.toString()}\n$stack');
        }
      }
    Future<void> _resetPasswordDialog(BuildContext context) async {
      final emailController = TextEditingController();
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Reset Password'),
            content: TextField(
              controller: emailController,
              decoration: const InputDecoration(hintText: 'Enter your email'),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(emailController.text.trim()),
                child: const Text('Send'),
              ),
            ],
          );
        },
      );
      final email = result?.trim() ?? '';
      if (email.isEmpty) return;
      try {
        // Try to sign in with a dummy password to check if the user exists
        await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: 'dummyPasswordThatWillNeverBeCorrect',
        );
        // If sign-in succeeds (should not happen), do nothing
      } on AuthException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('invalid login credentials') || msg.contains('invalid email or password')) {
          // User exists, send reset email
          await Supabase.instance.client.auth.resetPasswordForEmail(email);
          displayMessage('Password reset email sent to $email');
        } else if (msg.contains('user not found')) {
          // User does not exist
          displayMessage('No account found for this email address. Please check and try again, or register for a new account.');
        } else {
          displayMessage('Could not send reset email.\n'+e.toString());
        }
      } catch (e, stack) {
        displayMessage('Could not send reset email.\n'+e.toString()+'\n$stack');
      }
    }
  final _formKey = GlobalKey<FormState>();
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();
  bool _isProcessing = false;

  void displayMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
  }

  String _friendlyAuthMessage(AuthException e) {
    final msg = e.message;
    final lower = msg.toLowerCase();

    if (lower.contains('email not confirmed')) {
      if (AppConfig.requireEmailConfirmation) {
        return 'Please confirm your email, then log in.';
      }
      return 'Email not confirmed. For now, disable email confirmation in Supabase Auth settings (or confirm via inbox).';
    }
    if (lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a bit and try again.';
    }

    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusEmail.unfocus();
        _focusPassword.unfocus();
      },
      child: Scaffold(
        backgroundColor: widget.dync.onPrimaryContainer,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 0, right: 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                tophead(context, widget.dync.primary),
                SizedBox(
                  height: MediaQuery.of(context).size.height / 18,
                ),
                formfield(context)
              ],
            ),
          ),
        ),
      ),
    );
  }

  Form formfield(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: widget.dync.inversePrimary,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: TextFormField(
              controller: _emailTextController,
              focusNode: _focusEmail,
              validator: (value) => Validator.validateEmail(
                email: value,
              ),
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(left: 15),
                  hintText: "Enter your email id",
                  hintStyle:
                      TextStyle(fontSize: 16, color: widget.dync.primary),
                  focusedBorder: InputBorder.none,
                  border: InputBorder.none),
              style: TextStyle(color: Colors.black),
            ),
          ),
          SizedBox(height: 8.0),
          Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: widget.dync.inversePrimary,
                border: Border.all(color: Colors.black),
                borderRadius: BorderRadius.all(Radius.circular(20))),
            child: TextFormField(
              controller: _passwordTextController,
              focusNode: _focusPassword,
              obscureText: true,
              validator: (value) => Validator.validatePassword(
                password: value,
              ),
              decoration: InputDecoration(
                  contentPadding: EdgeInsets.only(left: 15),
                  hintStyle:
                      TextStyle(fontSize: 16, color: widget.dync.primary),
                  hintText: "Your Password",
                  focusedBorder: InputBorder.none,
                  border: InputBorder.none),
              style: TextStyle(color: Colors.black),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => _resetPasswordDialog(context),
              child: const Text('Forgot Password?'),
            ),
          ),
          SizedBox(height: 24.0),
          _isProcessing
              ? CircularProgressIndicator()
              : Row(
                  children: [
                    Expanded(child: signinbutton(context)),
                  ],
                ),
          SizedBox(
            height: 20,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Don’t have an account ? "),
              GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RegisterPage(
                          dync: widget.dync,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Register",
                    style: TextStyle(color: Color.fromARGB(200, 139, 61, 241)),
                  )),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Or log in with a magic link: "),
              TextButton(
                onPressed: () => _magicLinkDialog(context),
                child: const Text('Send Magic Link'),
              ),
            ],
          ),
          SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Instructor Login? "),
              GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => InsHome(
                          dync: widget.dync,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Click Here",
                    style: TextStyle(color: Color.fromARGB(200, 139, 61, 241)),
                  )),
            ],
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 6,
          ),
        ],
      ),
    );
  }

  GestureDetector signinbutton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isProcessing) return;

        _focusEmail.unfocus();
        _focusPassword.unfocus();

        if (!(_formKey.currentState?.validate() ?? false)) return;

        setState(() {
          _isProcessing = true;
        });

        try {
          final response = await SupabaseAuth.signIn(
            email: _emailTextController.text.trim(),
            password: _passwordTextController.text,
          );

          if (!mounted) return;

          if (response.session == null) {
            displayMessage('Login failed. Please check your credentials.');
            return;
          }

          final email = Supabase.instance.client.auth.currentUser?.email;
          if (email == null || email.isEmpty) {
            displayMessage('Login succeeded, but no email found.');
            return;
          }

          int count = 0;
          bool hasLangSelected = false;
          try {
            // Load existing profile (if any)
            final row = await Supabase.instance.client
                .from('user')
                .select('email,count_lang,langs')
                .eq('email', email)
                .maybeSingle();

            if (row == null) {
              final metaName = Supabase.instance.client.auth.currentUser?.userMetadata?['name'];
              final resolvedName = (metaName is String && metaName.trim().isNotEmpty)
                  ? metaName.trim()
                  : email;
              // Insert defaults only when missing (don't overwrite existing users).
              await Supabase.instance.client.from('user').insert({
                'email': email,
                'name': resolvedName,
                'leader_board': 0,
                'status': false,
                'avtar_url': '',
                'count_lang': 0,
              });
              count = 0;
              hasLangSelected = false;
            } else {
              final countLang = row['count_lang'] ?? 0;
              count = (countLang is num)
                  ? countLang.toInt()
                  : int.tryParse(countLang.toString()) ?? 0;

              // Prefer real language selection state over count_lang.
              final slot1 = getLangSlot(row, 1);
              final selected = slot1?['Selected_lang'];
              hasLangSelected = selected is List && selected.length >= 2;
            }
          } catch (_) {
            // ignore and continue
          }


          // Requirement: after login, always show Language Selection first.
          // Clear the route stack so browser/system back can't jump back to Login.
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => LanguageSelectPage(dync: widget.dync),
            ),
            (route) => false,
          );
          return;
        } on AuthException catch (e) {
          displayMessage(_friendlyAuthMessage(e));
          return;
        } catch (e) {
          displayMessage(e.toString());
          return;
        } finally {
          if (mounted) {
            setState(() {
              _isProcessing = false;
            });
          }
        }
      },
      child: Container(
        height: MediaQuery.of(context).size.height / 17,
        margin: EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: widget.dync.primary,
            borderRadius: BorderRadius.all(Radius.circular(20))),
        width: 100,
        child: Center(
          child: Text(
            'Log In',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

Container tophead(BuildContext context, col) {
  return Container(
    padding: EdgeInsets.only(left: 20),
    height: MediaQuery.of(context).size.height / 3.4,
    width: double.infinity,
    alignment: Alignment.centerLeft,
    decoration: BoxDecoration(
        color: col,
        image: DecorationImage(
            image: AssetImage("assets/Studentbackpack.png"),
            scale: 1.4,
            alignment: Alignment.bottomRight)),
    child: Text(
      "Hi user\nWelcome\nback",
      style: TextStyle(fontSize: 36, color: Colors.white),
    ),
  );
}