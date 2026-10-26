import 'package:flutter/material.dart';

import '../lang.dart';
import '../theme.dart';

// Palette button: opens the color picker. Used in the website header and
// the admin side menu. Use light: true on dark backgrounds.
class ColorPickerButton extends StatelessWidget {
  const ColorPickerButton({super.key, this.light = false});

  final bool light;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.t('Change color', 'Rengi değiştir'),
      icon: Icon(Icons.palette_outlined,
          color: light ? Colors.white : AppColors.blue),
      onPressed: () => showColorPicker(context),
    );
  }
}

// Opens the color picker dialog.
Future<void> showColorPicker(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _ColorDialog());

// Dialog: ready-made colors, a box for any color code (e.g. #1F4FD1),
// and a button back to the default Koru navy. Every change shows right away.
class _ColorDialog extends StatefulWidget {
  const _ColorDialog();

  @override
  State<_ColorDialog> createState() => _ColorDialogState();
}

class _ColorDialogState extends State<_ColorDialog> {
  late final _hex = TextEditingController(text: _toHex(AppColors.blue));
  String? _hexError;

  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  // Color as "#1F4FD1".
  static String _toHex(Color c) =>
      '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

  // "#1F4FD1" or "1F4FD1" -> Color, or null if it is not a color code.
  static Color? _parseHex(String text) {
    final hex = text.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return Color(0xFF000000 | int.parse(hex, radix: 16));
  }

  Future<void> _pick(Color color) async {
    await colorController.set(color);
    setState(() {
      _hex.text = _toHex(color);
      _hexError = null;
    });
  }

  void _applyHex() {
    final color = _parseHex(_hex.text);
    if (color == null) {
      setState(() => _hexError =
          context.t('Use a code like #1F4FD1', '#1F4FD1 gibi bir kod girin'));
      return;
    }
    // Very light colors make white button text unreadable.
    if (color.computeLuminance() > 0.45) {
      setState(() => _hexError = context.t(
          'Too light: white text would be hard to read',
          'Çok açık: beyaz yazı okunmaz'));
      return;
    }
    _pick(color);
  }

  @override
  Widget build(BuildContext context) {
    final current = AppColors.blue;
    return AlertDialog(
      title: Text(context.t('Site color', 'Site rengi')),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                context.t('Pick the main color. White stays the background.',
                    'Ana rengi seçin. Arka plan beyaz kalır.'),
                style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 18),
            // Ready-made colors.
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final (en, tr, color) in colorPresets)
                  Tooltip(
                    message: context.t(en, tr),
                    child: InkWell(
                      onTap: () => _pick(color),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: color == current
                                  ? AppColors.text
                                  : Colors.transparent,
                              width: 3),
                        ),
                        child: color == current
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 22),
            // Any color by code.
            Text(context.t('Custom color code', 'Özel renk kodu'),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _hex,
                    onSubmitted: (_) => _applyHex(),
                    decoration: InputDecoration(
                      hintText: '#1F4FD1',
                      errorText: _hexError,
                      errorMaxLines: 2,
                      prefixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child:
                            CircleAvatar(radius: 10, backgroundColor: current),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                    onPressed: _applyHex,
                    child: Text(context.t('Apply', 'Uygula'))),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => _pick(colorPresets.first.$3),
            child:
                Text(context.t('Reset to Koru navy', 'Koru lacivertine dön'))),
        FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.t('Done', 'Tamam'))),
      ],
    );
  }
}
