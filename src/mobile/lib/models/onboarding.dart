/// Model representing a single onboarding page with its content
class OnboardingPageModel {
  /// The title displayed on the onboarding page
  final String title;

  /// The description/subtitle displayed below the title
  final String description;

  /// The path to the background image asset
  final String backgroundImage;

  /// The path to the foreground/stacked image asset
  final String foregroundImage;

  const OnboardingPageModel({
    required this.title,
    required this.description,
    required this.backgroundImage,
    required this.foregroundImage,
  });

  /// Creates a copy of this model with optional new values
  OnboardingPageModel copyWith({
    String? title,
    String? description,
    String? backgroundImage,
    String? foregroundImage,
  }) {
    return OnboardingPageModel(
      title: title ?? this.title,
      description: description ?? this.description,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      foregroundImage: foregroundImage ?? this.foregroundImage,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingPageModel &&
        other.title == title &&
        other.description == description &&
        other.backgroundImage == backgroundImage &&
        other.foregroundImage == foregroundImage;
  }

  @override
  int get hashCode {
    return title.hashCode ^
        description.hashCode ^
        backgroundImage.hashCode ^
        foregroundImage.hashCode;
  }

  @override
  String toString() {
    return 'OnboardingPageModel(title: $title, description: $description, '
        'backgroundImage: $backgroundImage, foregroundImage: $foregroundImage)';
  }
}

