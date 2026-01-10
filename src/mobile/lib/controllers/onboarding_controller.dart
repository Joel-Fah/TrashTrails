import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

import '../models/onboarding.dart';
import '../utils/constants.dart';

/// Controller for managing onboarding state and navigation
class OnboardingController extends GetxController
    with GetSingleTickerProviderStateMixin {
  static const String _storageKey = 'onboarding_completed';

  OnboardingController({GetStorage? box}) : _box = box ?? GetStorage();

  final GetStorage _box;

  // Page Controller for swipe gestures
  late final PageController pageController;

  // Animation controller for content transitions
  late final AnimationController animationController;

  // Current page index (reactive)
  final RxInt _currentIndex = 0.obs;

  // Animation state for content fade
  final RxBool _isAnimating = false.obs;

  /// List of onboarding pages data
  final List<OnboardingPageModel> pages = const [
    OnboardingPageModel(
      title: 'Spot It. Snap It.\nOne more time.',
      description:
          'See trash dumped where it shouldn’t be? Open the app, take a quick photo, and report it in seconds. No paperwork, no drama.',
      backgroundImage: onboarding1,
      foregroundImage: trash,
    ),
    OnboardingPageModel(
      title: 'Let the App Do the Heavy Thinking',
      description:
          'Our system analyzes the image to identify recyclable materials, helping turn random trash into useful environmental data.',
      backgroundImage: onboarding2,
      foregroundImage: camera,
    ),
    OnboardingPageModel(
      title: 'Clean Streets, Earn Bragging Rights',
      description:
          'Every report and endorsement earns you points. Climb the leaderboard, compete with others, and make cleaning the city oddly satisfying.',
      backgroundImage: onboarding3,
      foregroundImage: rank,
    ),
  ];

  // Getters
  int get currentIndex => _currentIndex.value;

  bool get isAnimating => _isAnimating.value;

  bool get isLastPage => _currentIndex.value == pages.length - 1;

  bool get isFirstPage => _currentIndex.value == 0;

  OnboardingPageModel get currentPage => pages[_currentIndex.value];

  int get totalPages => pages.length;

  /// Check if onboarding was already completed
  bool get isOnboardingCompleted => _box.read<bool>(_storageKey) ?? false;

  @override
  void onInit() {
    super.onInit();
    pageController = PageController(initialPage: 0);
    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    animationController.value = 1.0; // Start fully visible
  }

  @override
  void onClose() {
    pageController.dispose();
    animationController.dispose();
    super.onClose();
  }

  /// Navigate to next page with animation
  Future<void> nextPage() async {
    if (isLastPage || _isAnimating.value) return;

    _isAnimating.value = true;

    // Fade out current content
    await animationController.reverse();

    // Change page
    _currentIndex.value++;
    pageController.animateToPage(
      _currentIndex.value,
      duration: duration,
      curve: Curves.easeInOut,
    );

    // Fade in new content
    await animationController.forward();

    _isAnimating.value = false;
  }

  /// Navigate to previous page with animation
  Future<void> previousPage() async {
    if (isFirstPage || _isAnimating.value) return;

    _isAnimating.value = true;

    // Fade out current content
    await animationController.reverse();

    // Change page
    _currentIndex.value--;
    pageController.animateToPage(
      _currentIndex.value,
      duration: duration,
      curve: Curves.easeInOut,
    );

    // Fade in new content
    await animationController.forward();

    _isAnimating.value = false;
  }

  /// Handle page change from swipe gesture
  Future<void> onPageChanged(int index) async {
    if (_isAnimating.value || index == _currentIndex.value) return;

    _isAnimating.value = true;

    // Fade out current content
    await animationController.reverse();

    // Update index
    _currentIndex.value = index;

    // Fade in new content
    await animationController.forward();

    _isAnimating.value = false;
  }

  /// Go to specific page
  Future<void> goToPage(int index) async {
    if (index < 0 ||
        index >= pages.length ||
        index == _currentIndex.value ||
        _isAnimating.value) {
      return;
    }

    _isAnimating.value = true;

    // Fade out current content
    await animationController.reverse();

    // Change page
    _currentIndex.value = index;
    pageController.animateToPage(
      index,
      duration: duration,
      curve: Curves.easeInOut,
    );

    // Fade in new content
    await animationController.forward();

    _isAnimating.value = false;
  }

  /// Mark onboarding as completed and navigate to home/auth
  Future<void> completeOnboarding() async {
    await _box.write(_storageKey, true);
    // Navigation will be handled by the UI layer using go_router
  }

  /// Reset onboarding state (useful for testing or settings)
  Future<void> resetOnboarding() async {
    await _box.remove(_storageKey);
    _currentIndex.value = 0;
    pageController.jumpToPage(0);
    animationController.value = 1.0;
  }
}
