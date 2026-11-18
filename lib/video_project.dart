class VideoProject {
  const VideoProject({
    required this.id,
    required this.title,
    required this.videoPath,
    required this.thumbnailPath,
    required this.createdAt,
    required this.durationSeconds,
    this.caption = '',
    this.resolutionLabel = '720p',
    this.aspectRatioLabel = '16:9 Landscape',
  });

  final String id;
  final String title;
  final String videoPath;
  final String thumbnailPath;
  final String createdAt;
  final int durationSeconds;
  final String caption;
  final String resolutionLabel;
  final String aspectRatioLabel;

  String get duration {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String get date {
    final created = DateTime.tryParse(createdAt)?.toLocal();
    if (created == null) return 'Unknown date';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final createdDay = DateTime(created.year, created.month, created.day);
    final daysAgo = today.difference(createdDay).inDays;
    if (daysAgo == 0) {
      return 'Today';
    }
    if (daysAgo == 1) {
      return 'Yesterday';
    }
    return '${created.month}/${created.day}/${created.year}';
  }

  Map<String, Object> toJson() => {
    'id': id,
    'title': title,
    'videoPath': videoPath,
    'thumbnailPath': thumbnailPath,
    'createdAt': createdAt,
    'durationSeconds': durationSeconds,
    'caption': caption,
    'resolutionLabel': resolutionLabel,
    'aspectRatioLabel': aspectRatioLabel,
  };

  factory VideoProject.fromJson(Map<String, Object?> json) {
    return VideoProject(
      id: json['id']! as String,
      title: json['title']! as String,
      videoPath: json['videoPath']! as String,
      thumbnailPath: json['thumbnailPath']! as String,
      createdAt: json['createdAt']! as String,
      durationSeconds: json['durationSeconds']! as int,
      caption: json['caption'] as String? ?? '',
      resolutionLabel: json['resolutionLabel'] as String? ?? '720p',
      aspectRatioLabel:
          json['aspectRatioLabel'] as String? ?? '16:9 Landscape',
    );
  }
}

class VideoExportResult {
  const VideoExportResult({
    required this.project,
    required this.openVideo,
    this.goToLibrary = false,
    this.createAnother = false,
  });

  final VideoProject project;
  final bool openVideo;
  final bool goToLibrary;
  final bool createAnother;
}
