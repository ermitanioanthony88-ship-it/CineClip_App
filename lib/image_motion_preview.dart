import 'dart:math' as math;

import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'comic_panel_layout.dart';
import 'video_export_contract.dart';
import 'video_timing.dart';

class ImageMotionPreview extends StatefulWidget {
  const ImageMotionPreview({
    super.key,
    required this.photos,
    required this.sceneDurations,
    required this.motion,
    this.motionIntensity = MotionIntensity.medium,
    required this.secondsPerPhoto,
    this.style = VideoStyle.fullFrame,
    this.aspectRatio = VideoAspectRatio.landscape,
    this.comicTemplate = ComicTemplate.fourPanel,
    this.transition = VideoTransition.fade,
    this.transitionDuration = videoTransitionSeconds,
    this.caption = '',
    this.speechBubble = '',
    this.captionPlacement = CaptionPlacement.bottom,
    this.captionFontStyle = CaptionFontStyle.sansSerif,
    this.captionColor = CaptionColor.white,
    this.captionAlignment = TextAlign.center,
    this.captionScale = 1,
    this.captionPosition = const Offset(0.5, 0.875),
    this.captionBold = true,
    this.captionOutline = true,
    this.interactiveCaption = false,
    this.captionSelected = false,
    this.captionEditing = false,
    this.captionController,
    this.captionFocusNode,
    this.onCaptionPositionChanged,
    this.onCaptionScaleChanged,
    this.onCaptionTap,
    this.onCaptionChanged,
    this.onCaptionSubmitted,
    this.speechBubblePosition = const Offset(0.78, 0.2),
    this.speechBubbleScale = 1,
    this.speechBubbleColor = CaptionColor.black,
    this.speechBubbleOutline = true,
    this.interactiveSpeechBubble = false,
    this.speechBubbleSelected = false,
    this.speechBubbleEditing = false,
    this.speechBubbleController,
    this.speechBubbleFocusNode,
    this.onSpeechBubblePositionChanged,
    this.onSpeechBubbleScaleChanged,
    this.onSpeechBubbleTap,
    this.onSpeechBubbleChanged,
    this.onSpeechBubbleSubmitted,
    this.onPreviewTap,
    this.showPlaybackControls = false,
    this.showExpandButton = false,
    this.onExpand,
    this.onPlaybackChanged,
    this.onProgressChanged,
    this.initialProgress = 0,
  });

  final List<XFile> photos;
  final List<int> sceneDurations;
  final ImageMotion motion;
  final MotionIntensity motionIntensity;
  final int secondsPerPhoto;
  final VideoStyle style;
  final VideoAspectRatio aspectRatio;
  final ComicTemplate comicTemplate;
  final VideoTransition transition;
  final double transitionDuration;
  final String caption;
  final String speechBubble;
  final CaptionPlacement captionPlacement;
  final CaptionFontStyle captionFontStyle;
  final CaptionColor captionColor;
  final TextAlign captionAlignment;
  final double captionScale;
  final Offset captionPosition;
  final bool captionBold;
  final bool captionOutline;
  final bool interactiveCaption;
  final bool captionSelected;
  final bool captionEditing;
  final TextEditingController? captionController;
  final FocusNode? captionFocusNode;
  final ValueChanged<Offset>? onCaptionPositionChanged;
  final ValueChanged<double>? onCaptionScaleChanged;
  final VoidCallback? onCaptionTap;
  final ValueChanged<String>? onCaptionChanged;
  final ValueChanged<String>? onCaptionSubmitted;
  final Offset speechBubblePosition;
  final double speechBubbleScale;
  final CaptionColor speechBubbleColor;
  final bool speechBubbleOutline;
  final bool interactiveSpeechBubble;
  final bool speechBubbleSelected;
  final bool speechBubbleEditing;
  final TextEditingController? speechBubbleController;
  final FocusNode? speechBubbleFocusNode;
  final ValueChanged<Offset>? onSpeechBubblePositionChanged;
  final ValueChanged<double>? onSpeechBubbleScaleChanged;
  final VoidCallback? onSpeechBubbleTap;
  final ValueChanged<String>? onSpeechBubbleChanged;
  final ValueChanged<String>? onSpeechBubbleSubmitted;
  final VoidCallback? onPreviewTap;
  final bool showPlaybackControls;
  final bool showExpandButton;
  final VoidCallback? onExpand;
  final ValueChanged<bool>? onPlaybackChanged;
  final ValueChanged<double>? onProgressChanged;
  final double initialProgress;

