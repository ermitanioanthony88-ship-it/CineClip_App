import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'video_project.dart';

class CineClipVideoPreviewScreen extends StatefulWidget {
  const CineClipVideoPreviewScreen({super.key, required this.project});

  final VideoProject project;

  @override
  State<CineClipVideoPreviewScreen> createState() =>
      _CineClipVideoPreviewScreenState();
}

class _CineClipVideoPreviewScreenState
    extends State<CineClipVideoPreviewScreen> {
  late final VideoPlayerController _controller;
  String? _errorMessage;
  bool _savingToGallery = false;
  bool _fullscreen = false;
  bool _fullscreenControlsVisible = true;
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _controller =
        VideoPlayerController.networkUrl(Uri.file(widget.project.videoPath))
          ..initialize()
              .then((_) {
                if (mounted) setState(() {});
              })
              .catchError((Object error) {
                if (mounted) {
                  setState(
                    () => _errorMessage = 'Could not open video: $error',
                  );
                }
              });
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller.removeListener(_onControllerChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _toggleFullscreen() async {
    final entering = !_fullscreen;
    if (entering) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    }
    if (mounted) {
      setState(() {
        _fullscreen = entering;
        _fullscreenControlsVisible = true;
      });
      _scheduleControlsHide();
    }
  }

  void _toggleFullscreenControls() {
    setState(() => _fullscreenControlsVisible = !_fullscreenControlsVisible);
    if (_fullscreenControlsVisible) _scheduleControlsHide();
  }

  void _scheduleControlsHide() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _fullscreen) {
        setState(() => _fullscreenControlsVisible = false);
      }
    });
  }

  Future<void> _saveToGallery() async {
    if (_savingToGallery) return;
    setState(() => _savingToGallery = true);
    try {
      if (!await Gal.hasAccess()) await Gal.requestAccess();
      await Gal.putVideo(widget.project.videoPath, album: 'CineClip');
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
        setState(
          () => _errorMessage = 'Could not save video to Photos: $error',
        );
      }
    } finally {
      if (mounted) setState(() => _savingToGallery = false);
    }
  }

  Future<void> _shareVideo() async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: widget.project.title,
          files: [
            XFile(
              widget.project.videoPath,
              mimeType: 'video/mp4',
              name: '${widget.project.title}.mp4',
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_fullscreen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _fullscreen) _toggleFullscreen();
      },
      child: Scaffold(
        backgroundColor: _fullscreen ? Colors.black : null,
        appBar: _fullscreen ? null : AppBar(title: Text(widget.project.title)),
        body: _fullscreen
            ? _buildFullscreenPlayer()
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  AspectRatio(
                    aspectRatio: _controller.value.isInitialized
                        ? _controller.value.aspectRatio
                        : 16 / 9,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: _controller.value.isInitialized
                            ? VideoPlayer(_controller)
                            : Center(
                                child: _errorMessage == null
                                    ? const CircularProgressIndicator()
                                    : const Icon(
                                        Icons.error_outline,
                                        color: Colors.white,
                                        size: 44,
                                      ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_controller.value.isInitialized) ...[
                    VideoProgressIndicator(
                      _controller,
                      allowScrubbing: true,
                      colors: VideoProgressColors(
                        playedColor: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(_controller.value.position)),
                          Text(_formatDuration(_controller.value.duration)),
                        ],
                      ),
                    ),
                    Center(
                      child: IconButton.filled(
                        tooltip: _controller.value.isPlaying ? 'Pause' : 'Play',
                        onPressed: () {
                          setState(() {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          });
                        },
                        icon: Icon(
                          _controller.value.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        tooltip: 'Fullscreen',
                        onPressed: _toggleFullscreen,
                        icon: const Icon(Icons.fullscreen_rounded),
                      ),
                    ),
                  ],
                  if (widget.project.caption.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.project.caption,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                  Text(
                    '${widget.project.duration} · ${widget.project.date}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: _savingToGallery ? null : _saveToGallery,
                    icon: _savingToGallery
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _savingToGallery ? 'Saving…' : 'Download Video',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _shareVideo,
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Share Video'),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFullscreenPlayer() {
    if (!_controller.value.isInitialized) {
      return Center(
        child: _errorMessage == null
            ? const CircularProgressIndicator()
            : const Icon(Icons.error_outline, color: Colors.white, size: 44),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _toggleFullscreenControls,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
          if (_fullscreenControlsVisible)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
                    ],
                    stops: const [0, 0.45, 1],
                  ),
                ),
                child: SafeArea(
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          tooltip: 'Exit fullscreen',
                          color: Colors.white,
                          onPressed: _toggleFullscreen,
                          icon: const Icon(Icons.fullscreen_exit_rounded),
                        ),
                      ),
                      Align(
                        alignment: Alignment.center,
                        child: IconButton.filled(
                          onPressed: () {
                            if (_controller.value.isPlaying) {
                              _controller.pause();
                            } else {
                              _controller.play();
                            }
                          },
                          iconSize: 38,
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              VideoProgressIndicator(
                                _controller,
                                allowScrubbing: true,
                                colors: VideoProgressColors(
                                  playedColor: Theme.of(context)
                                      .colorScheme
                                      .secondary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDuration(_controller.value.position),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  Text(
                                    _formatDuration(_controller.value.duration),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final seconds = duration.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }
}
