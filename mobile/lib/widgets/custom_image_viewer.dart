import 'package:flutter/material.dart';

class CustomImageViewer extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;

  const CustomImageViewer({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit,
    this.errorBuilder,
  });

  @override
  Widget build(BuildContext context) {
    String path = imagePath.trim();
    if (path.startsWith('http://localhost:')) {
      path = path.replaceFirst('localhost', '10.0.2.2');
    }

    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    } else if (path.startsWith('/')) {
      return Image.network(
        'http://10.0.2.2:8080$path',
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    } else {
      return Image.asset(
        path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: errorBuilder,
      );
    }
  }
}
