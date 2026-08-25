#!/usr/bin/env python3
import argparse
import datetime as dt
import json
import pathlib

TERMINAL={'LIVE_IN_PLAYLIST','READY_TO_INJECT','BLACKLISTED_MODERATION_REJECTED','BLACKLISTED_DUPLICATE_SOURCE'}


def load(path, default=None):
    p=pathlib.Path(path)
    if not p.exists(): return {} if default is None else default
    return json.loads(p.read_text(encoding='utf-8'))


def save(path, data):
    p=pathlib.Path(path);p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(data,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')


def sval(v): return '' if v is None else str(v).strip()


def preflight(args):
    source=pathlib.Path(args.source);control=pathlib.Path(args.control)
    reg_path=source/'maps/bbya-social-hub/audio-playlists/rooftop-tropical.json'
    rights_path=source/'maps/bbya-social-hub/audio-rights-confirmation-rooftop.json'
    plan_path=control/'state/bbya-rooftop-plan.json'
    reg=load(reg_path);rights=load(rights_path,{})
    tracks=sorted(reg.get('tracks',[]),key=lambda t:int(t.get('index',0)))
    if not tracks: raise SystemExit('MISSING_ROOFTOP_REGISTRY')
    required=sval(reg.get('sourceFolderId'));confirmed=sval(rights.get('driveFolderId'))
    if rights.get('confirmed') is not True or not required or confirmed!=required or rights.get('scope')!='ALL_AUDIO_IN_FOLDER':
        plan={'action':'RIGHTS_CONFIRMATION_REQUIRED','requiredFolderId':required,'confirmedFolderId':confirmed or None,'confirmed':rights.get('confirmed') is True,'queueCount':len(tracks)}
        save(plan_path,plan);print(json.dumps(plan));return
    pending=[t for t in tracks if sval(t.get('assetId')) and sval(t.get('status')) not in TERMINAL]
    if pending:
        t=pending[0]
        plan={'action':'RECHECK_EXISTING','trackIndex':int(t['index']),'assetId':sval(t.get('assetId')),'driveFileId':t.get('driveFileId'),'sourceSha256':t.get('sourceSha256'),'title':t.get('title')}
        save(plan_path,plan);print(json.dumps(plan));return
    requested=sval(args.requested).lower();selected=None
    if requested and requested!='auto':
        try: idx=int(requested)
        except ValueError: raise SystemExit('REQUESTED_TRACK_MUST_BE_AUTO_OR_INTEGER')
        selected=next((t for t in tracks if int(t.get('index',0))==idx),None)
        if not selected: raise SystemExit('REQUESTED_ROOFTOP_TRACK_MISSING')
        if sval(selected.get('status')) in TERMINAL:
            plan={'action':'TERMINAL_SKIP','trackIndex':idx,'status':selected.get('status')}
            save(plan_path,plan);print(json.dumps(plan));return
    else:
        selected=next((t for t in tracks if sval(t.get('status')) not in TERMINAL),None)
    if selected is None:
        plan={'action':'DONE','queueCount':len(tracks)};save(plan_path,plan);print(json.dumps(plan));return
    action='RECHECK_EXISTING' if sval(selected.get('assetId')) else 'UPLOAD_NEW'
    plan={'action':action,'trackIndex':int(selected['index']),'assetId':sval(selected.get('assetId')) or None,'driveFileId':selected.get('driveFileId'),'sourceSha256':selected.get('sourceSha256'),'title':selected.get('title')}
    save(plan_path,plan);print(json.dumps(plan))


def postprocess(args):
    source=pathlib.Path(args.source);control=pathlib.Path(args.control);idx=int(args.track)
    reg=load(source/'maps/bbya-social-hub/audio-playlists/rooftop-tropical.json')
    report=load(source/'deploy-status'/f'bbya-rooftop-track{idx:02d}.json',{})
    t=next((x for x in reg.get('tracks',[]) if int(x.get('index',0))==idx),None)
    if not t or not report: raise SystemExit('MISSING_ROOFTOP_TRACK_OR_REPORT')
    receipt={'status':t.get('status'),'trackIndex':idx,'title':t.get('title'),'driveFileId':t.get('driveFileId'),'sourceSha256':t.get('sourceSha256'),'assetId':t.get('assetId'),'bbyaPermission':bool(t.get('bbyaPermission')),'moderationLastKnown':t.get('moderationLastKnown'),'sourceReportStatus':report.get('status'),'recordedAt':dt.datetime.now(dt.timezone.utc).isoformat()}
    save(control/'deploy-status'/f'bbya-rooftop-cadangan-track{idx:02d}.json',receipt)
    save(control/'deploy-status'/'bbya-rooftop-cadangan-last.json',receipt)
    print(json.dumps(receipt))


def mark_live(args):
    source=pathlib.Path(args.source);idx=int(args.track)
    reg_path=source/'maps/bbya-social-hub/audio-playlists/rooftop-tropical.json';reg=load(reg_path)
    t=next((x for x in reg.get('tracks',[]) if int(x.get('index',0))==idx),None)
    if not t: raise SystemExit('ROOFTOP_TRACK_MISSING_FOR_LIVE_MARK')
    if t.get('status')!='READY_TO_INJECT' or not t.get('assetId') or t.get('bbyaPermission') is not True: raise SystemExit('ROOFTOP_LIVE_MARK_GATE_FAILED')
    t['status']='LIVE_IN_PLAYLIST';save(reg_path,reg)
    report=source/'deploy-status'/f'bbya-rooftop-track{idx:02d}.json';d=load(report,{})
    if d:
        d['status']='LIVE_PUBLISHED';d['livePublishedAt']=dt.datetime.now(dt.timezone.utc).isoformat();save(report,d)
    print(json.dumps({'trackIndex':idx,'status':'LIVE_IN_PLAYLIST','assetId':t.get('assetId')}))


def main():
    p=argparse.ArgumentParser();sub=p.add_subparsers(dest='cmd',required=True)
    a=sub.add_parser('preflight');a.add_argument('--source',required=True);a.add_argument('--control',required=True);a.add_argument('--requested',default='auto');a.set_defaults(func=preflight)
    b=sub.add_parser('postprocess');b.add_argument('--source',required=True);b.add_argument('--control',required=True);b.add_argument('--track',required=True);b.set_defaults(func=postprocess)
    c=sub.add_parser('mark-live');c.add_argument('--source',required=True);c.add_argument('--track',required=True);c.set_defaults(func=mark_live)
    args=p.parse_args();args.func(args)

if __name__=='__main__': main()
