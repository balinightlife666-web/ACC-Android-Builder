#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

source "${HOME}/acc-builder/env.sh" 2>/dev/null || true
ACC_HOME=${ACC_HOME:-$HOME/acc-builder}
PROJECTS="$ACC_HOME/projects"
OUTPUT="$ACC_HOME/output"
LOGS="$ACC_HOME/logs"
mkdir -p "$PROJECTS" "$OUTPUT" "$LOGS"

usage() {
  cat <<'EOF'
ACC Android Builder

Usage:
  ./builder.sh add <name> <git-url> [branch]
  ./builder.sh build <name>
  ./builder.sh pull <name>
  ./builder.sh list

Examples:
  ./builder.sh add content-hub https://github.com/OWNER/REPO.git main
  ./builder.sh build content-hub
EOF
}

cfg() { echo "$PROJECTS/$1/.acc-project"; }

cmd_add() {
  local name="$1" url="$2" branch="${3:-main}" dir="$PROJECTS/$name"
  if [ -d "$dir/.git" ]; then
    echo "Project already exists: $name"
  else
    git clone --branch "$branch" "$url" "$dir"
  fi
  cat > "$(cfg "$name")" <<EOF
NAME=$name
URL=$url
BRANCH=$branch
EOF
  echo "Added: $name"
}

cmd_pull() {
  local name="$1" dir="$PROJECTS/$name"
  [ -d "$dir/.git" ] || { echo "Unknown project: $name"; exit 2; }
  git -C "$dir" fetch --all --prune
  local branch
  branch=$(awk -F= '/^BRANCH=/{print $2}' "$(cfg "$name")" 2>/dev/null || echo main)
  git -C "$dir" checkout "$branch"
  git -C "$dir" pull --ff-only origin "$branch"
}

copy_apks() {
  local name="$1" dir="$2" stamp
  stamp=$(date +%Y%m%d-%H%M%S)
  local found=0
  while IFS= read -r -d '' apk; do
    found=1
    local base
    base=$(basename "$apk")
    cp -f "$apk" "$OUTPUT/${name}-${stamp}-${base}"
    echo "APK: $OUTPUT/${name}-${stamp}-${base}"
  done < <(find "$dir" -type f -name '*.apk' -path '*/build/outputs/*' -print0 2>/dev/null)
  [ "$found" -eq 1 ] || echo "No APK found in standard Gradle output paths."
}

cmd_build() {
  local name="$1" dir="$PROJECTS/$name"
  [ -d "$dir/.git" ] || { echo "Unknown project: $name"; exit 2; }
  cmd_pull "$name"

  local logfile="$LOGS/${name}-$(date +%Y%m%d-%H%M%S).log"
  echo "Build log: $logfile"
  (
    cd "$dir"

    if [ -f package.json ]; then
      if [ -f package-lock.json ]; then npm ci; else npm install; fi
      if node -e 'const p=require("./package.json");process.exit(p.scripts&&p.scripts.build?0:1)' 2>/dev/null; then
        npm run build
      fi
      if [ -f capacitor.config.ts ] || [ -f capacitor.config.json ] || [ -f capacitor.config.js ]; then
        npx cap sync android
      fi
    fi

    if [ -x ./gradlew ]; then
      ./gradlew --no-daemon assembleDebug
    elif [ -f gradlew ]; then
      chmod +x gradlew
      ./gradlew --no-daemon assembleDebug
    elif [ -d android ] && [ -f android/gradlew ]; then
      chmod +x android/gradlew
      (cd android && ./gradlew --no-daemon assembleDebug)
    elif [ -f build.gradle ] || [ -f build.gradle.kts ]; then
      gradle --no-daemon assembleDebug
    else
      echo "ERROR: No supported Android Gradle project detected."
      exit 3
    fi
  ) 2>&1 | tee "$logfile"

  copy_apks "$name" "$dir"
}

cmd_list() {
  echo "Registered projects:"
  find "$PROJECTS" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' 2>/dev/null | sort
  echo
  echo "APK output: $OUTPUT"
}

case "${1:-}" in
  add) [ $# -ge 3 ] || { usage; exit 1; }; cmd_add "$2" "$3" "${4:-main}" ;;
  build) [ $# -eq 2 ] || { usage; exit 1; }; cmd_build "$2" ;;
  pull) [ $# -eq 2 ] || { usage; exit 1; }; cmd_pull "$2" ;;
  list) cmd_list ;;
  *) usage ;;
esac
