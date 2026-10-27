import 'package:flutter/material.dart';

import '../data/bookings.dart';
import '../lang.dart';
import '../theme.dart';
import 'color_picker.dart';
import 'common.dart';

// Logo: the "KORU TRANSPORT" logo.
// Use light: true on blue backgrounds (white heart icon + white text).
class Logo extends StatelessWidget {
  const Logo({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    // White backgrounds: the full logo (gold heart, blue text). Made from
    // the original logo with the black background removed.
    if (!light) {
      return Image.asset('assets/images/koru_transport_logo.png',
          height: 48, semanticLabel: 'Koru Transport');
    }
    // Blue backgrounds: the heart + "KORU" logo painted white, then a gold
    // "Transport" (the blue logo text would not show on a blue background).
    // Shrinks to fit narrow spaces such as a phone's top bar.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: AlignmentDirectional.centerStart,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image.asset('assets/images/koru_logo.png',
              height: 30,
              color: Colors.white,
              colorBlendMode: BlendMode.srcIn,
              semanticLabel: 'Koru Transport'),
          const SizedBox(width: 10),
          const Text('Transport',
              style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight)),
        ],
      ),
    );
  }
}

// The links in the top menu.
enum NavItem { book, track, shuttle, directions, drivers, feedback, contact }

extension NavItemText on NavItem {
  String label(BuildContext context) => switch (this) {
        NavItem.book => context.t('Book', 'Rezervasyon'),
        NavItem.track => context.t('Track ride', 'Takip'),
        NavItem.shuttle => context.t('Free bus', 'Ücretsiz servis'),
        NavItem.directions => context.t('Directions', 'Yol tarifi'),
        NavItem.drivers => context.t('Our drivers', 'Sürücülerimiz'),
        NavItem.feedback => context.t('Feedback', 'Görüşler'),
        NavItem.contact => context.t('Contact', 'İletişim'),
      };
}

// Opens a menu link.
// "Book", "Track ride", "Feedback" and "Contact" are their own pages. Shuttle, Directions
// and Our drivers are parts of the homepage: if we are on the homepage,
// [onAnchor] scrolls to them; otherwise we open the homepage and tell it
// which part to scroll to.
void openNavItem(
    BuildContext context, NavItem item, ValueChanged<String>? onAnchor) {
  switch (item) {
    case NavItem.book:
      Navigator.pushNamed(context, '/booking');
    case NavItem.track:
      Navigator.pushNamed(context, '/track');
    case NavItem.feedback:
      Navigator.pushNamed(context, '/feedback');
    case NavItem.contact:
      Navigator.pushNamed(context, '/contact');
    case NavItem.shuttle || NavItem.directions || NavItem.drivers:
      if (onAnchor != null) {
        onAnchor(item.name);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false,
            arguments: item.name);
      }
  }
}

// Page frame used by the public pages: header on top, then the page
// content, then the footer, all in one scrolling column.
class SiteScaffold extends StatelessWidget {
  const SiteScaffold({
    super.key,
    required this.children,
    this.current,
    this.onAnchor,
    this.scrollController,
  });

  final List<Widget> children;
  // Menu link to highlight (the page we are on).
  final NavItem? current;
  // Only the homepage passes this (see openNavItem).
  final ValueChanged<String>? onAnchor;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SiteHeader(current: current, onAnchor: onAnchor),
      body: SingleChildScrollView(
        controller: scrollController,
        child: Column(children: [...children, const SiteFooter()]),
      ),
    );
  }
}

// Top bar: logo, pill-shaped menu, TR / EN switch and call button.
// On small screens the menu moves into a menu button.
class SiteHeader extends StatelessWidget implements PreferredSizeWidget {
  const SiteHeader({super.key, this.current, this.onAnchor});

