import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:trashtrails/controllers/controllers.dart';
import 'package:trashtrails/utils/routes.dart';
import 'package:trashtrails/utils/theme.dart';
import 'package:trashtrails/utils/utils.dart';

import 'l10n/app_localizations.dart';
import 'l10n/l10n.dart';

Future<void> main() async {
  // Ensure that the app is initialized before running
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize GetStorage
  await GetStorage.init();
  await ThemeController.ensureStorageInitialized();

  // Set default locale for intl
  initializeDateFormatting('en_US', null);
  Intl.defaultLocale = 'en_US';

  // Initialize GetX controllers
  Get.put(LocaleController());
  Get.put(ThemeController());
  Get.put(OnboardingController());

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
