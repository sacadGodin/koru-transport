import 'package:flutter/material.dart';

import '../data/bookings.dart';
import '../data/feedback.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_layout.dart';

// "Feedback" page: patients rate their ride and leave a comment.
// Staff read every comment in the admin dashboard and choose which ones
// appear on the homepage.
class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ref = TextEditingController();
  final _comment = TextEditingController();
  TransportType _type = TransportType.standard;
  // 0 = no stars chosen yet.
  int _rating = 0;

  // Shows the "choose a rating" error after a failed send.
  bool _showErrors = false;

  // True after sending (the thank-you message is shown).
  bool _sent = false;

  @override
  void dispose() {
    for (final c in [_name, _ref, _comment]) {
      c.dispose();
    }
    super.dispose();
  }

  // Checks the form and saves the comment.
  void _send() {
    final formOk = _formKey.currentState!.validate();
    if (!formOk || _rating == 0) {
      setState(() => _showErrors = true);
      return;
    }
    feedbackStore.add(PatientFeedback(
      rating: _rating,
      type: _type,
      comment: _comment.text.trim(),
      name: _name.text.trim(),
      ref: _ref.text.trim(),
      date: DateTime.now(),
    ));
    setState(() => _sent = true);
  }

  // Clears everything to leave another comment.
  void _reset() {
    for (final c in [_name, _ref, _comment]) {
      c.clear();
    }
    setState(() {
      _type = TransportType.standard;
      _rating = 0;
      _showErrors = false;
      _sent = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SiteScaffold(
      current: NavItem.feedback,
      children: [
        SectionContainer(
          top: 40,
          bottom: 80,
          child: Align(
            alignment: Alignment.topLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeading(
                      context.t('How was your ride?', 'Yolculuğunuz nasıldı?'),
                      subtitle: context.t(
                          'Your comment helps us look after the next patient '
                              'better. It takes one minute.',
                          'Yorumunuz bir sonraki hastamıza daha iyi bakmamıza '
                              'yardımcı olur. Bir dakikanızı alır.')),
                  const SizedBox(height: 32),
                  _sent ? _thanks() : _form(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _form() {
    return Container(
      padding: EdgeInsets.all(Responsive.isMobile(context) ? 20 : 32),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FieldLabel(
              context.t('Your rating', 'Puanınız'),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Stars(_rating,
                    size: 36, onChanged: (v) => setState(() => _rating = v)),
              ),
            ),
            // Red error under the stars if none were chosen.
            if (_showErrors && _rating == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                    context.t(
                        'Choose 1 to 5 stars', '1 ile 5 arası yıldız seçin'),
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 13)),
              ),
            const SizedBox(height: 16),
            FieldLabel(
              context.t('Service you used', 'Kullandığınız hizmet'),
              child: DropdownButtonFormField<TransportType>(
                initialValue: _type,
                isExpanded: true,
                items: [
                  for (final type in TransportType.values)
                    DropdownMenuItem(
                        value: type, child: Text(type.label(context))),
                ],
                onChanged: (v) => setState(() => _type = v!),
              ),
            ),
            const SizedBox(height: 16),
            FieldLabel(
              context.t('Your comment', 'Yorumunuz'),
              child: TextFormField(
                controller: _comment,
                maxLines: 5,
                maxLength: 600,
                decoration: InputDecoration(
                    hintText: context.t(
                        'What went well? What could we do better?',
                        'Neler iyiydi? Neyi daha iyi yapabiliriz?')),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? context.t('Required', 'Zorunlu alan')
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            FieldLabel(
              context.t('Your name (optional)', 'Adınız (isteğe bağlı)'),
              child: TextFormField(controller: _name),
            ),
            const SizedBox(height: 16),
            FieldLabel(
              context.t('Booking reference (optional)',
                  'Rezervasyon numarası (isteğe bağlı)'),
              child: TextFormField(
                  controller: _ref,
                  decoration: const InputDecoration(hintText: 'KR-1234')),
            ),
            const SizedBox(height: 16),
            // Privacy note: comments may be shown on the homepage.
            Text(
                context.t(
                    'Our team reads every comment. We may show it on our '
                        'website with your first name only. Please don\'t '
                        'write medical details.',
                    'Ekibimiz her yorumu okur. Yorumunuzu sitemizde yalnızca '
                        'adınızla gösterebiliriz. Lütfen tıbbi bilgi yazmayın.'),
                style: const TextStyle(
                    fontSize: 13, height: 1.5, color: AppColors.muted)),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _send,
                child: Text(context.t('Send feedback', 'Yorumu gönder'))),
          ],
        ),
      ),
    );
  }

  // Thank-you message shown after sending.
  Widget _thanks() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.favorite, color: AppColors.success, size: 44),
          const SizedBox(height: 16),
          Text(context.t('Thank you!', 'Teşekkür ederiz!'),
              style:
                  const TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(
              context.t('We received your feedback and our team will read it.',
                  'Yorumunuzu aldık, ekibimiz okuyacak.'),
              style: const TextStyle(
                  fontSize: 17, height: 1.6, color: AppColors.muted)),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/', (_) => false),
                child: Text(context.t('Back to homepage', 'Ana sayfaya dön')),
              ),
              OutlinedButton(
                onPressed: _reset,
                child: Text(context.t(
                    'Leave another comment', 'Başka bir yorum bırak')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
