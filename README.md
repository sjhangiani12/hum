# Hum

A lightweight macOS menu bar app that identifies songs playing around you — like Shazam, but lives in your toolbar.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue)
![Swift 6](https://img.shields.io/badge/Swift-6-orange)

## Features

- Click the music note in your menu bar to identify any song playing nearby
- Copies song title + artist to clipboard with one click
- Opens Spotify search for the identified song
- Logs every identified song to `~/Documents/ShazamLog.md` with timestamps
- Shows your 5 most recent identifications
- No dock icon — runs entirely in the menu bar

## Download

Grab the latest `Hum.zip` from [Releases](../../releases), unzip, and drag `Hum.app` to your Applications folder.

On first launch, right-click the app and choose **Open** (macOS will warn about unidentified developer on first run).

## How it works

Hum uses Apple's [ShazamKit](https://developer.apple.com/shazamkit/) framework to match audio from your microphone against Shazam's catalog. When you click "Shazam", it listens for a few seconds, identifies the song, and shows you the result.

Songs are logged to a markdown file at `~/Documents/ShazamLog.md` that looks like:

```
## Bohemian Rhapsody — Queen
- **Recognized**: 2026-02-08 21:30:45
- **Album**: A Night at the Opera
- **Genres**: Rock, Classic Rock
- **Spotify**: [Open in Spotify](https://open.spotify.com/search/...)
- **ISRC**: GBUM71029604
```

## Building from source

Requires:
- macOS 14+
- Xcode 16+
- Apple Developer Program membership ($99/year) — ShazamKit requires a registered App ID with the ShazamKit capability enabled

Steps:
1. Clone the repo
2. Open `Hum.xcodeproj` in Xcode
3. In Signing & Capabilities, set your team and bundle identifier
4. Register your bundle ID at [developer.apple.com](https://developer.apple.com) with the ShazamKit App Service enabled
5. Build and run (Cmd+R)

## Tech

- **SwiftUI** + **NSStatusItem/NSPopover** for the menu bar UI
- **ShazamKit** (`SHSession` + `AVAudioEngine`) for audio recognition
- **Swift 6** strict concurrency with nonisolated audio capture

Built with [Claude Code](https://claude.ai/claude-code).
