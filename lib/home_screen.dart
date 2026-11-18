import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'creation_flow_screen.dart';
import 'video_export_service.dart';
import 'video_preview_screen.dart';
import 'video_project.dart';
import 'video_thumbnail.dart';

const _blue = Color(0xFF087BFF);
const _cyan = Color(0xFF20D7FF);
const _videoLibraryKey = 'cineclip_video_library';

class CineClipHomeScreen extends StatefulWidget {
  const CineClipHomeScreen({super.key, required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  State<CineClipHomeScreen> createState() => _CineClipHomeScreenState();
}

class _CineClipHomeScreenState extends State<CineClipHomeScreen> {
  int _selectedTab = 0;
  bool _searching = false;
  bool _showRecentOnly = false;
  bool _loadingVideos = true;
  final _searchController = TextEditingController();
  final List<VideoProject> _videos = [];
  final _videoExportService = createVideoExportService();

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVideos() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final encoded = preferences.getString(_videoLibraryKey);
      if (encoded == null) {
        if (mounted) setState(() => _loadingVideos = false);
        return;
      }
      final decoded = jsonDecode(encoded);
      if (decoded is! List) {
        throw const FormatException('The saved video library is not a list.');
      }
      final videos = decoded
          .whereType<Map>()
          .map(
            (entry) => VideoProject.fromJson(Map<String, Object?>.from(entry)),
          )
          .toList();
      if (mounted) {
        setState(() {
          _videos
            ..clear()
            ..addAll(videos);
          _loadingVideos = false;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadingVideos = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load your video library: $error')),
      );
    }
  }

  Future<void> _saveVideos(List<VideoProject> videos) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _videoLibraryKey,
      jsonEncode(videos.map((video) => video.toJson()).toList()),
    );
    if (!saved) throw StateError('Could not save your video library.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(child: _selectedTab == 0 ? _buildHome() : _buildLibrary()),
      floatingActionButton: _selectedTab == 1 && _videos.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _showCreateFlow,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Create New Video'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        backgroundColor: _surfaceFor(context),
        indicatorColor: _cyan.withValues(alpha: 0.16),
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTab = index;
            _searching = false;
            _searchController.clear();
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.video_library_outlined),
            selectedIcon: Icon(Icons.video_library_rounded),
            label: 'Library',
          ),
        ],
      ),
    );
  }

  Widget _buildHome() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _buildTopBar(),
        const SizedBox(height: 28),
        const Text(
          'Create Videos Easily',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          'Turn your photos into memorable videos.',
          style: TextStyle(color: _secondaryText(context)),
        ),
        const SizedBox(height: 22),
        _buildCreateCard(),
        const SizedBox(height: 32),
        _sectionHeading(
          title: 'Recent Videos',
          action: 'See All',
          onTap: () => setState(() => _selectedTab = 1),
        ),
        const SizedBox(height: 16),
        if (_loadingVideos)
          const SizedBox(
            height: 100,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_videos.isEmpty)
          _buildHomeEmptyState()
        else
          SizedBox(
            height: 222,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _videos.length,
              separatorBuilder: (context, index) => const SizedBox(width: 14),
              itemBuilder: (context, index) => SizedBox(
                width: 176,
                child: _VideoCard(
                  video: _videos[index],
                  onTap: () => _showPreview(_videos[index]),
                  onMenuSelected: (action) =>
                      _handleVideoAction(_videos[index], action),
                ),
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          'Your next story starts here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _secondaryText(context, alpha: 0.75),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildHomeEmptyState() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surfaceFor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _secondaryText(context, alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: _cyan.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.video_library_outlined,
              color: _cyan,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Your first video is waiting',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 5),
                Text(
                  'Your creations will show up here.',
                  style: TextStyle(
                    color: _secondaryText(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _showCreateFlow,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Create your first video',
                    style: TextStyle(color: _cyan),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: const LinearGradient(colors: [_blue, _cyan]),
          ),
          child: const Icon(Icons.movie_creation_rounded, color: Colors.white),
        ),
        const SizedBox(width: 11),
        Text(
          'CineClip',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Settings',
          onPressed: widget.onOpenSettings,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }

  Widget _buildCreateCard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [Color(0xFF123D79), Color(0xFF09264F), Color(0xFF0B1D38)]
              : const [Color(0xFFD9F2FF), Color(0xFFE7F4FF), Colors.white],
        ),
        border: Border.all(color: _cyan.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: _cyan, size: 28),
          const SizedBox(height: 14),
          const Text(
            'Your memories, in motion',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick your favorite photos and create a video in moments.',
            style: TextStyle(color: _secondaryText(context), height: 1.4),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showCreateFlow,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Create New Video'),
              style: FilledButton.styleFrom(
                backgroundColor: _blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLibrary() {
    final query = _searchController.text.trim().toLowerCase();
    final filteredVideos =
        _videos.where((video) {
          final matchesQuery = video.title.toLowerCase().contains(query);
          final createdAt = DateTime.tryParse(video.createdAt)?.toLocal();
          final isRecent =
              createdAt != null &&
              !createdAt.isAfter(DateTime.now()) &&
              DateTime.now().difference(createdAt).inDays < 7;
          return matchesQuery && (!_showRecentOnly || isRecent);
        }).toList()..sort((first, second) {
          final firstDate =
              DateTime.tryParse(first.createdAt) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final secondDate =
              DateTime.tryParse(second.createdAt) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return secondDate.compareTo(firstDate);
        });

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 12, 16),
          child: Row(
            children: [
              Expanded(
                child: _searching
                    ? TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Search videos',
                          border: InputBorder.none,
                        ),
                      )
                    : const Text(
                        'Library',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              IconButton(
                tooltip: _searching ? 'Close search' : 'Search',
                onPressed: () {
                  setState(() {
                    _searching = !_searching;
                    if (!_searching) _searchController.clear();
                  });
                },
                icon: Icon(_searching ? Icons.close_rounded : Icons.search),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _FilterChip(
                label: 'All Videos',
                selected: !_showRecentOnly,
                onTap: () => setState(() => _showRecentOnly = false),
              ),
              const SizedBox(width: 10),
              _FilterChip(
                label: 'Recent',
                selected: _showRecentOnly,
                onTap: () => setState(() => _showRecentOnly = true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _loadingVideos
              ? const Center(child: CircularProgressIndicator())
              : filteredVideos.isEmpty
              ? _buildEmptyLibrary()
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: filteredVideos.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final video = filteredVideos[index];
                    return _LibraryVideoTile(
                      video: video,
                      onTap: () => _showPreview(video),
                      onMenuSelected: (action) =>
                          _handleVideoAction(video, action),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyLibrary() {
    final hasVideos = _videos.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: _cyan.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasVideos
                    ? Icons.search_off_rounded
                    : Icons.video_library_outlined,
                size: 42,
                color: _cyan,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasVideos ? 'No videos found' : 'Your library is empty',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              hasVideos ? 'Try another title or filter.' : 'Your finished videos will appear here. Start by turning your photos into a memorable video.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _secondaryText(context)),
            ),
            if (!hasVideos) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _showCreateFlow,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Create New Video'),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionHeading({
    required String title,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
        ),
        const Spacer(),
        TextButton(
          onPressed: onTap,
          child: Text(action, style: const TextStyle(color: _cyan)),
        ),
      ],
    );
  }

  Future<void> _showCreateFlow() async {
    final result = await Navigator.push<VideoExportResult>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            CineClipCreationFlowScreen(onProjectSaved: _saveVideoToLibrary),
      ),
    );
    if (result == null || !mounted) return;

    final project = result.project;
    setState(() {
      _selectedTab = result.openVideo || result.goToLibrary ? 1 : 0;
      _showRecentOnly = false;
    });
    if (result.openVideo) await _showPreview(project);
    if (result.createAnother && mounted) await _showCreateFlow();
  }

  Future<void> _saveVideoToLibrary(VideoProject project) async {
    final updatedVideos = [
      project,
      ..._videos.where((video) => video.id != project.id),
    ];
    await _saveVideos(updatedVideos);
    if (!mounted) return;
    setState(() {
      _videos
        ..clear()
        ..addAll(updatedVideos);
      _showRecentOnly = false;
    });
  }

  Future<void> _showPreview(VideoProject video) async {
    try {
      await XFile(video.videoPath).length();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('This video file is unavailable: $error')),
        );
      }
      return;
    }
    return Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => CineClipVideoPreviewScreen(project: video),
      ),
    );
  }

  Future<void> _handleVideoAction(VideoProject video, String action) async {
    if (action == 'open') {
      await _showPreview(video);
      return;
    }
    if (action == 'download') {
      try {
        if (!await Gal.hasAccess()) await Gal.requestAccess();
        await Gal.putVideo(video.videoPath, album: 'CineClip');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Video saved to your Photos gallery.'),
            ),
          );
        }
      } on GalException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.type.message)));
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not download video: $error')),
          );
        }
      }
      return;
    }
    if (action == 'share') {
      try {
        await SharePlus.instance.share(
          ShareParams(
            title: video.title,
            files: [
              XFile(
                video.videoPath,
                mimeType: 'video/mp4',
                name: '${video.title}.mp4',
              ),
            ],
          ),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not share video: $error')),
          );
        }
      }
      return;
    }
    if (action == 'rename') {
      final controller = TextEditingController(text: video.title);
      final title = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _surfaceFor(context),
          title: const Text('Rename video'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLength: 40,
            decoration: const InputDecoration(hintText: 'Video title'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      controller.dispose();
      if (title == null || title.isEmpty || !mounted) return;
      final updatedVideos = [
        for (final item in _videos)
          if (item.id == video.id)
            VideoProject(
              id: item.id,
              title: title,
              videoPath: item.videoPath,
              thumbnailPath: item.thumbnailPath,
              createdAt: item.createdAt,
              durationSeconds: item.durationSeconds,
              caption: item.caption,
              resolutionLabel: item.resolutionLabel,
              aspectRatioLabel: item.aspectRatioLabel,
            )
          else
            item,
      ];
      try {
        await _saveVideos(updatedVideos);
        if (mounted) {
          setState(() {
            _videos
              ..clear()
              ..addAll(updatedVideos);
          });
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not rename video: $error')),
          );
        }
      }
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: _surfaceFor(context),
          title: const Text('Delete video?'),
          content: Text(
            '“${video.title}” and its exported video and thumbnail will be deleted from CineClip storage. The original photos on your device will not be affected.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      final updatedVideos = _videos
          .where((item) => item.id != video.id)
          .toList();
      try {
        await _saveVideos(updatedVideos);
        if (!mounted) return;
        setState(() {
          _videos
            ..clear()
            ..addAll(updatedVideos);
        });
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not delete video: $error')),
          );
        }
        return;
      }
      try {
        await _videoExportService.deleteProjectFiles(video);
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Video was removed from your library, but its files could not be deleted: $error',
              ),
            ),
          );
        }
      }
    }
  }
}

