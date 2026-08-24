#!/usr/bin/env python3
import argparse, datetime as dt, json, pathlib

QUEUE = [17, 18, 20, 21, 22, 24]
TERMINAL = {"LIVE_IN_PLAYLIST", "READY_TO_INJECT", "MODERATION_REJECTED", "DUPLICATE_SOURCE_SKIPPED"}


def load(path, default=None):
    p = pathlib.Path(path)
    if not p.exists():
        return {} if default is None else default
    return json.loads(p.read_text(encoding="utf-8"))


def save(path, data):
    p = pathlib.Path(path)
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def sval(v):
    return "" if v is None else str(v).strip()


def bool_perm(v):
    if isinstance(v, bool):
        return v
    if isinstance(v, dict):
        return bool(v.get("ok"))
    return False


def report_candidates(source, control, idx):
    paths = [
        source / "deploy-status" / f"bbya-vip-track{idx:02d}.json",
        source / "deploy-status" / f"bbya-vip-track{idx:02d}-prep.json",
        control / "deploy-status" / f"bbya-amapiano-cadangan-track{idx:02d}.json",
    ]
    return [(p, load(p, {})) for p in paths if p.exists()]


def ensure_extra_in_main(main, extra):
    by = {int(t.get("index", 0)): t for t in main.get("tracks", [])}
    immutable = (
        "title", "driveFileId", "musicalKey", "camelot",
        "sourceDurationSeconds", "sourceSizeBytes", "sourceSha256",
    )
    for src in extra.get("tracks", []):
        idx = int(src.get("index", 0))
        if idx not in QUEUE:
            continue
        if idx not in by:
            main.setdefault("tracks", []).append(dict(src))
            by[idx] = main["tracks"][-1]
            continue
        dst = by[idx]
        for key in immutable:
            if dst.get(key) in (None, "") and src.get(key) not in (None, ""):
                dst[key] = src[key]
    main["tracks"] = sorted(main.get("tracks", []), key=lambda t: int(t.get("index", 0)))


def blacklist_match(blacklist, track):
    drive = sval(track.get("driveFileId"))
    sha = sval(track.get("sourceSha256")).lower()
    for item in (blacklist.get("items") or {}).values():
        if drive and sval(item.get("driveId")) == drive:
            return True
        if sha and sval(item.get("sourceSha256")).lower() == sha:
            return True
    return False


