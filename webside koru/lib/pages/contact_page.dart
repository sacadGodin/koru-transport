import 'package:flutter/material.dart';

import '../data/bookings.dart';
import '../data/messages.dart';
import '../lang.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/site_layout.dart';

// Contact page: phone / WhatsApp / email cards, a contact form, and the
// list of branches with a map.
class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  @override
  Widget build(BuildContext context) {
    final tablet = Responsive.isTablet(context);
    return SiteScaffold(
      current: NavItem.contact,
      children: [
        SectionContainer(
          top: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeading(context.t('Contact us', 'Bize ulaşın'),
                  subtitle: context.t('Our transport coordinators answer 24/7.',
                      'Ulaşım koordinatörlerimiz 7/24 yanıt verir.')),
              const SizedBox(height: 32),
              // Three ways to reach the team. Tapping opens the phone,
              // WhatsApp or email app.
              ResponsiveGrid(
                children: [
                  _ChannelCard(
                    icon: Icons.call_outlined,
                    title: context.t('Phone', 'Telefon'),
                    value: ContactInfo.phone,
                    onTap: () => openLink('tel:${ContactInfo.phone}'),
                  ),
                  _ChannelCard(
                    icon: Icons.chat_outlined,
                    title: 'WhatsApp',
                    value: ContactInfo.whatsapp,
                    onTap: () =>
                        openLink('https://wa.me/${ContactInfo.whatsapp}'),
                  ),
                  _ChannelCard(
                    icon: Icons.mail_outline,
                    title: context.t('Email', 'E-posta'),
                    value: ContactInfo.email,
                    onTap: () => openLink('mailto:${ContactInfo.email}'),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Form on the left, branches on the right (stacked on small screens).
        SectionContainer(
          top: 8,
          bottom: 80,
          child: tablet
              ? const Column(
                  children: [_ContactForm(), SizedBox(height: 24), _Branches()])
              : const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _ContactForm()),
                    SizedBox(width: 32),
                    Expanded(child: _Branches()),
                  ],
                ),
        ),
      ],
    );
  }
}

// Light blue card: icon, title and the number/address. Tap to open it.
class _ChannelCard extends StatelessWidget {
  const _ChannelCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.blueSoft,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              // Icon in a white rounded square.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.control),
                ),
                child: Icon(icon, color: AppColors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.muted)),
                    Text(value,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: AppColors.blue),
            ],
          ),
        ),
      ),
    );
  }
}

// Contact form: name, phone or email, topic, booking reference, message.
class _ContactForm extends StatefulWidget {
  const _ContactForm();

  @override
  State<_ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<_ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _reply = TextEditingController();
  final _reference = TextEditingController();
  final _message = TextEditingController();
  ContactTopic _topic = ContactTopic.booking;
  // true while the message is being saved.
  bool _sending = false;

  @override
  void dispose() {
    for (final c in [_name, _reply, _reference, _message]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty)
      ? context.t('Required', 'Zorunlu alan')
      : null;

  // Checks the fields and saves the message (staff read it in the admin
  // dashboard). Clears the form once it is saved.
  Future<void> _send() async {
    if (_sending || !_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await messageStore.send(
        name: _name.text.trim(),
        reply: _reply.text.trim(),
        topic: _topic,
        reference: _reference.text.trim(),
        message: _message.text.trim(),
      );
    } catch (e) {
      debugPrint('Sending message failed: $e');
      if (!mounted) return;
      setState(() => _sending = false);
      messenger.showSnackBar(SnackBar(
          content: Text(context.t(
              'Could not send your message. Please try again or call us.',
              'Mesajınız gönderilemedi. Lütfen tekrar deneyin veya bizi '
                  'arayın.'))));
      return;
    }
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
        content: Text(context.t('Message sent. We will reply soon.',
            'Mesajınız gönderildi. En kısa sürede yanıt vereceğiz.'))));
    for (final c in [_name, _reply, _reference, _message]) {
      c.clear();
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
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
            Text(context.t('Send us a message', 'Bize mesaj gönderin'),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            FieldLabel(context.t('Your name', 'Adınız'),
                child: TextFormField(controller: _name, validator: _required)),
            const SizedBox(height: 16),
            FieldLabel(context.t('Phone or email', 'Telefon veya e-posta'),
                child: TextFormField(controller: _reply, validator: _required)),
            const SizedBox(height: 16),
            FieldLabel(
              context.t('Topic', 'Konu'),
              child: DropdownButtonFormField<ContactTopic>(
                initialValue: _topic,
                isExpanded: true,
                items: [
                  for (final topic in ContactTopic.values)
                    DropdownMenuItem(
                        value: topic, child: Text(topic.label(context))),
                ],
                onChanged: (v) => setState(() => _topic = v!),
              ),
            ),
            const SizedBox(height: 16),
            FieldLabel(
              context.t('Booking reference (optional)',
                  'Rezervasyon numarası (isteğe bağlı)'),
              child: TextFormField(
                  controller: _reference,
                  decoration: const InputDecoration(hintText: 'KR-1234')),
            ),
            const SizedBox(height: 16),
            FieldLabel(context.t('Message', 'Mesaj'),
                child: TextFormField(
                    controller: _message, validator: _required, maxLines: 5)),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _sending ? null : _send,
                child: Text(_sending
                    ? context.t('Sending...', 'Gönderiliyor...')
                    : context.t('Send message', 'Mesajı gönder'))),
          ],
        ),
      ),
    );
  }
}

// List of branches (name, address, phone) with a map placeholder under it.
class _Branches extends StatelessWidget {
  const _Branches();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.t('Our branches', 'Şubelerimiz'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        for (final branch in branches)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on_outlined, color: AppColors.blue),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(branch,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                      // Replace with each branch's real address and phone.
                      Text('${ContactInfo.address} · ${ContactInfo.phone}',
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        const PlaceholderBox('[MAP EMBED]', height: 280),
      ],
    );
  }
}
