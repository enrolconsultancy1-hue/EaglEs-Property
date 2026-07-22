// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tigrinya (`ti`).
class AppLocalizationsTi extends AppLocalizations {
  AppLocalizationsTi([String locale = 'ti']) : super(locale);

  @override
  String get appTitle => 'EaglEs ንብረት';

  @override
  String get navDashboard => 'ዳሽቦርድ';

  @override
  String get navProperties => 'ንብረታት';

  @override
  String get navConstruction => 'ህንፃ';

  @override
  String get navSalesCrm => 'ናይ መሸጣ CRM';

  @override
  String get navMarketplace => 'ዕዳጋ';

  @override
  String get navAiAssistant => 'ሚስተር EaglEs';

  @override
  String get navSettings => 'ቅጥዕታት';

  @override
  String get currencySymbol => 'ብር';

  @override
  String welcomeMessage(String tenantName) {
    return 'እንቋዕ ናብ $tenantName ብደሓን መጹ';
  }
}
