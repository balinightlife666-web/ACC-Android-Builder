#!/usr/bin/env python3
import pathlib
import re
import sys

if len(sys.argv) != 2:
    raise SystemExit("usage: bbya-mainclub-runtime-hardening.py <source-script>")

p = pathlib.Path(sys.argv[1])
text = p.read_text(encoding="utf-8")
original = text

# 1) Make canonical-state commits resilient to another BBYA worker advancing main
# between pull and push. This does not change Roblox/audio behavior.
old_git = '''def git_commit(paths, message):
    run(["git", "config", "user.name", "ACC Roblox Audio Safety Bot"])
    run(["git", "config", "user.email", "actions@users.noreply.github.com"])
    existing = [str(p.relative_to(ROOT) if isinstance(p, pathlib.Path) else p) for p in paths if (ROOT / str(p.relative_to(ROOT) if isinstance(p, pathlib.Path) and p.is_absolute() else p)).exists()]
    if not existing:
        return run(["git", "rev-parse", "HEAD"], capture=True).stdout.strip()
    run(["git", "add", "--", *existing])
    diff = run(["git", "diff", "--cached", "--quiet"], check=False)
    if diff.returncode == 0:
        return run(["git", "rev-parse", "HEAD"], capture=True).stdout.strip()
    run(["git", "commit", "-m", message])
    run(["git", "pull", "--rebase", "origin", "main"])
    run(["git", "push", "origin", "HEAD:main"])
    return run(["git", "rev-parse", "HEAD"], capture=True).stdout.strip()
'''
new_git = '''def git_commit(paths, message):
    run(["git", "config", "user.name", "ACC Roblox Audio Safety Bot"])
    run(["git", "config", "user.email", "actions@users.noreply.github.com"])
    run(["git", "config", "rebase.autoStash", "true"])
    existing = [str(p.relative_to(ROOT) if isinstance(p, pathlib.Path) else p) for p in paths if (ROOT / str(p.relative_to(ROOT) if isinstance(p, pathlib.Path) and p.is_absolute() else p)).exists()]
    if not existing:
        return run(["git", "rev-parse", "HEAD"], capture=True).stdout.strip()
    run(["git", "add", "--", *existing])
    diff = run(["git", "diff", "--cached", "--quiet"], check=False)
    if diff.returncode == 0:
        return run(["git", "rev-parse", "HEAD"], capture=True).stdout.strip()
    run(["git", "commit", "-m", message])
    last_error = None
    for attempt in range(1, 6):
        pull = run(["git", "pull", "--rebase", "origin", "main"], check=False, capture=True)
        if pull.returncode != 0:
            last_error = f"pull/rebase attempt {attempt}: {pull.stderr[-1200:]}"
            run(["git", "rebase", "--abort"], check=False)
            time.sleep(attempt * 2)
            continue
        push = run(["git", "push", "origin", "HEAD:main"], check=False, capture=True)
        if push.returncode == 0:
            return run(["git", "rev-parse", "HEAD"], capture=True).stdout.strip()
        last_error = f"push attempt {attempt}: {push.stderr[-1200:]}"
        time.sleep(attempt * 2)
    raise RuntimeError("canonical git push failed after retries: " + str(last_error))
'''
if old_git in text:
    text = text.replace(old_git, new_git, 1)
elif "canonical git push failed after retries" not in text:
    raise SystemExit("GIT_COMMIT_PATCH_ANCHOR_NOT_FOUND")

# 2) Build a conservative set of normalized hashes that Roblox already rejected.
old_hashes = '''    live_hashes = {}
    for did, item in state["items"].items():
        if item.get("status") in ("LIVE", "DUPLICATE_REUSED") and item.get("normalizedSha256") and item.get("assetId"):
            live_hashes[item["normalizedSha256"]] = {"driveId": did, "assetId": str(item["assetId"]), "title": item.get("title")}
'''
new_hashes = '''    live_hashes = {}
    rejected_hashes = {}
    for did, item in state["items"].items():
        sha = item.get("normalizedSha256")
        if item.get("status") in ("LIVE", "DUPLICATE_REUSED") and sha and item.get("assetId"):
            live_hashes[sha] = {"driveId": did, "assetId": str(item["assetId"]), "title": item.get("title")}
        if item.get("status") == "BLACKLISTED" and sha:
            rejected_hashes[sha] = {"driveId": did, "assetId": str(item.get("assetId") or ""), "title": item.get("title")}
'''
if old_hashes in text:
    text = text.replace(old_hashes, new_hashes, 1)
