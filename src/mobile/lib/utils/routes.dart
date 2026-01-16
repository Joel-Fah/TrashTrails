import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:trashtrails/controllers/onboarding_controller.dart';
import 'package:trashtrails/services/auth_service.dart';
import 'package:trashtrails/ui/pages/auth/auth.dart';
import 'package:trashtrails/ui/pages/home.dart';
import 'package:trashtrails/ui/pages/leaderboard/leaderboard.dart';
import 'package:trashtrails/ui/pages/reports/new_report.dart';
import 'package:trashtrails/ui/pages/reports/report_points.dart';
import 'package:trashtrails/ui/pages/onboarding/onboarding.dart';
import 'package:trashtrails/utils/utils.dart';

import '../ui/pages/reports/reports.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

final router = GoRouter(
  debugLogDiagnostics: true,
  navigatorKey: rootNavigatorKey,
  initialLocation: OnboardingPage.routeName,
  redirect: (context, state) {
    // Get services/controllers (they should be initialized in main.dart)
    final onboardingController = Get.find<OnboardingController>();
    final authService = Get.find<AuthService>();

    final isOnboardingCompleted = onboardingController.isOnboardingCompleted;
    final canAccessApp = authService.canAccessApp;

    final isOnboardingPage = state.matchedLocation == OnboardingPage.routeName;
    final isAuthPage = state.matchedLocation == AuthPage.routeName;

    // Flow: Onboarding → Auth → Home

    // If onboarding is not completed, redirect to onboarding
    if (!isOnboardingCompleted && !isOnboardingPage) {
      return OnboardingPage.routeName;
    }

    // If onboarding is completed but trying to access onboarding page
    if (isOnboardingCompleted && isOnboardingPage) {
      // Check if user can access app (authenticated or skipped)
      if (canAccessApp) {
        return HomePage.routeName;
      }
      return AuthPage.routeName;
    }

    // If onboarding is completed but user can't access app and not on auth page
    if (isOnboardingCompleted && !canAccessApp && !isAuthPage) {
      return AuthPage.routeName;
    }

    // If user can access app and is on auth page, redirect to home
    if (canAccessApp && isAuthPage) {
      return HomePage.routeName;
    }

    // No redirect needed
    return null;
  },
  routes: [
    // Onboarding + Auth routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: removeLeadingSlash(OnboardingPage.routeName),
      path: OnboardingPage.routeName,
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: removeLeadingSlash(AuthPage.routeName),
      path: AuthPage.routeName,
      builder: (context, state) => const AuthPage(),
    ),

    // Home
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: removeLeadingSlash(HomePage.routeName),
      path: HomePage.routeName,
      builder: (context, state) => const HomePage(),
    ),

    // Reports routes
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: removeLeadingSlash(NewReportPage.routeName),
      path: NewReportPage.routeName,
      builder: (context, state) => const NewReportPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: removeLeadingSlash(ReportPointsPage.routeName),
      path: ReportPointsPage.routeName,
      builder: (context, state) => const ReportPointsPage(),
    ),
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: removeLeadingSlash(ReportsFeedPage.routeName),
      path: ReportsFeedPage.routeName,
      builder: (context, state) => const ReportsFeedPage(),
    ),

    // Leaderboard
    GoRoute(
      parentNavigatorKey: rootNavigatorKey,
      name: removeLeadingSlash(LeaderboardPage.routeName),
      path: LeaderboardPage.routeName,
      builder: (context, state) => const LeaderboardPage(),
    ),
  ],
);
