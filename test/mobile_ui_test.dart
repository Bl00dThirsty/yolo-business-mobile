import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yolo_business_mobile/core/theme.dart';
import 'package:yolo_business_mobile/data/demo_repository.dart';
import 'package:yolo_business_mobile/ui/auth_page.dart';
import 'package:yolo_business_mobile/ui/workspace_page.dart';

Future<void> loadFonts() async {
  await (FontLoader(
    'MaterialIcons',
  )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  await (FontLoader('packages/iconsax/iconsax')..addFont(
        rootBundle.load('packages/iconsax/lib/assets/fonts/iconsax.ttf'),
      ))
      .load();
  for (final font in [
    ('Barlow Semi Condensed', 'BarlowSemiCondensed-Regular.ttf'),
    ('Barlow Condensed', 'BarlowCondensed-Bold.ttf'),
    ('Geist Mono', 'GeistMono-Regular.ttf'),
  ]) {
    await (FontLoader(
      font.$1,
    )..addFont(rootBundle.load('assets/fonts/${font.$2}'))).load();
  }
}

Widget app(Widget home, {GlobalKey? capture, double scale = 1}) => MaterialApp(
  theme: YoloTheme.light,
  locale: const Locale('fr'),
  supportedLocales: const [Locale('fr')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: RepaintBoundary(key: capture, child: child!),
  ),
  home: home,
);
Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage('assets/brand/yolo-business-brand-black.png'),
      key.currentContext!,
    );
    await precacheImage(
      const AssetImage('assets/brand/yolo-business-brand-white.png'),
      key.currentContext!,
    );
  });
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final image =
        await (key.currentContext!.findRenderObject() as RenderRepaintBoundary)
            .toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('artifacts').create(recursive: true);
    await File('artifacts/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(loadFonts);
  testWidgets('Dashboard remains usable on narrow screens with larger text', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(WorkspacePage(repository: DemoRepository(), email: 'responsable@exemple.com'), scale: 1.5));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('Mobile dashboard navigation, filtering and screenshots', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      app(
        WorkspacePage(
          repository: DemoRepository(),
          email: 'responsable@exemple.com',
        ),
        capture: key,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Vos colis.\nToujours en mouvement.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await screenshot(tester, key, '01-accueil');
    await tester.tap(find.text('Livraisons').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Marie');
    await tester.pumpAndSettle();
    expect(find.text('Marie N.'), findsOneWidget);
    expect(find.text('Paul M.'), findsNothing);
    await screenshot(tester, key, '02-livraisons');
    await tester.tap(find.text('Marie N.'));
    await tester.pumpAndSettle();
    expect(find.text('Annuler la livraison'), findsNothing);
    await screenshot(tester, key, '03-detail');
    await tester.tap(find.byTooltip('Retour'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Points').last);
    await tester.pumpAndSettle();
    expect(find.text('Points de retrait.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await screenshot(tester, key, '04-points');
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Login validates empty credentials and supports narrow large text',
    (tester) async {
      tester.view.physicalSize = const Size(320, 740);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(app(const AuthPage(), scale: 1.5));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Se connecter'));
      await tester.pumpAndSettle();
      expect(find.text('Saisissez une adresse e-mail valide.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Login visual check', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(app(const AuthPage(), capture: key));
    await tester.pumpAndSettle();
    await screenshot(tester, key, '00-connexion');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
