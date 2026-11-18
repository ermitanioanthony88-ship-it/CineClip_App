# CineClip -- Added Improvements

## UI Organization, Video Editor Enhancements, Text Editing, and Export Settings

**Document type:** UI/UX and functional improvement requirements\
**Application:** CineClip -- Image-to-Video Flutter App\
**Purpose:** Organize the existing screens around the supplied wireframe
and improve the editing experience without removing useful features
already present.

------------------------------------------------------------------------

## 1. Project Goal

Improve CineClip so users can move through a clear image-to-video
workflow:

1.  Open CineClip.
2.  Choose photos.
3.  Arrange and edit the photos.
4.  Add motion, transitions, music, and text.
5.  Preview the complete video.
6.  Choose video quality and aspect ratio.
7.  Export the finished MP4.
8.  Open, share, or manage the exported video in the Library.

Use the supplied CineClip wireframe as the main guide for screen order
and visual organization. Keep the existing dark navy background, bright
blue/cyan accents, rounded controls, readable typography, and simple
navigation.

**Important implementation rule:** Inspect the current Flutter project
before changing it. Reuse working screens, widgets, data models, and
services where possible. Do not assume a feature works just because its
button is visible. Do not replace real functionality with sample data or
placeholder success messages.

------------------------------------------------------------------------

## 2. Main Design Principles

-   **Simple workflow:** Each screen should have one main purpose and
    one clear primary action.
-   **Consistent design:** Use the same colors, spacing, button styles,
    field styles, and icon treatment throughout the app.
-   **Mobile-first layout:** The app must remain usable on smaller
    Android screens.
-   **Visible progress:** Show users where they are in the creation
    process.
-   **Real editing feedback:** A selected setting should affect the
    preview and, where supported, the final exported video.
-   **Avoid crowded screens:** Group related settings into expandable
    sections or clearly separated panels.
-   **Safe actions:** Confirm destructive actions such as clearing all
    photos or deleting an exported video.
-   **Preserve user work:** Navigating backward should not unexpectedly
    erase selected photos or editing settings.

------------------------------------------------------------------------

## 3. Recommended App Workflow and Screen Organization

Follow this overall sequence:

### Screen 1 -- Splash Screen

-   Display the CineClip logo and tagline: **Turn Moments Into Movies**.
-   Use a short, simple loading animation.
-   Navigate to onboarding for first-time users, or Home for returning
    users.
-   Do not keep users on the splash screen longer than necessary.

### Screens 2--4 -- Onboarding

Use three short onboarding pages based on the supplied wireframe:

1.  **Your Photos, Your Story** -- Turn favorite photos into videos.
2.  **Make It Move** -- Add smooth motion and transitions.
3.  **Save and Share** -- Export and share finished videos.

Include page indicators, Next, and Get Started. Allow users to skip
onboarding if appropriate.

### Screen 5 -- Home

Organize the Home screen into:

-   Top bar: CineClip logo/name and Settings icon.
-   Welcome heading: **Create Videos Easily**.
-   Short supporting text.
-   Prominent **Create New Video** button.
-   **Recent Videos** section with thumbnail cards.
-   **See All** action to open Library.
-   Bottom navigation: Home and Library, if that is the chosen
    navigation pattern.

Each recent video card should show: - Thumbnail. - Video title. -
Duration. - Optional date or resolution. - Overflow menu for available
actions.

When there are no exported videos, show a helpful empty state and a
Create New Video action. Do not display invented recent videos in the
real Library.

### Screen 6 -- Select Images

-   Provide a clear **Choose Photos** area that opens the device gallery
    or supported file picker.
-   Support selecting multiple images.
-   Display selected image thumbnails.
-   Show the selected photo count.
-   Allow users to remove an individual photo.
-   Provide a clear selection confirmation/Next action.
-   Prevent proceeding when no valid image is selected.
-   Preserve selection if the user returns from the editor, unless they
    choose to clear it.

### Screens 7--8 -- Video Editor and Preview

The editor should be organized into manageable sections. The preview
should show the result of the current editing settings.

### Screens 9--10 -- Exporting and Export Complete

-   Show real export progress when available.
-   Show an error state if export fails.
-   Only show Export Complete after the MP4 has actually been created
    and saved.
-   Provide Open Video, Share, and return-to-Home/Library actions where
    supported.

### Screen 11 -- Library

