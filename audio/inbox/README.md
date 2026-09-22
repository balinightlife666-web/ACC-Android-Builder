# BBYA Music Audio Inbox

Temporary repository inbox for the manual BBYA Music Audio Publisher V1 workflow.

## Use

1. Add an audio file here on a feature branch or temporary upload commit.
2. Supported formats: `.mp3`, `.ogg`, `.wav`, `.flac`.
3. File must be smaller than 20 MB. Roblox also enforces its current audio duration/format/moderation rules.
4. Open **Actions → BBYA Music Audio Publisher V1 → Run workflow**.
5. Set `audio_path` to the repository path, for example `audio/inbox/bbya-test-01.mp3`.
6. Enter the Roblox creator ID and select whether it is a user or group.
7. Set `confirm_upload` to `UPLOAD` only when ready.
8. Read the workflow summary for the resulting Roblox Asset ID and moderation state.

## Security

The workflow reads only the repository secret `GUDANGPET88_AUDIO_UPLOADER` as its Roblox Open Cloud API key. Do not commit API keys, cookies, tokens, OTPs, or recovery codes to this folder.

## Scope

This workflow uploads audio assets only. It does not publish a Roblox place/map and it does not modify BBYA Social Hub source.
