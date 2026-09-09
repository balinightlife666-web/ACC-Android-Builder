# AM STUDIO MUSIC DISTRIBUTION — PERMANENT APK SIGNING LOCK

Status: PERMANENT KEY GENERATED / ACTIONS SECRET PROVISIONING PENDING

## Goal
All user-facing AM STUDIO Music Distribution APKs must use the same permanent signing certificate so Android can upgrade the installed app without uninstalling and without losing app data.

Package lock: `com.amstudio.distribution`

## Permanent certificate identity

- Alias: `amstudio-release`
- Key type: RSA 4096 / SHA256withRSA
- Keystore format: PKCS12
- Certificate SHA-256 fingerprint:
  `34:47:8F:B9:8A:55:73:45:EA:7F:22:1A:C1:98:33:4F:28:7F:9F:A1:94:BC:B6:94:75:27:1C:F8:5D:E9:56:23`
- Certificate serial: `961d392186486e7a`

The private keystore and passwords are intentionally NOT stored in this repository. The fingerprint above is public identity metadata and is safe to record for future signature verification.

## Build channels

### Debug CI
- Triggered automatically by branch/PR changes.
- Uses Android debug signing.
- Artifact is explicitly marked `DEBUG`.
- Never distribute as the upgrade channel.

### Signed Release
- Triggered manually through GitHub Actions `workflow_dispatch`.
- Build task: `:app:assembleRelease`.
- Fails closed unless all permanent AM STUDIO signing secrets exist.
- Produces `*-SIGNED.apk`, SHA-256 checksum, signing certificate report, and build-channel receipt.

## Required GitHub Actions secrets

1. `AM_STUDIO_KEYSTORE_B64`
   - Base64 representation of the permanent keystore.
2. `AM_STUDIO_KEYSTORE_PASSWORD`
   - Keystore password.
3. `AM_STUDIO_KEY_ALIAS`
   - Permanent key alias.
4. `AM_STUDIO_KEY_PASSWORD`
   - Private-key password.

The keystore/private key must NEVER be committed to the repository.

## Permanent lock rules

- Never rotate or regenerate the signing key casually.
- Keep at least two encrypted offline backups of the permanent keystore.
- Losing the signing key means existing direct-install users cannot receive normal APK upgrades signed by a replacement key.
- Never expose signing secrets in source, APK, PR comments, logs, or issue bodies.
- Every distributed APK must have a signing certificate fingerprint recorded and it must equal the permanent fingerprint above.
- A build is not called `UPGRADE-SAFE` until signed-release CI has passed with the permanent key.

## Migration state

APK v0.4.0 and earlier were development/debug artifacts and may require uninstall before moving onto the permanent signed channel.

The first permanent signed release becomes the signing baseline. Every later AM STUDIO Music Distribution user-facing APK must use exactly the same certificate.
