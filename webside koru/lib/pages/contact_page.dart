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
        const SectionContainer(top: 48, bottom: 48, child: _About()),
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

// About Koru Hospital: who founded it, a card for each of the three
// locations, and what Koru Transport does.
class _About extends StatelessWidget {
  const _About();

  @override
  Widget build(BuildContext context) {
    // Branch name, optional tag and short description of each location.
    final locations = [
      (
        'Koru Hospital Çukurambar',
        context.t('Main hospital', 'Ana hastane'),
        context.t(
            'The main hospital location, offering a range of medical '
                'specialties and services. It serves as the primary '
                'destination for patients seeking medical care through the '
                'Koru network.',
            'Çeşitli tıbbi branş ve hizmetler sunan ana hastane. Koru ağı '
                'üzerinden tedavi arayan hastalar için ilk adrestir.'),
      ),
      (
        'Koru Hospital Sincan',
        null,
        context.t(
            "The Sincan location extends access to Koru Hospital's "
                'healthcare services, serving patients in the Sincan area and '
                'surrounding communities.',
            "Sincan lokasyonu, Koru Hastanesi'nin sağlık hizmetlerini Sincan "
                've çevresindeki hastalara ulaştırır.'),
      ),
      (
        'Koru Hospital Kavaklıdere',
        null,
        context.t(
            'The Kavaklıdere location provides another point of access for '
                'patients seeking healthcare services in Ankara.',
            "Kavaklıdere lokasyonu, Ankara'da sağlık hizmeti arayan hastalar "
                'için bir başka erişim noktasıdır.'),
      ),
    ];

    const body = TextStyle(fontSize: 17, height: 1.6, color: AppColors.muted);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeading(context.t('Koru Hospital — three locations in Ankara',
            "Koru Hastanesi — Ankara'da üç lokasyon")),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  context.t(
                      'Koru Hospital is a healthcare institution in Ankara, '
                          'Türkiye, associated with the vision and expertise '
                          'of two doctors: Dr. Hassan Berri, a urologist, and Dr. '
                          'Aydın Berri, a gynecologist.',
                      "Koru Hastanesi, Ankara'da iki doktorun vizyonu ve "
                          'uzmanlığıyla anılan bir sağlık kuruluşudur: üroloji '
                          'uzmanı Dr. Hassan Berri ve kadın hastalıkları ve doğum '
                          'uzmanı Dr. Aydın Berri.'),
                  style: body),
              const SizedBox(height: 12),
              Text(
                  context.t(
                      'Today, Koru Hospital serves patients across three '
                          'locations in Ankara, providing access to medical '
                          'services and supporting patients throughout their '
                          'healthcare journey.',
                      "Bugün Koru Hastanesi, Ankara'daki üç lokasyonunda "
                          'hastalara hizmet veriyor; tıbbi hizmetlere erişim '
                          'sağlıyor ve hastaları sağlık yolculukları boyunca '
                          'destekliyor.'),
                  style: body),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ResponsiveGrid(
          children: [
            for (final (i, (branch, tag, text)) in locations.indexed)
              _LocationCard(
                  number: i + 1, branch: branch, tag: tag, text: text),
          ],
        ),
        const SizedBox(height: 32),
        // Koru Transport in a light blue box, with the tagline at the end.
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(Responsive.isMobile(context) ? 24 : 40),
          decoration: BoxDecoration(
            color: AppColors.blueSoft,
            borderRadius: BorderRadius.circular(AppRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  context.t('Koru Transport — connecting patients to care',
                      'Koru Transport — hastaları sağlığa bağlıyor'),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 820),
                child: Text(
                    context.t(
                        'Koru Transport helps patients travel conveniently '
                            "between Ankara Airport, Koru Hospital's three "
                            'locations, hotels, and other destinations. Our '
                            'goal is to make every journey comfortable, '
                            'reliable, and stress-free.',
                        'Koru Transport, hastaların Ankara Havalimanı, Koru '
                            "Hastanesi'nin üç lokasyonu, oteller ve diğer "
                            'noktalar arasında rahatça seyahat etmesini '
                            'sağlar. Amacımız her yolculuğu konforlu, '
                            'güvenilir ve stressiz kılmak.'),
                    style: body),
              ),
              const SizedBox(height: 20),
              Text(
                  context.t('Three locations. One commitment: patient care.',
                      'Üç lokasyon. Tek bir taahhüt: hasta bakımı.'),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.blue)),
            ],
          ),
        ),
      ],
    );
  }
}

// One location: photo, number, branch name, optional tag and description.
class _LocationCard extends StatelessWidget {
  const _LocationCard({
    required this.number,
    required this.branch,
    required this.tag,
    required this.text,
  });

  final int number;
  final String branch;
  final String? tag;
  final String text;

  @override
  Widget build(BuildContext context) {
    final photo = branchPhotos[branch];
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The photos are portrait, so a 4:5 frame crops very little.
          AspectRatio(
            aspectRatio: 4 / 5,
            child: photo == null
                ? const PlaceholderBox('[PHOTO]', height: double.infinity)
                : Image.asset(photo, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Number in a blue circle.
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AppColors.blue,
                      child: Text('$number',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    if (tag != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.blueSoft,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(tag!,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.blue)),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(branch,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(text,
                    style: const TextStyle(
                        fontSize: 15, height: 1.6, color: AppColors.muted)),
              ],
            ),
          ),
        ],
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
