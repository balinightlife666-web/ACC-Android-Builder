# BBYA Music Manager — Roblox Direct Sync v0.3

Status: DRAFT / UNDERGROUND PILOT / NOT LIVE

## Goal

Remove the external backend requirement while preserving the core product contract:

`Drive / phone -> APK playlist -> Roblox -> matching map venue`

The APK remains a playlist library, not a music player.

## Direct sync architecture

1. User imports a song into the Underground playlist.
2. APK authenticates to Roblox once with OAuth 2.0 Authorization Code + PKCE.
3. OAuth scopes:
   - `openid`
   - `profile`
   - `asset:read`
   - `asset:write`
   - `universe-messaging-service:publish`
4. APK uploads the local audio file to Roblox Assets API with `Authorization: Bearer ...`.
5. APK polls the returned asset operation until Roblox returns the Asset ID.
6. Asset ID is saved only as an internal track field. It is never a required user input.
7. APK publishes a compact per-track playlist delta to Universe `8116636513` topic `BBYA_MUSIC_UNDERGROUND_V1`.
8. The BBYA game server subscribes to that topic with `MessagingService:SubscribeAsync()`.
9. The game server validates the delta, stores the Underground catalog in native Roblox DataStore, and updates the existing Underground AutoDJ authority.
10. Underground UI/panel continues reading the existing AutoDJ state/playlist remotes.

This removes the need for Cloudflare/Vercel/Render/Firebase/Supabase or a permanent phone tunnel.

## Security

- Never embed `GUDANGPET88_AUDIO_UPLOADER` or any Open Cloud API key in the APK.
- Never embed an OAuth client secret in the APK.
- The Android APK is a public OAuth client and must use PKCE.
- OAuth Client ID is public configuration and may be embedded in the APK.
- Refresh/access tokens must remain in app-private storage.
- The game receives only sanitized metadata and Roblox Asset IDs.

## Messaging contract

Roblox MessagingService has a 1 KiB message limit, therefore the APK sends deltas rather than the whole playlist.

Upsert example:

```json
{
  "v": 1,
  "z": "underground",
  "op": "upsert",
  "trackId": "track-uuid",
  "title": "Track Title",
  "artist": "Artist",
  "assetId": "123456789",
  "order": 1,
  "enabled": true,
  "rev": 12
}
```

Delete example:

```json
{
  "v": 1,
  "z": "underground",
  "op": "delete",
  "trackId": "track-uuid",
  "rev": 13
}
```

## One-time prerequisite

A Roblox OAuth 2.0 application must be registered as a **public client** with PKCE and a custom Android redirect URI such as:

`bbyamusic://oauth/callback`

The app requires the scopes listed above and access to the BBYA Social Hub universe for universe messaging.

Only the OAuth Client ID is needed by the APK. No client secret is shipped.

## Current implementation

`RobloxSyncClient.java` now implements:

- PKCE verifier/challenge/state generation
- OAuth authorize URL generation
- authorization-code exchange
- refresh-token exchange
- OAuth-authenticated Roblox audio upload
- operation polling
- internal Asset ID extraction
- Underground per-track upsert/delete publication through Universe Messaging

Next integration step: wire OAuth redirect/login + pending-track sync into MainActivity, then install the Underground DataStore/Messaging adapter into the existing `85-basement-autodj.server.lua` authority.