-   Show saved/exported videos from the app's real storage source.
-   Include All Videos and Recent filters/tabs if useful.
-   Provide search if the Library grows large.
-   Each item should show a thumbnail, title, date, and duration.
-   Provide Open/Play, Share, Rename, and Delete actions where
    implemented.
-   Confirm before deleting.
-   Refresh the Library after export, rename, or deletion.

------------------------------------------------------------------------

## 4. Video Editor -- Recommended Organization

The supplied screenshots show useful editor features, but the current
form is long and requires considerable scrolling. Keep the features, but
group them into a clearer editing layout.

### 4.1 Editor Header and Progress

At the top: - Back button. - Screen title: **Video Editor**. -
Three-step progress indicator: 1. Photos and editing. 2. Style and
settings. 3. Preview and export.

The progress indicator should reflect the user's actual workflow, not
just be decorative.

### 4.2 Preview Area

Near the top of the editor, show a large preview of the current video or
selected scene.

Include: - Play/Pause. - Playback progress. - Current time and total
duration. - Full-screen preview button. - Clear loading or empty state
if a preview cannot yet be generated.

The preview must use the current photo order and the editing settings
that have actually been implemented. If it is only a still-image
preview, do not present it as a fully rendered video preview.

### 4.3 Photo Timeline

Place the photo timeline immediately below the preview.

Controls: - **Add Photos** - **Clear All**, with a confirmation
dialog. - Drag-and-drop reordering. - Up and Down buttons as an
accessible alternative to dragging. - Remove photo action. - Selected
photo highlight. - Photo thumbnail, sequence number, and duration.

Show a summary such as:

`3 photos · 3 seconds per photo · Estimated total 0:08`

The estimated total should be recalculated whenever photo durations or
transition settings change. Clearly define whether the estimate includes
transition overlap.

### 4.4 Video Style

Provide two clear style choices:

-   **Full Frame:** Each photo fills the video frame according to the
    selected aspect ratio and fit/crop behavior.
-   **Comic Page:** Photos or panels are arranged in a comic-page
    layout.

The selected style must be visually obvious. Switching styles should not
unexpectedly delete photos or text.

------------------------------------------------------------------------

## 5. Put Video Quality and Aspect Ratio Inside the Video Editor

**Required improvement:** Move Video Quality and Aspect Ratio controls
from the separate Preview & Export settings area into the Video Editor.

Place a dedicated **Output Settings** section in the editor. It can
appear after the main visual editing controls and before the final
Preview & Export action.

### 5.1 Video Quality

Provide quality choices supported by the actual export implementation,
for example:

-   480p
-   720p
-   1080p

Requirements: - Show the selected quality. - Explain briefly that higher
quality generally creates a larger file and may take longer to export. -
Do not offer a quality setting that the renderer cannot produce. - Keep
a sensible default, such as 720p, if supported. - Apply the chosen
output dimensions to the actual MP4 export, not only to the UI.

### 5.2 Aspect Ratio

Provide these common formats:

  Aspect ratio     Suggested use
  ---------------- -------------------------------------------------
  16:9 Landscape   YouTube and landscape viewing
  9:16 Portrait    Reels, Shorts, and TikTok-style vertical videos
  1:1 Square       Square social posts

Requirements: - Show the ratio name and a small visual preview if
practical. - Update the preview frame when the user changes the ratio. -
Define how photos are fitted: crop/fill or contain/letterbox. - Keep
text and important content inside safe margins. - Ensure the final
exported MP4 uses the selected dimensions and framing. - Avoid
stretching photos to fit.

### 5.3 Preview & Export Screen

After moving these settings into the editor, simplify Preview & Export.

It should focus on: - Large final video preview. - Play/Pause and
timeline controls. - Video title. - Selected video style. - Photo count
and estimated duration. - Selected music, if any. - A concise summary of
quality and aspect ratio, shown as read-only information or an Edit
Settings shortcut. - **Edit Again** - **Export Video**

Do not make users configure the same quality and ratio a second time on
the Preview screen.

------------------------------------------------------------------------

## 6. Text Editing -- Directly on the Video, CapCut-Inspired

**Required improvement:** Upgrade the current optional text field and
dropdown controls into a direct on-preview text editing experience
inspired by common mobile video editors such as CapCut.

