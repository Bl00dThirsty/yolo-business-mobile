// ignore_for_file: avoid_print
import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final iconFile = File('assets/brand/x-yolo-business-white-android-icon.png');
  final original = img.decodeImage(iconFile.readAsBytesSync())!;

  // Background color #034bff
  final bgColor = img.ColorRgba8(0x03, 0x4B, 0xFF, 0xFF);

  // Mipmap sizes for legacy ic_launcher
  final mipmaps = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  // Sizes for adaptive foreground
  final adaptiveSizes = {
    'drawable-mdpi': 108,
    'drawable-hdpi': 162,
    'drawable-xhdpi': 216,
    'drawable-xxhdpi': 324,
    'drawable-xxxhdpi': 432,
  };

  // 1. Generate legacy icons with #034bff background
  for (final entry in mipmaps.entries) {
    final folder = Directory('android/app/src/main/res/${entry.key}');
    if (!folder.existsSync()) folder.createSync(recursive: true);

    final size = entry.value;
    final square = img.Image(width: size, height: size, numChannels: 4);
    img.fill(square, color: bgColor);

    // Fit original into 70% of size
    final maxDim = (size * 0.70).round();
    final scale = maxDim / (original.width > original.height ? original.width : original.height);
    final targetW = (original.width * scale).round();
    final targetH = (original.height * scale).round();

    final resized = img.copyResize(original, width: targetW, height: targetH, interpolation: img.Interpolation.linear);
    final dstX = (size - targetW) ~/ 2;
    final dstY = (size - targetH) ~/ 2;

    img.compositeImage(square, resized, dstX: dstX, dstY: dstY);

    File('${folder.path}/ic_launcher.png').writeAsBytesSync(img.encodePng(square));

    // Circular crop for round legacy launcher icon
    final roundIcon = img.Image(width: size, height: size, numChannels: 4);
    final radius = size / 2.0;
    final r2 = radius * radius;
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final dx = x + 0.5 - radius;
        final dy = y + 0.5 - radius;
        if (dx * dx + dy * dy <= r2) {
          roundIcon.setPixel(x, y, square.getPixel(x, y));
        }
      }
    }
    File('${folder.path}/ic_launcher_round.png').writeAsBytesSync(img.encodePng(roundIcon));
    print('Generated legacy icons: ${folder.path}/ic_launcher.png & ic_launcher_round.png (${size}x$size)');
  }

  // 2. Generate adaptive foreground icons (transparent canvas, centered white logo in safe area)
  for (final entry in adaptiveSizes.entries) {
    final folder = Directory('android/app/src/main/res/${entry.key}');
    if (!folder.existsSync()) folder.createSync(recursive: true);

    final size = entry.value;
    final canvas = img.Image(width: size, height: size, numChannels: 4);

    // Inner safe area is ~60% of adaptive icon size
    final maxDim = (size * 0.60).round();
    final scale = maxDim / (original.width > original.height ? original.width : original.height);
    final targetW = (original.width * scale).round();
    final targetH = (original.height * scale).round();

    final resized = img.copyResize(original, width: targetW, height: targetH, interpolation: img.Interpolation.linear);
    final dstX = (size - targetW) ~/ 2;
    final dstY = (size - targetH) ~/ 2;

    img.compositeImage(canvas, resized, dstX: dstX, dstY: dstY);

    File('${folder.path}/ic_launcher_foreground.png').writeAsBytesSync(img.encodePng(canvas));
    print('Generated adaptive foreground: ${folder.path}/ic_launcher_foreground.png (${size}x$size)');
  }

  // 3. Ensure values/colors.xml has #034bff
  final colorsFile = File('android/app/src/main/res/values/colors.xml');
  colorsFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#034bff</color>
</resources>
''');

  // 4. Ensure mipmap-anydpi-v26 xmls exist
  final v26Folder = Directory('android/app/src/main/res/mipmap-anydpi-v26');
  if (!v26Folder.existsSync()) v26Folder.createSync(recursive: true);

  File('${v26Folder.path}/ic_launcher.xml').writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
''');

  File('${v26Folder.path}/ic_launcher_round.xml').writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/ic_launcher_foreground"/>
</adaptive-icon>
''');

  print('Adaptive XMLs and colors updated successfully.');
}
