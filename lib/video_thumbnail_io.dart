import 'dart:io';

import 'package:flutter/material.dart';

Widget buildVideoThumbnail(String path) {
  return Image.file(
    File(path),
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => const _ThumbnailPlaceholder(),
  );
}

class _ThumbnailPlaceholder extends StatelessWidget {
  const _ThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) => const ColoredBox(
    color: Color(0xFF123D79),
    child: Center(
      child: Icon(Icons.landscape_rounded, color: Color(0xFF20D7FF), size: 38),
    ),
  );
}