  @override
  State<ImageMotionPreview> createState() => _ImageMotionPreviewState();
}

class _ImageMotionPreviewState extends State<ImageMotionPreview>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Future<List<Uint8List>> _photoBytes;
  bool _playing = true;

  @override
  void initState() {
    super.initState();
    _photoBytes = _readPhotos();
    _controller =
        AnimationController(
            vsync: this,
            duration: Duration(
              milliseconds: math.max(
                1,
                (_previewDurationSeconds * 1000).round(),
              ),
            ),
          )
          ..addStatusListener(_handleAnimationStatus)
          ..addListener(_reportProgress);
    if (widget.photos.isNotEmpty) {
      _controller.forward(
        from: widget.initialProgress.clamp(0.0, 0.999999).toDouble(),
      );
    }
  }

  @override
  void didUpdateWidget(covariant ImageMotionPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.photos != widget.photos) _photoBytes = _readPhotos();
    if (oldWidget.photos.length != widget.photos.length ||
        !listEquals(oldWidget.sceneDurations, widget.sceneDurations) ||
        oldWidget.style != widget.style ||
        oldWidget.motionIntensity != widget.motionIntensity ||
        oldWidget.comicTemplate != widget.comicTemplate ||
        oldWidget.transition != widget.transition ||
        oldWidget.transitionDuration != widget.transitionDuration) {
      _controller.duration = Duration(
        milliseconds: math.max(1, (_previewDurationSeconds * 1000).round()),
      );
      if (_playing && widget.photos.isNotEmpty) {
        _controller.forward(
          from: _controller.value.clamp(0.0, 0.999999).toDouble(),
        );
      }
    }
  }

  Future<List<Uint8List>> _readPhotos() async =>
      Future.wait(widget.photos.map((photo) => photo.readAsBytes()));

  double get _previewDurationSeconds => videoDurationSeconds(
    sceneDurations: widget.sceneDurations,
    transition: widget.transition,
    transitionDuration: widget.transitionDuration,
  );

  Duration get _transitionDuration => widget.transition == VideoTransition.cut
      ? Duration.zero
      : Duration(
          milliseconds: math.max(1, (widget.transitionDuration * 1000).round()),
        );

  int get _sceneCount => widget.style == VideoStyle.comicPanel
      ? (widget.photos.length / widget.comicTemplate.panelCount).ceil()
      : widget.photos.length;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(() {
      _playing = !_playing;
      if (_playing) {
        _controller.forward(
          from: _controller.value.clamp(0.0, 0.999999).toDouble(),
        );
      } else {
        _controller.stop();
      }
    });
    widget.onPlaybackChanged?.call(_playing);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _playing) {
      _controller.forward(from: 0);
    }
  }

  void _reportProgress() {
    widget.onProgressChanged?.call(_controller.value);
  }

  Widget _buildTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeInOut);
    return switch (widget.transition) {
      VideoTransition.cut => child,
      VideoTransition.fade ||
      VideoTransition.dissolve => FadeTransition(opacity: curved, child: child),
      VideoTransition.slideLeft => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
      VideoTransition.slideRight => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
      VideoTransition.slideUp => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
      VideoTransition.wipe => SizeTransition(
        sizeFactor: curved,
        axis: Axis.horizontal,
        axisAlignment: -1,
        child: child,
      ),
      VideoTransition.pageTurn => AnimatedBuilder(
        animation: curved,
        child: child,
        builder: (context, child) => Transform(
          alignment: Alignment.centerLeft,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY((1 - curved.value) * -math.pi / 2),
          child: child,
        ),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: widget.aspectRatio.width / widget.aspectRatio.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: FutureBuilder<List<Uint8List>>(
                  future: _photoBytes,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return ColoredBox(
                        color: Colors.black87,
                        child: Center(
                          child: snapshot.hasError
                              ? const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white,
                                  size: 40,
                                )
                              : const CircularProgressIndicator(),
                        ),
                      );
                    }
                    if (snapshot.data!.isEmpty) {
                      return const ColoredBox(
                        color: Colors.black87,
                        child: Center(
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Colors.white70,
                            size: 40,
                          ),
                        ),
                      );
                    }
                    return AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final elapsed =
                            _controller.value * _previewDurationSeconds;
                        final clipInterval =
                            (widget.transition == VideoTransition.cut
                                    ? 0
                                    : widget.transitionDuration)
                                .toDouble();
                        var sceneIndex = 0;
                        var sceneStart = 0.0;
                        while (sceneIndex < _sceneCount - 1 &&
                            elapsed >=
                                sceneStart +
                                    widget.sceneDurations[sceneIndex] -
                                    clipInterval) {
                          sceneStart +=
                              widget.sceneDurations[sceneIndex] - clipInterval;
                          sceneIndex++;
                        }
                        final photoIndex = widget.style == VideoStyle.comicPanel
                            ? sceneIndex * widget.comicTemplate.panelCount
                            : sceneIndex;
                        final progress =
                            ((elapsed - sceneStart) /
                                    widget.sceneDurations[sceneIndex])
                                .clamp(0.0, 1.0);
                        final transform = _transform(progress);
                        final movingPhoto = Stack(
                          fit: StackFit.expand,
                          children: [
                            ColoredBox(
                              color: Colors.black,
                              child: ClipRect(
                                child: AnimatedSwitcher(
                                  duration: _transitionDuration,
                                  transitionBuilder: _buildTransition,
                                  layoutBuilder:
                                      (currentChild, previousChildren) => Stack(
                                        fit: StackFit.expand,
                                        children: [
                                          ...previousChildren,
                                          ?currentChild,
                                        ],
                                      ),
                                  child: Transform.translate(
                                    key: ValueKey(photoIndex),
                                    offset: transform.offset,
                                    child: Transform.scale(
                                      scale: transform.scale,
                                      child: Opacity(
                                        opacity: switch (widget.motion) {
                                          ImageMotion.fade =>
                                            (progress / 0.2).clamp(0.0, 1.0),
                                          ImageMotion.fadeOut =>
                                            ((1 - progress) / 0.2).clamp(
                                              0.0,
                                              1.0,
                                            ),
                                          _ => 1,
                                        },
                                        child: Image.memory(
                                          snapshot.data![photoIndex],
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (widget.interactiveCaption ||
                                widget.interactiveSpeechBubble)
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: widget.onPreviewTap,
                                ),
                              ),
                            if (widget.caption.trim().isNotEmpty)
                              _buildCaptionOverlay(),
                            if (widget.style == VideoStyle.comicPanel &&
                                (widget.speechBubble.trim().isNotEmpty ||
                                    widget.interactiveSpeechBubble))
                              _buildSpeechBubble(),
                          ],
                        );
                        if (widget.style == VideoStyle.fullFrame) {
                          return movingPhoto;
                        }
                        return AnimatedSwitcher(
                          duration: _transitionDuration,
                          transitionBuilder: _buildTransition,
                          child: KeyedSubtree(
                            key: ValueKey(sceneIndex),
                            child: _comicPagePreview(
                              snapshot.data!,
                              photoIndex,
                              transform,
                              progress,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (widget.showExpandButton && widget.onExpand != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton.filledTonal(
                    tooltip: 'Expand preview',
                    onPressed: widget.onExpand,
                    icon: const Icon(Icons.fullscreen_rounded),
                  ),
                ),
            ],
          ),
        ),
        if (widget.showPlaybackControls) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: _playing ? 'Pause preview' : 'Play preview',
                onPressed: _togglePlayback,
                icon: Icon(
                  _playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
              ),
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => LinearProgressIndicator(
                    value: _controller.value,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${_formatDuration(_controller.value * _previewDurationSeconds)} / '
                '${_formatDuration(_previewDurationSeconds)}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatDuration(double seconds) {
    final totalSeconds = seconds.floor();
    return '${totalSeconds ~/ 60}:${(totalSeconds % 60).toString().padLeft(2, '0')}';
  }

  Widget _buildCaptionOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final position = widget.captionPosition;
        final outline = widget.captionOutline
            ? const [
                Shadow(
                  color: Colors.black,
                  blurRadius: 3,
                  offset: Offset(1, 1),
                ),
              ]
            : null;
        return Align(
          alignment: Alignment(position.dx * 2 - 1, position.dy * 2 - 1),
          child: GestureDetector(
            onTap: widget.interactiveCaption ? widget.onCaptionTap : null,
            onPanUpdate: widget.interactiveCaption && !widget.captionEditing
                ? (details) {
                    widget.onCaptionPositionChanged?.call(
                      Offset(
                        (position.dx +
                                details.delta.dx / constraints.maxWidth)
                            .clamp(0.27, 0.73)
                            .toDouble(),
                        (position.dy +
                                details.delta.dy / constraints.maxHeight)
                            .clamp(0.1, 0.9)
                            .toDouble(),
                      ),
                    );
                  }
                : null,
            child: SizedBox(
              width: constraints.maxWidth * 0.5,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      border: widget.interactiveCaption &&
                              widget.captionSelected &&
                              !widget.captionEditing
                          ? Border.all(
                              color: const Color(0xFF20D7FF),
                              width: 1.5,
                            )
                          : null,
                    ),
                    child: widget.captionEditing &&
                            widget.captionController != null
                        ? TextField(
                            controller: widget.captionController,
                            focusNode: widget.captionFocusNode,
                            maxLines: 2,
                            maxLength: 80,
                            textCapitalization: TextCapitalization.sentences,
                            textAlign: widget.captionAlignment,
                            textInputAction: TextInputAction.done,
                            onSubmitted: widget.onCaptionSubmitted,
                            onChanged: widget.onCaptionChanged,
                            decoration: const InputDecoration(
                              hintText: 'Type your text',
                              hintStyle: TextStyle(color: Colors.white70),
                              counterText: '',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              color: Color(widget.captionColor.value),
                              fontFamily: widget.captionFontStyle.family,
                              fontSize:
                                  constraints.maxWidth * 0.045 * widget.captionScale,
                              fontWeight: widget.captionBold
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              shadows: outline,
                            ),
                            cursorColor: const Color(0xFF20D7FF),
                          )
                        : Text(
                            widget.caption,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: widget.captionAlignment,
                            style: TextStyle(
                              color: Color(widget.captionColor.value),
                              fontFamily: widget.captionFontStyle.family,
                              fontSize:
                                  constraints.maxWidth * 0.045 * widget.captionScale,
                              fontWeight: widget.captionBold
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              shadows: outline,
                            ),
                          ),
                  ),
                  if (widget.interactiveCaption &&
                      widget.captionSelected &&
                      !widget.captionEditing)
                    Positioned(
                      right: -9,
                      bottom: -9,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          widget.onCaptionScaleChanged?.call(
                            (widget.captionScale + details.delta.dy * 0.01)
                                .clamp(0.7, 2.4)
                                .toDouble(),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.open_in_full_rounded,
                            size: 15,
                            color: Color(0xFF20D7FF),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpeechBubble() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final position = widget.speechBubblePosition;
        final bubbleWidth = constraints.maxWidth * 0.38 * widget.speechBubbleScale;
        final bubbleHeight =
            constraints.maxHeight * 0.2 * widget.speechBubbleScale;
        return Align(
          alignment: Alignment(position.dx * 2 - 1, position.dy * 2 - 1),
          child: GestureDetector(
            onTap: widget.interactiveSpeechBubble
                ? widget.onSpeechBubbleTap
                : null,
            onPanUpdate:
                widget.interactiveSpeechBubble &&
                    !widget.speechBubbleEditing
                ? (details) {
                    widget.onSpeechBubblePositionChanged?.call(
                      Offset(
                        (position.dx +
                                details.delta.dx / constraints.maxWidth)
                            .clamp(
                              0.02 + 0.19 * widget.speechBubbleScale,
                              0.98 - 0.19 * widget.speechBubbleScale,
                            )
                            .toDouble(),
                        (position.dy +
                                details.delta.dy / constraints.maxHeight)
                            .clamp(
                              0.02 + 0.1 * widget.speechBubbleScale,
                              0.92 - 0.1 * widget.speechBubbleScale,
                            )
                            .toDouble(),
                      ),
                    );
                  }
                : null,
            child: SizedBox(
              width: bubbleWidth,
              height: bubbleHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(
                    painter: _SpeechBubblePainter(
                      selected: widget.interactiveSpeechBubble &&
                          widget.speechBubbleSelected &&
                          !widget.speechBubbleEditing,
                      outline: widget.speechBubbleOutline,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      bubbleWidth * 0.08,
                      bubbleHeight * 0.04,
                      bubbleWidth * 0.08,
                      bubbleHeight * 0.2,
                    ),
                    child: widget.speechBubbleEditing &&
                            widget.speechBubbleController != null
                        ? TextField(
                            controller: widget.speechBubbleController,
                            focusNode: widget.speechBubbleFocusNode,
                            maxLines: 3,
                            maxLength: 60,
                            textCapitalization: TextCapitalization.sentences,
                            textAlign: TextAlign.center,
                            textInputAction: TextInputAction.done,
                            onSubmitted: widget.onSpeechBubbleSubmitted,
                            onChanged: widget.onSpeechBubbleChanged,
                            decoration: const InputDecoration(
                              hintText: 'Type bubble text',
                              counterText: '',
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            style: TextStyle(
                              color: Color(widget.speechBubbleColor.value),
                              fontFamily: widget.captionFontStyle.family,
                              fontSize:
                                  constraints.maxWidth *
                                  0.032 *
                                  widget.speechBubbleScale,
                              fontWeight: FontWeight.w700,
                            ),
                            cursorColor: const Color(0xFF20D7FF),
                          )
                        : Center(
                            child: Text(
                              widget.speechBubble,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(widget.speechBubbleColor.value),
                                fontFamily: widget.captionFontStyle.family,
                                fontSize:
                                    constraints.maxWidth *
                                    0.032 *
                                    widget.speechBubbleScale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                  ),
                  if (widget.interactiveSpeechBubble &&
                      widget.speechBubbleSelected &&
                      !widget.speechBubbleEditing)
                    Positioned(
                      right: -8,
                      bottom: 1,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          widget.onSpeechBubbleScaleChanged?.call(
                            (widget.speechBubbleScale +
                                    details.delta.dy * 0.01)
                                .clamp(0.6, 1.6)
                                .toDouble(),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(
                            Icons.open_in_full_rounded,
                            size: 15,
                            color: Color(0xFF20D7FF),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ({double scale, Offset offset}) _transform(double progress) {
    final size = MediaQuery.sizeOf(context);
    return switch (widget.motion) {
      ImageMotion.zoomIn => (
        scale: 1 + widget.motionIntensity.zoomAmount * progress,
        offset: Offset.zero,
      ),
      ImageMotion.zoomOut => (
        scale: 1 + widget.motionIntensity.zoomAmount * (1 - progress),
        offset: Offset.zero,
      ),
      ImageMotion.panLeft => (
        scale: 1 + widget.motionIntensity.zoomAmount,
        offset: Offset(
          (widget.motionIntensity.zoomAmount -
                  progress * widget.motionIntensity.zoomAmount * 2) *
              size.width /
              2,
          0,
        ),
      ),
      ImageMotion.panRight => (
        scale: 1 + widget.motionIntensity.zoomAmount,
        offset: Offset(
          (-widget.motionIntensity.zoomAmount +
                  progress * widget.motionIntensity.zoomAmount * 2) *
              size.width /
              2,
          0,
        ),
      ),
      ImageMotion.panUp => (
        scale: 1 + widget.motionIntensity.zoomAmount,
        offset: Offset(
          0,
          (widget.motionIntensity.zoomAmount -
                  progress * widget.motionIntensity.zoomAmount * 2) *
              size.height /
              2,
        ),
      ),
      ImageMotion.panDown => (
        scale: 1 + widget.motionIntensity.zoomAmount,
        offset: Offset(
          0,
          (-widget.motionIntensity.zoomAmount +
                  progress * widget.motionIntensity.zoomAmount * 2) *
              size.height /
              2,
        ),
      ),
      ImageMotion.fade ||
      ImageMotion.fadeOut => (scale: 1, offset: Offset.zero),
    };
  }

  Widget _comicPagePreview(
    List<Uint8List> photos,
    int firstPhoto,
    ({double scale, Offset offset}) transform,
    double progress,
  ) {
    final panels = comicPanelLayout(widget.comicTemplate);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        return ColoredBox(
          color: const Color(0xFFF4EAD4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (
                var index = 0;
                index < panels.length && firstPhoto + index < photos.length;
                index++
              )
                Positioned.fromRect(
                  rect: Rect.fromLTWH(
                    panels[index].left * width,
                    panels[index].top * height,
                    panels[index].width * width,
                    panels[index].height * height,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF28232A),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x5528232A),
                          blurRadius: 5,
                          offset: Offset(2, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(3),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Transform.translate(
                        offset: transform.offset,
                        child: Transform.scale(
                          scale: transform.scale,
                          child: Opacity(
                            opacity: widget.motion == ImageMotion.fade
                                ? (progress / 0.2).clamp(0.0, 1.0)
                                : widget.motion == ImageMotion.fadeOut
                                ? ((1 - progress) / 0.2).clamp(0.0, 1.0)
                                : 1,
                            child: Image.memory(
                              photos[firstPhoto + index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (widget.interactiveCaption ||
                    widget.interactiveSpeechBubble)
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.onPreviewTap,
                    ),
                  ),
                if (widget.caption.trim().isNotEmpty) _buildCaptionOverlay(),
                if (widget.speechBubble.trim().isNotEmpty ||
                    widget.interactiveSpeechBubble)
                  _buildSpeechBubble(),
            ],
          ),
        );
      },
    );
  }
}

class _SpeechBubblePainter extends CustomPainter {
  const _SpeechBubblePainter({required this.selected, required this.outline});

  final bool selected;
  final bool outline;

  @override
  void paint(Canvas canvas, Size size) {
    final body = Rect.fromLTWH(0, 0, size.width, size.height * 0.8);
    final bubble = RRect.fromRectAndRadius(
      body,
      Radius.circular(size.width * 0.08),
    );
    final tail = Path()
      ..moveTo(size.width * 0.22, body.bottom - 1)
      ..lineTo(size.width * 0.2, size.height)
      ..lineTo(size.width * 0.48, body.bottom - 1)
      ..close();
    canvas
      ..drawPath(tail, Paint()..color = Colors.white)
      ..drawRRect(bubble, Paint()..color = Colors.white);
    if (outline || selected) {
      final stroke = Paint()
        ..color = selected
            ? const Color(0xFF20D7FF)
            : const Color(0xFF28232A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 2 : 1.5;
      canvas
        ..drawPath(tail, stroke)
        ..drawRRect(bubble, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SpeechBubblePainter oldDelegate) =>
      oldDelegate.selected != selected || oldDelegate.outline != outline;
}
