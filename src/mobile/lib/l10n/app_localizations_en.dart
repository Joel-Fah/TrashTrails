// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get language_english => 'English';

  @override
  String get language_french => 'French';

  @override
  String get weekday_monday => 'Monday';

  @override
  String get weekday_tuesday => 'Tuesday';

  @override
  String get weekday_wednesday => 'Wednesday';

  @override
  String get weekday_thursday => 'Thursday';

  @override
  String get weekday_friday => 'Friday';

  @override
  String get weekday_saturday => 'Saturday';

  @override
  String get weekday_sunday => 'Sunday';

  @override
  String get locale_popup_btn_tooltip => 'Change Language';

  @override
  String locale_popup_btn_label(String locale) {
    return 'Language changed to $locale';
  }

  @override
  String get backButton => 'Back';

  @override
  String get continueButton => 'Continue';

  @override
  String get imageBox_sizeLimit => 'The image size should not be more than';

  @override
  String get imageBox_uploadError => 'Error during image upload:';

  @override
  String get imageBox_loadingError => 'Loading error';

  @override
  String get change => 'Change';

  @override
  String get remove => 'Remove';
}