  final NavItem? current;
  final ValueChanged<String>? onAnchor;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    // The full menu needs about 1360 px; below that use the menu button.
    final compact = MediaQuery.sizeOf(context).width < 1360;
    final mobile = Responsive.isMobile(context);
    return Material(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 76,
          padding: EdgeInsets.symmetric(horizontal: mobile ? 16 : 24),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(
            children: [
              // Clicking the logo opens the homepage.
              InkWell(
                onTap: () => Navigator.pushNamedAndRemoveUntil(
                    context, '/', (_) => false),
                child: const Logo(),
              ),
              const Spacer(),
              // Wide screens: all links inside a grey pill.
              if (!compact) _PillNav(current: current, onAnchor: onAnchor),
              if (!compact) const Spacer(),
              // Palette button: change the site's main color.
              const ColorPickerButton(),
              const SizedBox(width: 4),
              const _LangSwitch(),
              // Call button (hidden on phones to save space).
              if (!mobile) ...[
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: () => openLink('tel:${ContactInfo.phone}'),
                  style: FilledButton.styleFrom(shape: const StadiumBorder()),
                  child: Text(context.t(
                      'Call ${ContactInfo.phone}', 'Ara ${ContactInfo.phone}')),
                ),
              ],
              // Small screens: menu button that lists the links.
              if (compact)
                PopupMenuButton<NavItem>(
                  tooltip: context.t('Menu', 'Menü'),
                  icon: const Icon(Icons.menu, color: AppColors.text),
                  onSelected: (item) => openNavItem(context, item, onAnchor),
                  itemBuilder: (context) => [
                    for (final item in NavItem.values)
                      PopupMenuItem(
                          value: item, child: Text(item.label(context))),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Grey pill holding the menu links; the current page is a white pill.
class _PillNav extends StatelessWidget {
  const _PillNav({this.current, this.onAnchor});

  final NavItem? current;
  final ValueChanged<String>? onAnchor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final item in NavItem.values)
            TextButton(
              onPressed: () => openNavItem(context, item, onAnchor),
              style: TextButton.styleFrom(
                foregroundColor:
                    item == current ? AppColors.text : AppColors.muted,
                backgroundColor: item == current ? Colors.white : null,
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                shape: const StadiumBorder(),
              ),
              child: Text(item.label(context),
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}

// Language button: shows the current language code (e.g. "TR") and opens
// a menu with all languages.
class _LangSwitch extends StatelessWidget {
  const _LangSwitch();

  @override
  Widget build(BuildContext context) {
    final current = context.lang;
    return PopupMenuButton<Lang>(
      tooltip: context.t('Language', 'Dil'),
      initialValue: current,
      onSelected: (lang) => langController.value = lang,
      itemBuilder: (context) => [
        for (final lang in Lang.values)
          PopupMenuItem(
            value: lang,
            child: Text(lang.nativeName,
                style: TextStyle(
                    fontWeight:
                        lang == current ? FontWeight.w800 : FontWeight.w500,
                    color: lang == current ? AppColors.blue : AppColors.text)),
          ),
      ],
      // Looks like the other outlined buttons in the header.
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.translate, size: 18, color: AppColors.muted),
            const SizedBox(width: 6),
            Text(current.code,
                style: TextStyle(
                    fontWeight: FontWeight.w800, color: AppColors.blue)),
            const Icon(Icons.arrow_drop_down, color: AppColors.muted),
          ],
        ),
      ),
    );
  }
}

// Dialog listing all languages (used in the admin side menu).
Future<void> showLanguageDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => SimpleDialog(
      title: Text(context.t('Language', 'Dil')),
      children: [
        for (final lang in Lang.values)
          SimpleDialogOption(
            onPressed: () {
              langController.value = lang;
              Navigator.pop(dialogContext);
            },
            child: Text(lang.nativeName,
                style: TextStyle(
                    fontWeight: lang == context.lang
                        ? FontWeight.w800
                        : FontWeight.w500)),
          ),
      ],
    ),
  );
}

// Bottom of every public page: copyright, KVKK, emergency number and
// the staff and driver login links.
class SiteFooter extends StatelessWidget {
  const SiteFooter({super.key});

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(color: AppColors.muted, fontSize: 14);
    return Container(
      decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border))),
      child: SectionContainer(
        top: 28,
        bottom: 28,
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 24,
          runSpacing: 12,
          children: [
            Text(
                '© ${DateTime.now().year} ${context.t('Koru Hospital', 'Koru Hastanesi')} · '
                '${context.t('KVKK / Privacy', 'KVKK / Gizlilik')}',
                style: style),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${context.t('Emergency', 'Acil')}: ', style: style),
                const Text('112',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.text)),
                const Text('  ·  ', style: style),
                // Link to the staff-only admin login.
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/admin/login'),
                  child: Text(context.t('Staff login', 'Personel girişi')),
                ),
                // Link to the driver login.
                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, '/driver/login'),
                  child: Text(context.t('Driver login', 'Sürücü girişi')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
