// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'EaglEs Property';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navProperties => 'Properties';

  @override
  String get navConstruction => 'Construction';

  @override
  String get navSalesCrm => 'Sales CRM';

  @override
  String get navMarketplace => 'Marketplace';

  @override
  String get navAiAssistant => 'Mr. EaglEs';

  @override
  String get navSettings => 'Settings';

  @override
  String get currencySymbol => 'ETB';

  @override
  String welcomeMessage(String tenantName) {
    return 'Welcome to $tenantName';
  }
}