This means users should be able to see text over the video and
manipulate its placement visually. The goal is to provide familiar
editing behavior, not to copy another app's branding or exact interface.

### 6.1 Text Overlay Entry

Add a clear **Text** or **Add Text** action in the editor.

When tapped: - Create a new text overlay. - Show an editable text box
over the preview. - Open the keyboard or a text-entry panel. - Let the
user type and confirm the text. - Keep the overlay selected after text
entry so the user can style and position it.

Support more than one text overlay if practical. Each overlay should be
independently editable and removable.

### 6.2 Direct Manipulation on the Preview

When a text overlay is selected, allow the user to:

-   Drag it to a new position on the video.
-   Resize it using visible corner handles, or use a simple size control
    if gesture resizing is too complex for the first implementation.
-   Rotate it if practical.
-   Tap it to edit its wording.
-   Use a selection outline/handles to show which text item is active.
-   Deselect it by tapping an empty area of the preview.

On touch devices, avoid making drag gestures interfere with the video
playback controls. Provide a clear selected state and sensible touch
targets.

### 6.3 Text Styling Panel

Organize text controls into a compact panel:

**Font** - Sans Serif default. - A small selection of additional fonts
supported by the app. - Use only fonts that can also be rendered during
MP4 export.

**Size** - Adjustable text size. - Keep text within the video frame. -
Prevent text from becoming too small or too large to use.

**Color** - White, black, and a practical color palette. - Optional
custom color picker if feasible.

**Text appearance** - Bold. - Italic, if supported. - Outline/stroke for
readability. - Background/highlight box. - Shadow, if supported.

**Alignment** - Left. - Center. - Right.

**Position** - Drag directly on the preview. - Optional quick positions:
Top, Center, Bottom.

**Text actions** - Duplicate. - Delete. - Bring Forward / Send Backward
if multiple overlays are supported.

### 6.4 Text Timing

Text should not automatically appear throughout the entire video unless
the user chooses that behavior.

For each text overlay, provide: - Start time. - End time or duration. -
A simple way to choose which scene/photo it belongs to. - An optional
Apply to All Photos action for users who want a title or watermark
across the whole video.

At minimum, support assigning text to a selected photo/scene. More
advanced timeline trimming can be added later.

### 6.5 Comic Page Text

For Comic Page style, provide comic-specific options where practical: -
Speech bubble. - Thought bubble. - Caption box. - Editable bubble
text. - Adjustable bubble placement and size.

Keep comic text and ordinary video text as clearly named choices. Do not
force users to use speech bubbles in Full Frame mode.

### 6.6 Text Export Requirements

The text seen in the final preview must appear in the exported MP4.

-   Preserve font, color, size, alignment, position, rotation, and
    style.
-   Preserve each overlay's start and end timing.
-   Scale overlay positions correctly for 16:9, 9:16, and 1:1 output.
-   Keep text inside safe margins.
-   Ensure text remains readable over bright and dark photos.
-   Do not treat a Flutter-only overlay as complete export support. The
    rendering service must draw the text into the final video frames.

------------------------------------------------------------------------

## 7. Motion, Transitions, Music, and Scene Settings

Keep these controls grouped so the editor remains understandable.

### 7.1 Photo Duration

-   Allow an individual duration for each photo.
-   Provide a Set All Photo Durations option.
-   Display duration in seconds.
-   Recalculate estimated total duration after changes.

### 7.2 Photo Motion

Provide a motion-effect selector: - None - Slow Zoom In - Slow Zoom
Out - Pan Left - Pan Right

Provide Low, Medium, and High intensity if supported. The effect should
be visible in preview and reproduced by the MP4 renderer.

### 7.3 Transitions

Provide a transition selector: - Cut - Fade - Dissolve - Slide Left -
Slide Right - Page Turn, especially for Comic Page mode if supported.

Include: - Transition duration. - Apply to All. - Apply to Selected, if
supported. - Preview Transition.

A transition is between scenes/pages. Do not confuse transition duration
with the duration of an individual photo. Define how transitions affect
total video length.

### 7.4 Background Music

Provide: - Built-in music selection, if licensed/original tracks are
included. - Device audio file selection, if supported. - Play/Pause
preview. - Replace and Remove. - Volume. - Optional fade-in/fade-out and
trim controls in a later phase.

Show the selected track name. Handle music that is shorter or longer
than the video. Use only music the app owns, the user owns, or the user
is licensed to use.

