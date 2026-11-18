import 'dart:convert';

import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cineclip/home_screen.dart';
import 'package:cineclip/comic_panel_layout.dart';
import 'package:cineclip/image_motion_preview.dart';
import 'package:cineclip/main.dart';
import 'package:cineclip/settings_screen.dart';
import 'package:cineclip/video_export_contract.dart';
import 'package:cineclip/video_timing.dart';

void main() {
  test('video editor exposes the final motion and soundtrack options', () {
    expect(ImageMotion.values, hasLength(8));
    expect(
      ImageMotion.values.map((motion) => motion.label),
      containsAll([
        'Slow Zoom In',
        'Slow Zoom Out',
        'Pan Left',
        'Pan Right',
        'Pan Up',
        'Pan Down',
        'Fade In',
        'Fade Out',
      ]),
    );
    expect(
      BuiltInMusicTrack.values.where(
        (track) => track != BuiltInMusicTrack.none,
      ),
      hasLength(8),
    );
    expect(
      BuiltInMusicTrack.values.map((track) => track.label),
      containsAll([
        'Cinematic',
        'Happy',
        'Romantic',
        'Emotional',
        'Adventure',
        'Relaxing',
        'Comedy',
        'Dramatic',
      ]),
    );
    expect(
      BuiltInMusicTrack.values
          .where((track) => track != BuiltInMusicTrack.none)
          .every((track) => track.tempo > 0 && track.rootFrequency > 0),
      isTrue,
    );
    expect(VideoStyle.values, hasLength(2));
    expect(
      VideoStyle.values.map((style) => style.label),
      containsAll(['Full Frame', 'Comic Page']),
    );
    expect(ComicTemplate.values, hasLength(5));
    expect(
      ComicTemplate.values.map((template) => template.label),
      containsAll([
        'Four-Panel Layout',
        'Six-Panel Layout',
        'Hero Panel Layout',
        'Dynamic Comic Layout',
        'Vertical Comic Layout',
      ]),
    );
    expect(VideoAspectRatio.values, hasLength(3));
    expect(VideoTransition.values, hasLength(8));
    expect(
      VideoTransition.pageTurn.ffmpegName,
      isNot(VideoTransition.wipe.ffmpegName),
    );
  });

  test('comic templates produce complete, non-overlapping page layouts', () {
    for (final template in ComicTemplate.values) {
      final panels = comicPanelLayout(template);
      expect(panels, hasLength(template.panelCount));
      for (var index = 0; index < panels.length; index++) {
        final panel = panels[index];
        expect(panel.left, greaterThanOrEqualTo(0));
        expect(panel.top, greaterThanOrEqualTo(0));
        expect(panel.right, lessThanOrEqualTo(1));
        expect(panel.bottom, lessThanOrEqualTo(1));
        for (final other in panels.skip(index + 1)) {
          expect(panel.overlaps(other), isFalse);
        }
      }
    }
  });

  test('scene duration matches the selected transition behavior', () {
    expect(
      videoDurationSeconds(
        sceneDurations: [3, 5, 2],
        transition: VideoTransition.fade,
        transitionDuration: 0.5,
      ),
      9,
    );
    expect(
      videoDurationSeconds(
        sceneDurations: [3, 5, 2],
        transition: VideoTransition.cut,
        transitionDuration: 0.5,
      ),
      10,
    );
    expect(
      videoDurationSeconds(
        sceneDurations: [4],
        transition: VideoTransition.pageTurn,
        transitionDuration: 1,
      ),
      4,
    );
  });

  testWidgets('preview text and comic bubble can be selected and moved', (
    tester,
  ) async {
    final photo = XFile.fromData(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8'
        '/x8AAwMCAO+/r9sAAAAASUVORK5CYII=',
      ),
      name: 'preview.png',
    );
    final captionController = TextEditingController(text: 'Title');
    final bubbleController = TextEditingController(text: 'Bubble');
    final captionFocusNode = FocusNode();
    final bubbleFocusNode = FocusNode();
    var captionPosition = const Offset(0.5, 0.5);
    var bubblePosition = const Offset(0.75, 0.25);
    var captionEditing = false;
    var bubbleEditing = false;
    late StateSetter rebuild;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Scaffold(
              body: Center(
                child: SizedBox(
                  width: 360,
                  child: ImageMotionPreview(
                    photos: [photo],
                    sceneDurations: const [3],
                    motion: ImageMotion.zoomIn,
                    secondsPerPhoto: 3,
                    style: VideoStyle.comicPanel,
                    caption: captionController.text,
                    speechBubble: bubbleController.text,
                    captionPosition: captionPosition,
                    captionSelected: true,
                    captionEditing: captionEditing,
                    captionController: captionController,
                    captionFocusNode: captionFocusNode,
                    interactiveCaption: true,
                    onCaptionTap: () => setState(() => captionEditing = true),
                    onCaptionChanged: (_) => setState(() {}),
                    onCaptionPositionChanged: (position) {
                      setState(() => captionPosition = position);
                    },
                    onCaptionSubmitted: (_) =>
                        setState(() => captionEditing = false),
                    speechBubblePosition: bubblePosition,
                    speechBubbleSelected: true,
                    speechBubbleEditing: bubbleEditing,
                    speechBubbleController: bubbleController,
                    speechBubbleFocusNode: bubbleFocusNode,
                    interactiveSpeechBubble: true,
                    onSpeechBubbleTap: () =>
                        setState(() => bubbleEditing = true),
                    onSpeechBubbleChanged: (_) => setState(() {}),
                    onSpeechBubblePositionChanged: (position) {
                      setState(() => bubblePosition = position);
                    },
                    onSpeechBubbleSubmitted: (_) =>
                        setState(() => bubbleEditing = false),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final initialBubblePosition = bubblePosition;
    await tester.drag(find.text('Bubble'), const Offset(24, 20));
    await tester.pump();
    expect(bubblePosition, isNot(initialBubblePosition));

    await tester.tap(find.text('Bubble'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Updated bubble');
    await tester.pump();
    expect(bubbleController.text, 'Updated bubble');
    rebuild(() => bubbleEditing = false);
    await tester.pump();
    expect(find.byType(TextField), findsNothing);

    final initialCaptionPosition = captionPosition;
    await tester.drag(find.text('Title'), const Offset(24, -18));
    await tester.pump();
    expect(captionPosition, isNot(initialCaptionPosition));

    await tester.tap(find.text('Title'));
    await tester.pump();
    expect(find.byType(TextField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Updated title');
    await tester.pump();
    expect(captionController.text, 'Updated title');

    await tester.pumpWidget(const SizedBox.shrink());
    captionFocusNode.dispose();
    bubbleFocusNode.dispose();
    captionController.dispose();
    bubbleController.dispose();
  });

  testWidgets('empty library opens a creation flow that validates photos', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(
      MaterialApp(home: CineClipHomeScreen(onOpenSettings: _noop)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your first video is waiting'), findsOneWidget);
    expect(find.text('Mountain Memories'), findsNothing);

    await tester.tap(find.byType(NavigationDestination).last);
    await tester.pumpAndSettle();
    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.text('Create New Video'), findsOneWidget);

    await tester.tap(find.text('Create New Video'));
    await tester.pumpAndSettle();
    expect(find.text('Choose Photos'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Choose at least one photo to continue.'), findsOneWidget);
    expect(find.text('My New Story'), findsNothing);
  });

  testWidgets('settings persist appearance and notification preferences', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    ThemeMode selectedTheme = ThemeMode.system;
    await tester.pumpWidget(
      MaterialApp(
        home: CineClipSettingsScreen(
          themeMode: selectedTheme,
          onThemeModeChanged: (mode) async {
            selectedTheme = mode;
            final preferences = await SharedPreferences.getInstance();
            await preferences.setString(
              settingsThemeModeKey,
              mode == ThemeMode.dark ? 'dark' : 'system',
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Reset Settings to Default'), findsOneWidget);

    await tester.tap(find.text('Appearance'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();
    expect(selectedTheme, ThemeMode.dark);
    expect(
      (await SharedPreferences.getInstance()).getString(settingsThemeModeKey),
      'dark',
    );

    await tester.tap(find.text('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable Notifications'));
    await tester.pumpAndSettle();
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'settings_notifications_enabled',
      ),
      isFalse,
    );
  });

  testWidgets('onboarding shows once and remains complete after relaunch', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CineClipApp());

    expect(find.text('Turn Moments Into Movies'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 4999));
    expect(find.text('Turn Moments Into Movies'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('Your Photos,\nYour Story'), findsOneWidget);
    expect(find.text('Turn Moments Into Movies'), findsNothing);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Make It Move'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Save and Share'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.text('Create Videos Easily'), findsOneWidget);
    final onboardingCompleted =
        (await SharedPreferences.getInstance()).getBool(
          'onboarding_completed',
        ) ??
        false;
    expect(onboardingCompleted, isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      CineClipApp(onboardingCompleted: onboardingCompleted),
    );
    await tester.pumpAndSettle();
    expect(find.text('Turn Moments Into Movies'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Create Videos Easily'), findsOneWidget);
    expect(find.text('Your Photos,\nYour Story'), findsNothing);
  });
}

void _noop() {}
