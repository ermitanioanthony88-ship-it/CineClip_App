import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

import 'video_export_contract.dart';
import 'video_project.dart';

VideoExporter createVideoExportService() => _WebVideoExportService();

class _WebVideoExportService implements VideoExporter {
  @override
  Future<XFile> createMusicPreview(BuiltInMusicTrack track) {
    throw UnsupportedError(
      'Built-in music previews are currently supported on Android and iOS only.',
    );
  }

  @override
  Future<VideoProject> exportVideo({
    required List<XFile> photos,
    required String title,
    required String caption,
    required Uint8List? captionOverlay,
    required List<int> sceneDurations,
    required VideoResolution resolution,
    required VideoAspectRatio aspectRatio,
    required VideoStyle style,
    required ComicTemplate comicTemplate,
    required ImageMotion motion,
    required MotionIntensity motionIntensity,
    required VideoTransition transition,
    required double transitionDuration,
    required double musicVolume,
    double musicStartSeconds = 0,
    double? musicEndSeconds,
    BuiltInMusicTrack? builtInMusic,
    XFile? music,
    required void Function(double progress) onProgress,
  }) {
    throw UnsupportedError(
      'Video creation is currently supported on Android and iOS only.',
    );
  }

  @override
  Future<void> cancelExport() async {}

  @override
  Future<void> deleteProjectFiles(VideoProject project) {
    throw UnsupportedError(
      'Video file storage is currently supported on Android and iOS only.',
    );
  }
}
