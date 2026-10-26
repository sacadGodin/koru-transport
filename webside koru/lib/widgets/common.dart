import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../lang.dart';
import '../theme.dart';

// Opens a phone call (tel:), email (mailto:), WhatsApp chat or web page.
Future<void> openLink(String url) async {
  await launchUrl(Uri.parse(url));
}

// Centers content, caps its width at 1280 px and adds side padding
// (16 px on phones, 24 px on bigger screens).
class SectionContainer extends StatelessWidget {
  const SectionContainer({
    super.key,
    required this.child,
    this.color,
    this.top = 48,
    this.bottom = 48,
  });

  final Widget child;
  final Color? color;
  final double top;
  final double bottom;

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final side = mobile ? 16.0 : 24.0;
    return Container(
      width: double.infinity,
      color: color,
      padding: EdgeInsets.fromLTRB(
          side, mobile ? top * 0.7 : top, side, mobile ? bottom * 0.7 : bottom),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1232),
          child: child,
        ),
      ),
    );
  }
}

// Big bold section title with an optional grey subtitle under it.
class SectionHeading extends StatelessWidget {
  const SectionHeading(this.title,
      {super.key, this.subtitle, this.center = false, this.size = 40});

  final String title;
  final String? subtitle;
  final bool center;
  final double size;

  @override
  Widget build(BuildContext context) {
    final mobile = Responsive.isMobile(context);
    final align = center ? TextAlign.center : TextAlign.start;
    return Column(
      crossAxisAlignment:
          center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Text(title,
            textAlign: align,
            style: TextStyle(
                fontSize: mobile ? size * 0.75 : size,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                height: 1.15)),
        // Subtitle, only if one is given.
        if (subtitle != null) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(subtitle!,
                textAlign: align,
                style: const TextStyle(
                    fontSize: 17, height: 1.6, color: AppColors.muted)),
          ),
        ],
      ],
    );
  }
}

// Light blue box with a [PLACEHOLDER] label, used for photos and maps
// until real images are added.
class PlaceholderBox extends StatelessWidget {
  const PlaceholderBox(this.label,
      {super.key, this.height = 320, this.radius = 24});

  final String label;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.blueSoft,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.blue, fontWeight: FontWeight.w700)),
    );
  }
}

// Small bold grey label above a form field.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.label, {super.key, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.muted)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }
}

// Field that looks like a text field but opens a picker when tapped
// (used for date and time).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.value,
    required this.hint,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final String? value;
  final String hint;
  final IconData icon;
  final VoidCallback onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.control),
      child: InputDecorator(
        decoration: InputDecoration(
            suffixIcon: Icon(icon, size: 20), errorText: errorText),
        child: Text(value ?? hint,
            style: TextStyle(
                fontSize: 16,
                color: value == null ? AppColors.muted : AppColors.text)),
      ),
    );
  }
}

// Places children in a grid: 1 column on phones, [tabletColumns] on
// medium screens and [desktopColumns] on wide screens.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.desktopColumns = 3,
    this.tabletColumns = 2,
    this.spacing = 20,
  });

  final List<Widget> children;
  final int desktopColumns;
  final int tabletColumns;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      // Choose how many columns fit in the available width.
      final columns = constraints.maxWidth < 600
          ? 1
          : constraints.maxWidth < 1000
              ? tabletColumns
              : desktopColumns;
      // Width of each item so the columns fill the row exactly.
      final itemWidth =
          (constraints.maxWidth - spacing * (columns - 1)) / columns;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: [
          for (final child in children)
            SizedBox(width: itemWidth, child: child),
        ],
      );
    });
  }
}

// Light orange "Emergency? Call 112" box. It stays orange so it stands out.
class EmergencyNotice extends StatelessWidget {
  const EmergencyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.emergencyBg,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.emergencyText),
            const SizedBox(width: 10),
            Text(context.t('Emergency?', 'Acil durum mu?'),
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emergencyText)),
          ]),
          const SizedBox(height: 8),
          Text(
              context.t(
                  'This form is not for emergencies. Call 112 right away.',
                  'Bu form acil durumlar için değildir. Hemen 112\'yi arayın.'),
              style: const TextStyle(height: 1.5, color: AppColors.text)),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => openLink('tel:112'),
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.emergencyText),
            icon: const Icon(Icons.call, size: 18),
            label: Text(context.t('Call 112', '112\'yi ara')),
          ),
        ],
      ),
    );
  }
}

// Row of 5 stars. With [onChanged] the user can tap a star to pick a
// rating; without it the stars only show [rating].
class Stars extends StatelessWidget {
  const Stars(this.rating, {super.key, this.size = 20, this.onChanged});

  final int rating;
  final double size;
  final ValueChanged<int>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          onChanged == null
              ? Icon(
                  i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: size,
                  color: AppColors.star)
              : IconButton(
                  onPressed: () => onChanged!(i),
                  tooltip: '$i / 5',
                  iconSize: size,
                  icon: Icon(
                      i <= rating
                          ? Icons.star_rounded
                          : Icons.star_outline_rounded,
                      color: AppColors.star),
                ),
      ],
    );
  }
}