Color _surfaceFor(BuildContext context) {
  return Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF0B1D38)
      : Colors.white;
}

Color _secondaryText(BuildContext context, {double alpha = 0.7}) {
  return Theme.of(context).colorScheme.onSurface.withValues(alpha: alpha);
}

class _VideoCard extends StatelessWidget {
  const _VideoCard({
    required this.video,
    required this.onTap,
    required this.onMenuSelected,
  });

  final VideoProject video;
  final VoidCallback onTap;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  VideoThumbnail(path: video.thumbnailPath),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _DurationBadge(duration: video.duration),
                  ),
                  const Center(
                    child: Icon(
                      Icons.play_circle_fill_rounded,
                      size: 42,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 9, 4, 9),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  _VideoMenu(onSelected: onMenuSelected),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryVideoTile extends StatelessWidget {
  const _LibraryVideoTile({
    required this.video,
    required this.onTap,
    required this.onMenuSelected,
  });

  final VideoProject video;
  final VoidCallback onTap;
  final ValueChanged<String> onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _surfaceFor(context),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 104,
          child: Row(
            children: [
              SizedBox(
                width: 132,
                height: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoThumbnail(path: video.thumbnailPath),
                    Center(
                      child: Icon(
                        Icons.play_circle_fill_rounded,
                        size: 38,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                    ),
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: _DurationBadge(duration: video.duration),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      video.date,
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      video.resolutionLabel,
                      style: TextStyle(
                        color: _secondaryText(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _VideoMenu(onSelected: onMenuSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoMenu extends StatelessWidget {
  const _VideoMenu({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Video options',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'open', child: Text('Open Video')),
        PopupMenuItem(value: 'download', child: Text('Download Video')),
        PopupMenuItem(value: 'share', child: Text('Share Video')),
        PopupMenuItem(value: 'rename', child: Text('Rename')),
        PopupMenuItem(value: 'delete', child: Text('Delete Video')),
      ],
      icon: const Icon(Icons.more_vert_rounded, size: 20),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.duration});

  final String duration;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(duration, style: const TextStyle(fontSize: 11)),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: _blue,
      backgroundColor: _surfaceFor(context),
      side: BorderSide(
        color: selected ? _cyan.withValues(alpha: 0.55) : Colors.transparent,
      ),
      labelStyle: TextStyle(
        color: selected ? Colors.white : _secondaryText(context),
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
