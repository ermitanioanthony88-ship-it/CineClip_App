# CineClip – Landing Page, Home, and Library

## 1. Project Overview

**App name:** CineClip  
**Tagline:** Turn Moments Into Movies

CineClip is a mobile application that helps users turn photos from their device gallery into videos. The landing experience gives users access to the main features, recent projects, and their saved videos.

The design uses a dark navy and blue theme, bright cyan accents, rounded cards, and clear buttons.

## 2. Main Navigation

The application has two primary sections:

- **Home:** The main landing page where users can start creating a video and view recent videos.
- **Library:** A collection of videos created or exported by the user.

A bottom navigation bar lets users switch between Home and Library.

## 3. Home Screen

### Purpose

The Home screen is the main page users see after completing onboarding. It provides a clear starting point for creating a video and quick access to recent projects.

### Main elements

1. **Top bar**
   - CineClip logo and application name.
   - Settings icon on the right.

2. **Welcome section**
   - Heading: "Create Videos Easily"
   - Supporting text: "Turn your photos into memorable videos."

3. **Create New Video button**
   - The primary action on the page.
   - Opens the Select Images screen.

4. **Recent Videos section**
   - Displays recently created videos as thumbnail cards.
   - Each card includes a thumbnail, title, duration, and options menu.
   - A "See All" link opens the Library.

5. **Bottom navigation**
   - Home tab.
   - Library tab.

### Home screen behavior

- Tapping **Create New Video** starts the image-to-video creation flow.
- Tapping a recent video opens its preview or editing view.
- Tapping **See All** opens the Library.
- Tapping **Library** in the bottom navigation opens the complete video collection.
- Tapping the settings icon opens application settings.

## 4. Library Screen

### Purpose

The Library stores and organizes videos created by the user. It makes previously exported videos easy to find and open.

### Main elements

1. **Page title**
   - "Library" appears at the top.

2. **Search icon**
   - Allows users to find a saved video by title.

3. **Video filters**
   - **All Videos:** Displays every saved video.
   - **Recent:** Displays videos ordered by their most recent creation or export.

4. **Video list**
   - Each item includes a thumbnail, video title, date, and duration.
   - An options menu can provide actions such as rename or delete.

5. **Bottom navigation**
   - Home tab.
   - Library tab, shown as active.

### Library screen behavior

- Tapping a video opens its preview.
- Tapping the options menu displays available actions for that video.
- Searching filters the displayed list by title.
- Selecting **All Videos** or **Recent** changes the list being displayed.
- Tapping **Home** returns to the Home screen.

## 5. Visual Design Guidelines

### Colors

- **Dark navy:** Main background.
- **Deep blue:** Cards, panels, and secondary surfaces.
- **Bright blue:** Primary buttons and important actions.
- **Cyan:** Highlights, active tabs, progress indicators, and selected states.
- **White:** Main text and icons.
- **Muted blue-gray:** Supporting text and secondary labels.

### Components

- Rounded buttons and cards.
- Clear icons with short labels.
- Consistent spacing between sections.
- Visible active states for navigation.
- Video thumbnails with readable titles and durations.

### Usability considerations

- Keep **Create New Video** easy to find on Home.
- Make the active navigation tab obvious.
- Keep Home and Library navigation consistent.
- Confirm before destructive actions such as deleting a saved video.
- Provide a helpful empty state when the Library has no saved videos.

## 6. Suggested Screens

| No. | Screen | Main purpose |
|---:|---|---|
| 1 | Home | Main landing page and recent videos. |
| 2 | Library | Displays and organizes saved videos. |

## 7. Notes for Implementation

This document describes the intended interface and behavior, not a specific technical implementation. A working application will need suitable storage and media access features to display, organize, and open exported videos.

For an early prototype, Home and Library can use sample video data and thumbnail images.
