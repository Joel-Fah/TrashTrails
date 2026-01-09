import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trashtrails/ui/pages/home.dart';
import 'package:trashtrails/ui/pages/onboarding/onboarding.dart';
import 'package:trashtrails/utils/utils.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: rootNavigatorKey,
  initialLocation: OnboardingPage.routeName,
  routes: [
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: removeLeadingSlash(OnboardingPage.routeName),
      path: OnboardingPage.routeName,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: removeLeadingSlash(HomePage.routeName),
      path: HomePage.routeName,
      builder: (context, state) => const HomePage(),
    ),
  ],
);
