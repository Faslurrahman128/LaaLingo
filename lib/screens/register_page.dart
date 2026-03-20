import 'package:flutter/material.dart';
import 'package:LaaLingo/admin/insregister.dart';
import 'package:LaaLingo/screens/login_page.dart';
import 'package:LaaLingo/utils/validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:LaaLingo/app_config.dart';
import '../supabase_auth.dart';

class RegisterPage extends StatefulWidget {
  late ColorScheme dync;
  RegisterPage({required this.dync});
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _registerFormKey = GlobalKey<FormState>();
  final _nameTextController = TextEditingController();
  final _emailTextController = TextEditingController();
  final _passwordTextController = TextEditingController();
  final _focusName = FocusNode();
  final _focusEmail = FocusNode();
  final _focusPassword = FocusNode();
  bool _isProcessing = false;
  bool _obscurePassword = true;

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

    if (lower.contains('rate limit')) {
      return 'Too many sign-up attempts right now. Please wait a bit and try again.';
    }
    if (lower.contains('email not confirmed')) {
      if (AppConfig.requireEmailConfirmation) {
        return 'Please confirm your email, then log in.';
      }
      return 'Email not confirmed (disabled for now in the app). If login fails, disable email confirmation in Supabase Auth settings or confirm via inbox.';
    }
    if (lower.contains('already registered') || lower.contains('user already')) {
      return 'This email is already registered. Please log in.';
    }

    return msg;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        _focusName.unfocus();
        _focusEmail.unfocus();
        _focusPassword.unfocus();
      },
      child: Scaffold(
        backgroundColor: widget.dync.onPrimaryContainer,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(0.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  tophead(context),
                  SizedBox(
                    height: MediaQuery.of(context).size.height / 18,
                  ),
                  Form(
                    key: _registerFormKey,
                    child: Column(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: widget.dync.inversePrimary,
                              border: Border.all(color: Colors.black),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                          child: TextFormField(
                            controller: _nameTextController,
                            focusNode: _focusName,
                            validator: (value) => Validator.validateName(
                              name: value,
                            ),
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(left: 15),
                                hintText: "Enter your name",
                                hintStyle: TextStyle(
                                    fontSize: 16, color: widget.dync.primary),
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
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                          child: TextFormField(
                            controller: _emailTextController,
                            focusNode: _focusEmail,
                            validator: (value) => Validator.validateEmail(
                              email: value,
                            ),
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(left: 15),
                                hintText: "Enter your email id",
                                hintStyle: TextStyle(
                                    fontSize: 16, color: widget.dync.primary),
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
                              borderRadius:
                                  BorderRadius.all(Radius.circular(20))),
                          child: TextFormField(
                            controller: _passwordTextController,
                            focusNode: _focusPassword,
                            obscureText: _obscurePassword,
                            validator: (value) => Validator.validatePassword(
                              password: value,
                            ),
                            decoration: InputDecoration(
                                contentPadding: EdgeInsets.only(left: 15),
                                hintStyle: TextStyle(
                                    fontSize: 16, color: widget.dync.primary),
                                hintText: "Your Password",
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: widget.dync.primary,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                focusedBorder: InputBorder.none,
                                border: InputBorder.none),
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                        SizedBox(height: 24.0),
                        _isProcessing
                            ? CircularProgressIndicator()
                            : Row(
                                children: [
                                  Expanded(child: signupbutton(context)),
                                ],
                              ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Already have an account ? "),
                      GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => LoginPage(
                                  dync: widget.dync,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            "Login",
                            style: TextStyle(
                                color: Color.fromARGB(200, 139, 61, 241)),
                          )),
                    ],
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Are you an Instructor ? "),
                      GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) => RegisterInstructor(
                                        dync: widget.dync,
                                      )),
                            );
                          },
                          child: Text(
                            "Click here",
                            style: TextStyle(
                                color: Color.fromARGB(200, 139, 61, 241)),
                          )),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  GestureDetector signupbutton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (_isProcessing) return;

        _focusName.unfocus();
        _focusEmail.unfocus();
        _focusPassword.unfocus();

        if (!(_registerFormKey.currentState?.validate() ?? false)) return;

        setState(() {
          _isProcessing = true;
        });

        try {
          final response = await SupabaseAuth.signUp(
            email: _emailTextController.text.trim(),
            password: _passwordTextController.text,
            name: _nameTextController.text.trim(),
          );

          if (!mounted) return;

          if (response.user == null) {
            displayMessage('Registration failed. Please try again.');
            return;
          }

          // Create (or update) the public profile row used by leaderboard/progress.
          // Keep this best-effort to avoid blocking signup on DB/RLS issues.
          try {
            final email = _emailTextController.text.trim();
            final name = _nameTextController.text.trim();
            await Supabase.instance.client.from('user').upsert({
              'email': email,
              'name': name.isEmpty ? email : name,
              'leader_board': 0,
              'status': false,
              'avtar_url': '',
              'count_lang': 0,
            });
          } catch (_) {
            // ignore
          }

          if (response.session == null) {
            displayMessage(
              AppConfig.requireEmailConfirmation
                  ? 'Account created. Please confirm your email, then log in.'
                  : 'Account created. You can log in now.',
            );
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => LoginPage(
                dync: widget.dync,
              ),
            ),
          );
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
            'Sign Up',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  Container tophead(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(left: 20),
      height: MediaQuery.of(context).size.height / 3.4,
      width: double.infinity,
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
          color: widget.dync.primary,
          image: DecorationImage(
              scale: 1.4,
              image: AssetImage("assets/Studentbackpack.png"),
              alignment: Alignment.bottomRight)),
      child: Text(
        "Hi user \nRegister",
        style: TextStyle(fontSize: 36, color: Colors.white),
      ),
    );
  }
}