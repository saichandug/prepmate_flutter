import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_controller.dart';
import '../services/api_client.dart';
import '../theme.dart';
import '../widgets/common.dart';

final _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _signup = false;
  bool _showPassword = false;
  bool _busy = false;
  Map<String, String> _errors = {};
  String? _banner;
  bool _bannerIsError = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _switchMode(bool signup, {String? info}) {
    setState(() {
      _signup = signup;
      _errors = {};
      _banner = info;
      _bannerIsError = false;
      _password.clear();
      _confirm.clear();
    });
  }

  Map<String, String> _validate() {
    final e = <String, String>{};
    final pw = _password.text;
    if (_signup && _name.text.trim().length < 2) e['name'] = 'Enter your name.';
    if (!_emailRe.hasMatch(_email.text.trim()))
      e['email'] = 'Enter a valid email address.';
    if (pw.isEmpty) {
      e['password'] = _signup ? 'Choose a password.' : 'Enter your password.';
    } else if (_signup && pw.length < 8) {
      e['password'] = 'Use at least 8 characters.';
    }
    if (_signup && _confirm.text != pw) e['confirm'] = "Passwords don't match.";
    return e;
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _banner = null);
    final found = _validate();
    setState(() => _errors = found);
    if (found.isNotEmpty) return;

    setState(() => _busy = true);
    final auth = context.read<AuthController>();
    try {
      if (_signup) {
        await auth.signup(
          _name.text.trim(),
          _email.text.trim(),
          _password.text,
        );
      } else {
        await auth.login(_email.text.trim(), _password.text);
      }
      // AuthGate switches to the workspace once the status changes.
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'ACCOUNT_NOT_FOUND') {
        _switchMode(
          true,
          info: 'No account found for this email. Create one to get started.',
        );
      } else if (e.code == 'ACCOUNT_EXISTS') {
        _switchMode(
          false,
          info: 'An account with this email already exists. Sign in instead.',
        );
      } else {
        setState(() {
          if (e.fields != null) {
            _errors = e.fields!.map((k, v) => MapEntry(k, v.toString()));
          }
          _banner = e.message;
          _bannerIsError = true;
        });
      }
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 860;
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Row(
          children: [
            if (wide) const Expanded(flex: 5, child: _AuthAside()),
            Expanded(
              flex: 6,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildForm(showBrand: !wide),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm({required bool showBrand}) {
    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showBrand) ...[
            const _Brand(dark: false),
            const SizedBox(height: 24),
          ],
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Sign in')),
              ButtonSegment(value: true, label: Text('Create account')),
            ],
            selected: {_signup},
            showSelectedIcon: false,
            onSelectionChanged: (s) => _switchMode(s.first),
          ),
          const SizedBox(height: 22),
          Text(
            _signup ? 'Create your account' : 'Welcome back',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _signup
                ? 'It takes a few seconds. Your data stays private to you.'
                : 'Sign in with your email and password to continue.',
            style: const TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 18),
          if (_banner != null) ...[
            InlineAlert(
              _banner!,
              kind: _bannerIsError ? ToastKind.error : ToastKind.info,
            ),
            const SizedBox(height: 14),
          ],
          if (_signup) ...[
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              autofillHints: const [AutofillHints.name],
              maxLength: 60,
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Your full name',
                errorText: _errors['name'],
                counterText: '',
              ),
              onChanged: (_) => setState(() => _errors.remove('name')),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email],
            autocorrect: false,
            maxLength: 254,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'you@example.com',
              errorText: _errors['email'],
              counterText: '',
            ),
            onChanged: (_) => setState(() => _errors.remove('email')),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _password,
            obscureText: !_showPassword,
            autofillHints: [
              _signup ? AutofillHints.newPassword : AutofillHints.password,
            ],
            maxLength: 128,
            textInputAction: _signup
                ? TextInputAction.next
                : TextInputAction.done,
            onSubmitted: (_) {
              if (!_signup) _submit();
            },
            decoration: InputDecoration(
              labelText: 'Password',
              hintText: _signup ? 'At least 8 characters' : 'Your password',
              errorText: _errors['password'],
              counterText: '',
              suffixIcon: IconButton(
                tooltip: _showPassword ? 'Hide password' : 'Show password',
                icon: Icon(
                  _showPassword ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _showPassword = !_showPassword),
              ),
            ),
            onChanged: (_) => setState(() => _errors.remove('password')),
          ),
          if (_signup) ...[
            const SizedBox(height: 14),
            TextField(
              controller: _confirm,
              obscureText: !_showPassword,
              autofillHints: const [AutofillHints.newPassword],
              maxLength: 128,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                labelText: 'Confirm password',
                hintText: 'Repeat your password',
                errorText: _errors['confirm'],
                counterText: '',
              ),
              onChanged: (_) => setState(() => _errors.remove('confirm')),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _busy ? null : _submit,
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: Colors.white,
                    ),
                  )
                : Text(_signup ? 'Create account' : 'Sign in'),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _signup ? 'Already have an account?' : 'New to PrepMate?',
                style: const TextStyle(color: AppColors.muted),
              ),
              TextButton(
                onPressed: () => _switchMode(!_signup),
                child: Text(_signup ? 'Sign in' : 'Create an account'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.dark});
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF8B5CF6), Color(0xFF5B21B6)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'P',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 19,
            ),
          ),
        ),
        const SizedBox(width: 11),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PrepMate',
              style: TextStyle(
                color: dark ? Colors.white : AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            Text(
              'Job ready, faster.',
              style: TextStyle(
                color: dark ? const Color(0xFFC9C1DC) : AppColors.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AuthAside extends StatelessWidget {
  const _AuthAside();

  @override
  Widget build(BuildContext context) {
    const points = [
      'Applications and progress saved to your account',
      'Roadmaps built from the roles you apply for',
      'Mock interviews with instant feedback',
    ];
    return Container(
      padding: const EdgeInsets.all(44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171125), Color(0xFF251849), Color(0xFF36216B)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Brand(dark: true),
          const Spacer(),
          const Text(
            'From job description to job ready.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Track every application, turn a job description into a study plan, and practise until the interview feels familiar.',
            style: TextStyle(color: Color(0xFFC9C1DC), height: 1.5),
          ),
          const SizedBox(height: 28),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(Icons.check, color: Color(0xFFA78BFA), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      p,
                      style: const TextStyle(
                        color: Color(0xFFE4DEFA),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
