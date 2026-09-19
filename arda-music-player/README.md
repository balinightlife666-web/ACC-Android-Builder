# ARDA MUSIC PLAYER

Native Android wedding music player with an order-locked queue and a two-deck equal-power AutoMix engine.

## Permanent identity

- Application ID: `com.arda.musicplayer`
- Version: `1.2.0` (`versionCode 3`)
- Minimum Android: 8.0 (API 26)
- Target Android: 15 (API 35)
- Release alias: `arda-music-player-release`

Future releases must keep the same application ID and signing key and increment `versionCode`.

## Features

- Select several audio files or a complete folder.
- Persist the playlist and URI permissions.
- Keep the playlist in exact order.
- Normal and AutoMix modes.
- Equal-power crossfade adjustable from 4 to 20 seconds.
- Dual `MediaPlayer` decks with preloading.
- Screen-off playback through a foreground media service.
- Notification controls, seeking, previous/next, clear queue.
- MP3, AAC/M4A, WAV, OGG, OPUS and FLAC file support as provided by Android codecs.
- Save one Spotify or YouTube playlist link as the persistent wedding-playlist reference.
- Receive a playlist link directly from Android's Share menu.
- Professional dual-deck interface with next-track preload and live transition status.
- Position-synced AutoMix that follows the outgoing track instead of a drifting wall-clock timer.
- Preloaded handoff in Normal mode to reduce the pause between tracks.

Spotify and YouTube links are stored as references, not treated as raw audio sources. AutoMix uses local audio files that the user adds to the queue.
