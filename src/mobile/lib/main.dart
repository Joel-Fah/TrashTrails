import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:trashtrails/controllers/controllers.dart';
import 'package:trashtrails/services/services.dart';
import 'package:trashtrails/utils/routes.dart';
import 'package:trashtrails/utils/theme.dart';
import 'package:trashtrails/utils/utils.dart';

import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  // Ensure that the app is initialized before running
  WidgetsFlutterBinding.ensureInitialized();

  // Load env file
  try {
    await dotenv.load(fileName: ".env");
    if (kDebugMode) {
      debugPrint('✓ .env file loaded successfully');
    }

    // Configure Mapbox access token
    final mapboxToken = dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? '';
    if (mapboxToken.isNotEmpty) {
      MapboxOptions.setAccessToken(mapboxToken);
      if (kDebugMode) {
        debugPrint('✓ Mapbox access token configured');
      }
    }
  } on FileSystemException catch (e) {
    if (kDebugMode) {
      debugPrint('Warning: .env file not found or inaccessible: ${e.message}');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Warning: Error loading .env file: $e');
    }
  }

  // Initialize GetStorage
  await GetStorage.init();
  await ThemeController.ensureStorageInitialized();

  // Set default locale for intl
  initializeDateFormatting('en_US', null);
  Intl.defaultLocale = 'en_US';

  // ─── Initialize Services (Global, persist throughout app lifecycle) ──────
  // Note: Order matters! StorageService and ApiService must be initialized first
  Get.put(StorageService(), permanent: true);
  Get.put(ApiService(), permanent: true);
  Get.put(AuthService(), permanent: true);
  Get.put(LocationService(), permanent: true);
  Get.put(MapService(), permanent: true);
  Get.put(ReportService(), permanent: true);

  // ─── Initialize Controllers ──────────────────────────────────────────────
  Get.put(LocaleController());
  Get.put(ThemeController());
  Get.put(OnboardingController());
  Get.put(AuthController());
  Get.put(HomeController());

  // locked orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Time ago locales
  timeago.setDefaultLocale('en');
  timeago.setLocaleMessages('fr', timeago.FrMessages());

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'Trash Trails',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: snackBarKey,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: Get.find<ThemeController>().themeMode,
      locale: Get.find<LocaleController>().locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: L10n.all,
      fallbackLocale: const Locale('en', 'US'),
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
