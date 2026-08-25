#!/usr/bin/env python3
import argparse, datetime as dt, json, pathlib

# READY_TO_INJECT is intentionally not terminal. A ready asset must be
# staged/published and marked LIVE before another new asset may be created.
TERMINAL={
    "LIVE_IN_PLAYLIST",
    "BLACKLISTED_MODERATION_REJECTED",
    "BLACKLISTED_DUPLICATE_SOURCE",
    "BLACKLISTED_PLATFORM_DURATION_LIMIT",
    "BLACKLISTED_PLATFORM_DURATION_LIMIT_AFTER_TRIM",
}

def load(path,default=None):
    p=pathlib.Path(path)
    if not p.exists(): return {} if default is None else default
    return json.loads(p.read_text(encoding='utf-8'))

def save(path,data):
    p=pathlib.Path(path);p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')

def sval(v): return '' if v is None else str(v).strip()

def reconcile_ready_receipts(reg_path,reg,control):
    """Recover canonical state only from a matching, already persisted cadangan receipt.

    This never creates/replaces a Roblox asset. It only repairs source-state drift when the
    same asset/source has already been verified Approved and permissioned for BBYA.
    """
    changed=[]
    for t in reg.get('tracks',[]):
        idx=int(t.get('index',0) or 0)
        if idx<=0 or sval(t.get('status')) in {
            'LIVE_IN_PLAYLIST','BLACKLISTED_MODERATION_REJECTED','BLACKLISTED_DUPLICATE_SOURCE',
            'BLACKLISTED_PLATFORM_DURATION_LIMIT','BLACKLISTED_PLATFORM_DURATION_LIMIT_AFTER_TRIM'
        }:
            continue
        rp=control/'deploy-status'/f'bbya-funkot-cadangan-track{idx:02d}.json'
        receipt=load(rp,{})
        if receipt.get('status')!='READY_TO_INJECT':
            continue
        aid=sval(receipt.get('assetId'))
        if not aid or aid!=sval(t.get('assetId')):
            continue
        rsha=sval(receipt.get('sourceSha256'));tsha=sval(t.get('sourceSha256'))
        if tsha and rsha and rsha!=tsha:
            continue
        if receipt.get('bbyaPermission') is not True or receipt.get('moderationLastKnown')!='Approved':
            continue
        t['assetId']=aid
        t['bbyaPermission']=True
        t['moderationLastKnown']='Approved'
        t['status']='READY_TO_INJECT'
        changed.append(idx)
    if changed:
        save(reg_path,reg)
    return changed

def preflight(args):
    source=pathlib.Path(args.source);control=pathlib.Path(args.control)
    reg_path=source/'maps/bbya-social-hub/audio-playlists/funkot.json'
    rights_path=source/'maps/bbya-social-hub/audio-rights-confirmation-funkot.json'
    plan_path=control/'state/bbya-funkot-plan.json'
    reg=load(reg_path);rights=load(rights_path,{})
    tracks=sorted(reg.get('tracks',[]),key=lambda t:int(t.get('index',0)))
    if not tracks: raise SystemExit('Missing Funkot registry')
    required=sval(reg.get('sourceFolderId'));confirmed=sval(rights.get('driveFolderId'))
    if rights.get('confirmed') is not True or not required or confirmed!=required:
        plan={'action':'RIGHTS_CONFIRMATION_REQUIRED','requiredFolderId':required,'confirmedFolderId':confirmed or None,'confirmed':rights.get('confirmed') is True,'queueCount':len(tracks)}
        save(plan_path,plan);print(json.dumps(plan));return

    recovered=reconcile_ready_receipts(reg_path,reg,control)
    if recovered:
        print('RECOVERED_READY_RECEIPTS',recovered)
    tracks=sorted(reg.get('tracks',[]),key=lambda t:int(t.get('index',0)))

    pending=[t for t in tracks if sval(t.get('assetId')) and sval(t.get('status')) not in TERMINAL]
    if pending:
        t=pending[0];plan={'action':'RECHECK_EXISTING','trackIndex':int(t['index']),'assetId':sval(t.get('assetId')),'driveFileId':t.get('driveFileId'),'sourceSha256':t.get('sourceSha256')}
        save(plan_path,plan);print(json.dumps(plan));return
    requested=sval(args.requested).lower()
    selected=None
    if requested and requested!='auto':
        try: idx=int(requested)
        except ValueError: raise SystemExit('requested track must be auto or integer')
        selected=next((t for t in tracks if int(t.get('index',0))==idx),None)
        if not selected: raise SystemExit('requested Funkot track missing')
        if sval(selected.get('status')) in TERMINAL:
            plan={'action':'TERMINAL_SKIP','trackIndex':idx,'status':selected.get('status')};save(plan_path,plan);print(json.dumps(plan));return
    else:
        selected=next((t for t in tracks if sval(t.get('status')) not in TERMINAL),None)
    if selected is None:
        plan={'action':'DONE','queueCount':len(tracks)};save(plan_path,plan);print(json.dumps(plan));return
    if sval(selected.get('assetId')):
        action='RECHECK_EXISTING'
    else:
        action='UPLOAD_NEW'
    plan={'action':action,'trackIndex':int(selected['index']),'assetId':sval(selected.get('assetId')) or None,'driveFileId':selected.get('driveFileId'),'sourceSha256':selected.get('sourceSha256'),'title':selected.get('title')}
    save(plan_path,plan);print(json.dumps(plan))

