#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ACC_HOME=${ACC_HOME:-$HOME/acc-publisher}
MAPS_DIR="$ACC_HOME/ACC-Roblox-maps"
LOGS="$ACC_HOME/logs"
SECRETS="$ACC_HOME/secrets.env"
REPO_URL="https://github.com/ardarawk-cloud/ACC-Roblox-maps.git"
mkdir -p "$ACC_HOME" "$LOGS"

usage() {
  cat <<'EOF'
ACC Local Roblox Publisher

Usage:
  acc setup
  acc pull
  acc list
  acc <map-id>
  acc publish <map-id>
  acc all
  acc build-all
  acc status

Examples:
  acc a-club
  acc bbyavatar
  acc becak-e-bike
  acc all

Every enabled map in maps/registry.json is supported automatically.
Disabled/incomplete targets are skipped by `acc all`.
No GitHub-hosted Actions runner is used.
EOF
}

need_maps_repo() {
  if [ ! -d "$MAPS_DIR/.git" ]; then
    echo "Maps repo is not cloned yet. Run: acc setup"
    exit 2
  fi
}

load_secret() {
  if [ -f "$SECRETS" ]; then
    # shellcheck disable=SC1090
    source "$SECRETS"
  fi
  if [ -z "${ROBLOX_API_KEY:-}" ] || [ "$ROBLOX_API_KEY" = "PASTE_ROBLOX_OPEN_CLOUD_KEY_HERE" ]; then
    echo "Missing ROBLOX_API_KEY."
    echo "Edit $SECRETS and paste the Roblox Open Cloud key there."
    echo "Keep that file only on this phone. Do not commit it."
    exit 3
  fi
}

cmd_setup() {
  if [ -d "$MAPS_DIR/.git" ]; then
    echo "Maps repo already present: $MAPS_DIR"
  else
    echo "Cloning ACC-Roblox-maps..."
    git clone "$REPO_URL" "$MAPS_DIR"
  fi
  chmod 700 "$ACC_HOME" 2>/dev/null || true
  if [ ! -f "$SECRETS" ]; then
    cat > "$SECRETS" <<'EOF'
# Local-only secret. Never commit this file.
ROBLOX_API_KEY='PASTE_ROBLOX_OPEN_CLOUD_KEY_HERE'
EOF
    chmod 600 "$SECRETS"
    echo "Created secret template: $SECRETS"
  fi
  echo "Setup complete."
}

cmd_pull() {
  need_maps_repo
  git -C "$MAPS_DIR" fetch --all --prune
  git -C "$MAPS_DIR" checkout main
  git -C "$MAPS_DIR" pull --ff-only origin main
}

cmd_list() {
  need_maps_repo
  node - "$MAPS_DIR" <<'NODE'
const fs=require('fs'); const path=require('path');
const root=process.argv[2];
const r=JSON.parse(fs.readFileSync(path.join(root,'maps/registry.json'),'utf8'));
for (const [id,m] of Object.entries(r.maps)) {
  const complete=/^\d+$/.test(String(m.universeId)) && /^\d+$/.test(String(m.placeId));
  console.log(id+'\t'+(m.enabled&&complete?'READY':m.enabled?'INCOMPLETE':'disabled')+'\t'+m.name);
}
NODE
}

validate_target() {
  local map_id="$1"
  node - "$MAPS_DIR" "$map_id" <<'NODE'
const fs=require('fs'); const path=require('path');
const root=process.argv[2], id=process.argv[3];
const r=JSON.parse(fs.readFileSync(path.join(root,'maps/registry.json'),'utf8'));
const t=r.maps?.[id];
if(!t) throw new Error('Unknown map id: '+id);
if(!t.enabled) throw new Error('Target disabled: '+id);
if(!/^\d+$/.test(String(t.universeId)) || !/^\d+$/.test(String(t.placeId))) throw new Error('Invalid universe/place id');
const f=path.join(root,t.file);
if(!fs.existsSync(f)) throw new Error('Place file missing: '+t.file);
console.log('Target OK: '+t.name);
console.log('File: '+t.file);
NODE
}

publish_one_no_pull() {
  local map_id="$1" stamp logfile
  validate_target "$map_id"
  stamp=$(date +%Y%m%d-%H%M%S)
  logfile="$LOGS/${map_id}-${stamp}.log"
  echo "Publishing $map_id"
  echo "Log: $logfile"
  (
    cd "$MAPS_DIR"
    export ROBLOX_API_KEY
    export PUBLISH_RECEIPT_DIR="deploy-status/local-publisher"
    export GITHUB_SHA="$(git rev-parse HEAD)"
    node scripts/publish-map.js "$map_id"
  ) 2>&1 | tee "$logfile"
  echo "PUBLISH COMPLETE: $map_id"
}

cmd_publish() {
  local map_id="$1"
  need_maps_repo
  load_secret
  cmd_pull
  publish_one_no_pull "$map_id"
}

ready_map_ids() {
  node - "$MAPS_DIR" <<'NODE'
const fs=require('fs'); const path=require('path');
const root=process.argv[2];
const r=JSON.parse(fs.readFileSync(path.join(root,'maps/registry.json'),'utf8'));
for (const [id,t] of Object.entries(r.maps)) {
  if (!t.enabled) continue;
  if (!/^\d+$/.test(String(t.universeId)) || !/^\d+$/.test(String(t.placeId))) continue;
  const f=path.join(root,t.file || '');
  if (!fs.existsSync(f)) continue;
  console.log(id);
}
NODE
}

cmd_all() {
  need_maps_repo
  load_secret
  cmd_pull
  mapfile -t ids < <(ready_map_ids)
  if [ "${#ids[@]}" -eq 0 ]; then
    echo "No READY maps found."
    exit 4
  fi
  echo "Publishing ${#ids[@]} READY map(s) sequentially: ${ids[*]}"
  local ok=0 fail=0 id
  for id in "${ids[@]}"; do
    echo
    echo "===== $id ====="
    if publish_one_no_pull "$id"; then
      ok=$((ok+1))
    else
      fail=$((fail+1))
      echo "FAILED: $id"
    fi
  done
  echo
  echo "ALL DONE — success=$ok failed=$fail total=${#ids[@]}"
  [ "$fail" -eq 0 ]
}

cmd_status() {
  need_maps_repo
  echo "Repo: $MAPS_DIR"
  echo "Commit: $(git -C "$MAPS_DIR" rev-parse --short HEAD)"
  echo "Branch: $(git -C "$MAPS_DIR" branch --show-current)"
  echo "Secrets: $([ -f "$SECRETS" ] && echo configured || echo missing)"
  echo "Recent logs:"
  ls -1t "$LOGS" 2>/dev/null | head -n 10 || true
}

cmd_dynamic() {
  local requested="$1"
  need_maps_repo
  if node - "$MAPS_DIR" "$requested" <<'NODE' >/dev/null 2>&1
const fs=require('fs'); const path=require('path');
const r=JSON.parse(fs.readFileSync(path.join(process.argv[2],'maps/registry.json'),'utf8'));
process.exit(r.maps?.[process.argv[3]] ? 0 : 1);
NODE
  then
    cmd_publish "$requested"
  else
    usage
    exit 1
  fi
}

case "${1:-}" in
  setup) cmd_setup ;;
  pull) cmd_pull ;;
  list) cmd_list ;;
  publish) [ $# -eq 2 ] || { usage; exit 1; }; cmd_publish "$2" ;;
  all|build-all|publish-all) cmd_all ;;
  bbya) cmd_publish a-club ;;
  status) cmd_status ;;
  "") usage ;;
  *) cmd_dynamic "$1" ;;
esac
