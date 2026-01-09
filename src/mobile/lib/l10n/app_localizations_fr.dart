// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get language_english => 'Anglais';

  @override
  String get language_french => 'Français';

  @override
  String get weekday_monday => 'Lundi';

  @override
  String get weekday_tuesday => 'Mardi';

  @override
  String get weekday_wednesday => 'Mercredi';

  @override
  String get weekday_thursday => 'Jeudi';

  @override
  String get weekday_friday => 'Vendredi';

  @override
  String get weekday_saturday => 'Samedi';

  @override
  String get weekday_sunday => 'Dimanche';

  @override
  String get locale_popup_btn_tooltip => 'Changez la langue';

  @override
  String locale_popup_btn_label(String locale) {
    return 'Langue changée en $locale';
  }

  @override
  String get backButton => 'Retour';

  @override
  String get continueButton => 'Continuer';

  @override
  String get imageBox_sizeLimit => 'La taille de l\'image ne doit pas dépasser';

  @override
  String get imageBox_uploadError => 'Erreur lors du chargement de l\'image :';

  @override
  String get imageBox_loadingError => 'Erreur de chargement';

  @override
  String get change => 'Changer';

  @override
  String get remove => 'Retirer';
}
