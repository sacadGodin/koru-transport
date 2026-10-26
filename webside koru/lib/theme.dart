import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Ready-made main colors shown in the color picker. The first one (Koru
// navy, from koruhastanesi.com) is the default. Add or change colors here.
const colorPresets = <(String, String, Color)>[
  ('Koru navy', 'Koru laciverti', Color(0xFF003973)),
  ('Royal blue', 'Kraliyet mavisi', Color(0xFF1F4FD1)),
  ('Sky blue', 'Gök mavisi', Color(0xFF0B84D8)),
  ('Teal', 'Turkuaz', Color(0xFF0E8C8C)),
  ('Green', 'Yeşil', Color(0xFF16884A)),
  ('Indigo', 'Çivit', Color(0xFF4F46E5)),
  ('Purple', 'Mor', Color(0xFF7A3FD1)),
  ('Rose', 'Gül', Color(0xFFD1366B)),
  ('Orange', 'Turuncu', Color(0xFFD9620B)),
];

// Holds the main color of the site. Changing it re-colors every page
// (see KoruApp in main.dart). The choice is saved in this browser.
class ColorController extends ValueNotifier<Color> {
  ColorController() : super(colorPresets.first.$3);

  static const _key = 'main_color';

  // Loads the color saved last time (called once at app start).
  Future<void> load() async {
    try {
      final saved = (await SharedPreferences.getInstance()).getInt(_key);
      if (saved != null) value = Color(saved);
    } catch (_) {
      // Storage blocked (e.g. private window): keep the default color.
    }
  }

  // Sets a new main color and saves it.
  Future<void> set(Color color) async {
    value = color;
    try {
      (await SharedPreferences.getInstance()).setInt(_key, color.toARGB32());
    } catch (_) {}
  }

  // Back to the default Koru navy.
  Future<void> reset() => set(colorPresets.first.$3);
}

// The one color controller for the whole app.
final colorController = ColorController();

// Returns [color] made lighter (amount > 0) or darker (amount < 0).
Color _shade(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

// All website colors in one place (Koru Hastanesi palette: navy, gold
// and white). The four "blue" colors follow the main color chosen in the
// color picker; the rest are fixed.
class AppColors {
  // Main color (Koru navy by default): buttons, links, highlights.
  static Color get blue => colorController.value;
  // Darker main color: hover color and the admin side menu.
  static Color get blueDark => _shade(blue, -0.12);
  // Very light main color: card backgrounds.
  static Color get blueSoft => Color.lerp(blue, Colors.white, 0.91)!;
  // Light text used on top of main-color backgrounds.
  static Color get blueOnDark => Color.lerp(blue, Colors.white, 0.85)!;
  // Koru gold accent (logo heart), and a lighter gold for dark backgrounds.
  static const gold = Color(0xFFAE8A30);
  static const goldLight = Color(0xFFC9A34A);
  // Light grey background for some sections.
  static const surface = Color(0xFFF4F6F9);
  // Thin grey lines around cards.
  static const border = Color(0xFFE3E8EF);
  // Grey outline of text fields and outline buttons.
  static const inputBorder = Color(0xFFD0D5DD);
  // Main text color (dark navy-grey).
  static const text = Color(0xFF1F2A37);
  // Grey text for descriptions.
  static const muted = Color(0xFF52627A);
  // Green dot for "available" badges.
  static const success = Color(0xFF12B76A);
  // Rating stars.
  static const star = Color(0xFFF5A524);
  // Light orange box + dark orange text for the "Call 112" emergency notice.
  static const emergencyBg = Color(0xFFFFF1EC);
  static const emergencyText = Color(0xFFB93815);
}

// Corner sizes from the brief.
class AppRadius {
  // Buttons and text fields.
  static const control = 14.0;
  // Cards.
  static const card = 28.0;
}

// Builds the app theme: Material 3, blue color scheme, Manrope font,
// rounded buttons and text fields.
ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      primary: AppColors.blue,
      secondary: AppColors.blueDark,
      surface: Colors.white,
    ),
    scaffoldBackgroundColor: Colors.white,
  );

  // Button text style (buttons don't inherit the page font, so set it here).
  final buttonText =
      GoogleFonts.manrope(fontWeight: FontWeight.w700, fontSize: 15);
  final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.control));

  return base.copyWith(
    // Manrope everywhere, near-black text.
    textTheme: GoogleFonts.manropeTextTheme(base.textTheme).apply(
      bodyColor: AppColors.text,
      displayColor: AppColors.text,
    ),
    // Blue filled buttons, at least 48 px tall (easy to tap).
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.blue,
        foregroundColor: Colors.white,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: controlShape,
        textStyle: buttonText,
      ),
    ),
    // White buttons with a grey outline.
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        side: const BorderSide(color: AppColors.inputBorder),
        shape: controlShape,
        textStyle: buttonText,
      ),
    ),
    // Every text field: white, rounded, grey outline, blue when focused.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.control)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
        borderSide: BorderSide(color: AppColors.blue, width: 2),
      ),
    ),
  );
}

// Screen size checks shared by every page.
class Responsive {
  // Phone: screen narrower than 700 px.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 700;
  // Tablet or small laptop: narrower than 1100 px.
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 1100;
}
