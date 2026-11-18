import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:cross_file/cross_file.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_full/session.dart';
import 'package:ffmpeg_kit_flutter_new_full/statistics.dart';
import 'package:path_provider/path_provider.dart';

import 'comic_panel_layout.dart';
import 'video_export_contract.dart';
import 'video_project.dart';
import 'video_timing.dart';

VideoExporter createVideoExportService() => _NativeVideoExportService();

class _NativeVideoExportService implements VideoExporter {
  int? _activeSessionId;
  bool _cancelRequested = false;

  @override
  Future<XFile> createMusicPreview(BuiltInMusicTrack track) async {
    if (track == BuiltInMusicTrack.none) {
      throw ArgumentError.value(track, 'track', 'Select a music category.');
    }
    _cancelRequested = false;
    final temporaryDirectory = await getTemporaryDirectory();
    final previewFile = File(
      '${temporaryDirectory.path}/cineclip_${track.name}_'
      '${DateTime.now().microsecondsSinceEpoch}.wav',
    );
    await _writeBuiltInMusic(previewFile, track, 16, (_) {});
    return XFile(previewFile.path, name: '${track.label} preview.wav');
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
  }) async {
    _cancelRequested = false;
    _activeSessionId = null;
    if (photos.isEmpty) throw ArgumentError('Choose at least one photo.');
    if (photos.length > 20) {
      throw ArgumentError('Choose no more than 20 photos per video.');
    }
    if (sceneDurations.isEmpty ||
        sceneDurations.any((duration) => duration < 2 || duration > 8)) {
      throw ArgumentError.value(
        sceneDurations,
        'sceneDurations',
        'Scene durations must be from 2 to 8 seconds.',
      );
    }
    if (!musicVolume.isFinite || musicVolume < 0 || musicVolume > 1) {
      throw ArgumentError.value(
        musicVolume,
        'musicVolume',
        'Must be from 0 to 1.',
      );
    }
    if (!musicStartSeconds.isFinite ||
        musicStartSeconds < 0 ||
        (musicEndSeconds != null &&
            (!musicEndSeconds.isFinite ||
                musicEndSeconds <= musicStartSeconds))) {
      throw ArgumentError(
        'Music selection must have a valid start and end time.',
      );
    }
    if (!transitionDuration.isFinite ||
        transitionDuration < 0.1 ||
        transitionDuration > 1.5) {
      throw ArgumentError.value(
        transitionDuration,
        'transitionDuration',
        'Must be from 0.1 to 1.5 seconds.',
      );
    }

    final id =
        '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(1 << 32)}';
    final temporaryRoot = await getTemporaryDirectory();
    final workDirectory = Directory('${temporaryRoot.path}/cineclip_$id');
    final appDirectory = await getApplicationDocumentsDirectory();
    final videosDirectory = Directory('${appDirectory.path}/CineClip/videos');
    final thumbnailsDirectory = Directory(
      '${appDirectory.path}/CineClip/thumbnails',
    );
    await workDirectory.create(recursive: true);
    await videosDirectory.create(recursive: true);
    await thumbnailsDirectory.create(recursive: true);

    final safeTitle = title
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    final fileName = '${safeTitle.isEmpty ? 'CineClip' : safeTitle}_$id';
    final outputFile = File('${videosDirectory.path}/$fileName.mp4');
    final thumbnailFile = File('${thumbnailsDirectory.path}/$fileName.jpg');
    final imageFiles = <File>[];
    File? captionFile;
    File? musicFile;
    final sceneCount = style == VideoStyle.comicPanel
        ? (photos.length / comicTemplate.panelCount).ceil()
        : photos.length;
    if (sceneDurations.length != sceneCount) {
      throw ArgumentError.value(
        sceneDurations.length,
        'sceneDurations.length',
        'There must be one duration per exported scene.',
      );
    }
    final outputDuration = videoDurationSeconds(
      sceneDurations: sceneDurations,
      transition: transition,
      transitionDuration: transitionDuration,
    );

    try {
      for (var index = 0; index < photos.length; index++) {
        _ensureNotCancelled();
        final file = File('${workDirectory.path}/photo_$index.jpg');
        await file.writeAsBytes(await photos[index].readAsBytes(), flush: true);
        imageFiles.add(file);
      }
      onProgress(0.02);
      if (captionOverlay != null) {
        captionFile = File('${workDirectory.path}/caption.png');
        await captionFile.writeAsBytes(captionOverlay, flush: true);
      }
      if (music != null) {
        musicFile = File(
          '${workDirectory.path}/music.${_audioExtension(music)}',
        );
        await musicFile.writeAsBytes(await music.readAsBytes(), flush: true);
        _ensureNotCancelled();
      } else if (builtInMusic != null &&
          builtInMusic != BuiltInMusicTrack.none) {
        musicFile = File('${workDirectory.path}/cineclip_music.wav');
        await _writeBuiltInMusic(
          musicFile,
          builtInMusic,
          outputDuration,
          onProgress,
        );
      }
      _ensureNotCancelled();
      onProgress(0.08);

      final command = _buildCommand(
        imageFiles: imageFiles,
        outputFile: outputFile,
        captionFile: captionFile,
        musicFile: musicFile,
        outputDuration: outputDuration,
        resolution: resolution,
        aspectRatio: aspectRatio,
        sceneDurations: sceneDurations,
        style: style,
        comicTemplate: comicTemplate,
        motion: motion,
        motionIntensity: motionIntensity,
        transition: transition,
        transitionDuration: transitionDuration,
        musicVolume: musicVolume,
        musicStartSeconds: musicStartSeconds,
        musicEndSeconds: musicEndSeconds,
        hardwareEncoder: Platform.isAndroid
            ? 'h264_mediacodec'
            : 'h264_videotoolbox',
      );
      try {
        await _execute(
          command,
          outputDuration,
          (progress) => onProgress(0.08 + progress * 0.5),
        );
      } catch (error) {
        if (error is VideoExportCancelledException) rethrow;
        if (await outputFile.exists()) await outputFile.delete();
        await _execute(
          _buildCommand(
            imageFiles: imageFiles,
            outputFile: outputFile,
            captionFile: captionFile,
            musicFile: musicFile,
            outputDuration: outputDuration,
            resolution: resolution,
            aspectRatio: aspectRatio,
            sceneDurations: sceneDurations,
            style: style,
            comicTemplate: comicTemplate,
            motion: motion,
            motionIntensity: motionIntensity,
            transition: transition,
            transitionDuration: transitionDuration,
            musicVolume: musicVolume,
            musicStartSeconds: musicStartSeconds,
            musicEndSeconds: musicEndSeconds,
            hardwareEncoder: 'mpeg4',
          ),
          outputDuration,
          (progress) => onProgress(0.58 + progress * 0.38),
        );
      }

      _ensureNotCancelled();
      if (!await outputFile.exists() || await outputFile.length() < 1024) {
        throw StateError(
          'Video encoding finished without a valid output file.',
        );
      }
      await imageFiles.first.copy(thumbnailFile.path);
      onProgress(1);
      return VideoProject(
        id: id,
        title: title.trim().isEmpty ? 'My Video' : title.trim(),
        videoPath: outputFile.path,
        thumbnailPath: thumbnailFile.path,
        createdAt: DateTime.now().toIso8601String(),
        durationSeconds: outputDuration.round(),
        caption: caption.trim(),
        resolutionLabel: resolution.label,
        aspectRatioLabel: aspectRatio.label,
      );
    } catch (_) {
      if (await outputFile.exists()) await outputFile.delete();
      if (await thumbnailFile.exists()) await thumbnailFile.delete();
      rethrow;
    } finally {
      if (await workDirectory.exists()) {
        await workDirectory.delete(recursive: true);
      }
    }
  }

  @override
  Future<void> cancelExport() async {
    _cancelRequested = true;
    final sessionId = _activeSessionId;
    if (sessionId != null) await FFmpegKit.cancel(sessionId);
  }

  String _buildCommand({
    required List<File> imageFiles,
    required File outputFile,
    required File? captionFile,
    required File? musicFile,
    required double outputDuration,
    required VideoResolution resolution,
    required VideoAspectRatio aspectRatio,
    required List<int> sceneDurations,
    required VideoStyle style,
    required ComicTemplate comicTemplate,
    required ImageMotion motion,
    required MotionIntensity motionIntensity,
    required VideoTransition transition,
    required double transitionDuration,
    required double musicVolume,
    required double musicStartSeconds,
    required double? musicEndSeconds,
    required String hardwareEncoder,
  }) {
    final arguments = StringBuffer('-y -hide_banner -loglevel error ');
    for (final image in imageFiles) {
      arguments.write('-i ${_quote(image.path)} ');
    }
    final captionIndex = captionFile == null ? null : imageFiles.length;
    if (captionFile != null) {
      arguments.write(
        '-loop 1 -framerate 30 -t $outputDuration -i ${_quote(captionFile.path)} ',
      );
    }
    final audioIndex = musicFile == null
        ? null
        : imageFiles.length + (captionFile == null ? 0 : 1);
    if (musicFile != null) {
      arguments.write('-i ${_quote(musicFile.path)} ');
    }

    final (width, height) = switch (aspectRatio) {
      VideoAspectRatio.landscape => (resolution.width, resolution.height),
      VideoAspectRatio.portrait => (resolution.height, resolution.width),
      VideoAspectRatio.square => (resolution.height, resolution.height),
    };
    final filters = <String>[];
    final scenes = <String>[];
    if (style == VideoStyle.fullFrame) {
      for (var index = 0; index < imageFiles.length; index++) {
        final sceneDuration = sceneDurations[index];
        final expressions = _motionExpressions(
          motion,
          sceneDuration * 30,
          motionIntensity,
        );
        final fadeFilter = motion == ImageMotion.fade
            ? 'fade=t=in:st=0:d=0.6,'
            : motion == ImageMotion.fadeOut
            ? 'fade=t=out:st=${sceneDuration - 0.6}:d=0.6,'
            : '';
        filters.add(
          '[$index:v]scale=$width:$height:force_original_aspect_ratio=increase,'
          'crop=$width:$height,'
          "zoompan=z='${expressions.zoom}':x='${expressions.x}':y='${expressions.y}':"
          'd=${sceneDuration * 30}:s=${width}x$height:fps=30,'
          '${fadeFilter}setsar=1,format=yuv420p[scene$index]',
        );
        scenes.add('[scene$index]');
      }
    } else {
      final border = max(4, width ~/ 180);
      final pageCount = (imageFiles.length / comicTemplate.panelCount).ceil();
      var photoIndex = 0;
      for (var pageIndex = 0; pageIndex < pageCount; pageIndex++) {
        final firstPhoto = photoIndex;
        final pagePhotos = min(
          comicTemplate.panelCount,
          imageFiles.length - photoIndex,
        );
        final slots = comicPanelLayout(comicTemplate)
            .take(pagePhotos)
            .map(
              (panel) => (
                x: (panel.left * width).round() ~/ 2 * 2,
                y: (panel.top * height).round() ~/ 2 * 2,
                width: (panel.width * width).round() ~/ 2 * 2,
                height: (panel.height * height).round() ~/ 2 * 2,
              ),
            )
            .toList();
        final pageBase = 'page$pageIndex';
        filters.add(
          'color=c=0xf4ead4:s=${width}x$height:r=30:'
          'd=${sceneDurations[pageIndex]},format=rgba[${pageBase}bg]',
        );
        var previousLayer = '[${pageBase}bg]';
        for (var slotIndex = 0; slotIndex < slots.length; slotIndex++) {
          final slot = slots[slotIndex];
          final inputIndex = photoIndex++;
          final sceneDuration = sceneDurations[pageIndex];
          final expressions = _motionExpressions(
            motion,
            sceneDuration * 30,
            motionIntensity,
          );
          final panelFade = motion == ImageMotion.fade
              ? 'fade=t=in:st=0:d=0.6,'
              : motion == ImageMotion.fadeOut
              ? 'fade=t=out:st=${sceneDuration - 0.6}:d=0.6,'
              : '';
          final panelLabel = '${pageBase}panel$slotIndex';
          final layerLabel = '${pageBase}layer$slotIndex';
          filters.add(
            '[$inputIndex:v]scale=${slot.width}:${slot.height}:'
            'force_original_aspect_ratio=increase,crop=${slot.width}:${slot.height},'
            "zoompan=z='${expressions.zoom}':x='${expressions.x}':y='${expressions.y}':"
            'd=${sceneDuration * 30}:s=${slot.width}x${slot.height}:fps=30,'
            '${panelFade}drawbox=x=0:y=0:w=iw:h=ih:color=0x28232a:t=$border,'
            'setsar=1,format=rgba[$panelLabel]',
          );
          filters.add(
            '$previousLayer[$panelLabel]overlay=${slot.x}:${slot.y}:shortest=1'
            '[$layerLabel]',
          );
          previousLayer = '[$layerLabel]';
        }
        final sceneLabel = 'scene$pageIndex';
        filters.add('$previousLayer,format=yuv420p[$sceneLabel]');
        scenes.add('[$sceneLabel]');
        if (photoIndex <= firstPhoto) {
          throw StateError('Comic page composition did not consume a photo.');
        }
      }
    }

    var previousVideoLabel = scenes.first;
    for (var index = 1; index < scenes.length; index++) {
      final nextLabel = index == scenes.length - 1 ? '[vbase]' : '[x$index]';
      if (transition == VideoTransition.cut) {
        filters.add(
          '$previousVideoLabel${scenes[index]}concat=n=2:v=1:a=0$nextLabel',
        );
      } else {
        final elapsedBeforeScene = sceneDurations
            .take(index)
            .fold<int>(0, (total, duration) => total + duration);
        final offset = elapsedBeforeScene - index * transitionDuration;
        filters.add(
          '$previousVideoLabel${scenes[index]}'
          'xfade=transition=${transition.ffmpegName}:duration=$transitionDuration:offset=$offset$nextLabel',
        );
      }
      previousVideoLabel = nextLabel;
    }
    if (scenes.length == 1) {
      filters.add('${scenes.first}null[vbase]');
    }
    if (captionIndex != null) {
      filters
        ..add('[$captionIndex:v]format=rgba[caption]')
        ..add('[vbase][caption]overlay=0:0:shortest=1[vout]');
    } else {
      filters.add('[vbase]null[vout]');
    }

    if (audioIndex != null) {
      final volume = musicVolume.toStringAsFixed(2);
      final musicDuration = musicEndSeconds == null
          ? outputDuration
          : musicEndSeconds - musicStartSeconds;
      const sampleRate = 22050;
      final loopSamples = (musicDuration * sampleRate).round();
      filters.add(
        '[$audioIndex:a:0]aresample=$sampleRate,'
        'atrim=start=$musicStartSeconds:duration=$musicDuration,'
        'asetpts=PTS-STARTPTS,aloop=loop=-1:size=$loopSamples,'
        'atrim=duration=$outputDuration,volume=$volume[aout]',
      );
    }
    arguments
      ..write('-filter_complex ${_quote(filters.join(';'))} ')
      ..write('-map ${_quote('[vout]')} ');
    if (audioIndex != null) {
      arguments
        ..write('-map ${_quote('[aout]')} ')
        ..write('-c:a aac -b:a 128k ');
    } else {
      arguments.write('-an ');
    }
    arguments
      ..write('-c:v $hardwareEncoder ')
      ..write('-b:v ${resolution == VideoResolution.p1080 ? 8 : 4}M ')
      ..write('-r 30 -pix_fmt yuv420p -t $outputDuration ')
      ..write('-movflags +faststart ${_quote(outputFile.path)}');
    return arguments.toString();
  }

  ({String zoom, String x, String y}) _motionExpressions(
    ImageMotion motion,
    int frameCount,
    MotionIntensity intensity,
  ) {
    final lastFrame = frameCount - 1;
    final maximumZoom = 1 + intensity.zoomAmount;
    final zoomStep = intensity.zoomAmount / frameCount;
    final zoomIn = 'min(zoom+$zoomStep,$maximumZoom)';
    const centerX = 'iw/2-(iw/zoom/2)';
    const centerY = 'ih/2-(ih/zoom/2)';
    return switch (motion) {
      ImageMotion.zoomIn => (zoom: zoomIn, x: centerX, y: centerY),
      ImageMotion.zoomOut => (
        zoom: 'if(eq(on,0),$maximumZoom,max(zoom-$zoomStep,1))',
        x: centerX,
        y: centerY,
      ),
      ImageMotion.panLeft => (
        zoom: '$maximumZoom',
        x: '(iw-iw/zoom)*(1-on/$lastFrame)',
        y: centerY,
      ),
      ImageMotion.panRight => (
        zoom: '$maximumZoom',
        x: '(iw-iw/zoom)*on/$lastFrame',
        y: centerY,
      ),
      ImageMotion.panUp => (
        zoom: '$maximumZoom',
        x: centerX,
        y: '(ih-ih/zoom)*(1-on/$lastFrame)',
      ),
      ImageMotion.panDown => (
        zoom: '$maximumZoom',
        x: centerX,
        y: '(ih-ih/zoom)*on/$lastFrame',
      ),
      ImageMotion.fade => (zoom: '1', x: centerX, y: centerY),
      ImageMotion.fadeOut => (zoom: '1', x: centerX, y: centerY),
    };
  }

  Future<void> _writeBuiltInMusic(
    File file,
    BuiltInMusicTrack track,
    double duration,
    void Function(double progress) onProgress,
  ) async {
    const sampleRate = 22050;
    final frameCount = (sampleRate * duration).round();
    final sink = file.openWrite();
    final header = ByteData(44)
      ..setUint8(0, 0x52)
      ..setUint8(1, 0x49)
      ..setUint8(2, 0x46)
      ..setUint8(3, 0x46)
      ..setUint32(4, frameCount * 4 + 36, Endian.little)
      ..setUint8(8, 0x57)
      ..setUint8(9, 0x41)
      ..setUint8(10, 0x56)
      ..setUint8(11, 0x45)
      ..setUint8(12, 0x66)
      ..setUint8(13, 0x6d)
      ..setUint8(14, 0x74)
      ..setUint8(15, 0x20)
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 2, Endian.little)
      ..setUint32(24, sampleRate, Endian.little)
      ..setUint32(28, sampleRate * 4, Endian.little)
      ..setUint16(32, 4, Endian.little)
      ..setUint16(34, 16, Endian.little)
      ..setUint8(36, 0x64)
      ..setUint8(37, 0x61)
      ..setUint8(38, 0x74)
      ..setUint8(39, 0x61)
      ..setUint32(40, frameCount * 4, Endian.little);
    sink.add(header.buffer.asUint8List());

    const minorScale = [0, 2, 3, 5, 7, 8, 10];
    const majorScale = [0, 2, 4, 5, 7, 9, 11];
    const minorProgression = [0, 5, 3, 6];
    const majorProgression = [0, 3, 4, 0];
    const chunkFrames = 4096;
    final isMinor = const {
      BuiltInMusicTrack.cinematic,
      BuiltInMusicTrack.emotional,
      BuiltInMusicTrack.adventure,
      BuiltInMusicTrack.dramatic,
    }.contains(track);
    final scale = isMinor ? minorScale : majorScale;
    final progression = isMinor ? minorProgression : majorProgression;
    final bpm = track.tempo.toDouble();
    final beatSeconds = 60 / bpm;
    final root = track.rootFrequency.toDouble();
    final melody = switch (track) {
      BuiltInMusicTrack.cinematic => [0, 2, 4, 2, 6, 4, 2, 1],
      BuiltInMusicTrack.happy => [0, 2, 4, 5, 4, 2, 1, 2],
      BuiltInMusicTrack.romantic => [0, 4, 2, 4, 5, 4, 2, 1],
      BuiltInMusicTrack.emotional => [0, 2, 3, 5, 4, 3, 2, 0],
      BuiltInMusicTrack.adventure => [0, 4, 3, 2, 5, 4, 2, 0],
      BuiltInMusicTrack.relaxing => [0, 2, 4, 2, 1, 2, 0, 2],
      BuiltInMusicTrack.comedy => [0, 4, 1, 5, 2, 6, 4, 2],
      BuiltInMusicTrack.dramatic => [0, 6, 5, 4, 3, 2, 1, 0],
      BuiltInMusicTrack.none => const <int>[],
    };
    final percussionEnabled = track != BuiltInMusicTrack.relaxing;
    final chordRoots = List.generate(
      progression.length,
      (bar) => root * pow(2, scale[progression[bar]] / 12),
    );
    final chordThirds = List.generate(
      progression.length,
      (bar) => root * pow(2, scale[(progression[bar] + 2) % 7] / 12),
    );
    final chordFifths = List.generate(
      progression.length,
      (bar) => root * pow(2, scale[(progression[bar] + 4) % 7] / 12),
    );
    final bassFrequencies = List.generate(
      progression.length,
      (bar) => root * 0.5 * pow(2, scale[progression[bar]] / 12),
    );
    final melodyFrequencies = List.generate(
      progression.length,
      (bar) => List.generate(
        melody.length,
        (step) =>
            root *
            2 *
            pow(2, scale[(melody[step] + progression[bar]) % 7] / 12),
      ),
    );
    try {
      for (var start = 0; start < frameCount; start += chunkFrames) {
        final count = min(chunkFrames, frameCount - start);
        final bytes = ByteData(count * 4);
        for (var offset = 0; offset < count; offset++) {
          final frame = start + offset;
          final time = frame / sampleRate;
          final beatNumber = (time / beatSeconds).floor();
          final beatPhase = time - beatNumber * beatSeconds;
          final bar = beatNumber ~/ 4;
          final chordIndex = bar % progression.length;
          final chordRoot = chordRoots[chordIndex];
          final third = chordThirds[chordIndex];
          final fifth = chordFifths[chordIndex];
          final padPulse = 0.94 + 0.06 * sin(2 * pi * time / 7.3);
          final pad =
              (sin(2 * pi * chordRoot * time) * 0.15 +
                  sin(2 * pi * third * time) * 0.105 +
                  sin(2 * pi * fifth * time) * 0.075 +
                  sin(2 * pi * chordRoot * 2 * time) * 0.035) *
              padPulse;

          final eighthNote = (time / (beatSeconds / 2)).floor();
          final notePhase = time % (beatSeconds / 2);
          final noteFrequency =
              melodyFrequencies[chordIndex][eighthNote % melody.length];
          final noteEnvelope = exp(
            -notePhase * (track == BuiltInMusicTrack.relaxing ? 3.2 : 5.5),
          );
          final pianoLikePluck =
              (sin(2 * pi * noteFrequency * time) * 0.62 +
                  sin(2 * pi * noteFrequency * 2.01 * time) * 0.24 +
                  sin(2 * pi * noteFrequency * 3.9 * time) * 0.08) *
              noteEnvelope *
              0.12;

          final bassFrequency = bassFrequencies[chordIndex];
          final bass = sin(2 * pi * bassFrequency * time) * 0.13;

          var kick = 0.0;
          var clap = 0.0;
          var hiHat = 0.0;
          if (percussionEnabled) {
            final kickBeat =
                track == BuiltInMusicTrack.happy ||
                    track == BuiltInMusicTrack.adventure ||
                    track == BuiltInMusicTrack.comedy
                ? true
                : beatNumber.isEven;
            if (kickBeat) {
              final kickFrequency = 54 + 90 * exp(-beatPhase * 22);
              kick =
                  sin(2 * pi * kickFrequency * beatPhase) *
                  exp(-beatPhase * 13) *
                  0.25;
            }
            if (beatNumber.isOdd && beatPhase < 0.18) {
              clap = _noiseSample(frame) * exp(-beatPhase * 24) * 0.075;
            }
            if (eighthNote.isOdd && notePhase < 0.055) {
              hiHat =
                  _noiseSample(frame + sampleRate) *
                  exp(-notePhase * 58) *
                  0.035;
            }
          }

          final sparkle =
              sin(2 * pi * noteFrequency * 2.5 * time) *
              sin(2 * pi * 0.35 * time) *
              0.022;
          final mix =
              pad + bass + pianoLikePluck + kick + clap + hiHat + sparkle;
          final fadeIn = (time / 1.4).clamp(0.0, 1.0);
          final fadeOut = ((duration - time) / 1.6).clamp(0.0, 1.0);
          final pan = bar.isEven ? -0.12 : 0.12;
          final left = ((mix - pianoLikePluck * pan) * fadeIn * fadeOut).clamp(
            -0.95,
            0.95,
          );
          final right = ((mix + pianoLikePluck * pan) * fadeIn * fadeOut).clamp(
            -0.95,
            0.95,
          );
          bytes
            ..setInt16(offset * 4, (left * 32767).round(), Endian.little)
            ..setInt16(offset * 4 + 2, (right * 32767).round(), Endian.little);
        }
        sink.add(bytes.buffer.asUint8List());
        onProgress(0.02 + (start + count) / frameCount * 0.06);
        await Future<void>.delayed(Duration.zero);
        _ensureNotCancelled();
      }
      await sink.flush();
    } finally {
      await sink.close();
    }
  }

  double _noiseSample(int sample) {
    var value = sample & 0x7fffffff;
    value = ((value ^ (value >> 13)) * 1274126177) & 0x7fffffff;
    value = ((value ^ (value >> 16)) * 2246822519) & 0x7fffffff;
    return value / 1073741824 - 1;
  }

  void _ensureNotCancelled() {
    if (_cancelRequested) throw const VideoExportCancelledException();
  }

  Future<void> _execute(
    String command,
    double totalSeconds,
    void Function(double) onProgress,
  ) async {
    final completion = Completer<void>();
    try {
      final session = await FFmpegKit.executeAsync(
        command,
        (Session session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            if (!completion.isCompleted) completion.complete();
          } else {
            if (_cancelRequested) {
              if (!completion.isCompleted) {
                completion.completeError(const VideoExportCancelledException());
              }
              return;
            }
            final logs = await session.getAllLogsAsString();
            if (!completion.isCompleted) {
              final logOutput = logs ?? 'No encoder logs were returned.';
              completion.completeError(
                StateError(
                  'Video encoding failed: ${_lastLines(logOutput, 8)}',
                ),
              );
            }
          }
        },
        null,
        (Statistics statistics) {
          final elapsedMilliseconds = statistics.getTime();
          final progress = elapsedMilliseconds / (totalSeconds * 1000);
          onProgress(progress.clamp(0.0, 0.98).toDouble());
        },
      );
      _activeSessionId = session.getSessionId();
      if (_cancelRequested) await FFmpegKit.cancel(_activeSessionId);
    } catch (error, stackTrace) {
      if (!completion.isCompleted) {
        completion.completeError(error, stackTrace);
      }
    }
    try {
      await completion.future;
    } finally {
      _activeSessionId = null;
    }
  }

  String _audioExtension(XFile file) {
    final extension = file.name.split('.').last.toLowerCase();
    return const {'mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'}.contains(extension)
        ? extension
        : 'audio';
  }

  String _quote(String value) => '"${value.replaceAll('"', r'\"')}"';

  String _lastLines(String value, int count) {
    final lines = value.trim().split('\n');
    return lines.skip(max(0, lines.length - count)).join('\n');
  }

  @override
  Future<void> deleteProjectFiles(VideoProject project) async {
    for (final path in [project.videoPath, project.thumbnailPath]) {
      final file = File(path);
      if (await file.exists()) await file.delete();
    }
  }
}
