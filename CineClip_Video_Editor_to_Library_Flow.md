# CineClip – Video Editor to Library Flow

**Tagline:** Turn Moments Into Movies

## 1. Purpose

This document describes the user journey from editing selected photos in CineClip through previewing, exporting, and finding the finished video in the Library.

CineClip focuses on turning still pictures into memorable videos. Users arrange photos, add motion effects, customize the result, preview it, and export it as a video.

## 2. Overall User Flow

```text
VIDEO EDITOR
    |
    v
PREVIEW VIDEO
    | Edit Again
    +--------------------> VIDEO EDITOR
    |
    | Export Video
    v
EXPORT SETTINGS
    |
    v
EXPORTING
    |
    +---- Failed ----> ERROR / RETRY
    |
    | Successful
    v
EXPORT COMPLETE
    |
    +---- Open Video
    +---- Share
    |
    v
LIBRARY
    |
    v
VIEW OR MANAGE EXPORTED VIDEO
```

## 3. Video Editor

### Purpose
The Video Editor is where users arrange selected photos and customize how they appear and move in the final video.

### 3.1 Photo Timeline
- Display each selected photo as a thumbnail.
- Show the order of the photos.
- Allow drag-and-drop reordering.
- Keep move-up and move-down buttons as alternatives.
- Allow users to add or remove photos.
- Show each photo's duration.
- Provide a Clear All option with a confirmation dialog.

**Behavior:** The final video follows the timeline order. Removing a photo from the timeline must not delete the original photo from the device.

### 3.2 Photo Animation
Suggested options:
- None
- Slow Zoom In
- Slow Zoom Out
- Pan Left
- Pan Right
- Pan Up
- Pan Down
- Fade In
- Fade Out

**Motion Intensity:**
- Low – subtle movement.
- Medium – noticeable movement.
- High – more pronounced movement.

Allow users to preview the selected effect. Clearly indicate the selected option.

### 3.3 Photo Duration
- Display the current duration in seconds.
- Provide a slider or numeric selector.
- If supported, allow a common duration for all photos or an individual duration per photo.
- Update the estimated total video duration when durations change.
- Clearly indicate whether the duration applies to all photos or only the selected photo.

### 3.4 Video Layout
Initial options:
- **Full Frame:** Displays one photo across the video frame.
- **Comic Panel:** Arranges photos in a comic-inspired panel layout.

Show a sample or thumbnail for each layout and let users preview the selected layout.

### 3.5 Text Customization
Suggested controls:
- Add or edit text.
- Font selection.
- Text size and color.
- Text alignment: left, center, or right.
- Text position: top, center, or bottom.

Show text in the preview and allow users to edit or remove it.

### 3.6 Background Music
- Browse built-in music tracks.
- Choose music from the device, if supported.
- Play or pause a music preview.
- Adjust music volume.
- Replace or remove the selected track.
- Adjust music start and end points, if supported.

Only use audio that the user has permission to use.

### 3.7 Additional Editing Options
These can be added as the project develops:
- **Aspect Ratio:** 16:9 landscape, 9:16 portrait, and 1:1 square.
- **Image Cropping:** Adjust how a photo fits the video frame.
- **Photo Filters:** Vintage, Warm, Cool, and Black and White.
- **Transitions:** Fade, Slide, Dissolve, and Wipe between photos.

### 3.8 Main Editor Actions
- **Preview:** Opens the Preview screen.
- **Add Photos:** Opens the photo picker.
- **Back:** Returns to the previous screen. If there are unsaved changes, ask whether to save as a draft, discard changes, or continue editing.
- **Clear All:** Removes photos from the current project after confirmation. It must not delete originals from the device.

## 4. Preview Screen

### Purpose
Allows users to review the complete photo-based video before exporting.

### Content and controls
- Large video preview.
- Play and pause controls.
- Playback progress bar.
- Current playback time and total duration.
- Edit Again button.
- Export Video button.

### Behavior
- Play photos in the selected order.
- Apply the selected motion, layout, text, transitions, and music.
- **Edit Again** returns to the Video Editor while preserving the project.
- **Export Video** opens Export Settings.
- If preview generation fails, show an understandable error and allow another attempt.

## 5. Export Settings

### Purpose
Allows users to confirm the output settings.

### Content and controls
- **Video Quality / Resolution:** 480p, 720p, or 1080p, depending on what the app supports.
- **Aspect Ratio:** Show the selected ratio if configured in the editor.
- **Estimated File Size:** Show only if the app can calculate a reasonable estimate.
- Export button.
- Back button.

### Behavior
- Show the selected resolution before export.
- Explain that higher resolutions may take longer and create larger files.
- Preserve the editing project if the user returns to the editor.
- Offer only formats the app can actually generate.

## 6. Exporting Screen

### Content and controls
- Progress indicator or progress bar.
- Status message, such as "Creating your video..."
- Percentage only if accurate progress is available.

### Behavior
- Prevent duplicate export requests while an export is in progress.
- Keep the user informed.
- If export fails, show an understandable error and a Retry option.
- Do not show success until the video has actually been saved.

## 7. Export Complete Screen

