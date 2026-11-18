import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';

import 'video_project.dart';

const videoTransitionDuration = Duration(milliseconds: 450);
const videoTransitionSeconds = 0.45;

enum VideoResolution {
  p480(854, 480, '480p'),
  p720(1280, 720, '720p'),
  p1080(1920, 1080, '1080p');

  const VideoResolution(this.width, this.height, this.label);

  final int width;
  final int height;
  final String label;
}

enum VideoAspectRatio {
  landscape(16, 9, '16:9 Landscape'),
  portrait(9, 16, '9:16 Portrait'),
  square(1, 1, '1:1 Square');

  const VideoAspectRatio(this.width, this.height, this.label);

  final int width;
  final int height;
  final String label;
}

enum ComicTemplate {
  fourPanel('Four-Panel Layout', 4),
  sixPanel('Six-Panel Layout', 6),
  heroPanel('Hero Panel Layout', 3),
  dynamic('Dynamic Comic Layout', 4),
  vertical('Vertical Comic Layout', 4);

  const ComicTemplate(this.label, this.panelCount);

  final String label;
  final int panelCount;
}

enum VideoTransition {
  cut('Cut', 'fade'),
  fade('Fade', 'fade'),
  dissolve('Dissolve', 'dissolve'),
  slideLeft('Slide Left', 'slideleft'),
  slideRight('Slide Right', 'slideright'),
  slideUp('Slide Up', 'slideup'),
  wipe('Wipe', 'wipeleft'),
  pageTurn('Page Turn', 'hlslice');

  const VideoTransition(this.label, this.ffmpegName);

  final String label;
  final String ffmpegName;
}

enum ImageMotion {
  zoomIn('Slow Zoom In'),
  zoomOut('Slow Zoom Out'),
  panLeft('Pan Left'),
  panRight('Pan Right'),
  panUp('Pan Up'),
  panDown('Pan Down'),
  fade('Fade In'),
  fadeOut('Fade Out');

  const ImageMotion(this.label);

  final String label;
}

enum MotionIntensity {
  low('Low', 0.06),
  medium('Medium', 0.14),
  high('High', 0.24);

  const MotionIntensity(this.label, this.zoomAmount);

  final String label;
  final double zoomAmount;
}

enum CaptionPlacement {
  top('Top'),
  center('Center'),
  bottom('Bottom');

  const CaptionPlacement(this.label);

  final String label;
}

enum CaptionFontStyle {
  sansSerif('Sans Serif', null),
  serif('Serif', 'serif'),
  monospace('Monospace', 'monospace');

  const CaptionFontStyle(this.label, this.family);

  final String label;
  final String? family;
}

enum CaptionColor {
  white('White', 0xFFFFFFFF),
  yellow('Yellow', 0xFFFFE082),
  cyan('Cyan', 0xFF80DEEA),
  black('Black', 0xFF111827);

  const CaptionColor(this.label, this.value);

  final String label;
  final int value;
}

enum VideoStyle {
  fullFrame('Full Frame'),
  comicPanel('Comic Page');

  const VideoStyle(this.label);

  final String label;
}

enum BuiltInMusicTrack {
  none('No music', 0, 0),
  cinematic('Cinematic', 110, 76),
  happy('Happy', 132, 112),
  romantic('Romantic', 98, 82),
  emotional('Emotional', 116, 74),
  adventure('Adventure', 124, 118),
  relaxing('Relaxing', 92, 66),
  comedy('Comedy', 138, 116),
  dramatic('Dramatic', 108, 96);

  const BuiltInMusicTrack(this.label, this.rootFrequency, this.tempo);

  final String label;
  final int rootFrequency;
  final int tempo;
}

class VideoExportCancelledException implements Exception {
  const VideoExportCancelledException();

  @override
  String toString() => 'Video export was cancelled.';
}

abstract interface class VideoExporter {
  Future<XFile> createMusicPreview(BuiltInMusicTrack track);

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
  });

  Future<void> cancelExport();

  Future<void> deleteProjectFiles(VideoProject project);
}
