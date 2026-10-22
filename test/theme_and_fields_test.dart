import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:yolo_business_mobile/core/constants/colors.dart';
import 'package:yolo_business_mobile/core/theme.dart';
import 'package:yolo_business_mobile/data/demo_repository.dart';
import 'package:yolo_business_mobile/ui/auth_page.dart';
import 'package:yolo_business_mobile/ui/components.dart';
import 'package:yolo_business_mobile/ui/workspace_page.dart';

void main() {
  group('AppColors Constants', () {
    test('brand and theme colors are properly defined', () {
      expect(AppColors.brandBlue, const Color(0xFF034BFF));
      expect(AppColors.primary, AppColors.brandBlue);
      expect(AppColors.ink, const Color(0xFF121317));
      expect(AppColors.darkBackground, const Color(0xFF121317));
      expect(AppColors.darkSurface, const Color(0xFF1C1E24));
      expect(AppColors.darkSurfaceHighest, const Color(0xFF262932));
      expect(AppColors.darkBorder, const Color(0xFF323642));
      expect(AppColors.darkTextPrimary, const Color(0xFFF6F6F6));
      expect(AppColors.darkMuted, const Color(0xFFA0A3AA));
      expect(AppColors.error, const Color(0xFFB3261E));
      expect(AppColors.darkError, const Color(0xFFFFB4AB));
    });
  });

  group('YoloTheme Dark Theme', () {
    test('dark theme configuration properties', () {
      final dark = YoloTheme.dark;
      expect(dark.brightness, Brightness.dark);
      expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(dark.cardColor, AppColors.darkSurface);
      expect(dark.colorScheme.brightness, Brightness.dark);
      expect(dark.colorScheme.surface, AppColors.darkSurface);
      expect(dark.colorScheme.onSurface, AppColors.darkTextPrimary);
      expect(dark.colorScheme.onSurfaceVariant, AppColors.darkMuted);
      expect(dark.inputDecorationTheme.filled, true);
      expect(dark.inputDecorationTheme.fillColor, AppColors.darkSurfaceHighest);
      expect(dark.inputDecorationTheme.hintStyle?.color, AppColors.darkMuted);
      expect(dark.inputDecorationTheme.helperStyle?.color, AppColors.darkMuted);
    });

    test('light theme maintains backward compatibility and has onSurfaceVariant', () {
      final light = YoloTheme.light;
      expect(light.brightness, Brightness.light);
      expect(light.scaffoldBackgroundColor, Colors.white);
      expect(light.colorScheme.onSurfaceVariant, AppColors.muted);
      expect(YoloTheme.ink, AppColors.ink);
      expect(YoloTheme.muted, AppColors.muted);
      expect(YoloTheme.surface, AppColors.lightSurface);
      expect(YoloTheme.border, AppColors.lightBorder);
    });

    testWidgets('YoloTheme.mutedColor adapts dynamically to theme', (tester) async {
      Color? lightMuted;
      Color? darkMuted;

      await tester.pumpWidget(
        MaterialApp(
          theme: YoloTheme.light,
          home: Builder(
            builder: (context) {
              lightMuted = YoloTheme.mutedColor(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(lightMuted, AppColors.muted);

      await tester.pumpWidget(
        MaterialApp(
          theme: YoloTheme.dark,
          home: Builder(
            builder: (context) {
              darkMuted = YoloTheme.mutedColor(context);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(darkMuted, AppColors.darkMuted);
    });
  });

  group('Brand Widget', () {
    testWidgets('displays black logo in light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: YoloTheme.light,
          home: const Scaffold(body: Brand()),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      final asset = image.image as AssetImage;
      expect(asset.assetName, 'assets/brand/yolo-business-brand-black.png');
    });

    testWidgets('displays white logo in dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: YoloTheme.dark,
          home: const Scaffold(body: Brand()),
        ),
      );
      await tester.pumpAndSettle();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.image, isA<AssetImage>());
      final asset = image.image as AssetImage;
      expect(asset.assetName, 'assets/brand/yolo-business-brand-white.png');
    });
  });

  group('LabeledField Widget', () {
    testWidgets('displays label above child without embedded labelText', (tester) async {
      const fieldKey = Key('input_field');
      await tester.pumpWidget(
        MaterialApp(
          theme: YoloTheme.light,
          home: Scaffold(
            body: LabeledField(
              label: 'Mon Label Au Dessus',
              child: TextFormField(
                key: fieldKey,
                decoration: const InputDecoration(hintText: 'mon_hint'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Label text exists outside input decoration
      expect(find.text('Mon Label Au Dessus'), findsOneWidget);
      expect(find.byKey(fieldKey), findsOneWidget);

      // Verify the label is above the text input vertically
      final labelPos = tester.getTopLeft(find.text('Mon Label Au Dessus'));
      final inputPos = tester.getTopLeft(find.byKey(fieldKey));
      expect(labelPos.dy, lessThan(inputPos.dy));
    });

    testWidgets('renders trailing widget when specified', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LabeledField(
              label: 'Email',
              trailing: Text('Requis'),
              child: TextField(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Requis'), findsOneWidget);
    });

    testWidgets('wraps long label without overflowing on narrow screens', (tester) async {
      tester.view.physicalSize = const Size(200, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LabeledField(
              label: 'Un très long intitulé de champ qui nécessite plusieurs lignes sans déborder',
              trailing: Icon(Icons.info, size: 16),
              child: TextField(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('Android Launcher Icons & Resources', () {
    test('values/colors.xml has ic_launcher_background set to #034bff', () {
      final file = File('android/app/src/main/res/values/colors.xml');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      expect(content, contains('<color name="ic_launcher_background">#034bff</color>'));
    });

    test('mipmap-anydpi-v26 adaptive icon xml files exist and reference correct drawables', () {
      final xmlFile = File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml');
      final roundXmlFile = File('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml');
      expect(xmlFile.existsSync(), isTrue);
      expect(roundXmlFile.existsSync(), isTrue);

      final xml = xmlFile.readAsStringSync();
      expect(xml, contains('@color/ic_launcher_background'));
      expect(xml, contains('@drawable/ic_launcher_foreground'));

      final roundXml = roundXmlFile.readAsStringSync();
      expect(roundXml, contains('@color/ic_launcher_background'));
      expect(roundXml, contains('@drawable/ic_launcher_foreground'));
    });

    test('legacy ic_launcher.png has #034bff background and ic_launcher_round.png has circular transparent corners', () {
      final legacy = File('android/app/src/main/res/mipmap-hdpi/ic_launcher.png');
      final round = File('android/app/src/main/res/mipmap-hdpi/ic_launcher_round.png');
      expect(legacy.existsSync(), isTrue);
      expect(round.existsSync(), isTrue);

      final legacyImg = img.decodeImage(legacy.readAsBytesSync())!;
      final roundImg = img.decodeImage(round.readAsBytesSync())!;

      // Corner of square legacy icon should be blue (#034bff)
      final legacyCorner = legacyImg.getPixel(0, 0);
      expect(legacyCorner.a, 255);
      expect(legacyCorner.r, 3);
      expect(legacyCorner.g, 75);
      expect(legacyCorner.b, 255);

      // Corner of round icon must be transparent due to circular crop
      final roundCorner = roundImg.getPixel(0, 0);
      expect(roundCorner.a, 0);
    });
  });

  group('Full UI Dark Theme Rendering', () {
    testWidgets('AuthPage renders cleanly without error in dark theme', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: YoloTheme.light,
          darkTheme: YoloTheme.dark,
          themeMode: ThemeMode.dark,
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const AuthPage(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(AuthPage), findsOneWidget);
    });

    testWidgets('WorkspacePage renders cleanly without error in dark theme', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          theme: YoloTheme.light,
          darkTheme: YoloTheme.dark,
          themeMode: ThemeMode.dark,
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: WorkspacePage(
            repository: DemoRepository(),
            email: 'responsable@exemple.com',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Vos colis.\nToujours en mouvement.'), findsOneWidget);
    });
  });
}