def preflight(args):
    source = pathlib.Path(args.source)
    control = pathlib.Path(args.control)
    reg_path = source / "maps/bbya-social-hub/audio-playlists/vip-amapiano.json"
    extra_path = source / "maps/bbya-social-hub/audio-playlists/vip-amapiano-extra.json"
    blacklist_path = source / "maps/bbya-social-hub/audio-blacklist.json"
    plan_path = control / "state/bbya-amapiano-plan.json"

    reg = load(reg_path)
    extra = load(extra_path)
    blacklist = load(blacklist_path, {"version": 1, "items": {}})
    if not reg.get("tracks") or not extra.get("tracks"):
        raise SystemExit("Missing Amapiano registry/extra queue")

    ensure_extra_in_main(reg, extra)
    by = {int(t.get("index", 0)): t for t in reg.get("tracks", [])}
    extra_by = {int(t.get("index", 0)): t for t in extra.get("tracks", [])}

    recovered = []
    conflicts = []
    for idx in QUEUE:
        t = by[idx]
        candidates = []
        if sval(t.get("assetId")):
            candidates.append(("registry", sval(t.get("assetId")), t))
        if sval(extra_by.get(idx, {}).get("assetId")):
            candidates.append(("extra", sval(extra_by[idx].get("assetId")), extra_by[idx]))
        for p, rep in report_candidates(source, control, idx):
            if sval(rep.get("assetId")):
                candidates.append((str(p), sval(rep.get("assetId")), rep))
        ids = sorted({aid for _, aid, _ in candidates})
        if len(ids) > 1:
            conflicts.append({"index": idx, "assetIds": ids, "sources": [x[0] for x in candidates]})
            continue
        if len(ids) == 1 and not sval(t.get("assetId")):
            aid = ids[0]
            donor = next(d for _, a, d in candidates if a == aid)
            t["assetId"] = aid
            donor_status = sval(donor.get("status"))
            if donor_status == "MODERATION_REJECTED":
                t["status"] = "MODERATION_REJECTED"
                t["moderationLastKnown"] = donor.get("moderationLastKnown") or donor.get("moderationState") or "Rejected"
            elif donor_status in {"READY_TO_INJECT", "LIVE_IN_PLAYLIST"}:
                t["status"] = donor_status
                t["bbyaPermission"] = bool_perm(donor.get("bbyaPermission")) or bool(t.get("bbyaPermission"))
                t["moderationLastKnown"] = donor.get("moderationLastKnown") or donor.get("moderationState") or "Approved"
            else:
                t["status"] = "ASSET_RECOVERED_RECHECK_REQUIRED"
                t["moderationLastKnown"] = donor.get("moderationLastKnown") or donor.get("moderationState") or t.get("moderationLastKnown")
            recovered.append({"index": idx, "assetId": aid, "from": [x[0] for x in candidates]})

    if conflicts:
        save(reg_path, reg)
        plan = {"action": "CONFLICT_STOP", "conflicts": conflicts, "queue": QUEUE}
        save(plan_path, plan)
        print(json.dumps(plan))
        return

    now = dt.datetime.now(dt.timezone.utc).isoformat()
    items = blacklist.setdefault("items", {})
    for idx in QUEUE:
        t = by[idx]
        if sval(t.get("status")) == "MODERATION_REJECTED":
            key = sval(t.get("driveFileId")) or f"track-{idx}"
            if key not in items:
                items[key] = {
                    "driveId": t.get("driveFileId"),
                    "title": t.get("title"),
                    "reason": "ROBLOX_MODERATION_REJECTED_PERMANENT",
                    "previousAssetId": t.get("assetId"),
                    "sourceSha256": t.get("sourceSha256"),
                    "blacklistedAt": now,
                }

    save(reg_path, reg)
    save(blacklist_path, blacklist)

    if recovered:
        plan = {"action": "RECOVERY_ONLY", "recovered": recovered, "queue": QUEUE}
        save(plan_path, plan)
        print(json.dumps(plan))
        return

    pending_existing = []
    for idx in QUEUE:
        t = by[idx]
        status = sval(t.get("status"))
        if sval(t.get("assetId")) and status not in TERMINAL:
            pending_existing.append(idx)

    requested = args.requested.strip().lower()
    if requested != "auto":
        try:
            req_idx = int(requested)
        except ValueError:
            raise SystemExit("requested track must be auto or an integer")
        if req_idx not in QUEUE:
            raise SystemExit(f"requested track not in safe queue: {req_idx}")
        if pending_existing and req_idx != pending_existing[0]:
            plan = {
                "action": "BLOCKED_PENDING_ASSET",
                "requested": req_idx,
                "mustRecheckFirst": pending_existing[0],
                "queue": QUEUE,
            }
            save(plan_path, plan)
            print(json.dumps(plan))
            return
        selected = req_idx
    elif pending_existing:
        selected = pending_existing[0]
    else:
        selected = next((i for i in QUEUE if sval(by[i].get("status")) not in TERMINAL and not blacklist_match(blacklist, by[i])), None)

    if selected is None:
        plan = {"action": "DONE", "queue": QUEUE}
        save(plan_path, plan)
        print(json.dumps(plan))
        return

    t = by[selected]
    if blacklist_match(blacklist, t) or sval(t.get("status")) == "MODERATION_REJECTED":
        plan = {"action": "BLACKLISTED_SKIP", "trackIndex": selected, "queue": QUEUE}
    elif sval(t.get("status")) in {"READY_TO_INJECT", "LIVE_IN_PLAYLIST"}:
        plan = {"action": "TERMINAL_SKIP", "trackIndex": selected, "queue": QUEUE}
    elif sval(t.get("assetId")):
        plan = {
            "action": "RECHECK_EXISTING",
            "trackIndex": selected,
            "assetId": sval(t.get("assetId")),
            "driveFileId": t.get("driveFileId"),
            "sourceSha256": t.get("sourceSha256"),
            "queue": QUEUE,
        }
    else:
        plan = {
            "action": "UPLOAD_NEW",
            "trackIndex": selected,
            "assetId": None,
            "driveFileId": t.get("driveFileId"),
            "sourceSha256": t.get("sourceSha256"),
            "title": t.get("title"),
            "queue": QUEUE,
        }
    save(plan_path, plan)
    print(json.dumps(plan))


