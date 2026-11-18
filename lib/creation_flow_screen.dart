import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'image_motion_preview.dart';
import 'video_export_service.dart';
import 'video_project.dart';
import 'video_thumbnail.dart';
import 'video_timing.dart';

class CineClipCreationFlowScreen extends StatefulWidget {
  const CineClipCreationFlowScreen({super.key, required this.onProjectSaved});

  final Future<void> Function(VideoProject project) onProjectSaved;

  @override
  State<CineClipCreationFlowScreen> createState() =>
      _CineClipCreationFlowScreenState();
}

class _CineClipCreationFlowScreenState extends State<CineClipCreationFlowScreen>
    with SingleTickerProviderStateMixin {
  static const _maximumPhotos = 20;

  final _picker = ImagePicker();
  final _exportService = createVideoExportService();
  final _titleController = TextEditingController(text: 'My Video');
  final _captionController = TextEditingController();
  final _speechBubbleController = TextEditingController();
  final _captionFocusNode = FocusNode();
  final _speechBubbleFocusNode = FocusNode();
  final List<XFile> _photos = [];
  final List<int> _photoDurations = [];
  XFile? _music;
  VideoPlayerController? _musicPreviewController;
  bool _isMusicPreviewing = false;
  bool _preparingMusic = false;
  bool _seekingMusicLoop = false;
  double _musicDurationSeconds = 0;
  double _musicStartSeconds = 0;
  double _musicEndSeconds = 0;
  double _musicVolume = 0.8;
  double _previewProgress = 0;
  VideoResolution _resolution = VideoResolution.p720;
  VideoAspectRatio _aspectRatio = VideoAspectRatio.landscape;
  VideoStyle _style = VideoStyle.fullFrame;
  ComicTemplate _comicTemplate = ComicTemplate.fourPanel;
  ImageMotion _motion = ImageMotion.zoomIn;
  MotionIntensity _motionIntensity = MotionIntensity.medium;
  CaptionPlacement _captionPlacement = CaptionPlacement.bottom;
  Offset _captionPosition = const Offset(0.5, 0.875);
  Offset _speechBubblePosition = const Offset(0.78, 0.2);
  CaptionFontStyle _captionFontStyle = CaptionFontStyle.sansSerif;
  CaptionColor _captionColor = CaptionColor.white;
  CaptionColor _speechBubbleColor = CaptionColor.black;
  TextAlign _captionAlignment = TextAlign.center;
  double _captionScale = 1;
  double _speechBubbleScale = 1;
  bool _captionEditing = false;
  bool _speechBubbleEditing = false;
  bool _captionSelected = false;
  bool _speechBubbleSelected = false;
  bool _captionBold = true;
  bool _captionOutline = true;
  bool _speechBubbleOutline = true;
  VideoTransition _transition = VideoTransition.fade;
  double _transitionDuration = videoTransitionSeconds;
  bool _transitionCustomized = false;
  BuiltInMusicTrack _builtInMusic = BuiltInMusicTrack.cinematic;
  VideoProject? _project;
  int _secondsPerPhoto = 3;
  int _currentStep = 0;
  bool _pickingPhotos = false;
  bool _exporting = false;
  bool _savingToGallery = false;
  bool _allowPop = false;
  bool _confirmingDiscard = false;
  bool _cancelled = false;
  late final AnimationController _exportPulseController;
  double _progress = 0;
  String? _errorMessage;

  int get _sceneCount => _style == VideoStyle.comicPanel
      ? (_photos.length / _comicTemplate.panelCount).ceil()
      : _photos.length;

  List<int> get _sceneDurations => _style == VideoStyle.comicPanel
      ? List<int>.filled(_sceneCount, _secondsPerPhoto)
      : List<int>.unmodifiable(_photoDurations);

  int get _estimatedDurationSeconds {
    return videoDurationSeconds(
      sceneDurations: _sceneDurations,
      transition: _transition,
      transitionDuration: _transitionDuration,
    ).round();
  }

  String get _estimatedDuration {
    final seconds = _estimatedDurationSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _exportPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
  }

  @override
  void dispose() {
    _musicPreviewController?.dispose();
    _exportPulseController.dispose();
    _titleController.dispose();
    _captionController.dispose();
    _speechBubbleController.dispose();
    _captionFocusNode.dispose();
    _speechBubbleFocusNode.dispose();
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    if (_pickingPhotos || _exporting) return;
    setState(() {
      _pickingPhotos = true;
      _errorMessage = null;
    });
    try {
      final remaining = _maximumPhotos - _photos.length;
      if (remaining <= 0) {
        setState(() => _errorMessage = 'You can add up to 20 photos.');
        return;
      }
      final pickedPhotos = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
        requestFullMetadata: false,
        limit: remaining,
      );
      if (!mounted || pickedPhotos.isEmpty) return;
      setState(() {
        final additions = pickedPhotos.take(remaining).toList();
        _photos.addAll(additions);
        _photoDurations.addAll(
          List<int>.filled(additions.length, _secondsPerPhoto),
        );
      });
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not open your photos: $error');
      }
    } finally {
      if (mounted) setState(() => _pickingPhotos = false);
    }
  }

  Future<void> _pickMusic() async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.audio);
      if (!mounted || result.isEmpty) return;
      final music = result.first;
      final path = music.path;
      if (path == null) {
        setState(() => _errorMessage = 'This audio file could not be opened.');
        return;
      }
      await _stopMusicPreview();
      final selectedMusic = XFile(path, name: music.name);
      setState(() {
        _music = selectedMusic;
        _builtInMusic = BuiltInMusicTrack.none;
        _preparingMusic = true;
        _musicDurationSeconds = 0;
        _musicStartSeconds = 0;
        _musicEndSeconds = 0;
        _errorMessage = null;
      });
      await _prepareCustomMusicPreview(selectedMusic);
    } catch (error) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Could not select the music file: $error',
        );
      }
    }
  }

  Future<void> _prepareCustomMusicPreview(XFile music) async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(Uri.file(music.path));
      _musicPreviewController = controller;
      await controller.initialize();
      if (!mounted || controller != _musicPreviewController) return;
      final duration = controller.value.duration.inMilliseconds / 1000;
      if (!duration.isFinite || duration <= 0) {
        throw StateError('The selected music has no playable duration.');
      }
      await controller.setVolume(_musicVolume);
      controller.addListener(_onMusicPreviewPositionChanged);
      setState(() {
        _musicDurationSeconds = duration;
        _musicStartSeconds = 0;
        _musicEndSeconds = duration;
        _preparingMusic = false;
      });
    } catch (error) {
      if (controller != null && controller == _musicPreviewController) {
        _musicPreviewController = null;
        await controller.dispose();
      }
      if (mounted) {
        setState(() {
          _preparingMusic = false;
          _errorMessage = 'Could not load the selected music: $error';
        });
      }
    }
  }

  Future<void> _toggleMusicPreview() async {
    if (_isMusicPreviewing) {
      await _pauseMusicPreview();
    } else {
      await _startMusicPreview();
    }
  }

  Future<void> _startMusicPreview() async {
    if (_preparingMusic ||
        (_music != null && _musicDurationSeconds <= 0) ||
        (_music == null && _builtInMusic == BuiltInMusicTrack.none)) {
      return;
    }
    try {
      var controller = _musicPreviewController;
      if (controller == null) {
        final preview = await _exportService.createMusicPreview(_builtInMusic);
        controller = VideoPlayerController.networkUrl(Uri.file(preview.path));
        _musicPreviewController = controller;
        await controller.initialize();
        controller.addListener(_onMusicPreviewPositionChanged);
        if (mounted) {
          setState(() {
            _musicDurationSeconds =
                controller!.value.duration.inMilliseconds / 1000;
            _musicStartSeconds = 0;
            _musicEndSeconds = _musicDurationSeconds;
          });
        }
      }
      await controller.setVolume(_musicVolume);
      await controller.setLooping(_music == null);
      if (_music != null) {
        final position = controller.value.position.inMilliseconds / 1000;
        if (position < _musicStartSeconds || position >= _musicEndSeconds) {
          await controller.seekTo(
            Duration(milliseconds: (_musicStartSeconds * 1000).round()),
          );
        }
      }
      await controller.play();
      if (mounted) setState(() => _isMusicPreviewing = true);
    } catch (error) {
      await _pauseMusicPreview();
      if (mounted) {
        setState(() => _errorMessage = 'Could not preview music: $error');
      }
    }
  }

  Future<void> _pauseMusicPreview() async {
    final controller = _musicPreviewController;
    if (controller != null && controller.value.isPlaying) {
      await controller.pause();
    }
    if (mounted) setState(() => _isMusicPreviewing = false);
  }

  void _onMusicPreviewPositionChanged() {
    final controller = _musicPreviewController;
    if (_music == null ||
        !_isMusicPreviewing ||
        _seekingMusicLoop ||
        controller == null ||
        controller.value.position.inMilliseconds / 1000 < _musicEndSeconds) {
      return;
    }
    unawaited(_restartMusicPreviewSegment(controller));
  }

  Future<void> _restartMusicPreviewSegment(
    VideoPlayerController controller,
  ) async {
    _seekingMusicLoop = true;
    try {
      await controller.seekTo(
        Duration(milliseconds: (_musicStartSeconds * 1000).round()),
      );
      if (mounted && _isMusicPreviewing) await controller.play();
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not loop music preview: $error');
      }
    } finally {
      _seekingMusicLoop = false;
    }
  }

  void _setMusicTrim(RangeValues range) {
    if (range.end - range.start < 0.25) return;
    setState(() {
      _musicStartSeconds = range.start;
      _musicEndSeconds = range.end;
    });
    final controller = _musicPreviewController;
    if (controller != null && _isMusicPreviewing) {
      final position = controller.value.position.inMilliseconds / 1000;
      if (position < range.start || position >= range.end) {
        unawaited(
          controller
              .seekTo(Duration(milliseconds: (range.start * 1000).round()))
              .catchError((Object error) {
                if (mounted) {
                  setState(
                    () => _errorMessage = 'Could not seek in music: $error',
                  );
                }
              }),
        );
      }
    }
  }

  Future<void> _stopMusicPreview() async {
    final controller = _musicPreviewController;
    _musicPreviewController = null;
    _isMusicPreviewing = false;
    if (controller != null) {
      controller.removeListener(_onMusicPreviewPositionChanged);
      await controller.dispose();
    }
    if (mounted) setState(() {});
  }

  Future<void> _setMusicVolume(double volume) async {
    setState(() => _musicVolume = volume);
    try {
      await _musicPreviewController?.setVolume(volume);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not adjust music volume: $error');
      }
    }
  }

  Future<void> _selectBuiltInMusic(BuiltInMusicTrack track) async {
    await _stopMusicPreview();
    if (!mounted) return;
    setState(() {
      _builtInMusic = track;
      _music = null;
      _musicDurationSeconds = 0;
      _musicStartSeconds = 0;
      _musicEndSeconds = 0;
      _preparingMusic = false;
      _errorMessage = null;
    });
  }

  Future<void> _removeCustomMusic() async {
    await _stopMusicPreview();
    if (!mounted) return;
    setState(() {
      _music = null;
      _builtInMusic = BuiltInMusicTrack.cinematic;
      _musicDurationSeconds = 0;
      _musicStartSeconds = 0;
      _musicEndSeconds = 0;
      _preparingMusic = false;
      _errorMessage = null;
    });
  }

  void _movePhoto(int index, int offset) {
    final target = index + offset;
    if (target < 0 || target >= _photos.length) return;
    setState(() {
      final photo = _photos.removeAt(index);
      _photos.insert(target, photo);
    });
  }

  void _reorderPhoto(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    if (oldIndex == newIndex) return;
    setState(() {
      final photo = _photos.removeAt(oldIndex);
      _photos.insert(newIndex, photo);
      final duration = _photoDurations.removeAt(oldIndex);
      _photoDurations.insert(newIndex, duration);
    });
  }

  void _setPhotoDuration(int index, int duration) {
    if (index < 0 || index >= _photoDurations.length) return;
    setState(() => _photoDurations[index] = duration);
  }

  Future<void> _clearPhotos() async {
    if (_photos.isEmpty) return;
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear this project?'),
        content: const Text(
          'This removes the selected photos from this video only. Your original photos will stay on your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear photos'),
          ),
        ],
      ),
    );
    if (clear != true || !mounted) return;
    setState(() {
      _photos.clear();
      _photoDurations.clear();
      _currentStep = 0;
      _errorMessage = null;
    });
  }

  void _continueToEditor() {
    if (_photos.isEmpty) {
      setState(() => _errorMessage = 'Choose at least one photo to continue.');
      return;
    }
    setState(() {
      _currentStep = 1;
      _errorMessage = null;
    });
  }

  Future<void> _handleBack() async {
    if (_exporting) {
      await _confirmCancelExport();
      return;
    }
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 1;
        _errorMessage = null;
      });
      return;
    }
    if (_currentStep == 1) {
      setState(() {
        _currentStep = 0;
        _errorMessage = null;
      });
      return;
    }
    if (_currentStep == 4 && _project != null) {
      _finishSuccess(openVideo: false, goToLibrary: true);
      return;
    }
    if (_photos.isEmpty) {
      Navigator.pop(context);
      return;
    }
    if (_confirmingDiscard) return;
    _confirmingDiscard = true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard this video?'),
        content: const Text('Your selected photos and edits will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    _confirmingDiscard = false;
    if (discard != true || !mounted) return;
    setState(() => _allowPop = true);
    await WidgetsBinding.instance.endOfFrame;
    if (mounted) Navigator.pop(context);
  }

  void _openPreview() {
    if (_photos.isEmpty) {
      setState(() => _errorMessage = 'Choose at least one photo to continue.');
      return;
    }
    _captionEditing = false;
    _speechBubbleEditing = false;
    _captionSelected = false;
    _speechBubbleSelected = false;
    _captionFocusNode.unfocus();
    _speechBubbleFocusNode.unfocus();
    setState(() {
      _currentStep = 2;
      _errorMessage = null;
    });
  }

  void _onPreviewPlaybackChanged(bool playing) {
    if ((_music == null && _builtInMusic == BuiltInMusicTrack.none) ||
        (_music != null && _musicDurationSeconds <= 0)) {
      return;
    }
    if (playing) {
      unawaited(_startMusicPreview());
    } else {
      unawaited(_pauseMusicPreview());
    }
  }

  Future<void> _showExpandedPreview() async {
    _onPreviewPlaybackChanged(true);
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog.fullscreen(
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Video Preview'),
            leading: IconButton(
              tooltip: 'Close fullscreen preview',
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close_rounded),
            ),
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final ratio = _aspectRatio.width / _aspectRatio.height;
              final previewHeight = math.max(1.0, constraints.maxHeight - 56);
              final width = math.min(
                1000.0,
                math.min(constraints.maxWidth, previewHeight * ratio),
              );
              final height = width / ratio + 56;
              return Center(
                child: SizedBox(
                  width: width,
                  height: height,
                  child: _buildMotionPreview(
                    showPlaybackControls: true,
                    initialProgress: _previewProgress,
                    showExpandButton: false,
                    interactiveCaption: _currentStep == 1,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _confirmCancelExport() async {
    if (_confirmingDiscard || !_exporting) return;
    _confirmingDiscard = true;
    final cancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this export?'),
        content: const Text(
          'The video being exported will be discarded. You can return to the preview and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep exporting'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel export'),
          ),
        ],
      ),
    );
    _confirmingDiscard = false;
    if (cancel != true || !mounted || !_exporting) return;
    setState(() => _cancelled = true);
    try {
      await _exportService.cancelExport();
    } catch (error) {
      if (mounted) {
        setState(() {
          _cancelled = false;
          _errorMessage = 'Could not cancel the export: $error';
        });
      }
    }
  }

  void _finishSuccess({
    required bool openVideo,
    bool goToLibrary = false,
    bool createAnother = false,
  }) {
    final project = _project;
    if (project == null) {
      throw StateError('The successful export is not available.');
    }
    Navigator.pop(
      context,
      VideoExportResult(
        project: project,
        openVideo: openVideo,
        goToLibrary: goToLibrary,
        createAnother: createAnother,
      ),
    );
  }

  Future<void> _shareExportedVideo() async {
    final project = _project;
    if (project == null) {
      throw StateError('The successful export is not available.');
    }
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: project.title,
          files: [
            XFile(
              project.videoPath,
              mimeType: 'video/mp4',
              name: '${project.title}.mp4',
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not share video: $error');
      }
    }
  }

  Future<void> _downloadExportedVideo() async {
    final project = _project;
    if (project == null || _savingToGallery) return;
    setState(() {
      _savingToGallery = true;
      _errorMessage = null;
    });
    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putVideo(project.videoPath, album: 'CineClip');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video saved to your Photos gallery.')),
        );
      }
    } on GalException catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.type.message);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not save video: $error');
      }
    } finally {
      if (mounted) setState(() => _savingToGallery = false);
    }
  }

  void _startCaptionEditing({bool create = false}) {
    if (create && _captionController.text.isEmpty) {
      _captionController.text = 'Your text';
    }
    setState(() {
      _speechBubbleEditing = false;
      _speechBubbleSelected = false;
      _captionSelected = true;
      _captionEditing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_captionEditing) return;
      _captionFocusNode.requestFocus();
      if (create) {
        _captionController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _captionController.text.length,
        );
      }
    });
  }

  void _startSpeechBubbleEditing({bool create = false}) {
    if (create && _speechBubbleController.text.isEmpty) {
      _speechBubbleController.text = 'Your text';
    }
    setState(() {
      _captionEditing = false;
      _captionSelected = false;
      _speechBubbleSelected = true;
      _speechBubbleEditing = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_speechBubbleEditing) return;
      _speechBubbleFocusNode.requestFocus();
      if (create) {
        _speechBubbleController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _speechBubbleController.text.length,
        );
      }
    });
  }

  void _finishCaptionEditing(String _) {
    setState(() => _captionEditing = false);
    _captionFocusNode.unfocus();
  }

  void _finishSpeechBubbleEditing(String _) {
    setState(() => _speechBubbleEditing = false);
    _speechBubbleFocusNode.unfocus();
  }

  void _deselectPreviewOverlays() {
    if (!_captionSelected && !_speechBubbleSelected) return;
    setState(() {
      _captionEditing = false;
      _speechBubbleEditing = false;
      _captionSelected = false;
      _speechBubbleSelected = false;
    });
    _captionFocusNode.unfocus();
    _speechBubbleFocusNode.unfocus();
  }

  Widget _buildOverlayActions() {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        OutlinedButton.icon(
          onPressed: _exporting
              ? null
              : () => _startCaptionEditing(create: true),
          icon: const Icon(Icons.title_rounded),
          label: Text(
            _captionController.text.isEmpty ? 'Add Text' : 'Edit Text',
          ),
        ),
        if (_style == VideoStyle.comicPanel)
          OutlinedButton.icon(
            onPressed: _exporting
                ? null
                : () => _startSpeechBubbleEditing(create: true),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: Text(
              _speechBubbleController.text.isEmpty
                  ? 'Add Speech Bubble'
                  : 'Edit Bubble',
            ),
          ),
        if (_captionController.text.isNotEmpty)
          IconButton(
            tooltip: 'Remove text overlay',
            onPressed: _exporting
                ? null
                : () {
                    _captionController.clear();
                    setState(() {
                      _captionEditing = false;
                      _captionSelected = false;
                    });
                    _captionFocusNode.unfocus();
                  },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        if (_style == VideoStyle.comicPanel &&
            _speechBubbleController.text.isNotEmpty)
          IconButton(
            tooltip: 'Remove speech bubble',
            onPressed: _exporting
                ? null
                : () {
                    _speechBubbleController.clear();
                    setState(() {
                      _speechBubbleEditing = false;
                      _speechBubbleSelected = false;
                    });
                    _speechBubbleFocusNode.unfocus();
                  },
            icon: const Icon(Icons.delete_outline_rounded),
          ),
      ],
    );
  }

  Future<Uint8List?> _renderCaptionOverlay() async {
    final caption = _captionController.text.trim();
    final speechBubble = _speechBubbleController.text.trim();
    if (caption.isEmpty && speechBubble.isEmpty) return null;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final (width, height) = switch (_aspectRatio) {
      VideoAspectRatio.landscape => (_resolution.width, _resolution.height),
      VideoAspectRatio.portrait => (_resolution.height, _resolution.width),
      VideoAspectRatio.square => (_resolution.height, _resolution.height),
    };
    if (caption.isNotEmpty) {
      final captionHeight = height * 0.17;
      final captionWidth = width * 0.5;
      final panel = Rect.fromLTWH(
        (_captionPosition.dx * width - captionWidth / 2)
            .clamp(0.02 * width, width - captionWidth - 0.02 * width)
            .toDouble(),
        (_captionPosition.dy * height - captionHeight / 2)
            .clamp(0.02 * height, height - captionHeight - 0.02 * height)
            .toDouble(),
        captionWidth,
        captionHeight,
      );

      final textColor = Color(_captionColor.value);
      final textPainter = TextPainter(
        text: TextSpan(
          text: caption,
          style: TextStyle(
            color: textColor,
            fontFamily: _captionFontStyle.family,
            fontSize: math.max(24.0, width * 0.045) * _captionScale,
            fontWeight: _captionBold ? FontWeight.w700 : FontWeight.w400,
            height: 1.15,
            shadows: _captionOutline
                ? const [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 3,
                      offset: Offset(1, 1),
                    ),
                  ]
                : null,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: _captionAlignment,
        maxLines: 2,
        ellipsis: '…',
      )..layout(maxWidth: panel.width - width * 0.08);
      textPainter.paint(
        canvas,
        Offset(switch (_captionAlignment) {
          TextAlign.left || TextAlign.start => panel.left + width * 0.04,
          TextAlign.right ||
          TextAlign.end => panel.right - textPainter.width - width * 0.04,
          _ => panel.left + (panel.width - textPainter.width) / 2,
        }, panel.top + (panel.height - textPainter.height) / 2),
      );
    }

    if (speechBubble.isNotEmpty && _style == VideoStyle.comicPanel) {
      final bubbleWidth = width * 0.38 * _speechBubbleScale;
      final bubbleHeight = height * 0.2 * _speechBubbleScale;
      final bubble = Rect.fromLTWH(
        (_speechBubblePosition.dx * width - bubbleWidth / 2)
            .clamp(0.02 * width, width - bubbleWidth - 0.02 * width)
            .toDouble(),
        (_speechBubblePosition.dy * height - bubbleHeight / 2)
            .clamp(0.02 * height, height - bubbleHeight - 0.08 * height)
            .toDouble(),
        bubbleWidth,
        bubbleHeight,
      );
      final bubbleOutlinePaint = Paint()
        ..color = const Color(0xFF28232A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(2, width * 0.004);
      canvas.drawRRect(
        RRect.fromRectAndRadius(bubble, Radius.circular(width * 0.035)),
        Paint()..color = Colors.white,
      );
      if (_speechBubbleOutline) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bubble, Radius.circular(width * 0.035)),
          bubbleOutlinePaint,
        );
      }
      final tail = Path()
        ..moveTo(bubble.left + bubble.width * 0.24, bubble.bottom - 1)
        ..lineTo(
          bubble.left + bubble.width * 0.2,
          bubble.bottom + height * 0.045,
        )
        ..lineTo(bubble.left + bubble.width * 0.48, bubble.bottom - 1)
        ..close();
      canvas.drawPath(tail, Paint()..color = Colors.white);
      if (_speechBubbleOutline) canvas.drawPath(tail, bubbleOutlinePaint);
      final bubbleText = TextPainter(
        text: TextSpan(
          text: speechBubble,
          style: TextStyle(
            color: Color(_speechBubbleColor.value),
            fontFamily: _captionFontStyle.family,
            fontSize: math.max(20.0, width * 0.032) * _speechBubbleScale,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: 3,
        ellipsis: '…',
      )..layout(maxWidth: bubble.width - width * 0.045);
      bubbleText.paint(
        canvas,
        Offset(
          bubble.left + (bubble.width - bubbleText.width) / 2,
          bubble.top + (bubble.height - bubbleText.height) / 2,
        ),
      );
    }

    final image = await recorder.endRecording().toImage(width, height);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return bytes?.buffer.asUint8List();
  }

  Future<void> _exportVideo() async {
    if (_preparingMusic ||
        (_music != null &&
            (_musicDurationSeconds <= 0 ||
                _musicEndSeconds <= _musicStartSeconds))) {
      setState(
        () => _errorMessage = _preparingMusic
            ? 'Wait for the selected music to finish loading before exporting.'
            : 'Choose a playable music file before exporting.',
      );
      return;
    }
    if (kIsWeb) {
      setState(
        () => _errorMessage = 'Video creation is currently available in the Android and iOS apps.',
      );
      return;
    }
    if (_photos.isEmpty) {
      setState(() => _errorMessage = 'Choose at least one photo to continue.');
      return;
    }
    setState(() {
      _currentStep = 3;
      _exporting = true;
      _cancelled = false;
      _progress = 0;
      _errorMessage = null;
    });
    _exportPulseController.repeat(reverse: true);

    try {
      final captionOverlay = await _renderCaptionOverlay();
      if (_cancelled) throw const VideoExportCancelledException();
      final project = await _exportService.exportVideo(
        photos: List.unmodifiable(_photos),
        title: _titleController.text,
        caption: _captionController.text,
        captionOverlay: captionOverlay,
        sceneDurations: _sceneDurations,
        resolution: _resolution,
        aspectRatio: _aspectRatio,
        style: _style,
        comicTemplate: _comicTemplate,
        motion: _motion,
        motionIntensity: _motionIntensity,
        transition: _transition,
        transitionDuration: _transitionDuration,
        musicVolume: _musicVolume,
        musicStartSeconds: _musicStartSeconds,
        musicEndSeconds: _music == null ? null : _musicEndSeconds,
        builtInMusic: _music == null ? _builtInMusic : null,
        music: _music,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _progress = math.max(_progress, progress));
          }
        },
      );
      try {
        await widget.onProjectSaved(project);
      } catch (error) {
        try {
          await _exportService.deleteProjectFiles(project);
        } catch (cleanupError) {
          throw StateError(
            'Could not save video to your library: $error. '
            'Could not clean up the exported files: $cleanupError',
          );
        }
        throw StateError('Could not save video to your library: $error');
      }
      _exportPulseController.stop();
      if (mounted) {
        setState(() {
          _project = project;
          _exporting = false;
          _currentStep = 4;
          _progress = 1;
        });
      }
    } catch (error) {
      _exportPulseController.stop();
      if (mounted) {
        setState(() {
          _exporting = false;
          _currentStep = 2;
          if (error is VideoExportCancelledException || _cancelled) {
            _errorMessage = 'Export cancelled. Your original photos are safe.';
          } else {
            _errorMessage = 'Could not export the video. $error';
          }
          _cancelled = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Select Images',
      'Video Editor',
      'Preview & Export',
      'Exporting',
      'Export Complete',
    ];
    return PopScope(
      canPop:
          _allowPop || (!_exporting && _currentStep == 0 && _photos.isEmpty),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titles[_currentStep]),
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _exporting ? _confirmCancelExport : _handleBack,
            icon: Icon(_exporting ? Icons.close_rounded : Icons.arrow_back),
          ),
        ),
        body: SafeArea(child: _buildCurrentScreen()),
      ),
    );
  }

  Widget _buildCurrentScreen() {
    if (_currentStep == 3) return _buildExportScreen();
    if (_currentStep == 4) return _buildSuccessScreen();

    final children = _currentStep == 0
        ? _buildSelectionStep(Theme.of(context).colorScheme.onSurfaceVariant)
        : _currentStep == 1
        ? _buildEditorStep(Theme.of(context).colorScheme.onSurfaceVariant)
        : _buildPreviewStep();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: children,
          ),
        ),
        SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: _buildStepActions(),
        ),
      ],
    );
  }

  Widget _buildStepActions() {
    if (_currentStep == 0) {
      return SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _pickingPhotos ? null : _continueToEditor,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Next'),
        ),
      );
    }

    if (_currentStep == 1) {
      return Row(
        children: [
          OutlinedButton(onPressed: _handleBack, child: const Text('Back')),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _preparingMusic ? null : _openPreview,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Preview & Export'),
            ),
          ),
        ],
      );
    }

    if (_currentStep == 2) return _buildExportSettingsActions();

    return Row(
      children: [
        OutlinedButton(onPressed: _handleBack, child: const Text('Edit Again')),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _openPreview,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Preview & Export'),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildOutputSettingsControls() => [
    const SizedBox(height: 24),
    Text('Output settings', style: Theme.of(context).textTheme.titleLarge),
    const SizedBox(height: 8),
    Text(
      'Choose a supported size and framing for your finished video.',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    ),
    const SizedBox(height: 20),
    DropdownButtonFormField<VideoResolution>(
      initialValue: _resolution,
      decoration: const InputDecoration(
        labelText: 'Video quality',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final resolution in VideoResolution.values)
          DropdownMenuItem(value: resolution, child: Text(resolution.label)),
      ],
      onChanged: (resolution) {
        if (resolution != null) setState(() => _resolution = resolution);
      },
    ),
    const SizedBox(height: 12),
    DropdownButtonFormField<VideoAspectRatio>(
      initialValue: _aspectRatio,
      decoration: const InputDecoration(
        labelText: 'Aspect ratio',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final ratio in VideoAspectRatio.values)
          DropdownMenuItem(value: ratio, child: Text(ratio.label)),
      ],
      onChanged: (ratio) {
        if (ratio != null) setState(() => _aspectRatio = ratio);
      },
    ),
    const SizedBox(height: 8),
    Text(
      'Higher resolutions create larger files and may take longer to export.',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 12,
      ),
    ),
  ];

  Widget _buildExportSettingsActions() {
    return Row(
      children: [
        OutlinedButton(onPressed: _handleBack, child: const Text('Edit Again')),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _exporting ? null : _exportVideo,
            icon: Icon(
              _errorMessage?.startsWith('Could not export') == true
                  ? Icons.refresh_rounded
                  : Icons.download_rounded,
            ),
            label: Text(
              _errorMessage?.startsWith('Could not export') == true
                  ? 'Retry Export'
                  : 'Export Video',
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildPreviewStep() => [
    _buildStepIndicator(),
    const SizedBox(height: 24),
    const Text(
      'Preview your story',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    Text(
      'Review the motion, photo order, and soundtrack before exporting.',
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    ),
    const SizedBox(height: 20),
    _buildMotionPreview(showPlaybackControls: true, showExpandButton: true),
    const SizedBox(height: 20),
    _PreviewDetail(
      icon: Icons.movie_creation_outlined,
      label: 'Video',
      value: _titleController.text.trim().isEmpty
          ? 'My Video'
          : _titleController.text.trim(),
    ),
    _PreviewDetail(
      icon: Icons.animation_rounded,
      label: 'Style · motion',
      value: '${_style.label} · ${_motion.label}',
    ),
    _PreviewDetail(
      icon: Icons.photo_library_outlined,
      label: 'Photos',
      value: '${_photos.length} · estimated $_estimatedDuration',
    ),
    _PreviewDetail(
      icon: Icons.music_note_rounded,
      label: 'Music',
      value: _music?.name ?? _builtInMusic.label,
    ),
    _PreviewDetail(
      icon: Icons.high_quality_outlined,
      label: 'Quality',
      value: _resolution.label,
    ),
    _PreviewDetail(
      icon: Icons.aspect_ratio_rounded,
      label: 'Aspect ratio',
      value: _aspectRatio.label,
    ),
    Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => setState(() => _currentStep = 1),
        icon: const Icon(Icons.tune_rounded),
        label: const Text('Edit Output Settings'),
      ),
    ),
    if (_errorMessage != null) ...[
      const SizedBox(height: 12),
      _buildErrorMessage(),
    ],
  ];

  Widget _buildExportScreen() {
    final progress = _progress.clamp(0.0, 1.0);
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 168,
            height: 168,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 156,
                  height: 156,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 9,
                    strokeCap: StrokeCap.round,
                    backgroundColor: accent.withValues(alpha: 0.12),
                  ),
                ),
                AnimatedBuilder(
                  animation: _exportPulseController,
                  builder: (context, child) => Transform.scale(
                    scale: 0.94 + _exportPulseController.value * 0.08,
                    child: child,
                  ),
                  child: Icon(
                    Icons.movie_creation_rounded,
                    size: 64,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Creating your video',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Please wait... Your photos are being brought to life.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '${(progress * 100).round()}%',
            style: TextStyle(
              color: accent,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: _confirmCancelExport,
            icon: const Icon(Icons.close_rounded),
            label: const Text('Cancel Export'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessScreen() {
    final project = _project;
    if (project == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final accent = Theme.of(context).colorScheme.primary;
    return ListView(
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 8),
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.35, end: 1),
            duration: const Duration(milliseconds: 550),
            curve: Curves.elasticOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: CircleAvatar(
              radius: 42,
              backgroundColor: accent.withValues(alpha: 0.12),
              child: Icon(Icons.check_circle_rounded, size: 60, color: accent),
            ),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Your Video Is Ready!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Your photos have been turned into a memorable video.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: _aspectRatio.width / _aspectRatio.height,
            child: VideoThumbnail(path: project.thumbnailPath),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          project.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 4),
        Text(
          '${project.duration} · ${project.resolutionLabel} · '
          '${project.aspectRatioLabel} · Saved in CineClip',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _buildErrorMessage(),
        ],
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: () => _finishSuccess(openVideo: true),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Open Video'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _savingToGallery ? null : _downloadExportedVideo,
          icon: _savingToGallery
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded),
          label: Text(_savingToGallery ? 'Saving…' : 'Download Video'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _shareExportedVideo,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share Video'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _finishSuccess(openVideo: false, goToLibrary: true),
          icon: const Icon(Icons.video_library_outlined),
          label: const Text('Go to Library'),
        ),
        TextButton.icon(
          onPressed: () =>
              _finishSuccess(openVideo: false, createAnother: true),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Create Another'),
        ),
      ],
    );
  }

  Future<void> _showPhotoPreview(XFile photo) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: FutureBuilder<Uint8List>(
          future: photo.readAsBytes(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const SizedBox(
                height: 240,
                child: Center(child: Icon(Icons.broken_image_outlined)),
              );
            }
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return InteractiveViewer(
              child: Image.memory(snapshot.data!, fit: BoxFit.contain),
            );
          },
        ),
      ),
    );
  }

  List<Widget> _buildSelectionStep(Color secondary) => [
    _buildStepIndicator(),
    const SizedBox(height: 24),
    const Text(
      'Choose your photos',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    Text(
      'Select up to $_maximumPhotos photos for your video. You can change their order next.',
      style: TextStyle(color: secondary, height: 1.4),
    ),
    const SizedBox(height: 20),
    OutlinedButton.icon(
      onPressed: _pickingPhotos || _exporting ? null : _pickPhotos,
      icon: _pickingPhotos
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.add_photo_alternate_outlined),
      label: Text(_photos.isEmpty ? 'Choose Photos' : 'Add More Photos'),
    ),
    if (_photos.isEmpty) ...[
      const SizedBox(height: 28),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: secondary.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 44,
              color: secondary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            const Text(
              'Your story starts with a photo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose at least one image to continue.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondary),
            ),
          ],
        ),
      ),
    ] else ...[
      const SizedBox(height: 16),
      Text(
        '${_photos.length} of $_maximumPhotos photos selected',
        style: TextStyle(color: secondary, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var index = 0; index < _photos.length; index++)
            _SelectedPhotoTile(
              key: ValueKey(_photos[index].path),
              photo: _photos[index],
              onPreview: () => _showPhotoPreview(_photos[index]),
              onMove: (offset) => _movePhoto(index, offset),
              canMoveEarlier: index > 0,
              canMoveLater: index < _photos.length - 1,
              onRemove: () => setState(() {
                _photos.removeAt(index);
                _photoDurations.removeAt(index);
              }),
            ),
        ],
      ),
    ],
    if (_errorMessage != null) ...[
      const SizedBox(height: 12),
      _buildErrorMessage(),
    ],
  ];

  List<Widget> _buildCaptionControls() => [
    const SizedBox(height: 8),
    Text('Text styling', style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 8),
    DropdownButtonFormField<CaptionFontStyle>(
      initialValue: _captionFontStyle,
      decoration: const InputDecoration(
        labelText: 'Font style',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final font in CaptionFontStyle.values)
          DropdownMenuItem(value: font, child: Text(font.label)),
      ],
      onChanged: _exporting
          ? null
          : (font) {
              if (font != null) setState(() => _captionFontStyle = font);
            },
    ),
    const SizedBox(height: 8),
    DropdownButtonFormField<CaptionColor>(
      initialValue: _captionColor,
      decoration: const InputDecoration(
        labelText: 'Text color',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final color in CaptionColor.values)
          DropdownMenuItem(value: color, child: Text(color.label)),
      ],
      onChanged: _exporting
          ? null
          : (color) {
              if (color != null) setState(() => _captionColor = color);
            },
    ),
    const SizedBox(height: 8),
    DropdownButtonFormField<CaptionPlacement>(
      initialValue: _captionPlacement,
      decoration: const InputDecoration(
        labelText: 'Text position',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final placement in CaptionPlacement.values)
          DropdownMenuItem(value: placement, child: Text(placement.label)),
      ],
      onChanged: _exporting
          ? null
          : (placement) {
              if (placement != null) {
                setState(() {
                  _captionPlacement = placement;
                  _captionPosition = Offset(0.5, switch (placement) {
                    CaptionPlacement.top => 0.13,
                    CaptionPlacement.center => 0.5,
                    CaptionPlacement.bottom => 0.875,
                  });
                });
              }
            },
    ),
    const SizedBox(height: 8),
    DropdownButtonFormField<TextAlign>(
      initialValue: _captionAlignment,
      decoration: const InputDecoration(
        labelText: 'Text alignment',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: TextAlign.left, child: Text('Left')),
        DropdownMenuItem(value: TextAlign.center, child: Text('Center')),
        DropdownMenuItem(value: TextAlign.right, child: Text('Right')),
      ],
      onChanged: _exporting
          ? null
          : (alignment) {
              if (alignment != null) {
                setState(() => _captionAlignment = alignment);
              }
            },
    ),
    Text(
      'Text size · ${(_captionScale * 100).round()}%',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    Slider(
      value: _captionScale,
      min: 0.7,
      max: 2.4,
      divisions: 17,
      label: '${(_captionScale * 100).round()}%',
      onChanged: _exporting
          ? null
          : (scale) => setState(() => _captionScale = scale),
    ),
    Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('Bold'),
          selected: _captionBold,
          onSelected: _exporting
              ? null
              : (selected) => setState(() => _captionBold = selected),
        ),
        FilterChip(
          label: const Text('Outline'),
          selected: _captionOutline,
          onSelected: _exporting
              ? null
              : (selected) => setState(() => _captionOutline = selected),
        ),
      ],
    ),
    if (_style == VideoStyle.comicPanel) ...[
      const SizedBox(height: 8),
      Text(
        'Speech bubble size · ${(_speechBubbleScale * 100).round()}%',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      Slider(
        value: _speechBubbleScale,
        min: 0.6,
        max: 1.6,
        divisions: 10,
        label: '${(_speechBubbleScale * 100).round()}%',
        onChanged: _exporting
            ? null
            : (scale) => setState(() => _speechBubbleScale = scale),
      ),
      DropdownButtonFormField<CaptionColor>(
        initialValue: _speechBubbleColor,
        decoration: const InputDecoration(
          labelText: 'Bubble text color',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final color in CaptionColor.values)
            DropdownMenuItem(value: color, child: Text(color.label)),
        ],
        onChanged: _exporting
            ? null
            : (color) {
                if (color != null) {
                  setState(() => _speechBubbleColor = color);
                }
              },
      ),
      FilterChip(
        label: const Text('Bubble outline'),
        selected: _speechBubbleOutline,
        onSelected: _exporting
            ? null
            : (selected) => setState(() => _speechBubbleOutline = selected),
      ),
    ],
  ];

  List<Widget> _buildVideoStyleControls() => [
    Text('Video style', style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 8),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final style in VideoStyle.values)
          ChoiceChip(
            label: Text(style.label),
            avatar: Icon(
              style == VideoStyle.comicPanel
                  ? Icons.auto_awesome_mosaic_rounded
                  : Icons.crop_16_9_rounded,
              size: 18,
            ),
            selected: _style == style,
            onSelected: _exporting
                ? null
                : (selected) {
                    if (selected) {
                      setState(() {
                        _style = style;
                        if (!_transitionCustomized) {
                          _transition = style == VideoStyle.comicPanel
                              ? VideoTransition.pageTurn
                              : VideoTransition.fade;
                        }
                      });
                    }
                  },
          ),
      ],
    ),
    if (_style == VideoStyle.comicPanel) ...[
      const SizedBox(height: 8),
      DropdownButtonFormField<ComicTemplate>(
        initialValue: _comicTemplate,
        decoration: const InputDecoration(
          labelText: 'Comic page layout',
          border: OutlineInputBorder(),
        ),
        items: [
          for (final template in ComicTemplate.values)
            DropdownMenuItem(value: template, child: Text(template.label)),
        ],
        onChanged: _exporting
            ? null
            : (template) {
                if (template != null) {
                  setState(() => _comicTemplate = template);
                }
              },
      ),
    ],
  ];

  List<Widget> _buildEditorStep(Color secondary) => [
    _buildStepIndicator(),
    const SizedBox(height: 24),
    const Text(
      'Make your video',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
    ),
    const SizedBox(height: 8),
    Text(
      'Arrange your photos and customize the details before previewing.',
      style: TextStyle(color: secondary, height: 1.4),
    ),
    const SizedBox(height: 18),
    _buildEditorPreview(),
    const SizedBox(height: 8),
    _buildOverlayActions(),
    const SizedBox(height: 20),
    Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        OutlinedButton.icon(
          onPressed: _pickingPhotos ? null : _pickPhotos,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add Photos'),
        ),
        TextButton.icon(
          onPressed: _photos.isEmpty ? null : _clearPhotos,
          icon: const Icon(Icons.delete_sweep_outlined),
          label: const Text('Clear All'),
        ),
      ],
    ),
    Text(
      'Photo timeline · drag to reorder or use the arrows',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    Text(
      '$_secondsPerPhoto seconds per photo · estimated total $_estimatedDuration',
      style: TextStyle(color: secondary, fontSize: 12),
    ),
    const SizedBox(height: 8),
    ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: _photos.length,
      onReorder: _reorderPhoto,
      itemBuilder: (context, index) => _PhotoRow(
        key: ValueKey(_photos[index].path),
        photo: _photos[index],
        index: index,
        dragIndex: index,
        count: _photos.length,
        enabled: !_exporting,
        durationSeconds: _photoDurations[index],
        onDurationChanged: (duration) => _setPhotoDuration(index, duration),
        onMove: (offset) => _movePhoto(index, offset),
        onRemove: () {
          setState(() {
            _photos.removeAt(index);
            _photoDurations.removeAt(index);
            if (_photos.isEmpty) _currentStep = 0;
          });
        },
      ),
    ),
    const SizedBox(height: 20),
    ..._buildVideoStyleControls(),
    const SizedBox(height: 12),
    TextField(
      controller: _titleController,
      enabled: !_exporting,
      maxLength: 40,
      textCapitalization: TextCapitalization.sentences,
      decoration: const InputDecoration(
        labelText: 'Video title',
        border: OutlineInputBorder(),
      ),
    ),
    const SizedBox(height: 8),
    ..._buildCaptionControls(),
    const SizedBox(height: 8),
    Text(
      _style == VideoStyle.comicPanel
          ? 'Comic page duration · $_secondsPerPhoto seconds per page'
          : 'Photo durations · estimated total $_estimatedDuration',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    if (_style == VideoStyle.comicPanel) ...[
      Slider(
        value: _secondsPerPhoto.toDouble(),
        min: 2,
        max: 8,
        divisions: 6,
        label: '$_secondsPerPhoto s',
        onChanged: _exporting
            ? null
            : (value) => setState(() => _secondsPerPhoto = value.round()),
      ),
    ] else ...[
      Text(
        'Set all photo durations · $_secondsPerPhoto seconds',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      Slider(
        value: _secondsPerPhoto.toDouble(),
        min: 2,
        max: 8,
        divisions: 6,
        label: '$_secondsPerPhoto s',
        onChanged: _exporting
            ? null
            : (value) {
                final duration = value.round();
                setState(() {
                  _secondsPerPhoto = duration;
                  for (var index = 0; index < _photoDurations.length; index++) {
                    _photoDurations[index] = duration;
                  }
                });
              },
      ),
    ],
    Text('Photo motion', style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 4),
    Text(
      'Choose how every image moves in your video.',
      style: TextStyle(color: secondary, fontSize: 12),
    ),
    DropdownButtonFormField<ImageMotion>(
      initialValue: _motion,
      decoration: const InputDecoration(
        labelText: 'Photo motion effect',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final motion in ImageMotion.values)
          DropdownMenuItem(value: motion, child: Text(motion.label)),
      ],
      onChanged: _exporting
          ? null
          : (motion) {
              if (motion != null) setState(() => _motion = motion);
            },
    ),
    const SizedBox(height: 8),
    DropdownButtonFormField<MotionIntensity>(
      initialValue: _motionIntensity,
      decoration: const InputDecoration(
        labelText: 'Animation intensity',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final intensity in MotionIntensity.values)
          DropdownMenuItem(value: intensity, child: Text(intensity.label)),
      ],
      onChanged: _exporting
          ? null
          : (intensity) {
              if (intensity != null) {
                setState(() => _motionIntensity = intensity);
              }
            },
    ),
    const SizedBox(height: 12),
    Text('Transitions', style: Theme.of(context).textTheme.titleSmall),
    const SizedBox(height: 8),
    DropdownButtonFormField<VideoTransition>(
      initialValue: _transition,
      decoration: const InputDecoration(
        labelText: 'Transition effect',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final transition in VideoTransition.values)
          DropdownMenuItem(value: transition, child: Text(transition.label)),
      ],
      onChanged: _exporting
          ? null
          : (transition) {
              if (transition != null) {
                setState(() {
                  _transition = transition;
                  _transitionCustomized = true;
                });
              }
            },
    ),
    if (_transition != VideoTransition.cut) ...[
      const SizedBox(height: 8),
      Text(
        'Transition duration · ${_transitionDuration.toStringAsFixed(1)} s',
        style: Theme.of(context).textTheme.titleSmall,
      ),
      Slider(
        value: _transitionDuration,
        min: 0.1,
        max: 1.5,
        divisions: 14,
        label: '${_transitionDuration.toStringAsFixed(1)} s',
        onChanged: _exporting
            ? null
            : (value) => setState(() => _transitionDuration = value),
      ),
    ],
    const SizedBox(height: 12),
    DropdownButtonFormField<String>(
      initialValue: _music == null ? 'builtin:${_builtInMusic.name}' : 'device',
      decoration: const InputDecoration(
        labelText: 'Background music',
        border: OutlineInputBorder(),
      ),
      items: [
        for (final track in BuiltInMusicTrack.values)
          DropdownMenuItem(
            value: 'builtin:${track.name}',
            child: Text(track.label),
          ),
        DropdownMenuItem(
          value: 'device',
          child: Text(_music?.name ?? 'Choose your music'),
        ),
      ],
      onChanged: _exporting
          ? null
          : (selection) {
              if (selection == null) return;
              if (selection == 'device') {
                _pickMusic();
                return;
              }
              final trackName = selection.substring('builtin:'.length);
              final track = BuiltInMusicTrack.values.firstWhere(
                (candidate) => candidate.name == trackName,
              );
              _selectBuiltInMusic(track);
            },
    ),
    Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        'Built-in tracks are original, beat-synced compositions. For recorded '
        'songs or instruments, choose audio you own or are licensed to use.',
        style: TextStyle(color: secondary, fontSize: 12, height: 1.4),
      ),
    ),
    if (_music != null) ...[
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.library_music_rounded),
        title: Text(_music!.name),
        subtitle: Text(
          _preparingMusic || _musicDurationSeconds == 0
              ? 'Loading audio details…'
              : 'Selected segment · ${_formatMusicTime(_musicStartSeconds)}–'
                    '${_formatMusicTime(_musicEndSeconds)}',
        ),
        trailing: IconButton(
          tooltip: 'Remove music',
          onPressed: _exporting ? null : _removeCustomMusic,
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      if (_musicDurationSeconds > 0) ...[
        Text(
          'Choose the part of the track to include',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        RangeSlider(
          values: RangeValues(_musicStartSeconds, _musicEndSeconds),
          min: 0,
          max: _musicDurationSeconds,
          divisions: math.max(1, (_musicDurationSeconds * 2).round()),
          labels: RangeLabels(
            _formatMusicTime(_musicStartSeconds),
            _formatMusicTime(_musicEndSeconds),
          ),
          onChanged: _exporting ? null : _setMusicTrim,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatMusicTime(_musicStartSeconds)),
            Text('Audio length · ${_formatMusicTime(_musicDurationSeconds)}'),
            Text(_formatMusicTime(_musicEndSeconds)),
          ],
        ),
      ],
    ],
    Row(
      children: [
        FilledButton.tonalIcon(
          onPressed:
              _exporting ||
                  _preparingMusic ||
                  (_music != null && _musicDurationSeconds <= 0) ||
                  (_music == null && _builtInMusic == BuiltInMusicTrack.none)
              ? null
              : _toggleMusicPreview,
          icon: Icon(
            _isMusicPreviewing ? Icons.pause_rounded : Icons.play_arrow_rounded,
          ),
          label: Text(
            _preparingMusic
                ? 'Loading music…'
                : _isMusicPreviewing
                ? 'Pause music'
                : 'Preview music',
          ),
        ),
        if (_music != null) ...[
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _exporting ? null : _pickMusic,
            icon: const Icon(Icons.swap_horiz_rounded),
            label: const Text('Replace'),
          ),
        ],
      ],
    ),
    Text(
      'Music volume · ${(_musicVolume * 100).round()}%',
      style: Theme.of(context).textTheme.titleSmall,
    ),
    Slider(
      value: _musicVolume,
      min: 0,
      max: 1,
      divisions: 20,
      label: '${(_musicVolume * 100).round()}%',
      onChanged: _exporting ? null : _setMusicVolume,
    ),
    ..._buildOutputSettingsControls(),
    if (_errorMessage != null) ...[
      const SizedBox(height: 8),
      _buildErrorMessage(),
    ],
    if (_exporting) ...[
      const SizedBox(height: 16),
      LinearProgressIndicator(value: _progress),
      const SizedBox(height: 8),
      Text(
        'Please wait... Your video is being exported. ${(_progress * 100).round()}%',
        textAlign: TextAlign.center,
        style: TextStyle(color: secondary),
      ),
    ],
    const SizedBox(height: 12),
  ];

  Widget _buildStepIndicator() {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final accent = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        for (var step = 0; step < 3; step++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: step <= _currentStep
                    ? accent
                    : secondary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          if (step < 2) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildEditorPreview() {
    return _buildMotionPreview(
      showPlaybackControls: true,
      showExpandButton: true,
      interactiveCaption: true,
    );
  }

  Widget _buildMotionPreview({
    required bool showPlaybackControls,
    required bool showExpandButton,
    bool interactiveCaption = false,
    double initialProgress = 0,
  }) {
    return ImageMotionPreview(
      photos: List.unmodifiable(_photos),
      sceneDurations: _sceneDurations,
      motion: _motion,
      motionIntensity: _motionIntensity,
      secondsPerPhoto: _secondsPerPhoto,
      caption: _captionController.text,
      speechBubble: _speechBubbleController.text,
      captionPlacement: _captionPlacement,
      captionFontStyle: _captionFontStyle,
      captionColor: _captionColor,
      captionAlignment: _captionAlignment,
      captionScale: _captionScale,
      captionPosition: _captionPosition,
      captionBold: _captionBold,
      captionOutline: _captionOutline,
      interactiveCaption: interactiveCaption,
      captionSelected: _captionSelected,
      captionEditing: _captionEditing,
      captionController: _captionController,
      captionFocusNode: _captionFocusNode,
      onCaptionPositionChanged: (position) {
        if (mounted && !_exporting) {
          setState(() => _captionPosition = position);
        }
      },
      onCaptionScaleChanged: (scale) {
        if (mounted && !_exporting) {
          setState(() => _captionScale = scale);
        }
      },
      onCaptionTap: _startCaptionEditing,
      onCaptionChanged: (_) {
        if (mounted) setState(() {});
      },
      onCaptionSubmitted: _finishCaptionEditing,
      speechBubblePosition: _speechBubblePosition,
      speechBubbleScale: _speechBubbleScale,
      speechBubbleColor: _speechBubbleColor,
      speechBubbleOutline: _speechBubbleOutline,
      interactiveSpeechBubble:
          interactiveCaption && _style == VideoStyle.comicPanel,
      speechBubbleSelected: _speechBubbleSelected,
      speechBubbleEditing: _speechBubbleEditing,
      speechBubbleController: _speechBubbleController,
      speechBubbleFocusNode: _speechBubbleFocusNode,
      onSpeechBubblePositionChanged: (position) {
        if (mounted && !_exporting) {
          setState(() => _speechBubblePosition = position);
        }
      },
      onSpeechBubbleScaleChanged: (scale) {
        if (mounted && !_exporting) {
          setState(() => _speechBubbleScale = scale);
        }
      },
      onSpeechBubbleTap: _startSpeechBubbleEditing,
      onSpeechBubbleChanged: (_) {
        if (mounted) setState(() {});
      },
      onSpeechBubbleSubmitted: _finishSpeechBubbleEditing,
      onPreviewTap: _deselectPreviewOverlays,
      style: _style,
      aspectRatio: _aspectRatio,
      comicTemplate: _comicTemplate,
      transition: _transition,
      transitionDuration: _transitionDuration,
      showPlaybackControls: showPlaybackControls,
      showExpandButton: showExpandButton,
      onExpand: showExpandButton ? _showExpandedPreview : null,
      onPlaybackChanged: _onPreviewPlaybackChanged,
      onProgressChanged: (progress) => _previewProgress = progress,
      initialProgress: initialProgress,
    );
  }

  String _formatMusicTime(double seconds) {
    final totalSeconds = seconds.floor();
    return '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildErrorMessage() {
    return Text(
      _errorMessage!,
      style: TextStyle(color: Theme.of(context).colorScheme.error),
    );
  }
}

class _SelectedPhotoTile extends StatelessWidget {
  const _SelectedPhotoTile({
    super.key,
    required this.photo,
    required this.onPreview,
    required this.onMove,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onRemove,
  });

  final XFile photo;
  final VoidCallback onPreview;
  final ValueChanged<int> onMove;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onPreview,
      child: SizedBox(
        width: 96,
        height: 96,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              FutureBuilder<Uint8List>(
                future: photo.readAsBytes(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Container(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      alignment: Alignment.center,
                      child: snapshot.hasError
                          ? const Icon(Icons.broken_image_outlined)
                          : const CircularProgressIndicator(strokeWidth: 2),
                    );
                  }
                  return Image.memory(snapshot.data!, fit: BoxFit.cover);
                },
              ),
              Positioned(
                left: 6,
                top: 6,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: accent,
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
              Positioned(
                right: 4,
                top: 4,
                child: IconButton.filledTonal(
                  tooltip: 'Remove photo',
                  onPressed: onRemove,
                  icon: const Icon(Icons.close_rounded, size: 16),
                  visualDensity: VisualDensity.compact,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    foregroundColor: Colors.black87,
                  ),
                ),
              ),
              Positioned(
                left: 2,
                right: 2,
                bottom: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                      tooltip: 'Move photo earlier',
                      onPressed: canMoveEarlier ? () => onMove(-1) : null,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_back_rounded, size: 16),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        foregroundColor: Colors.black87,
                      ),
                    ),
                    IconButton.filledTonal(
                      tooltip: 'Move photo later',
                      onPressed: canMoveLater ? () => onMove(1) : null,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        foregroundColor: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({
    super.key,
    required this.photo,
    required this.index,
    required this.dragIndex,
    required this.count,
    required this.enabled,
    required this.durationSeconds,
    required this.onDurationChanged,
    required this.onMove,
    required this.onRemove,
  });

  final XFile photo;
  final int index;
  final int dragIndex;
  final int count;
  final bool enabled;
  final int durationSeconds;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<int> onMove;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: FutureBuilder<Uint8List>(
                    future: photo.readAsBytes(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return const Icon(Icons.broken_image_outlined);
                      }
                      if (!snapshot.hasData) {
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Photo ${index + 1}'),
                      Text(
                        '$durationSeconds sec',
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
                ReorderableDragStartListener(
                  index: dragIndex,
                  enabled: enabled,
                  child: const Tooltip(
                    message: 'Drag to reorder photo',
                    child: Padding(
                      padding: EdgeInsets.all(6),
                      child: Icon(Icons.drag_handle_rounded),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Move photo up',
                  onPressed: enabled && index > 0 ? () => onMove(-1) : null,
                  icon: const Icon(Icons.arrow_upward),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Move photo down',
                  onPressed: enabled && index < count - 1
                      ? () => onMove(1)
                      : null,
                  icon: const Icon(Icons.arrow_downward),
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  tooltip: 'Remove photo',
                  onPressed: enabled ? onRemove : null,
                  icon: const Icon(Icons.close),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            Slider(
              value: durationSeconds.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              label: '$durationSeconds sec',
              onChanged: enabled
                  ? (value) => onDurationChanged(value.round())
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewDetail extends StatelessWidget {
  const _PreviewDetail({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(label),
      trailing: Text(value, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
