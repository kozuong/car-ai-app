import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/storage_service.dart';
import 'screens/home_page.dart';
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  final storage = StorageService();
  final langCode = await storage.getLanguage() ?? 'en';

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/lang',
      fallbackLocale: const Locale('en'),
      startLocale: Locale(langCode),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: tr('app_title'),
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      locale: context.locale,
      supportedLocales: context.supportedLocales,
      localizationsDelegates: context.localizationDelegates,
      home: HomePage(langCode: context.locale.languageCode),
    );
  }
}
