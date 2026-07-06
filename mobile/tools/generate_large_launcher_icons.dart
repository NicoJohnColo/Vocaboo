import 'dart:io';
import 'package:image/image.dart';

void main(List<String> args) {
  final base = Directory.current.path;
  final logoPath = '$base/assets/images/vocabooLogo.png';
  final srcFile = File(logoPath);
  if (!srcFile.existsSync()) {
    stderr.writeln('Logo not found at: $logoPath');
    exit(2);
  }

  var src = decodeImage(srcFile.readAsBytesSync());
  if (src == null) {
    stderr.writeln('Failed to decode logo image.');
    exit(3);
  }

  // Ensure image has alpha channel
  src = src.convert(numChannels: 4);

  // Convert the source to a black-on-transparent image while preserving anti-aliased edges.
  // New color will be pure black; alpha will be inverse of luminance so dark pixels are opaque.
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final p = src.getPixel(x, y);
      final avg = ((p.r + p.g + p.b) / 3).round();
      final newA = (255 - avg).clamp(0, 255).toInt();
      // Render white foreground on transparent background so icon is visible on dark launchers
      src.setPixelRgba(x, y, 255, 255, 255, newA);
    }
  }

  // Target launcher sizes for Android mipmap folders (px)
  final sizes = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
  };

  // How much of the canvas the logo should occupy (0..1). Increase to make logo larger.
  final double fill = 0.92; // bigger than default

  for (final entry in sizes.entries) {
    final folder = '$base/android/app/src/main/res/${entry.key}';
    final size = entry.value;
    final outDir = Directory(folder);
    if (!outDir.existsSync()) {
      stderr.writeln('Warning: target directory does not exist: $folder');
      continue;
    }

    final canvas = Image(width: size, height: size);

    // Calculate new logo size preserving aspect ratio
    final targetLogoWidth = (size * fill).round();
    final targetLogoHeight = (src.height * targetLogoWidth / src.width).round();
    final resized = copyResize(src, width: targetLogoWidth, height: targetLogoHeight, interpolation: Interpolation.average);

    final x = ((size - resized.width) / 2).round();
    final y = ((size - resized.height) / 2).round();

    // Composite the logo (respecting alpha)
    compositeImage(canvas, resized, dstX: x, dstY: y);

    final outPath = '$folder/ic_launcher.png';
    final outPathFg = '$folder/ic_launcher_foreground.png';
    final pngBytes = encodePng(canvas);
    File(outPath).writeAsBytesSync(pngBytes);
    // also write a foreground PNG (for adaptive icons)
    File(outPathFg).writeAsBytesSync(pngBytes);
    stdout.writeln('Wrote $outPath and $outPathFg (${size}x$size)');
  }
  stdout.writeln('Done generating launcher icons.');
}
