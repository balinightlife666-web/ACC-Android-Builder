# BBYA Music Manager MVP

Android playlist library for BBYA Social Hub.

## Hard contract

The APK is **not a music player**. It contains no Play, Pause, Next, Previous, MediaPlayer, audio streaming, or map playback controls.

Its job is to import/store songs, organize playlist channels per BBYA area, upload approved audio to Roblox, and mirror playlist changes to the matching Roblox venue. Roblox remains responsible for automatic playback.

## v0.3 Underground pilot

Pilot flow:

`Google Drive / phone -> APK library -> Roblox OAuth 2.0 PKCE -> Assets API -> Universe Messaging -> Underground AutoDJ -> DataStore`

No Roblox API key or OAuth Client Secret is embedded in the APK.

OAuth app Client ID is public configuration only. The Android app uses authorization-code + PKCE and the redirect URI `bbyamusic://oauth/callback`.

Requested scopes:

- `openid`
- `profile`
- `asset:read`
- `asset:write`
- `universe-messaging-service:publish`

Pilot target:

- Universe: `8116636513`
- Zone: `underground`
- Topic: `BBYA_MUSIC_UNDERGROUND_V1`

The Roblox map side remains a separate draft until reviewed/merged/published. It keeps the existing Underground owner catalog as fallback until a valid mirrored catalog exists.

## Library features

- Separate playlist channel per area.
- Import one or multiple MP3/OGG/WAV/FLAC files from Android's system picker, including Google Drive when available.
- Imported files are copied into app-private storage; originals remain untouched.
- Conservative 20 MB per-file validation.
- Edit title/artist without manually entering Roblox Asset IDs.
- Enable/disable and reorder tracks.
- Local catalog persistence.
- Hidden upload/sync state per track.

## Upload behavior

When `SYNC UNDERGROUND` is pressed with a valid Roblox OAuth session:

1. The APK reads only the Underground playlist.
2. Tracks without an internal Roblox Asset ID are uploaded through the Roblox Assets API.
3. The operation is polled until Roblox returns an asset result.
4. Only approved results are published to the Underground messaging topic.
5. The sanitized delta contains title, artist, order, enabled state, track ID and Roblox Asset ID; local file paths and Drive URIs never leave the device through Messaging.

The account used to authorize OAuth is the account/resource owner for the API calls. It must have permission to publish messages to the BBYA universe.

## Security

- Never store a Roblox Open Cloud API key in the APK.
- Never store the OAuth Client Secret in the APK.
- PKCE verifier/state are generated per authorization attempt.
- Access token is short-lived and stored only in app-private preferences for the pilot.
- No refresh token is persisted by this pilot; re-login is required after the OAuth access session expires.

## Status

v0.3 Android build compiles successfully on GitHub Actions. APK code remains in PR #33 and the Underground Roblox receiver remains isolated in map PR #238. Neither PR is considered LIVE merely because it exists or builds.
