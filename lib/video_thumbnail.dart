import 'package:flutter/widgets.dart';

import 'video_thumbnail_stub.dart'
    if (dart.library.io) 'video_thumbnail_io.dart' as implementation;

class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({super.key, required this.path});

  final String path;

  @override
  Widget build(BuildContext context) => implementation.buildVideoThumbnail(path);
}
