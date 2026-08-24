#!/usr/bin/env python3
import json
import pathlib
import subprocess
import sys
import time
from datetime import datetime, timezone

ROOT = pathlib.Path(__file__).resolve().parents[1]
if len(sys.argv) != 3:
    raise SystemExit('usage: bbya-mainclub-reconcile-publisher.py <source-dir> <cadangan-receipt>')
source = pathlib.Path(sys.argv[1]).resolve()
receipt_path = pathlib.Path(sys.argv[2]).resolve()
state_path = source / 'deploy-status/bbya-audio-safe-batch.json'
club_path = source / 'maps/bbya-social-hub/30-club-systems.server.lua'

def run(cmd, check=True):
    p=subprocess.run(cmd,cwd=source,text=True,capture_output=True)
    if check and p.returncode != 0:
        raise RuntimeError(f"command failed {p.returncode}: {' '.join(cmd)}\n{p.stderr[-1200:]}")
    return p

def now():
    return datetime.now(timezone.utc).isoformat()

if not state_path.exists() or not receipt_path.exists():
    print('RECONCILE_NO_STATE_OR_RECEIPT')
    raise SystemExit(0)
state=json.loads(state_path.read_text(encoding='utf-8'))
receipt=json.loads(receipt_path.read_text(encoding='utf-8'))
if receipt.get('status') != 'PUBLISHED':
    print('RECONCILE_RECEIPT_NOT_PUBLISHED')
    raise SystemExit(0)
source_commit=str(receipt.get('sourceCommit') or '')
version=((receipt.get('response') or {}).get('versionNumber'))
if not source_commit or not version:
    print('RECONCILE_RECEIPT_INCOMPLETE')
    raise SystemExit(0)
club=club_path.read_text(encoding='utf-8') if club_path.exists() else ''
changed=[]
for did,item in sorted((state.get('items') or {}).items(), key=lambda kv:int(kv[1].get('sequence') or 999999)):
    if item.get('status') != 'APPROVED_PENDING_PUBLISH':
        continue
    staged=str(item.get('stagedCommit') or '')
    asset=str(item.get('assetId') or '')
    seq=int(item.get('sequence') or 0)
    if not staged or not asset:
        continue
    anc=run(['git','merge-base','--is-ancestor',staged,source_commit],check=False)
    if anc.returncode != 0:
        print(f'RECONCILE_SEQ_{seq:02d}_NOT_IN_PUBLISHED_SOURCE')
        continue
    if asset not in club:
        raise SystemExit(f'RECONCILE_FAIL_ASSET_NOT_IN_CLUB seq={seq} asset={asset}')
    item['status']='LIVE'
    item['liveAt']=receipt.get('publishedAt') or now()
    item['publishReceipt']=receipt
    item['reconciledFromCadanganPublisher']=True
    item['reconciledAt']=now()
    item['updatedAt']=now()
    state['lastLiveSequence']=seq
    state['lastLiveDriveId']=did
    state['lastLiveAssetId']=asset
    state['lastLiveVersion']=version
    state['status']='RUNNING_SEQUENTIAL'
    state.pop('blockedOnDriveId',None)
    state.pop('blockedOnSequence',None)
    changed.append((seq,did,asset))
if not changed:
    print('RECONCILE_NO_ELIGIBLE_STAGED_AUDIO')
    raise SystemExit(0)
state['updatedAt']=now()
state_path.write_text(json.dumps(state,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
run(['git','config','user.name','BBYA Main Club Receipt Reconciler'])
run(['git','config','user.email','actions@users.noreply.github.com'])
run(['git','config','rebase.autoStash','true'])
run(['git','add','deploy-status/bbya-audio-safe-batch.json'])
run(['git','commit','-m',f'Reconcile BBYA Club audio live via cadangan v{version} [skip ci]'])
for attempt in range(1,6):
    pull=run(['git','pull','--rebase','origin','main'],check=False)
    if pull.returncode != 0:
        run(['git','rebase','--abort'],check=False)
        time.sleep(attempt*2)
        continue
    push=run(['git','push','origin','HEAD:main'],check=False)
    if push.returncode == 0:
        print(json.dumps({'status':'RECONCILED_LIVE','version':version,'publishedSourceCommit':source_commit,'items':[{'sequence':s,'driveId':d,'assetId':a} for s,d,a in changed]},indent=2))
        raise SystemExit(0)
    time.sleep(attempt*2)
raise SystemExit('RECONCILE_GIT_PUSH_FAILED_AFTER_RETRIES')
