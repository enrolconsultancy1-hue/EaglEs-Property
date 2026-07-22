// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Oromo (`om`).
class AppLocalizationsOm extends AppLocalizations {
  AppLocalizationsOm([String locale = 'om']) : super(locale);

  @override
  String get appTitle => 'Qabeenya EaglEs';

  @override
  String get navDashboard => 'Daashboordii';

  @override
  String get navProperties => 'Qabeenyawwan';

  @override
  String get navConstruction => 'Ijaarsa';

  @override
  String get navSalesCrm => 'Gurgurtaa CRM';

  @override
  String get navMarketplace => 'Gabaa';

  @override
  String get navAiAssistant => 'Obbo EaglEs';

  @override
  String get navSettings => 'Sajoo';

  @override
  String get currencySymbol => 'Birrii';

  @override
  String welcomeMessage(String tenantName) {
    return 'Baga gara $tenantName nagaan dhuftan';
  }
}
