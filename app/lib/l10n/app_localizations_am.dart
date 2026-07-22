// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'EaglEs ንብረት';

  @override
  String get navDashboard => 'ዳሽቦርድ';

  @override
  String get navProperties => 'ንብረቶች';

  @override
  String get navConstruction => 'ግንባታ';

  @override
  String get navSalesCrm => 'የሽያጭ CRM';

  @override
  String get navMarketplace => 'ገበያ';

  @override
  String get navAiAssistant => 'ሚስተር EaglEs';

  @override
  String get navSettings => 'ቅንብሮች';

  @override
  String get currencySymbol => 'ብር';

  @override
  String welcomeMessage(String tenantName) {
    return 'እንኳን ወደ $tenantName በደህና መጡ';
  }
}