elif "rejected_hashes = {}" not in text:
    raise SystemExit("HASH_INDEX_PATCH_ANCHOR_NOT_FOUND")

# 3) Before a new Roblox asset call, blacklist exact normalized clones of a prior
# rejected upload. No rename, pitch/speed/key change, retry, or new asset call.
anchor = '''                rec["normalizedSha256"] = prep["sha256"]
                if prep["sha256"] in live_hashes:
'''
replacement = '''                rec["normalizedSha256"] = prep["sha256"]
                if prep["sha256"] in rejected_hashes:
                    prior = rejected_hashes[prep["sha256"]]
                    rec["status"] = "BLACKLISTED"
                    rec["blacklistReason"] = "DUPLICATE_OF_REJECTED_NORMALIZED_AUDIO"
                    rec["duplicateOfRejectedDriveId"] = prior["driveId"]
                    if prior.get("assetId"):
                        rec["duplicateOfRejectedAssetId"] = prior["assetId"]
                    rec["updatedAt"] = now()
                    b = blacklist_item(blacklist, entry, "DUPLICATE_OF_REJECTED_NORMALIZED_AUDIO")
                    b["duplicateOfRejectedDriveId"] = prior["driveId"]
                    if prior.get("assetId"):
                        b["duplicateOfRejectedAssetId"] = prior["assetId"]
                    persist_state(state, blacklist, f"Blacklist duplicate rejected BBYA audio {seq:02d} without upload [skip ci]")
                    continue
                if prep["sha256"] in live_hashes:
'''
if anchor in text:
    text = text.replace(anchor, replacement, 1)
elif "DUPLICATE_OF_REJECTED_NORMALIZED_AUDIO" not in text:
    raise SystemExit("DUPLICATE_REJECT_PATCH_ANCHOR_NOT_FOUND")

# 4) Teach the same run immediately after a fresh moderation rejection, so a
# later identical file in this very run is also skipped without upload.
old_rej = '''            blacklist_item(blacklist, entry, "ROBLOX_MODERATION_REJECTED", asset_id=asset_id, moderation_state=mod_state)
            persist_state(state, blacklist, f"Blacklist BBYA audio {seq:02d} moderation rejection [skip ci]")
            continue
'''
new_rej = '''            blacklist_item(blacklist, entry, "ROBLOX_MODERATION_REJECTED", asset_id=asset_id, moderation_state=mod_state)
            if rec.get("normalizedSha256"):
                rejected_hashes[rec["normalizedSha256"]] = {"driveId": did, "assetId": str(asset_id), "title": entry["title"]}
            persist_state(state, blacklist, f"Blacklist BBYA audio {seq:02d} moderation rejection [skip ci]")
            continue
'''
if old_rej in text:
    text = text.replace(old_rej, new_rej, 1)
elif "rejected_hashes[rec[\"normalizedSha256\"]]" not in text:
    raise SystemExit("FRESH_REJECTION_PATCH_ANCHOR_NOT_FOUND")

if text == original:
    print("MAINCLUB_RUNTIME_HARDENING_ALREADY_PRESENT")
else:
    p.write_text(text, encoding="utf-8")
    print("MAINCLUB_RUNTIME_HARDENING_APPLIED")

# Fail closed if either protection is absent.
check = p.read_text(encoding="utf-8")
assert "canonical git push failed after retries" in check
assert "DUPLICATE_OF_REJECTED_NORMALIZED_AUDIO" in check
assert "rejected_hashes = {}" in check
print("MAINCLUB_RUNTIME_HARDENING_PASS")
