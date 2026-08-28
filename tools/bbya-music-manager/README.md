# BBYA Music Manager MVP

Android playlist manager for BBYA Social Hub.

## Hard contract

The APK is **not a music player**. It contains no Play, Pause, Next, Previous, MediaPlayer, audio streaming, or map playback controls.

Its job is to maintain playlist data per BBYA area/channel. Roblox remains responsible for automatic playback and zone detection.

Target flow:

`BBYA Music Manager APK -> playlist API/backend -> Roblox HttpService -> zone playlist -> automatic Roblox playback + zone panel`

## MVP features

- Separate playlist channel per area.
- Seed channels: Main Club, Underground, Rooftop, Mall, Pasar Malam, Lake / Outdoor.
- Add custom areas later without rebuilding the data model.
- Edit area name and genre.
- Add/edit/delete tracks.
- Track fields: title, artist, Roblox Audio Asset ID, optional cover Asset ID.
- Enable/disable areas and tracks.
- Reorder tracks with Up/Down.
- Local persistence with Android SharedPreferences.
- Export current catalog as JSON for backend/Roblox integration.

## Catalog shape

```json
{
  "schemaVersion": 1,
  "revision": 7,
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
          "robloxAssetId": "123456789",
          "coverImage": "rbxassetid://987654321",
          "enabled": true,
          "order": 1
        }
      ]
    }
  ]
}
```

## Integration status

MVP is local-only by design. `EXPORT JSON` exposes the exact sanitized catalog shape that the future backend will store. Backend sync and Roblox wiring are deliberately not faked in this revision.

Mall and Pasar Malam channels are included so their future in-map music panels can consume dedicated playlists without sharing the Main Club playlist.
