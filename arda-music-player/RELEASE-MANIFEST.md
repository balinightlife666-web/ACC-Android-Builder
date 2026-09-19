# ARDA MUSIC PLAYER — Permanent Release Manifest

- Package ID: `com.arda.musicplayer`
- Initial version: `1.0.0`
- Initial versionCode: `1`
- Current version: `1.2.0`
- Current versionCode: `3`
- Signing alias: `arda-music-player-release`
- Signing certificate SHA-256: `E3:71:2D:88:DF:F9:4D:C6:12:B8:7A:D5:FA:E5:F4:E7:98:E6:19:96:BD:3B:DC:07:AB:2D:88:9C:52:0B:6F:A3`
- Required schemes: v1, v2, v3
- v1.0.0 APK SHA-256: `d76726ec3460aa59dda6ec925cfd2f64ac81797ef8fdf29c06343e42341da862`
- v1.1.0 APK SHA-256: `76d2100947812b58aec5e095b59007cc88aa10929353d994668263753b2c73f5`

## Verification

- `assembleRelease`: PASS
- Android lint: PASS (0 errors)
- APK identity: PASS — `com.arda.musicplayer`, versionCode `2`, versionName `1.1.0`
- Signature: PASS — v1/v2/v3 present; v2/v3 required by the declared minimum Android 8.0
- Update compatibility: PASS — package ID and signing certificate match v1.0.0

The keystore and `signing.properties` in the source archive are the permanent update identity. Never regenerate or replace this key. Every future release must increase `versionCode` and use this exact keystore.
