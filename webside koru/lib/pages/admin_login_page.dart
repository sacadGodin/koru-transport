import 'package:flutter/material.dart';

import '../data/staff_auth.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_layout.dart';

// The first page of the site: one sign-in for staff, admins and drivers.
// Wide screens: a photo panel with the Koru Transport brand on the left and
// the sign-in card on the right, filling the screen. Phones: a short photo
// header above the card. Staff go to the main site (book rides, see
// information), admins to the admin dashboard, drivers to the driver
// dashboard.
class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key, this.role = Role.admin});

  // Which account type is selected when the page opens.
  final Role role;

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  // The account type picked above the form.
  late Role _role = widget.role;
  // true = password is hidden (dots).
  bool _hidePassword = true;
  // true while the sign-in is being checked.
  bool _busy = false;
  // Shown above the sign-in button when sign-in fails.
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

  // Name of an account type, shown on its tab.
  String _roleName(Role role) => switch (role) {
        Role.staff => context.t('Staff', 'Personel'),
        Role.admin => context.t('Admin', 'Yönetici'),
        Role.driver => context.t('Driver', 'Sürücü'),
      };

  // Checks the email and password with Firebase Auth, then opens the main
  // site (staff), the admin dashboard (admin) or the driver dashboard.
  Future<void> _signIn() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final result =
        await staffAuth.signIn(_email.text.trim(), _password.text, role: _role);
    if (!mounted) return;
    if (result == SignInResult.ok) {
      Navigator.pushNamedAndRemoveUntil(
          context,
          switch (_role) {
            Role.staff => '/home',
            Role.admin => '/admin',
            Role.driver => '/driver',
          },
          (_) => false);
      return;
    }
    setState(() {
      _busy = false;
      _error = switch (result) {
        SignInResult.wrongLogin =>
          context.t('Wrong email or password.', 'E-posta veya şifre hatalı.'),
        SignInResult.notStaff => switch (_role) {
            Role.driver => context.t(
                'This account is not an active driver account.',
                'Bu hesap aktif bir sürücü hesabı değil.'),
            Role.admin => context.t('This account does not have admin access.',
                'Bu hesabın yönetici erişimi yok.'),
            Role.staff => context.t('This account is not a staff account.',
                'Bu hesap bir personel hesabı değil.'),
          },
        SignInResult.tooManyTries => context.t(
            'Too many tries. Wait a few minutes or reset your password.',
            'Çok fazla deneme. Birkaç dakika bekleyin veya şifrenizi sıfırlayın.'),
        SignInResult.offline => context.t(
            'No internet connection. Check your connection and try again.',
            'İnternet bağlantısı yok. Bağlantınızı kontrol edip tekrar deneyin.'),
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
    final mobile = Responsive.isMobile(context);
    final card = _card(context, mobile);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: tablet
          // Small screens: photo header, then the card, all scrolling.
          ? SingleChildScrollView(
              child: Column(
                children: [
                  const _BrandPanel(compact: true),
                  Transform.translate(
                    offset: const Offset(0, -32),
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: mobile ? 16 : 32),
                      child: Center(child: card),
                    ),
                  ),
                ],
              ),
            )
          // Wide screens: photo panel on the left, card on the right.
          : Row(
              children: [
                const Expanded(flex: 6, child: _BrandPanel()),
                Expanded(
                  flex: 5,
                  // Soft wash of the brand colour behind the card.
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [AppColors.blueSoft, AppColors.surface],
                      ),
                    ),
                    child: SafeArea(
                      child: Stack(
                        children: [
                          Center(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(32),
                              child: card,
                            ),
                          ),
                          const PositionedDirectional(
                              top: 20, end: 24, child: LangSwitch()),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // White card: account type tabs and the sign-in form.
  Widget _card(BuildContext context, bool mobile) {
    final error = Theme.of(context).colorScheme.error;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        padding: EdgeInsets.all(mobile ? 24 : 40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
                color: AppColors.blueDark.withValues(alpha: 0.10),
                blurRadius: 60,
                offset: const Offset(0, 24)),
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Lock badge above the heading.
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.blue, AppColors.blueDark],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                            color: AppColors.blue.withValues(alpha: 0.30),
                            blurRadius: 16,
                            offset: const Offset(0, 6)),
                      ],
                    ),
                    child: const Icon(Icons.lock_person_outlined,
                        color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(height: 20),
                Text(context.t('Welcome back', 'Tekrar hoş geldiniz'),
                    style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text(
                    context.t('Sign in to the Koru Transport portal.',
                        'Koru Transport portalına giriş yapın.'),
                    style: const TextStyle(color: AppColors.muted)),
                const SizedBox(height: 28),
                // Account type tabs: Staff, Admin, Driver.
                FieldLabel(
                  context.t('I am signing in as', 'Giriş türü'),
                  child: Row(
                    children: [
                      for (final (i, role) in Role.values.indexed) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _RoleTab(
                            icon: switch (role) {
                              Role.staff => Icons.badge_outlined,
                              Role.admin => Icons.admin_panel_settings_outlined,
                              Role.driver => Icons.airport_shuttle_outlined,
                            },
                            label: _roleName(role),
                            selected: role == _role,
                            onTap: _busy
                                ? null
                                : () => setState(() {
                                      _role = role;
                                      _error = null;
                                    }),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                    switch (_role) {
                      Role.staff => context.t(
                          'Book rides and see transport information.',
                          'Yolculuk ayırtın ve ulaşım bilgilerini görün.'),
                      Role.admin => context.t(
                          'Manage bookings, drivers, the schedule and all settings.',
                          'Rezervasyonları, sürücüleri, programı ve tüm ayarları yönetin.'),
                      Role.driver => context.t(
                          'Use the account your coordinator gave you.',
                          'Koordinatörünüzün verdiği hesapla giriş yapın.'),
                    },
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _email,
                  validator: _required,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  // Stop phone keyboards from changing the email.
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                      labelText: context.t('Email', 'E-posta'),
                      prefixIcon: const Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _password,
                  validator: _required,
                  obscureText: _hidePassword,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.password],
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
                    child:
                        Text(context.t('Forgot password?', 'Şifremi unuttum')),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: error.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(AppRadius.control),
                      border: Border.all(color: error.withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.error_outline, size: 20, color: error),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(_error!,
                                style: TextStyle(color: error, height: 1.4))),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _busy ? null : _signIn,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          '${context.t('Sign in', 'Giriş yap')} · ${_roleName(_role)}'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        size: 16, color: AppColors.muted),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                          context.t('Secure sign-in for authorised personnel',
                              'Yetkili personel için güvenli giriş'),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                // Patients have no account: their feedback page is public.
                Text(
                    context.t('Are you a patient or visitor?',
                        'Hasta veya ziyaretçi misiniz?'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/feedback'),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(
                      context.t('Share your feedback', 'Görüşünüzü paylaşın')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// One account type tab: icon over the name, blue outline when selected.
class _RoleTab extends StatelessWidget {
  const _RoleTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.blue : AppColors.muted;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? AppColors.blueSoft : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.control),
          side: BorderSide(
              color: selected ? AppColors.blue : AppColors.inputBorder,
              width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.control),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, color: color, size: 26),
                const SizedBox(height: 6),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: selected ? AppColors.blue : AppColors.text,
                        fontWeight:
                            selected ? FontWeight.w800 : FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Brand panel: hospital photo under a navy tint, the logo, the tagline and
// what the portal is for. compact: true is the short header used on phones.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final features = [
      (
        Icons.route_outlined,
        context.t(
            'Live dispatch and trip tracking', 'Canlı sevk ve yolculuk takibi')
      ),
      (
        Icons.event_available_outlined,
        context.t('Bookings and 24-hour schedule',
            'Rezervasyonlar ve 24 saatlik program')
      ),
      (
        Icons.shield_outlined,
        context.t('Role-based secure access', 'Role göre güvenli erişim')
      ),
    ];

    // Soft shadow under the panel text so it stays readable over the photo.
    const textShadow = [
      Shadow(color: Color(0x66000000), blurRadius: 12, offset: Offset(0, 2)),
    ];

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: Logo(light: true)),
            if (compact) const _LightLangSwitch(),
          ],
        ),
        if (compact) const SizedBox(height: 28) else const Spacer(),
        Text(
            context.t('KORU HOSPITAL · STAFF PORTAL',
                'KORU HASTANESİ · PERSONEL PORTALI'),
            style: const TextStyle(
                color: AppColors.goldLight,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6,
                shadows: textShadow)),
        const SizedBox(height: 14),
        Text(
            context.t('Moving People,\nConnecting Care.',
                'İnsanları Taşıyor,\nBakımı Buluşturuyoruz.'),
            style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 30 : 48,
                height: 1.12,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                shadows: textShadow)),
        if (!compact) ...[
          const SizedBox(height: 18),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Text(
                context.t(
                    'The Koru Transport portal brings coordinators, '
                        'administrators and drivers together to move every '
                        'patient safely and on time.',
                    'Koru Transport portalı, her hastayı güvenle ve zamanında '
                        'taşımak için koordinatörleri, yöneticileri ve '
                        'sürücüleri bir araya getirir.'),
                style: TextStyle(
                    color: AppColors.blueOnDark,
                    fontSize: 17,
                    height: 1.6,
                    shadows: textShadow)),
          ),
          const SizedBox(height: 36),
          for (final (icon, text) in features)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18)),
                    ),
                    child: Icon(icon, color: AppColors.goldLight, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Text(text,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          const Spacer(),
          Text(
              '© ${DateTime.now().year} ${context.t('Koru Hospital', 'Koru Hastanesi')}'
              '  ·  ${context.t('Emergency', 'Acil')}: 112',
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6), fontSize: 13)),
        ],
      ],
    );

    final dark = AppColors.blueDark;
    return Container(
      decoration: BoxDecoration(
        color: dark,
        // Çukurambar branch. The photo is portrait, so cover fills the panel;
        // the alignment keeps the tower and the main building in frame (on
        // the short phone header it shows the middle of the tower).
        image: DecorationImage(
          image: const AssetImage('assets/images/koru_cukurambar.jpg'),
          fit: BoxFit.cover,
          alignment: compact
              ? const Alignment(-0.2, -0.1)
              : const Alignment(-0.25, 0.1),
        ),
      ),
      // Tint: light at the top so the building and sky show, darker towards
      // the bottom and the left where the white text sits.
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.35, 0.65, 1],
            colors: [
              dark.withValues(alpha: compact ? 0.70 : 0.55),
              dark.withValues(alpha: compact ? 0.62 : 0.30),
              dark.withValues(alpha: compact ? 0.80 : 0.78),
              dark.withValues(alpha: 0.94),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [dark.withValues(alpha: 0.45), dark.withValues(alpha: 0)],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: compact
                  ? const EdgeInsets.fromLTRB(20, 16, 20, 64)
                  : const EdgeInsets.all(56),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

// Language button for the phone header: white text on the navy panel.
class _LightLangSwitch extends StatelessWidget {
  const _LightLangSwitch();

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: () => showLanguageDialog(context),
      style: TextButton.styleFrom(foregroundColor: Colors.white),
      icon: const Icon(Icons.translate, size: 18),
      label: Text(context.lang.code,
          style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}
