import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'injection/injection_container.dart';
import 'l10n/app_localizations.dart';
import 'presentation/cubits/settings/settings_cubit.dart';
import 'presentation/cubits/settings/settings_state.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables.
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('📁 [dotenv] Loaded .env successfully. Keys: ${dotenv.env.keys.toList()}');
    debugPrint('📁 [dotenv] SUPABASE_URL: ${dotenv.env['SUPABASE_URL']}');
  } catch (e) {
    debugPrint('❌ [dotenv] Failed to load .env: $e');
  }

  // Initialise Supabase SDK.
  await SupabaseService.init();

  // Register dependencies in get_it.
  await initDependencies();

  runApp(const SpendlyApp());
}

/// Root widget of the Spendly application.
class SpendlyApp extends StatelessWidget {
  const SpendlyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<SettingsCubit>(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'Spendly',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: settingsState.themeMode,
            locale: settingsState.locale,
            routerConfig: appRouter,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          );
        },
      ),
    );
  }
}
