# CineClip – Image-to-Video Creation Flow

## 1. Overview

**App name:** CineClip  
**Tagline:** Turn Moments Into Movies

This document describes the steps a user follows to create a video from photos. The process starts when the user taps **Create New Video** on the Home screen and ends when the exported video is saved and added to the Library.

## 2. First-Use Home and Library

A new user starts with an empty Library; demo videos should not be shown as if they were the user's creations.

- Home keeps **Create New Video** as its primary action and shows a friendly empty state in the Recent Videos area.
- The empty state explains that finished videos will appear there and offers **Create your first video**.
- The Library empty state explains that no videos have been saved and offers **Create New Video**.
- After a successful export, the empty states are replaced by the user's saved videos.
- If a search or filter has no matches while videos exist, show a separate no-results message rather than the first-use empty state.

## 3. Image-to-Video Creation Flow

### Step 1 – Open the image selector

**Screen:** Home

- The user taps **Create New Video**.
- The application opens the Select Images screen (a selection sheet in the current prototype).
- The user can browse their device gallery and choose multiple photos.

### Step 2 – Select images

**Screen:** Select Images

- Display selected photos as thumbnails.
- Show a selection indicator on each chosen photo.
- Allow the user to remove a selected photo.
- Provide a **Next** button to continue.
- Keep the Library empty until a video is successfully exported.

**Validation:** The user should select at least one photo before continuing. If no photos are selected, display a message asking the user to choose an image.

### Step 3 – Open the video editor

**Screen:** Video Editor

- Display a large preview area.
- Show the selected images in a thumbnail timeline.
- Allow the user to arrange the images in the desired order.

### Step 4 – Customize the video

The editor provides the following basic controls:

| Editing option | Description |
|---|---|
| Image Duration | Sets how long each photo appears in the video. |
| Add Text | Adds a text overlay or caption. |
| Background Music | Choose no music, one of five built-in instrumental tracks, or a supported audio file from the device. |
| Motion | Applies one of five Ken Burns-style camera moves: Slow Zoom In, Slow Zoom Out, Pan Left, Pan Right, or Pan Up. Photos are combined into a continuous video with transitions. |
| Video Quality | Sets the output resolution: 480p (Low), 720p (Standard), or 1080p (High). |

The user can make adjustments and check the changes before exporting. The selected video quality determines the resolution of the exported video.

### Step 5 – Preview the video

**Screen:** Preview

- Play the generated video.
- Animate the selected photos with their chosen motion and show playback controls and progress.
- Provide an **Edit Video** button to return to the editor.
- Provide an **Export Video** button to begin exporting.
- Allow the user to return to the editor if changes are needed.

### Step 6 – Export the video

**Screen:** Downloading / Exporting

- Show an export progress indicator.
- Display a message such as "Please wait... Your video is being exported."
- Show animated progress and prevent duplicate export actions while processing.
- Ask for confirmation before cancelling and discarding an active export.
- Show an error message and a retry option if exporting fails.

### Step 7 – Export complete

**Screen:** Export Complete

- Display a success message: "Export Complete! Your video has been saved to your device."
- Provide an **Open Video** button.
- Provide a **Share** button, if sharing is supported.

After a successful export, the video should also appear in the application's Library.

### Step 8 – Return to Home or Library

- The user can return to Home to create another video.
- The user can open Library to view the newly saved video.
- The exported video should display its thumbnail, title, date, and duration.

## 4. Complete User Flow

```text
HOME
  |
  | First use: show helpful empty state, no demo videos
  |
  | Tap "Create New Video"
  v
SELECT IMAGES
  |
  | Choose one or more photos
  | Tap "Next"
  v
VIDEO EDITOR
  |
  | Arrange photos
  | Set image duration
  | Add text or music
  | Choose motion effect
  | Tap "Preview"
  v
PREVIEW
  |
  | Review the video
  | Return to editor if changes are needed
  | Tap "Download"
  v
EXPORTING
  |
  | Show export progress
  v
EXPORT COMPLETE
  |
  | Open Video / Share
  | Video is saved to the device
  | Video is added to the Library
  v
HOME or LIBRARY
```

## 5. Suggested Screens

| No. | Screen | Main purpose |
|---:|---|---|
| 1 | Select Images | Lets the user choose photos from the gallery. |
| 2 | Video Editor | Lets the user customize the video. |
| 3 | Preview | Plays the video before export. |
| 4 | Exporting | Shows the export progress. |
| 5 | Export Complete | Confirms that the video was saved. |

## 6. Usability Considerations

- Make selected images visually distinct.
- Clearly label editing controls.
- Make the selected video quality visible before export.
- Explain that higher resolutions may create larger video files and take longer to export.
- Allow users to return to the editor from Preview.
- Provide feedback while exporting.
- Confirm before discarding an unfinished project.
- Show a clear error and retry option if exporting fails.

## 7. Notes for Implementation

This document describes the intended screens and user experience, not a specific technical implementation. A working application needs a photo picker, a video-generation process, device storage access, and sharing support. The available export resolutions should depend on the capabilities of the device and the video-generation technology used.

The current app uses the device photo picker and presents selection, editing, preview, export, and success as separate steps. On Android and iOS, it applies five Ken Burns-style camera moves, crossfades between images, and renders a selected procedural CineClip soundtrack or device audio into an MP4. Export can be cancelled with confirmation; completed videos are added to the persisted Library. The preview screen for saved videos supports playback, sharing, and saving an additional copy to the device's Photos gallery. Video generation is not available in the web build. Keep sample onboarding imagery separate from saved projects so a first-time user's Library remains empty.
