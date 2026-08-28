# BBYA Music Manager MVP

Android playlist library for BBYA Social Hub.

## Hard contract

The APK is **not a music player**. It contains no Play, Pause, Next, Previous, MediaPlayer, audio streaming, or map playback controls.

Its job is to import/store songs, organize them into playlist channels per BBYA area, and later sync those channels to the backend consumed by Roblox panels. Roblox remains responsible for automatic zone playback.

Target flow:

`Google Drive / phone storage -> BBYA Music Manager -> playlist area -> secure backend -> Roblox panel for same area -> automatic Roblox playback`

## MVP v0.2 features

- Separate playlist channel per area.
- Seed channels: Main Club, Underground, Rooftop, Mall, Pasar Malam, Lake / Outdoor.
- Add/edit/delete custom areas and genres.
- Import one or multiple audio files through Android's system file picker; Google Drive appears there when available on the device.
- Supported import formats for the Roblox pipeline: MP3, OGG, WAV, FLAC.
- Imported files are copied into the app's private storage. Removing a playlist entry removes only the APK copy; the original Drive/phone file is not deleted.
- Conservative 20 MB per-file validation for the downstream Roblox upload pipeline.
- Edit song title and artist without manually entering a Roblox Asset ID.
- Enable/disable areas and tracks.
- Reorder tracks with Up/Down.
- Local catalog persistence with SharedPreferences.
- `MIRROR JSON` exports only the sanitized channel/track contract; private device paths and Drive URIs are never exposed to Roblox.

## Hidden integration fields

Every imported song begins with:

```json
{
  "robloxAssetId": "",
  "uploadState": "PENDING_UPLOAD",
  "syncState": "LOCAL_ONLY"
}
```

The Asset ID is an internal field. The user does not type or manage it in the APK. In the next integration step, the APK sends the stored audio file to a secure backend; the backend performs the Roblox upload with its server-side credential, stores the returned Asset ID, and publishes the sanitized playlist state.

**Never put a Roblox Open Cloud API key inside the APK.**

## Mirror catalog shape

```json
{
  "schemaVersion": 2,
  "revision": 8,
  "zones": [
    {
      "id": "mall",
      "name": "Mall",
      "genre": "Chill / Pop",
      "enabled": true,
      "tracks": [
        {
          "id": "track-example",
          "title": "Example Track",
          "artist": "Artist",
          "enabled": true,
          "order": 1,
          "robloxAssetId": "",
          "coverImage": "",
          "uploadState": "PENDING_UPLOAD"
        }
      ]
    }
  ]
}
```

## Integration status

Drive/phone import + local playlist management is implemented in the MVP branch. Backend upload/sync and Roblox panel wiring are the next layer and are deliberately not faked.

Mall and Pasar Malam have dedicated channels so their future panels do not share Main Club music.

Build validation is performed from PR #33 before the app is merged.