### Suggested content
**Title:** Your Video Is Ready!

**Message:** "Your photos have been turned into a memorable video."

Show:
- Video thumbnail or preview.
- Video title.
- Duration.
- Resolution.
- Save status.

### Actions
- **Open Video:** Opens the exported video in an available player.
- **Share:** Opens device sharing options, if supported.
- **Go to Library:** Opens the Library and highlights the new video.
- **Create Another:** Starts a new project.

Add the successfully exported video to the Library. Show this screen only after saving succeeds.

## 8. Library

### Purpose
The Library displays videos successfully exported from CineClip. It helps users find and manage finished videos.

### 8.1 Library Screen Content
- Page title: **Library**
- Search field or search icon.
- **All Videos** filter.
- **Recent** filter.
- Video cards or list items containing:
  - Thumbnail.
  - Video title.
  - Creation or export date.
  - Video duration.
  - Optional resolution label.
  - Options menu.

### 8.2 Library Actions

**Open or Play Video**
- Opens the selected exported video.
- Provides playback controls through the device or an in-app player.

**Rename**
- Lets the user change the Library display title.
- If the exported filename is also changed, handle filename conflicts safely.

**Share**
- Opens the device sharing options, if supported.

**Delete**
- Shows a confirmation dialog.
- Clearly explain whether deletion removes only the Library entry or also the exported file from device storage.
- Never delete the original photos used in the project.

**Search**
- Filters videos by title.
- Shows an empty result message when no video matches.

**All Videos**
- Displays all videos CineClip can access in its Library.

**Recent**
- Sorts videos by most recent creation or export date.

### 8.3 Empty Library State

**Title:** Your Library Is Empty

**Message:** "Your finished videos will appear here. Start by turning your photos into a memorable video."

**Button:** Create New Video

### 8.4 Library Data and File Handling
- Store the information needed to display each video, such as title, file location or media reference, thumbnail, duration, and export date.
- Handle missing or moved files gracefully.
- Request device permissions when needed.
- Explain deletion behavior clearly.

## 9. Navigation Between Screens

| Current screen | User action | Next screen |
|---|---|---|
| Video Editor | Tap Preview | Preview |
| Video Editor | Tap Back | Previous screen or unsaved-changes dialog |
| Preview | Tap Edit Again | Video Editor |
| Preview | Tap Export Video | Export Settings |
| Export Settings | Tap Export | Exporting |
| Export Settings | Tap Back | Preview |
| Exporting | Export succeeds | Export Complete |
| Exporting | Export fails | Error / Retry |
| Export Complete | Tap Open Video | Video Player |
| Export Complete | Tap Share | Device Share Sheet |
| Export Complete | Tap Go to Library | Library |
| Library | Tap a video | Video Player |
| Library | Tap Create New Video | Photo Selection |

## 10. Complete User Flow Diagram

```text
VIDEO EDITOR
  | Arrange photos, apply motion,
  | set duration, layout, text, music
  v
PREVIEW
  |  | +---- Edit Again ----------------> VIDEO EDITOR
  |
  | Export Video
  v
EXPORT SETTINGS
  | Confirm resolution and output
  v
EXPORTING
  |
  +---- Failed ----> ERROR / RETRY
  |
  | Successful
  v
EXPORT COMPLETE
  |
  +---- Open Video ----> VIDEO PLAYER
  +---- Share ----------> DEVICE SHARE SHEET
  |
  +---- Go to Library
  v
LIBRARY
  |
  +---- Search / Filter
  +---- Select Video --> VIDEO PLAYER
  +---- Rename / Share / Delete
  +---- Create New Video --> PHOTO SELECTION
```

## 11. Recommended Development Priorities

### Essential for the first working version
1. Arrange selected photos in the correct order.
2. Apply basic photo motion such as zoom and pan.
3. Set photo duration.
4. Select Full Frame or Comic Panel layout.
5. Preview the complete result.
6. Export at a supported resolution.
7. Save the exported file and display it in the Library.
8. Open and play a Library video.

### Useful next improvements
1. Drag-and-drop photo reordering.
2. Motion intensity controls.
3. Text customization.
4. Background music volume and track selection.
5. Aspect ratio selection.
6. Rename, search, share, and delete Library videos.
7. Save unfinished projects as drafts.

### Later enhancements
1. Photo filters.
2. More transitions.
3. Individual photo cropping and positioning.
4. More layout templates.
5. Additional animation presets.

## 12. Design Principles
- Keep CineClip focused on animating still photos and combining them into a finished video.
- Avoid making the interface feel like a complex traditional video editor.
- Keep important actions easy to find.
- Use clear labels and visual previews for motion effects and layouts.
- Preserve the project when users move between Editor and Preview.
- Give clear feedback during export.
- Confirm destructive actions.
- Keep the Library focused on successfully exported videos. Manage unfinished projects separately as drafts if draft support is added.
- Maintain CineClip's visual identity and consistent navigation.

## 13. Scope Note

This is a user-experience and screen-flow specification. It does not assume every listed feature is already implemented. Photo animation, video rendering, device media access, file saving, and sharing require suitable platform APIs or libraries. Only display controls supported by the current version of the app.