------------------------------------------------------------------------

## 8. Recommended Editor Section Order

Use this order to reduce unnecessary scrolling and make the workflow
easier to understand:

1.  **Preview** -- See the current result.
2.  **Photos and Timeline** -- Add, remove, and reorder photos.
3.  **Video Style** -- Full Frame or Comic Page.
4.  **Text and Captions** -- Add and edit text directly on the preview.
5.  **Photo Duration** -- Individual duration and Set All.
6.  **Motion** -- Ken Burns effects and intensity.
7.  **Transitions** -- Effect and duration.
8.  **Background Music** -- Track and volume.
9.  **Output Settings** -- Video quality and aspect ratio.
10. **Preview & Export** -- Continue to the final review.

On smaller screens, use collapsible sections or tabs for secondary
controls. Keep the main Preview & Export action easy to find without
covering important content.

------------------------------------------------------------------------

## 9. Preview & Export Requirements

The Preview & Export screen should be a final review, not another full
settings form.

Show: - Video playback preview. - Video title. - Style and motion
summary. - Photo count. - Estimated duration. - Music summary. - Output
quality. - Aspect ratio. - Edit Again button. - Export Video button.

When Export Video is tapped: 1. Validate the project. 2. Check that at
least one valid photo exists. 3. Check that selected media files are
still accessible. 4. Confirm that the requested quality, ratio, text,
motion, transitions, and audio are supported by the renderer. 5. Start
actual MP4 rendering. 6. Show progress if the rendering service provides
reliable progress information. 7. Handle cancellation or failure where
supported. 8. Save the resulting MP4 to the app's chosen output
location. 9. Show Export Complete only after verifying that the output
file exists and is usable.

The completed screen should provide: - Open Video. - Share. - Go to
Library. - Return Home.

Never display a fake 100% progress state or success message before the
file has been successfully created.

------------------------------------------------------------------------

## 10. Library and Home Improvements

### Home

-   Keep Create New Video prominent.
-   Show real recent exports.
-   Add See All navigation to Library.
-   Show a helpful empty state when no videos exist.
-   Keep Settings accessible from the Home header.

### Library

-   Show actual saved MP4 files.
-   Display thumbnail, title, date, and duration.
-   Include All Videos and Recent views if useful.
-   Support Open/Play, Share, Rename, and Delete where implemented.
-   Confirm deletion.
-   Refresh the list after changes.

Home Recent Videos and Library should use the same source of saved-video
records so their information does not disagree.

------------------------------------------------------------------------

## 11. Technical Organization Suggestions for Flutter

These are suggested responsibilities, not mandatory filenames. Adapt
them to the project's current folder structure and architecture.

  -----------------------------------------------------------------------
  Area                                Suggested responsibility
  ----------------------------------- -----------------------------------
  `video_editor_screen.dart`          Main editor layout and section
                                      navigation

  `photo_timeline_widget.dart`        Photo thumbnails, reordering,
                                      removal, duration

  `text_overlay_editor.dart`          Text selection, styling,
                                      positioning, timing

  `video_output_settings.dart`        Quality and aspect-ratio controls

  `video_preview_screen.dart`         Final preview and project summary

  `export_screen.dart`                Export progress, result, and errors

  `video_project.dart`                Project data and editing settings

  `text_overlay.dart`                 Text content, style, position, and
                                      timing data

  `video_export_service.dart`         Actual MP4 rendering and saving

  `library_screen.dart`               Listing and managing saved videos
  -----------------------------------------------------------------------

Keep UI code separate from rendering logic where possible. Store editor
settings in a project model instead of relying on temporary widget state
that disappears when navigating between screens.

### Suggested project data

A video project should be able to retain: - Project/video title. -
Selected photo file references and order. - Per-photo duration. - Motion
effect and intensity. - Transition type and duration. - Text overlays
and their timing. - Background audio reference and volume. - Video
style. - Output quality. - Aspect ratio.

Use persistent local storage if projects are expected to survive app
restarts. Ensure temporary media files are handled safely and do not
become broken references.

------------------------------------------------------------------------

## 12. Testing and Acceptance Checklist

### Navigation and layout

-   [ ] Splash and onboarding lead to the correct next screen.
-   [ ] Home opens Select Images.
-   [ ] Back navigation preserves the project.
-   [ ] Editor sections are readable on a small phone.
-   [ ] Preview & Export shows the latest project settings.

