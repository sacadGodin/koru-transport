import 'package:flutter/material.dart';

import '../data/staff_auth.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/site_layout.dart';

// Sign-in page for staff (admin dashboard) or drivers (driver dashboard):
// blue side panel on the left (wide screens), sign-in form on the right.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key, this.role = Role.staff});

  // Who signs in here.
  final Role role;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  // true = password is hidden (dots).
  bool _hidePassword = true;
  // true while the sign-in is being checked.
  bool _busy = false;
  // Shown under the form when sign-in fails.
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty)
      ? context.t('Required', 'Zorunlu alan')
      : null;

  bool get _driver => widget.role == Role.driver;

  // Checks the email and password with Firebase Auth and opens the dashboard.
  Future<void> _signIn() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await staffAuth.signIn(_email.text.trim(), _password.text,
        role: widget.role);
    if (!mounted) return;
    if (result == SignInResult.ok) {
      Navigator.pushReplacementNamed(context, _driver ? '/driver' : '/admin');
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (result) {
        SignInResult.wrongLogin =>
          context.t('Wrong email or password.', 'E-posta veya şifre hatalı.'),
        SignInResult.notStaff => _driver
            ? context.t('This account is not an active driver account.',
                'Bu hesap aktif bir sürücü hesabı değil.')
            : context.t('This account does not have staff access.',
                'Bu hesabın personel erişimi yok.'),
        _ => context.t('Could not sign in. Please try again.',
            'Giriş yapılamadı. Lütfen tekrar deneyin.'),
      };
    });
  }

  // Emails a "choose a new password" link to the address in the email field.
  Future<void> _forgotPassword() async {
    final email = _email.text.trim();
    if (email.isEmpty) {
      setState(() => _error = context.t(
          'Type your email first, then tap "Forgot password?".',
          'Önce e-postanızı yazın, sonra "Şifremi unuttum" seçin.'));
      return;
    }
    setState(() => _error = null);
    final sent = await staffAuth.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(sent
            ? context.t(
                'If $email has an account, a link to choose a new password '
                    'has been sent to it.',
                '$email adresine bağlı bir hesap varsa, yeni şifre '
                    'belirleme bağlantısı gönderildi.')
            : context.t('Could not send the email. Please try again.',
                'E-posta gönderilemedi. Lütfen tekrar deneyin.'))));
  }

  @override
  Widget build(BuildContext context) {
    final tablet = Responsive.isTablet(context);

    // Blue side panel with the logo and a short note.
    final sidePanel = Container(
      color: AppColors.blue,
      padding: const EdgeInsets.all(48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Logo(light: true),
          const Spacer(),
          Text(
              _driver
                  ? context.t('Driver portal', 'Sürücü portalı')
                  : context.t('Staff portal', 'Personel portalı'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Text(
              _driver
                  ? context.t(
                      'For Koru Hospital transport drivers. See your trips '
                          'and update each one as you go.',
                      'Koru Hastanesi ulaşım sürücüleri içindir. '
                          'Yolculuklarınızı görün ve her adımı güncelleyin.')
                  : context.t(
                      'For Koru Hospital transport coordinators only. '
                          'Manage requests, reservations and dispatch.',
                      'Yalnızca Koru Hastanesi ulaşım koordinatörleri içindir. '
                          'Talepleri, rezervasyonları ve sevkleri yönetin.'),
              style: TextStyle(
                  color: AppColors.blueOnDark, fontSize: 17, height: 1.6)),
          const Spacer(),
        ],
      ),
    );

    // The sign-in form.
    final form = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (tablet) ...[
                  const Align(alignment: Alignment.centerLeft, child: Logo()),
                  const SizedBox(height: 32),
                ],
                Text(
                    _driver
                        ? context.t('Driver sign in', 'Sürücü girişi')
                        : context.t('Staff sign in', 'Personel girişi'),
                    style: const TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                    _driver
                        ? context.t(
                            'Use the account your coordinator gave you.',
                            'Koordinatörünüzün verdiği hesapla giriş yapın.')
                        : context.t('Use your hospital account.',
                            'Hastane hesabınızla giriş yapın.'),
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _email,
                  validator: _required,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                      labelText: context.t('Email', 'E-posta'),
                      prefixIcon: const Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  validator: _required,
                  obscureText: _hidePassword,
                  onFieldSubmitted: (_) => _signIn(),
                  decoration: InputDecoration(
                    labelText: context.t('Password', 'Şifre'),
                    prefixIcon: const Icon(Icons.lock_outline),
                    // Eye button: shows or hides the password.
                    suffixIcon: IconButton(
                      tooltip: _hidePassword
                          ? context.t('Show password', 'Şifreyi göster')
                          : context.t('Hide password', 'Şifreyi gizle'),
                      icon: Icon(_hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                ),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TextButton(
                    onPressed: _busy ? null : _forgotPassword,
                    child: Text(
                        context.t('Forgot password?', 'Şifremi unuttum')),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!,
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.error)),
                ],
                const SizedBox(height: 24),
                FilledButton(
                    onPressed: _busy ? null : _signIn,
                    child: Text(_busy
                        ? context.t('Signing in...', 'Giriş yapılıyor...')
                        : context.t('Sign in', 'Giriş yap'))),
                const SizedBox(height: 12),
                // Back to the public website.
                TextButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/', (_) => false),
                  child: Text(context.t('Back to website', 'Siteye dön')),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        // Small screens: form only. Wide: blue panel + form.
        child: tablet
            ? form
            : Row(
                children: [
                  Expanded(child: sidePanel),
                  Expanded(child: form),
                ],
              ),
      ),
    );
  }
}