def postprocess(args):
    source = pathlib.Path(args.source)
    control = pathlib.Path(args.control)
    idx = int(args.track)
    reg_path = source / "maps/bbya-social-hub/audio-playlists/vip-amapiano.json"
    extra_path = source / "maps/bbya-social-hub/audio-playlists/vip-amapiano-extra.json"
    blacklist_path = source / "maps/bbya-social-hub/audio-blacklist.json"
    report_path = source / "deploy-status" / f"bbya-vip-track{idx:02d}.json"

    reg = load(reg_path)
    extra = load(extra_path)
    blacklist = load(blacklist_path, {"version": 1, "items": {}})
    report = load(report_path, {})
    by = {int(t.get("index", 0)): t for t in reg.get("tracks", [])}
    extra_by = {int(t.get("index", 0)): t for t in extra.get("tracks", [])}
    if idx not in by or not report:
        raise SystemExit("Missing track/report after runner")
    t = by[idx]

    if idx in extra_by and extra_by[idx].get("status") != "DUPLICATE_SOURCE_SKIPPED":
        extra_by[idx].update({
            "assetId": t.get("assetId"),
            "bbyaPermission": t.get("bbyaPermission"),
            "status": t.get("status"),
            "moderationLastKnown": t.get("moderationLastKnown"),
        })

    now = dt.datetime.now(dt.timezone.utc).isoformat()
    if sval(t.get("status")) == "MODERATION_REJECTED":
        key = sval(t.get("driveFileId")) or f"track-{idx}"
        blacklist.setdefault("items", {})[key] = {
            "driveId": t.get("driveFileId"),
            "title": t.get("title"),
            "reason": "ROBLOX_MODERATION_REJECTED_PERMANENT",
            "previousAssetId": t.get("assetId"),
            "sourceSha256": t.get("sourceSha256"),
            "blacklistedAt": now,
        }

    save(reg_path, reg)
    save(extra_path, extra)
    save(blacklist_path, blacklist)

    receipt = {
        "status": t.get("status"),
        "trackIndex": idx,
        "title": t.get("title"),
        "driveFileId": t.get("driveFileId"),
        "sourceSha256": t.get("sourceSha256"),
        "assetId": t.get("assetId"),
        "bbyaPermission": bool(t.get("bbyaPermission")),
        "moderationLastKnown": t.get("moderationLastKnown"),
        "sourceReportStatus": report.get("status"),
        "recordedAt": now,
    }
    save(control / "deploy-status" / f"bbya-amapiano-cadangan-track{idx:02d}.json", receipt)
    save(control / "deploy-status" / "bbya-amapiano-cadangan-last.json", receipt)
    print(json.dumps(receipt))


def main():
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)
    a = sub.add_parser("preflight")
    a.add_argument("--source", required=True)
    a.add_argument("--control", required=True)
    a.add_argument("--requested", default="auto")
    a.set_defaults(func=preflight)
    b = sub.add_parser("postprocess")
    b.add_argument("--source", required=True)
    b.add_argument("--control", required=True)
    b.add_argument("--track", required=True)
    b.set_defaults(func=postprocess)
    args = p.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()
