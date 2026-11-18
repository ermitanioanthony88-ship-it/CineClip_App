import 'video_export_contract.dart';

double videoDurationSeconds({
  required List<int> sceneDurations,
  required VideoTransition transition,
  required double transitionDuration,
}) {
  if (sceneDurations.isEmpty) return 0;
  final sceneTime = sceneDurations.fold<int>(
    0,
    (total, duration) => total + duration,
  );
  final overlap = transition == VideoTransition.cut ? 0 : transitionDuration;
  return (sceneTime - (sceneDurations.length - 1) * overlap).toDouble();
}
