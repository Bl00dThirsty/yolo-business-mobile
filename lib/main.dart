import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config.dart';
import 'core/theme.dart';
import 'data/business_repository.dart';
import 'data/demo_repository.dart';
import 'data/secure_auth_storage.dart';
import 'ui/auth_page.dart';
import 'ui/components.dart';
import 'ui/workspace_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String? startupError;
  if (AppConfig.configured && !AppConfig.demo) {
    try {
      await Supabase.initialize(
        url: AppConfig.url,
        publishableKey: AppConfig.key,
        authOptions: FlutterAuthClientOptions(
          localStorage: SecureAuthStorage(Uri.parse(AppConfig.url).host),
        ),
      );
    } catch (_) {
      startupError =
          'Impossible d’initialiser la connexion. Fermez puis rouvrez l’application.';
    }
  }
  runApp(YoloBusinessApp(startupError: startupError));
}

class YoloBusinessApp extends StatefulWidget {
  final String? startupError;
  const YoloBusinessApp({super.key, this.startupError});
  @override
  State<YoloBusinessApp> createState() => _YoloBusinessAppState();
}

class _YoloBusinessAppState extends State<YoloBusinessApp> {
  final navigator = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? subscription;
  Session? session;
  BusinessRepository? repository;
  bool recovery = false, demoOpen = AppConfig.demo;
  @override
  void initState() {
    super.initState();
    if (AppConfig.demo) {
      repository = DemoRepository();
    } else if (AppConfig.configured && widget.startupError == null) {
      final client = Supabase.instance.client;
      session = client.auth.currentSession;
      if (session != null) repository = SupabaseBusinessRepository(client);
      subscription = client.auth.onAuthStateChange.listen(
        (event) {
          if (!mounted) return;
          final changed = session?.user.id != event.session?.user.id;
          if (changed || event.event == AuthChangeEvent.passwordRecovery) {
            navigator.currentState?.popUntil((route) => route.isFirst);
          }
          setState(() {
            session = event.session;
            if (changed) {
              repository = session == null
                  ? null
                  : SupabaseBusinessRepository(client);
            }
            if (event.event == AuthChangeEvent.passwordRecovery) {
              recovery = true;
            }
            if (event.event == AuthChangeEvent.signedOut) recovery = false;
          });
        },
        onError: (_) {
          if (mounted) {
            navigator.currentState?.popUntil((route) => route.isFirst);
            setState(() {
              session = null;
              repository = null;
            });
          }
        },
      );
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'YOLO Business',
    debugShowCheckedModeBanner: false,
    navigatorKey: navigator,
    theme: YoloTheme.light,
    darkTheme: YoloTheme.dark,
    themeMode: ThemeMode.system,
    locale: const Locale('fr'),
    supportedLocales: const [Locale('fr')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: widget.startupError != null
        ? Scaffold(
            body: SafeArea(child: Center(child: Notice(widget.startupError!))),
          )
        : (session != null && !recovery) || (AppConfig.demo && demoOpen)
        ? WorkspacePage(
            key: ValueKey(repository!.userId),
            repository: repository!,
            email: session?.user.email ?? 'responsable@exemple.com',
            exitDemo: () => setState(() => demoOpen = false),
          )
        : AuthPage(
            recovery: recovery,
            onRecovered: () => setState(() => recovery = false),
            onDemo: AppConfig.demo
                ? () => setState(() => demoOpen = true)
                : null,
          ),
  );
}
