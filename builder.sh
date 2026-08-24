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
  ./builder.sh setup
  ./builder.sh pull
  ./builder.sh list
  ./builder.sh publish <map-id>
  ./builder.sh bbya
  ./builder.sh bbyavatar
  ./builder.sh becak
  ./builder.sh status

Primary target:
  ./builder.sh bbya

Map IDs are read from maps/registry.json in ACC-Roblox-maps.
No GitHub Actions hosted runner is used.
EOF
}

need_maps_repo() {
  if [ ! -d "$MAPS_DIR/.git" ]; then
    echo "Maps repo is not cloned yet. Run: ./builder.sh setup"
    exit 2
  fi
}

load_secret() {
  if [ -f "$SECRETS" ]; then
    # shellcheck disable=SC1090
    source "$SECRETS"
  fi
  if [ -z "${ROBLOX_API_KEY:-}" ]; then
    echo "Missing ROBLOX_API_KEY."
    echo "Create $SECRETS with: ROBLOX_API_KEY='YOUR_ROBLOX_OPEN_CLOUD_KEY'"
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
  node - <<NODE
const r=require('${MAPS_DIR}/maps/registry.json');
for (const [id,m] of Object.entries(r.maps)) console.log(`${id}\t${m.enabled?'ENABLED':'disabled'}\t${m.name}`);
NODE
}

validate_target() {
  local map_id="$1"
  node - "$MAPS_DIR" "$map_id" <<'NODE'
const fs=require('fs'); const path=require('path');
const root=process.argv[2], id=process.argv[3];
const r=JSON.parse(fs.readFileSync(path.join(root,'maps/registry.json'),'utf8'));
const t=r.maps?.[id];
if(!t) throw new Error(`Unknown map id: ${id}`);
if(!t.enabled) throw new Error(`Target disabled: ${id}`);
if(!/^\d+$/.test(String(t.universeId)) || !/^\d+$/.test(String(t.placeId))) throw new Error('Invalid universe/place id');
const f=path.join(root,t.file);
if(!fs.existsSync(f)) throw new Error(`Place file missing: ${t.file}`);
console.log(`Target OK: ${t.name}`);
console.log(`File: ${t.file}`);
NODE
}

cmd_publish() {
  local map_id="$1"
  need_maps_repo
  load_secret
  cmd_pull
  validate_target "$map_id"

  local stamp logfile
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

  echo
  echo "PUBLISH COMPLETE: $map_id"
}

cmd_status() {
  need_maps_repo
  echo "Repo: $MAPS_DIR"
  echo "Commit: $(git -C "$MAPS_DIR" rev-parse --short HEAD)"
  echo "Branch: $(git -C "$MAPS_DIR" branch --show-current)"
  echo "Secrets: $([ -f "$SECRETS" ] && echo configured || echo missing)"
  echo "Recent logs:"
  ls -1t "$LOGS" 2>/dev/null | head -n 5 || true
}

case "${1:-}" in
  setup) cmd_setup ;;
  pull) cmd_pull ;;
  list) cmd_list ;;
  publish) [ $# -eq 2 ] || { usage; exit 1; }; cmd_publish "$2" ;;
  bbya) cmd_publish a-club ;;
  bbyavatar) cmd_publish bbyavatar ;;
  becak) cmd_publish becak-e-bike ;;
  status) cmd_status ;;
  *) usage ;;
esac
