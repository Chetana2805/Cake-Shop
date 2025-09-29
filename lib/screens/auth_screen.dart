// lib/screens/auth_screen.dart

import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? _phoneNumber;
  bool _isLogin = true;
  bool _isLoading = false;
  String? _errorMessage;

  // UI state
  bool _obscurePassword = true;
  double _passwordStrength = 0.0; // 0.0 - 1.0
  String _passwordStrengthLabel = 'Too weak';
  Timer? _debounceTimer;

  final List<String> _commonPasswords = [
    'password', '12345678', 'qwerty', '123456789', '123456',
    'letmein', 'password1', 'admin', 'iloveyou'
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onPasswordChanged);
    _nameController.addListener(_onDependentFieldChanged);
    _emailController.addListener(_onDependentFieldChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _passwordController.removeListener(_onPasswordChanged);
    _nameController.removeListener(_onDependentFieldChanged);
    _emailController.removeListener(_onDependentFieldChanged);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onDependentFieldChanged() {
    if (!_isLogin) _evaluatePasswordStrength(_passwordController.text);
  }

  void _onPasswordChanged() {
    if (!_isLogin) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 150), () {
        _evaluatePasswordStrength(_passwordController.text);
      });
    }
  }

  void _evaluatePasswordStrength(String password) {
    final pass = password.trim();
    if (pass.isEmpty) {
      setState(() {
        _passwordStrength = 0.0;
        _passwordStrengthLabel = 'Too weak';
      });
      return;
    }

    double score = 0.0;

    if (pass.length >= 8) {
      score += 0.25;
      if (pass.length >= 12) score += 0.05;
    }

    final hasLower = RegExp(r'[a-z]').hasMatch(pass);
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pass);
    final hasDigit = RegExp(r'\d').hasMatch(pass);
    final hasSpecial = RegExp(r'[@$!%*?&^#\-\+_=~`.,;:<>/\\\[\]\(\)\{\}]').hasMatch(pass);

    final variety = [hasLower, hasUpper, hasDigit, hasSpecial].where((v) => v).length;
    score += (variety / 4) * 0.35;

    final lowered = pass.toLowerCase();

    for (final common in _commonPasswords) {
      if (lowered == common || lowered.contains(common)) {
        score -= 0.4;
        break;
      }
    }

    if (_hasRepeatedSequences(pass) || _hasSequentialChars(pass)) score -= 0.2;

    final name = _nameController.text.trim().toLowerCase();
    if (name.isNotEmpty) {
      for (final part in name.split(RegExp(r'\s+'))) {
        if (part.length >= 3 && lowered.contains(part)) {
          score -= 0.25;
          break;
        }
      }
    }

    final emailLocal = _extractEmailLocalPart(_emailController.text.trim());
    if (emailLocal.isNotEmpty) {
      for (final part in emailLocal.split(RegExp(r'[\.\-_]'))) {
        if (part.length >= 3 && lowered.contains(part)) {
          score -= 0.25;
          break;
        }
      }
    }

    score = score.clamp(0.0, 1.0);

    String label;
    if (score < 0.25) label = 'Very weak';
    else if (score < 0.5) label = 'Weak';
    else if (score < 0.75) label = 'Good';
    else label = 'Strong';

    setState(() {
      _passwordStrength = score;
      _passwordStrengthLabel = label;
    });
  }

  bool _hasRepeatedSequences(String s) {
    final lowered = s.toLowerCase();
    if (RegExp(r'(.)\1\1').hasMatch(lowered)) return true;
    for (int len = 2; len <= 4; len++) {
      for (int i = 0; i + len * 2 <= lowered.length; i++) {
        if (lowered.substring(i, i + len) == lowered.substring(i + len, i + len * 2)) return true;
      }
    }
    return false;
  }

  bool _hasSequentialChars(String s) {
    final seq = s.toLowerCase();
    if (seq.length < 4) return false;
    int forward = 1, backward = 1;
    for (int i = 1; i < seq.length; i++) {
      if (seq.codeUnitAt(i) == seq.codeUnitAt(i - 1) + 1) {
        forward++;
        backward = 1;
      } else if (seq.codeUnitAt(i) == seq.codeUnitAt(i - 1) - 1) {
        backward++;
        forward = 1;
      } else {
        forward = backward = 1;
      }
      if (forward >= 4 || backward >= 4) return true;
    }
    return false;
  }

  String _extractEmailLocalPart(String email) {
    final idx = email.indexOf('@');
    return (idx <= 0) ? email.toLowerCase() : email.substring(0, idx).toLowerCase();
  }

  String? _passwordValidator(String? value) {
    if (_isLogin) {
      if (value == null || value.trim().isEmpty) return 'Please enter password';
      return null; // only not empty check for login
    }

    final v = (value ?? '').trim();
    if (v.isEmpty) return 'Please enter password';
    if (v.length < 8) return 'Minimum 8 characters required';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Include at least 1 uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Include at least 1 lowercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Include at least 1 number';
    if (!RegExp(r'[@$!%*?&^#\-\+_=~`.,;:<>/\\\[\]\(\)\{\}]').hasMatch(v)) {
      return 'Include at least 1 special character';
    }

    final lowered = v.toLowerCase();
    final name = _nameController.text.trim().toLowerCase();
    if (name.isNotEmpty) {
      for (final part in name.split(RegExp(r'\s+'))) {
        if (part.length >= 3 && lowered.contains(part)) return 'Password should not contain parts of your name';
      }
    }

    final emailLocal = _extractEmailLocalPart(_emailController.text.trim());
    if (emailLocal.isNotEmpty) {
      for (final part in emailLocal.split(RegExp(r'[\.\-_]'))) {
        if (part.length >= 3 && lowered.contains(part)) return 'Password should not contain parts of your email';
      }
    }

    for (final common in _commonPasswords) {
      if (lowered == common || lowered.contains(common)) return 'This password is too common';
    }

    if (_hasRepeatedSequences(v) || _hasSequentialChars(v)) return 'Avoid repeated or sequential characters';

    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_isLogin && (_phoneNumber == null || _phoneNumber!.trim().isEmpty)) {
      setState(() => _errorMessage = 'Phone number is required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      User? user;
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();

      if (_isLogin) {
        user = (await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        )).user;
      } else {
        user = (await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        )).user;

        if (user != null) {
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'fullName': _nameController.text.trim(),
            'phone': _phoneNumber,
            'email': email,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
      }

      if (user != null && mounted) Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      String msg = 'Authentication failed';
      switch (e.code) {
        case 'email-already-in-use': msg = 'Email is already registered.'; break;
        case 'weak-password': msg = 'Password is too weak.'; break;
        case 'invalid-email': msg = 'Invalid email address.'; break;
        case 'user-not-found': msg = 'No account found with this email.'; break;
        case 'wrong-password': msg = 'Incorrect password.'; break;
        default: msg = e.message ?? msg;
      }
      setState(() => _errorMessage = msg);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      setState(() => _errorMessage = 'Something went wrong: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool get _canSubmit {
    final emailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(_emailController.text.trim());
    final passwordError = _passwordValidator(_passwordController.text);
    if (_isLogin) {
      return emailValid && passwordError == null && !_isLoading;
    } else {
      final nameValid = _nameController.text.trim().length >= 2;
      final phoneValid = _phoneNumber != null && _phoneNumber!.trim().length >= 10;
      return nameValid && emailValid && phoneValid && passwordError == null && !_isLoading;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(image: AssetImage('assets/bakery_bg.jpg'), fit: BoxFit.cover),
            ),
            child: Container(
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.45)),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Card(
                  elevation: 14,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isLogin ? 'Welcome back' : 'Create your account',
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _isLogin ? 'Login to continue' : 'Sign up to place orders quickly',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 20),

                          if (!_isLogin)
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Full name',
                                prefixIcon: Icon(Icons.person),
                                hintText: 'John Doe',
                              ),
                              validator: (value) {
                                if (_isLogin) return null;
                                if (value == null || value.trim().isEmpty) return 'Please enter your full name';
                                if (value.trim().length < 3) return 'Enter a valid name';
                                final nameRegex = RegExp(r"^[a-zA-ZÀ-ÿ ,.'-]+$");
                                if (!nameRegex.hasMatch(value.trim())) return 'Invalid characters in name';
                                if (value.trim().split(RegExp(r'\s+')).length < 2) return 'Please enter first and last name';
                                return null;
                              },
                            ),
                          if (!_isLogin) const SizedBox(height: 12),

                          TextFormField(
                            controller: _emailController,
                            textInputAction: TextInputAction.next,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email),
                              hintText: 'you@example.com',
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Please enter your email';
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
                              if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              hintText: _isLogin
                                  ? 'Enter your password'
                                  : 'Min 8 chars, upper, lower, number & special',
                            ),
                            validator: _passwordValidator,
                          ),
                          const SizedBox(height: 8),

                          if (!_isLogin)
                            Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: _passwordStrength,
                                    minHeight: 8,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _passwordStrength <= 0.25
                                          ? Colors.red
                                          : _passwordStrength <= 0.5
                                              ? Colors.orange
                                              : _passwordStrength <= 0.75
                                                  ? Colors.lightGreen
                                                  : Colors.green,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                SizedBox(
                                  width: 90,
                                  child: Text(
                                    _passwordStrengthLabel,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: _passwordStrength <= 0.25
                                          ? Colors.red
                                          : _passwordStrength <= 0.5
                                              ? Colors.orange
                                              : _passwordStrength <= 0.75
                                                  ? Colors.green[700]
                                                  : Colors.green[800],
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (!_isLogin) const SizedBox(height: 14),

                          if (!_isLogin)
                            IntlPhoneField(
                              decoration: const InputDecoration(
                                labelText: 'Phone number',
                                border: OutlineInputBorder(),
                              ),
                              initialCountryCode: 'IN',
                              onChanged: (phone) => _phoneNumber = phone.completeNumber,
                              validator: (value) {
                                if (_isLogin) return null;
                                if (value == null || value.number.isEmpty) return 'Phone number is required';
                                if (value.number.length < 8) return 'Enter a valid number';
                                return null;
                              },
                            ),
                          if (!_isLogin) const SizedBox(height: 18),

                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                _errorMessage!,
                                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                              ),
                            ),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _canSubmit ? _submit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _canSubmit ? Colors.pink : Colors.grey,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isLoading
                                  ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Text(_isLogin ? 'Login' : 'Create account', style: const TextStyle(fontSize: 16)),
                            ),
                          ),

                          const SizedBox(height: 12),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isLogin ? "Don't have an account?" : 'Already have an account?'),
                              TextButton(
                                onPressed: () => setState(() {
                                  _isLogin = !_isLogin;
                                  _errorMessage = null;
                                }),
                                child: Text(_isLogin ? 'Sign up' : 'Login'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