### Photos and timeline

-   [ ] Multiple photos can be selected.
-   [ ] Photos can be removed and reordered.
-   [ ] Timeline order matches preview order.
-   [ ] Duration changes update the estimated video duration.

### Text editing

-   [ ] Text can be added.
-   [ ] Text can be edited after creation.
-   [ ] Text can be dragged on the preview.
-   [ ] Styling changes update the preview.
-   [ ] Text timing is respected.
-   [ ] Multiple overlays remain independently editable if supported.

### Output settings

-   [ ] Quality selection updates the project.
-   [ ] Aspect-ratio selection updates preview framing.
-   [ ] Unsupported output settings are not offered.
-   [ ] Export uses the selected dimensions and quality.

### Motion, transitions, and music

-   [ ] Motion settings affect the preview.
-   [ ] Transitions work between scenes.
-   [ ] Transition duration is handled correctly.
-   [ ] Music preview, volume, replace, and remove work where
    implemented.
-   [ ] Exported audio matches the selected soundtrack and volume.

### Export and Library

-   [ ] A valid MP4 is created.
-   [ ] Export failures show a useful error.
-   [ ] Export Complete appears only after successful file creation.
-   [ ] The exported video can be opened.
-   [ ] The exported video appears in Library.
-   [ ] Share and delete actions work where implemented.

### Git workflow

-   [ ] Work is developed on a descriptive feature branch.
-   [ ] `flutter analyze` has no new errors.
-   [ ] Relevant tests pass.
-   [ ] Changes are committed with a clear message.
-   [ ] The feature branch is reviewed before merging into `main`.

------------------------------------------------------------------------

## 13. Recommended Implementation Phases

Do not attempt to implement every improvement in one session. Complete
and test one phase at a time.

### Phase 1 -- Reorganize the Existing Editor

-   Reorder the editor sections.
-   Improve spacing and labels.
-   Keep the photo timeline clear.
-   Move Video Quality and Aspect Ratio into the editor.
-   Simplify Preview & Export.

**Completion condition:** Users can navigate the editor comfortably and
configure output settings before opening the final preview.

### Phase 2 -- Direct Text Editing

-   Add text overlay creation.
-   Edit text directly on the preview.
-   Add drag positioning.
-   Add font, size, color, alignment, and basic appearance options.
-   Save text overlay data in the video project.

**Completion condition:** Users can add, select, move, edit, and remove
text overlays without losing their work.

### Phase 3 -- Text and Settings in MP4 Rendering

-   Pass text overlay data to the rendering service.
-   Render text with the correct appearance and timing.
-   Apply the selected quality and aspect ratio.
-   Test the exported video on a real device.

**Completion condition:** Exported MP4 matches the editor's text
placement and output settings.

### Phase 4 -- Finish the Video Workflow

-   Verify motion and transitions in the renderer.
-   Integrate background music.
-   Improve export progress and error handling.
-   Verify saved files and Library updates.

**Completion condition:** A user can create a video from photos, edit
it, preview it, export an MP4, and find the result in Library.

### Phase 5 -- Final UI Polish and Testing

-   Test small and large phone screens.
-   Improve empty, loading, and error states.
-   Check navigation and project persistence.
-   Fix visual inconsistencies.
-   Review the feature branches and merge completed work.

**Completion condition:** The core workflow is reliable and
understandable from first launch to exported video.

------------------------------------------------------------------------

## 14. Final Development Instruction

Improve the existing CineClip application using the supplied screenshots
and wireframe as design references. Prioritize a clean, connected user
workflow over adding more buttons.

The most important requested changes are:

1.  Reorganize the Video Editor into clear sections.
2.  Move Video Quality and Aspect Ratio into the Video Editor.
3.  Make text editable directly on the video preview, with drag
    positioning and familiar mobile editing controls.
4.  Ensure text, motion, transitions, music, quality, and aspect ratio
    are reflected in the final MP4.
5.  Keep Preview & Export focused on reviewing and exporting.
6.  Keep Home and Library connected to real saved videos.
7.  Preserve working features and test each change before merging.

**Definition of a successful CineClip improvement:** The controls are
not merely visible. The user can change a setting, see the correct
result in the preview, export the video, and confirm that the MP4
contains the same intended result.
