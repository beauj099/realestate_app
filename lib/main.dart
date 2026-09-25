import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/constants/app_constants.dart';
import 'core/network/platform_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'features/auth/providers/agent_profile_provider.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  try {
    await dotenv.load();
  } on FileNotFoundError {
    // .env is optional — fall back to build-time defines.
  } on EmptyEnvFileError {
    // .env exists but is empty — treat as not provided.
  }
  // Photos are served by the API, which runs on a self-signed dev cert.
  allowApiImagesWithDevCert(resolveDefaultBaseUrl());
  await SharedPreferences.getInstance();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(authProvider.notifier).init();
      FlutterNativeSplash.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeConfig = ref.watch(themeConfigProvider);
    final themeMode = ref.watch(themeModeProvider);
    final router = ref.watch(appRouterProvider);
    // Keep the profile alive from launch: it fetches the agent's profile and
    // applies their agency's brand whenever someone signs in.
    ref.listen(agentProfileProvider, (_, _) {});

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: themeConfig.toThemeData(),
      darkTheme: themeConfig.toDarkThemeData(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