def postprocess(args):
    source=pathlib.Path(args.source);control=pathlib.Path(args.control);idx=int(args.track)
    reg_path=source/'maps/bbya-social-hub/audio-playlists/funkot.json'
    report_path=source/'deploy-status'/f'bbya-funkot-track{idx:02d}.json'
    reg=load(reg_path);report=load(report_path,{})
    t=next((x for x in reg.get('tracks',[]) if int(x.get('index',0))==idx),None)
    if not t or not report: raise SystemExit('Missing Funkot track/report after runner')
    receipt={'status':t.get('status'),'trackIndex':idx,'title':t.get('title'),'driveFileId':t.get('driveFileId'),'sourceSha256':t.get('sourceSha256'),'assetId':t.get('assetId'),'bbyaPermission':bool(t.get('bbyaPermission')),'moderationLastKnown':t.get('moderationLastKnown'),'sourceReportStatus':report.get('status'),'recordedAt':dt.datetime.now(dt.timezone.utc).isoformat()}
    save(control/'deploy-status'/f'bbya-funkot-cadangan-track{idx:02d}.json',receipt)
    save(control/'deploy-status'/'bbya-funkot-cadangan-last.json',receipt)
    print(json.dumps(receipt))

def mark_live(args):
    source=pathlib.Path(args.source);idx=int(args.track)
    reg_path=source/'maps/bbya-social-hub/audio-playlists/funkot.json';reg=load(reg_path)
    current=next((x for x in reg.get('tracks',[]) if int(x.get('index',0))==idx),None)
    if not current: raise SystemExit('Track missing for live mark')
    if current.get('status')!='READY_TO_INJECT' or not current.get('assetId') or current.get('bbyaPermission') is not True:
        raise SystemExit('Live mark gate failed')

    now=dt.datetime.now(dt.timezone.utc).isoformat();live=[]
    for t in reg.get('tracks',[]):
        if t.get('status')=='READY_TO_INJECT' and t.get('assetId') and t.get('bbyaPermission') is True:
            tidx=int(t.get('index',0));t['status']='LIVE_IN_PLAYLIST';live.append(tidx)
            report=source/'deploy-status'/f'bbya-funkot-track{tidx:02d}.json';d=load(report,{})
            if d:
                d['status']='LIVE_PUBLISHED';d['livePublishedAt']=now;save(report,d)
    save(reg_path,reg)
    print(json.dumps({'triggerTrackIndex':idx,'status':'LIVE_IN_PLAYLIST','publishedTrackIndexes':live,'assetId':current.get('assetId')}))

def main():
    p=argparse.ArgumentParser();sub=p.add_subparsers(dest='cmd',required=True)
    a=sub.add_parser('preflight');a.add_argument('--source',required=True);a.add_argument('--control',required=True);a.add_argument('--requested',default='auto');a.set_defaults(func=preflight)
    b=sub.add_parser('postprocess');b.add_argument('--source',required=True);b.add_argument('--control',required=True);b.add_argument('--track',required=True);b.set_defaults(func=postprocess)
    c=sub.add_parser('mark-live');c.add_argument('--source',required=True);c.add_argument('--track',required=True);c.set_defaults(func=mark_live)
    args=p.parse_args();args.func(args)
if __name__=='__main__': main()
