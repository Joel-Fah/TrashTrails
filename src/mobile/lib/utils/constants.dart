import 'package:trashtrails/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/* ----------- Colors ----------- */
// Primaries
const Color seedColor = Color(0xFF366A91);

// Neutrals
const Color darkColor = Color(0xFF272727);
const Color lightColor = Colors.white;
const Color greyColor = Color(0xFF8D8D8D);

// Leaderboard Colors
const Color gold = Color(0xFFFFD700);
const Color silver = Color(0xFFC0C0C0);
const Color bronze = Color(0xFFCD7F32);

// States Colors
Color infoColor = themeController.isDark
    ? Colors.lightBlueAccent
    : Color(0xFF4285F4);
Color successColor = themeController.isDark
    ? Colors.green
    : Color(0xFF0F9D58);
Color errorColor = themeController.isDark
    ? Colors.redAccent
    : Color(0xFFDB4437);
Color warningColor = themeController.isDark
    ? Colors.amberAccent
    : Color(0xFFEAAB00);

// Gradients
LinearGradient lightGradient = LinearGradient(
  colors: [seedPalette.shade50, Colors.white],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

LinearGradient darkGradient = LinearGradient(
  colors: [seedColor, seedPalette.shade900],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
);

// Material Color Palettes
MaterialColor seedPalette =
    MaterialColor(seedColor.toARGB32(), const <int, Color>{
      50: Color(0xFFF4F7FB),
      100: Color(0xFFE8EFF6),
      200: Color(0xFFCCDDEB),
      300: Color(0xFF9FC2DA),
      400: Color(0xFF6bA1C5),
      500: Color(0xFF4886AF),
      600: Color(0xFF2D5677),
      700: Color(0xFF294A63),
      800: Color(0xFF263F54),
      900: Color(0xFF192938),
    });

/* ----------- Icons ----------- */
// States Icons
const List<List<dynamic>> infoIcon = HugeIcons.strokeRoundedInformationCircle;
const List<List<dynamic>> errorIcon = HugeIcons.strokeRoundedCancelCircle;
const List<List<dynamic>> warningIcon = HugeIcons.strokeRoundedAlert02;
const List<List<dynamic>> successIcon =
    HugeIcons.strokeRoundedCheckmarkCircle02;

/* ----------- Fonts ----------- */
// Font Family
const String textFont = "GeneralSans";

/* ----------- Images ----------- */
// Logo
const String cyanLogo = 'assets/images/logo/cyan.svg';
const String blackLogo = 'assets/images/logo/black.svg';
const String whiteLogo = 'assets/images/logo/white.svg';

// Icons & Flags
const String googleIcon = 'assets/images/icons/google.svg';
const String googleIconColor = 'assets/images/icons/google_color.svg';
const String usaFlag = 'assets/images/flags/usa.png';
const String franceFlag = 'assets/images/flags/france.png';

// Onboarding
const String onboarding1 = 'assets/images/onboarding1.jpg';
const String onboarding2 = 'assets/images/onboarding2.jpg';
const String onboarding3 = 'assets/images/onboarding3.jpg';
const String trash = 'assets/images/trash.png';
const String camera = 'assets/images/camera.png';
const String rank = 'assets/images/rank.png';

// Avatars
const String avatar1 = 'assets/images/avatars/avatar1.png';
const String avatar2 = 'assets/images/avatars/avatar2.png';
const String avatar3 = 'assets/images/avatars/avatar3.png';
const String avatar4 = 'assets/images/avatars/avatar4.png';

// Trash
const String trash1 = 'assets/images/trash/trash1.png';
const String trash2 = 'assets/images/trash/trash2.png';
const String trash3 = 'assets/images/trash/trash3.png';

// Misc
const String map = 'assets/images/map.png';
const String report = 'assets/images/report.png';
const String authBg = 'assets/images/auth_bg.png';



/* ----------- Widgets ----------- */
// BorderRadii
BorderRadius borderRadius = BorderRadius.circular(8.0);
BorderRadius topRadius = const BorderRadius.vertical(
  top: Radius.circular(16.0),
);

// Duration
const Duration duration = Duration(milliseconds: 300);

// TextStyles
class AppTextStyles {
  static const TextStyle title = TextStyle(
    fontFamily: textFont,
    fontSize: 34.0,
    height: 40.0 / 34.0,
    fontWeight: FontWeight.w900,
    fontVariations: [FontVariation('wght', 900)],
  );

  static TextStyle h1 = TextStyle(
    fontFamily: textFont,
    fontSize: 28.0,
    height: 36.0 / 28.0,
    fontWeight: FontWeight.bold,
    fontVariations: [FontVariation('wght', 700)],
  );

  static const TextStyle h2 = TextStyle(
    fontFamily: textFont,
    fontSize: 24.0,
    height: 32.0 / 24.0,
    fontWeight: FontWeight.w600,
    fontVariations: [FontVariation('wght', 600)],
  );

  static const TextStyle h3 = TextStyle(
    fontFamily: textFont,
    fontSize: 20.0,
    height: 28.0 / 20.0,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const TextStyle h4 = TextStyle(
    fontFamily: textFont,
    fontSize: 18.0,
    height: 24.0 / 18.0,
    fontWeight: FontWeight.w500,
    fontVariations: [FontVariation('wght', 500)],
  );

  static const TextStyle body = TextStyle(
    fontFamily: textFont,
    fontSize: 16.0,
    height: 24.0 / 16.0,
    fontWeight: FontWeight.normal,
    fontVariations: [FontVariation('wght', 400)],
  );

  static const TextStyle small = TextStyle(
    fontFamily: textFont,
    fontSize: 12.0,
    height: 16.0 / 12.0,
    fontWeight: FontWeight.w300,
    fontVariations: [FontVariation('wght', 300)],
  );
}

// Input Borders
class AppInputBorders {
  static OutlineInputBorder border = OutlineInputBorder(
    borderSide: BorderSide(
      color: themeController.isDark ? lightColor : seedColor,
      width: 1,
    ),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder focusedBorder = OutlineInputBorder(
    borderSide: BorderSide(
      color: themeController.isDark ? lightColor : seedColor,
      width: 1,
    ),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder errorBorder = OutlineInputBorder(
    borderSide: BorderSide(color: errorColor, width: 1),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder focusedErrorBorder = OutlineInputBorder(
    borderSide: BorderSide(color: errorColor, width: 1),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder enabledBorder = OutlineInputBorder(
    borderSide: BorderSide(
      color: themeController.isDark ? lightColor : seedColor,
      width: 1,
    ),
    borderRadius: borderRadius * 2.25,
  );

  static OutlineInputBorder disabledBorder = OutlineInputBorder(
    borderSide: BorderSide(color: greyColor, width: 1),
    borderRadius: borderRadius * 2.25,
  );
}

// Departments
const List<String> departments = ['ICT', 'BMS'];

// Programs by department
const Map<String, List<String>> programsByDepartment = {
  'ICT': [
    'Computer Science',
    'Software Engineering',
    'Cybersecurity',
    'Data Science',
    'Information Systems & Networking',
    'ICT',
  ],
  'BMS': [
    'Business Administration',
    'Marketing and Communication',
    'Human Resource Management',
    'Finance and Accounting',
    'International Business',
    'Entrepreneurship and Innovation',
  ],
};