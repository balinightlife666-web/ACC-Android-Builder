# BBYA Music Mirror API Contract v1

This contract defines the next integration layer between the Android playlist manager and Roblox.

## Security rule

The Android APK must never contain a Roblox Open Cloud API key. The APK talks only to the BBYA backend over HTTPS. The backend owns the Roblox upload credential and exposes only sanitized playlist state to Roblox.

## Write path: APK -> backend

### Import/upload one track

`POST /api/bbya/music/zones/{zoneId}/tracks`

Multipart form:

- `file`: MP3 / OGG / WAV / FLAC copied into the APK private storage
- `title`: user-editable track title
- `artist`: user-editable artist name
- `clientTrackId`: stable APK track UUID
- `order`: playlist order

Backend responsibilities:

1. Validate format, size, auth, and target zone.
2. Upload approved audio to Roblox using the server-side audio uploader credential.
3. Poll the Roblox asset operation until an Asset ID is returned or the operation fails.
4. Store the Asset ID internally with the BBYA track.
5. Mark the track `READY` only when the asset is actually usable for the BBYA experience.
6. Increment the zone/catalog revision.
7. Return sanitized track state to the APK.

Example response:

```json
{
  "id": "track-uuid",
  "zoneId": "mall",
  "title": "Example Track",
  "artist": "Artist",
  "order": 3,
  "enabled": true,
  "uploadState": "READY",
  "syncState": "SYNCED"
}
```

The APK does not need to display the Roblox Asset ID in its normal UI.

### Update playlist metadata/order

`PUT /api/bbya/music/zones/{zoneId}`

```json
{
  "name": "Mall",
  "genre": "Chill / Pop",
  "enabled": true,
  "trackOrder": ["track-a", "track-b", "track-c"]
}
```

### Delete track

`DELETE /api/bbya/music/zones/{zoneId}/tracks/{trackId}`

Deletion removes the track from the BBYA playlist catalog. Asset lifecycle/deletion on Roblox is a separate backend policy and must not be triggered accidentally by a playlist edit.

## Read path: Roblox -> backend

Roblox reads a sanitized, read-only endpoint:

`GET /api/bbya/music/zones/{zoneId}/playlist`

Example:

```json
{
  "schemaVersion": 2,
  "revision": 42,
  "zone": {
    "id": "mall",
    "name": "Mall",
    "genre": "Chill / Pop",
    "enabled": true,
    "tracks": [
      {
        "id": "track-a",
        "title": "Example Track",
        "artist": "Artist",
        "robloxAssetId": "123456789",
        "coverImage": "",
        "enabled": true,
        "order": 1
      }
    ]
  }
}
```

Roblox receives no APK file paths, Drive URIs, backend credentials, upload tokens, or write secrets.

## Zone isolation

Each in-map music panel subscribes only to its own zone ID. Changing `mall` must not change `main-club`, `pasar-malam`, `lake`, or any other channel.

## Playback ownership

The APK never starts/stops audio. Roblox owns automatic playback, zone detection, track progression, and the in-map Now Playing panel. The APK owns library import, playlist membership, metadata, order, and enable/disable state.
