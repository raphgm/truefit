// Welcome, sign in, sign up and forgot password. Accounts are local to this device (no server yet).
import 'package:material_ui/material_ui.dart';

import '../models.dart';
import '../state.dart';
import '../ui.dart';

enum AuthView { welcome, login, signup, forgot }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  AuthView view = AuthView.welcome;
  final name = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  bool accepted = false, show = false;

  void go(AuthView v) => setState(() => view = v);

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    return PopScope(
      canPop: view == AuthView.welcome,
      onPopInvokedWithResult: (popped, _) { if (!popped) go(view == AuthView.forgot ? AuthView.login : AuthView.welcome); },
      child: AnimatedSwitcher(duration: const Duration(milliseconds: 250), child: view == AuthView.welcome ? _welcome(s) : _form(s)),
    );
  }

  Widget _welcome(AppState s) => Scaffold(
        key: const ValueKey('welcome'),
        backgroundColor: dark,
        body: Stack(fit: StackFit.expand, children: [
          Image.asset(heroImage, fit: BoxFit.cover),
          const DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
              colors: [Color(0x55211D2B), Color(0x22211D2B), Color(0xEE211D2B), dark], stops: [0, 0.3, 0.62, 1]))),
          SafeArea(child: Padding(padding: const EdgeInsets.fromLTRB(22, 12, 22, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: purple, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.checkroom, color: Colors.white, size: 22)),
              const SizedBox(width: 10),
              const Text('TrueFit AI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
              const Spacer(),
              TextButton(onPressed: () => go(AuthView.login), child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))),
            ]),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(20)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_awesome, color: lavender, size: 16), SizedBox(width: 6),
                  Text('AI Fit Studio · Smart measurements', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                ])),
            const SizedBox(height: 14),
            const Text('BESPOKE FASHION & SMART TAILORING', style: TextStyle(color: lavender, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const SizedBox(height: 8),
            Text('Your style.\nYour perfect fit.', style: display(40, color: Colors.white)),
            const SizedBox(height: 12),
            Text('Browse curated Ankara, traditional, and contemporary silhouettes, capture your AI-assisted measurements, and book your custom piece directly with the studio.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), height: 1.45)),
            const SizedBox(height: 22),
            FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54), backgroundColor: Colors.white, foregroundColor: purple),
                onPressed: () => go(AuthView.signup), child: const Text('Get Started')),
            const SizedBox(height: 10),
            OutlinedButton(style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52), foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.35))), onPressed: () => go(AuthView.login), child: const Text('I already have an account')),
            const SizedBox(height: 6),
            Center(child: TextButton(onPressed: () => s.signIn(const UserAccount('Style Explorer', 'guest@truefit.ai', isGuest: true)),
                child: Text('Explore lookbook & Fit Studio without signing in', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), decoration: TextDecoration.underline, decorationColor: Colors.white54)))),
          ]))),
        ]),
      );

  Widget _field(TextEditingController c, String label, IconData icon, {String? hint, bool secret = false, TextInputType? type}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: TextField(
          controller: c, obscureText: secret && !show, keyboardType: type,
          decoration: InputDecoration(labelText: label, hintText: hint, prefixIcon: Icon(icon),
              suffixIcon: secret ? IconButton(tooltip: show ? 'Hide password' : 'Show password', onPressed: () => setState(() => show = !show),
                  icon: Icon(show ? Icons.visibility_off : Icons.visibility)) : null),
        ),
      );

  Widget _form(AppState s) {
    final (title, sub) = switch (view) {
      AuthView.login => ('Welcome back', 'Sign in to continue your style journey.'),
      AuthView.signup => ('Create your account', 'Start discovering your personal style and fit profile.'),
      _ => ('Forgot password?', 'Enter your email address to reset your password.'),
    };
    return Scaffold(
      key: ValueKey(view),
      appBar: AppBar(leading: BackButton(onPressed: () => go(view == AuthView.forgot ? AuthView.login : AuthView.welcome))),
      body: ListView(padding: const EdgeInsets.fromLTRB(24, 0, 24, 24), children: [
        Container(width: 52, height: 52, alignment: Alignment.center, decoration: BoxDecoration(color: lavender, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.checkroom, color: purple)),
        const SizedBox(height: 18),
        Text(title, style: display(30)),
        const SizedBox(height: 6),
        Text(sub, style: const TextStyle(color: muted)),
        const SizedBox(height: 24),
        if (view == AuthView.signup) _field(name, 'Full name', Icons.person_outline, hint: 'Adaeze Okafor'),
        _field(email, 'Email address', Icons.mail_outline, hint: 'you@example.com', type: TextInputType.emailAddress),
        if (view != AuthView.forgot) _field(password, 'Password', Icons.lock_outline, secret: true, hint: view == AuthView.signup ? 'At least 6 characters' : null),
        if (view == AuthView.login) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => go(AuthView.forgot), child: const Text('Forgot password?'))),
        if (view == AuthView.signup) CheckboxListTile(
          contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading, value: accepted,
          onChanged: (v) => setState(() => accepted = v ?? false),
          title: const Text('I agree to the TrueFit AI Terms of Service and Privacy Policy.', style: TextStyle(fontSize: 13)),
        ),
        const SizedBox(height: 12),
        FilledButton(style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)), onPressed: () => _submit(s),
            child: Text(switch (view) { AuthView.login => 'Sign In', AuthView.signup => 'Create Account', _ => 'Reset password' })),
        if (view == AuthView.forgot) const Padding(padding: EdgeInsets.only(top: 12),
            child: Text('Accounts in this version are saved only on this phone, so no email is sent. Sign in again with your email and a new password.',
                style: TextStyle(color: muted, fontSize: 12.5))),
        const SizedBox(height: 16),
        if (view != AuthView.forgot) Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(view == AuthView.login ? "Don't have an account?" : 'Already have an account?', style: const TextStyle(color: muted)),
          TextButton(onPressed: () => go(view == AuthView.login ? AuthView.signup : AuthView.login), child: Text(view == AuthView.login ? 'Sign Up' : 'Sign In')),
        ]),
      ]),
    );
  }

  void _submit(AppState s) {
    final e = email.text.trim();
    switch (view) {
      case AuthView.login:
        if (e.isEmpty || password.text.isEmpty) return s.notify('Please enter your email and password.');
        final n = e.split('@').first.replaceAll(RegExp(r'[._-]'), ' ').split(' ').where((w) => w.isNotEmpty)
            .map((w) => w[0].toUpperCase() + w.substring(1)).join(' ');
        final display = n.isEmpty ? 'Atelier Guest' : n;
        s.signIn(UserAccount(display, e));
        s.notify('Welcome back, $display.');
      case AuthView.signup:
        if (name.text.trim().isEmpty || e.isEmpty || password.text.length < 6) return s.notify('Enter your details. Password must be at least 6 characters.');
        if (!accepted) return s.notify('Please accept the Terms and Privacy Policy to continue.');
        s.signIn(UserAccount(name.text.trim(), e));
        s.notify('Account created for ${name.text.trim()}.');
      case AuthView.forgot:
        if (e.isEmpty) return s.notify('Enter your email address to reset your password.');
        go(AuthView.login);
      case AuthView.welcome:
        break;
    }
  }
}
