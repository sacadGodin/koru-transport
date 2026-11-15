import 'dart:async';

import 'package:flutter/material.dart';

import '../data/bookings.dart';
import '../data/feedback.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_layout.dart';

// Patient feedback page. Open to everyone, no sign-in needed: patients
// reach it from the "Share your feedback" button on the sign-in page, or
// staff open it on a tablet and hand it to the patient.
// After sending, a thank-you screen shows and the form clears itself after
// a short countdown, so the next patient never sees the previous answers.
// Staff read every comment in the admin dashboard (Feedback section).
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // Seconds the thank-you screen stays before the form clears itself.
  static const _resetAfter = 20;

  final _name = TextEditingController();
  final _ref = TextEditingController();
  final _comment = TextEditingController();
  TransportType? _type;
  final Set<FeedbackAspect> _aspects = {};
  // 0 = no stars chosen yet.
  int _rating = 0;

  // Shows the "choose a rating" error after a failed send.
  bool _showErrors = false;
  // True while saving.
  bool _busy = false;
  // Shown above the send button when saving failed.
  String? _error;
  // True after sending (the thank-you screen is shown).
  bool _sent = false;

  Timer? _timer;
  int _secondsLeft = _resetAfter;

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in [_name, _ref, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  // Word under the stars for each rating.
  String _ratingWord(int rating) => switch (rating) {
        1 => context.t('Poor', 'Kötü'),
        2 => context.t('Fair', 'Orta'),
        3 => context.t('Good', 'İyi'),
        4 => context.t('Very good', 'Çok iyi'),
        5 => context.t('Excellent', 'Mükemmel'),
        _ => context.t('Tap a star to rate', 'Puanlamak için bir yıldıza dokunun'),
      };

  Future<void> _send() async {
    if (_busy) return;
    if (_rating == 0) {
      setState(() => _showErrors = true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final ok = await feedbackStore.add(PatientFeedback(
      rating: _rating,
      type: _type ?? TransportType.standard,
      comment: _comment.text.trim(),
      name: _name.text.trim(),
      ref: _ref.text.trim().toUpperCase(),
      aspects: FeedbackAspect.values.where(_aspects.contains).toList(),
      date: DateTime.now(),
    ));
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _busy = false;
        _error = context.t(
            'Your feedback could not be sent. Check the internet connection '
                'and try again.',
            'Görüşünüz gönderilemedi. İnternet bağlantısını kontrol edip '
                'tekrar deneyin.');
      });
      return;
    }
    setState(() {
      _busy = false;
      _sent = true;
      _secondsLeft = _resetAfter;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _reset();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  // Clears everything for the next patient.
  void _reset() {
    _timer?.cancel();
    for (final c in [_name, _ref, _comment]) {
      c.clear();
    }
    setState(() {
      _type = null;
      _aspects.clear();
      _rating = 0;
      _showErrors = false;
      _error = null;
      _sent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          const _TopBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  mobile ? 16 : 32, mobile ? 24 : 48, mobile ? 16 : 32, 48),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _sent ? _thanks(mobile) : _form(mobile),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(bool mobile) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(context.t('PATIENT FEEDBACK', 'HASTA GÖRÜŞLERİ'),
            style: const TextStyle(
                color: AppColors.gold,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.6)),
        const SizedBox(height: 10),
        Text(
            context.t('How was your journey with Koru Transport?',
                'Koru Transport ile yolculuğunuz nasıldı?'),
            style: TextStyle(
                fontSize: mobile ? 28 : 38,
                height: 1.15,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8)),
        const SizedBox(height: 12),
        Text(
            context.t(
                'Your opinion helps us care for every patient better. It '
                    'takes about one minute and your name is optional.',
                'Görüşünüz her hastamıza daha iyi bakmamıza yardımcı olur. '
                    'Yaklaşık bir dakika sürer, adınızı yazmak isteğe bağlıdır.'),
            style: const TextStyle(
                fontSize: 17, height: 1.6, color: AppColors.muted)),
        const SizedBox(height: 28),
        _Card(
          step: 1,
          title: context.t('Overall, how would you rate our service?',
              'Genel olarak hizmetimizi nasıl değerlendirirsiniz?'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stars(_rating,
                  size: mobile ? 40 : 52,
                  onChanged: _busy
                      ? null
                      : (v) => setState(() {
                            _rating = v;
                            _showErrors = false;
                          })),
              const SizedBox(height: 6),
              Text(_ratingWord(_rating),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight:
                          _rating == 0 ? FontWeight.w500 : FontWeight.w800,
                      color: _showErrors && _rating == 0
                          ? errorColor
                          : _rating == 0
                              ? AppColors.muted
                              : AppColors.text)),
            ],
          ),
        ),
        _Card(
          step: 2,
          title: context.t('Which parts of the service is your feedback about?',
              'Görüşünüz hizmetin hangi bölümleriyle ilgili?'),
          hint: context.t('Optional · choose any', 'İsteğe bağlı · birden fazla seçebilirsiniz'),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final a in FeedbackAspect.values)
                FilterChip(
                  avatar: Icon(a.icon,
                      size: 18,
                      color: _aspects.contains(a)
                          ? AppColors.blue
                          : AppColors.muted),
                  showCheckmark: false,
                  label: Text(a.label(context)),
                  selected: _aspects.contains(a),
                  onSelected: _busy
                      ? null
                      : (on) => setState(
                          () => on ? _aspects.add(a) : _aspects.remove(a)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                  selectedColor: AppColors.blueSoft,
                  side: BorderSide(
                      color: _aspects.contains(a)
                          ? AppColors.blue
                          : AppColors.inputBorder),
                  labelStyle: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: _aspects.contains(a)
                          ? AppColors.blue
                          : AppColors.text),
                ),
            ],
          ),
        ),
        _Card(
          step: 3,
          title: context.t('Tell us more', 'Bize daha fazlasını anlatın'),
          hint: context.t('Optional', 'İsteğe bağlı'),
          child: TextField(
            controller: _comment,
            enabled: !_busy,
            maxLines: 5,
            maxLength: 600,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
                hintText: context.t(
                    'What went well? What could we do better?',
                    'Neler iyiydi? Neyi daha iyi yapabiliriz?')),
          ),
        ),
        _Card(
          step: 4,
          title: context.t('About your ride', 'Yolculuğunuz hakkında'),
          hint: context.t('Optional', 'İsteğe bağlı'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FieldLabel(
                context.t('Service you used', 'Kullandığınız hizmet'),
                child: DropdownButtonFormField<TransportType>(
                  initialValue: _type,
                  isExpanded: true,
                  hint: Text(context.t('Choose…', 'Seçin…')),
                  items: [
                    for (final type in TransportType.values)
                      DropdownMenuItem(
                          value: type, child: Text(type.label(context))),
                  ],
                  onChanged: _busy ? null : (v) => setState(() => _type = v),
                ),
              ),
              const SizedBox(height: 16),
              Flex(
                direction: mobile ? Axis.vertical : Axis.horizontal,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _flexible(
                    mobile,
                    FieldLabel(
                      context.t('Your name', 'Adınız'),
                      child: TextField(
                          controller: _name,
                          enabled: !_busy,
                          maxLength: 80,
                          textCapitalization: TextCapitalization.words,
                          decoration:
                              const InputDecoration(counterText: '')),
                    ),
                  ),
                  SizedBox(width: 16, height: mobile ? 16 : 0),
                  _flexible(
                    mobile,
                    FieldLabel(
                      context.t('Booking reference', 'Rezervasyon numarası'),
                      child: TextField(
                          controller: _ref,
                          enabled: !_busy,
                          maxLength: 20,
                          decoration: const InputDecoration(
                              hintText: 'KR-1234', counterText: '')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline, size: 18, color: AppColors.muted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                  context.t(
                      'Our patient services team reads every response. We may '
                          'share a comment on our website with your first name '
                          'only. Please do not write medical details.',
                      'Hasta hizmetleri ekibimiz her yanıtı okur. Bir yorumu '
                          'sitemizde yalnızca adınızla paylaşabiliriz. Lütfen '
                          'tıbbi bilgi yazmayın.'),
                  style: const TextStyle(
                      fontSize: 13, height: 1.5, color: AppColors.muted)),
            ),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(AppRadius.control),
              border: Border.all(color: errorColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 20, color: errorColor),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(_error!,
                        style: TextStyle(color: errorColor, height: 1.4))),
              ],
            ),
          ),
        ],
        if (_showErrors && _rating == 0) ...[
          const SizedBox(height: 16),
          Text(
              context.t('Please choose a star rating (step 1) before sending.',
                  'Göndermeden önce lütfen yıldız puanı seçin (1. adım).'),
              style: TextStyle(color: errorColor, fontWeight: FontWeight.w600)),
        ],
        const SizedBox(height: 20),
        SizedBox(
          height: 56,
          child: FilledButton.icon(
            onPressed: _busy ? null : _send,
            icon: _busy
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Icon(Icons.send_rounded),
            label: Text(context.t('Send feedback', 'Görüşü gönder'),
                style: const TextStyle(fontSize: 17)),
          ),
        ),
      ],
    );
  }

  Widget _flexible(bool mobile, Widget child) =>
      mobile ? child : Expanded(child: child);

  // Thank-you screen, then the form clears itself for the next patient.
  Widget _thanks(bool mobile) {
    return Container(
      key: const ValueKey('thanks'),
      padding: EdgeInsets.all(mobile ? 28 : 56),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded,
                color: AppColors.success, size: 48),
          ),
          const SizedBox(height: 24),
          Text(context.t('Thank you for your feedback', 'Görüşünüz için teşekkür ederiz'),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: mobile ? 26 : 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5)),
          const SizedBox(height: 12),
          Text(
              context.t(
                  'Our patient services team will read it. We wish you good '
                      'health.',
                  'Hasta hizmetleri ekibimiz okuyacak. Sağlıklı günler dileriz.'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17, height: 1.6, color: AppColors.muted)),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _reset,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(context.t('New feedback', 'Yeni görüş')),
          ),
          const SizedBox(height: 14),
          Text(
              context.t('This screen will clear in $_secondsLeft seconds.',
                  'Bu ekran $_secondsLeft saniye içinde temizlenecek.'),
              style: const TextStyle(color: AppColors.muted, fontSize: 13)),
        ],
      ),
    );
  }
}

// One numbered step of the form in a white card.
class _Card extends StatelessWidget {
  const _Card(
      {required this.step, required this.title, this.hint, required this.child});

  final int step;
  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(mobile ? 20 : 28),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    color: AppColors.blueSoft, shape: BoxShape.circle),
                child: Text('$step',
                    style: TextStyle(
                        color: AppColors.blue, fontWeight: FontWeight.w800)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                    ),
                    if (hint != null)
                      Text(hint!,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }
}

// Navy bar: logo, a back button when opened from another page (staff
// portal or sign-in), and the language button.
class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    final canGoBack = Navigator.canPop(context);
    return Container(
      color: AppColors.blue,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              if (canGoBack)
                IconButton(
                  tooltip: context.t('Back', 'Geri'),
                  color: Colors.white,
                  icon: const BackButtonIcon(),
                  onPressed: () => Navigator.maybePop(context),
                ),
              const SizedBox(width: 8),
              const Flexible(child: Logo(light: true)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => showLanguageDialog(context),
                style: TextButton.styleFrom(foregroundColor: Colors.white),
                icon: const Icon(Icons.translate, size: 18),
                label: Text(context.lang.code,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
