#!/data/data/com.termux/files/usr/bin/bash
set -u

source "${HOME}/acc-builder/env.sh" 2>/dev/null || true

fail=0
check() {
  local label="$1" cmd="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '[OK]   %-14s %s\n' "$label" "$(command -v "$cmd")"
  else
    printf '[MISS] %-14s %s\n' "$label" "$cmd"
    fail=1
  fi
}

printf 'ACC Android Builder doctor\n'
printf '==========================\n'
check Git git
check Java java
check Node node
check NPM npm
check Gradle gradle
check Curl curl
check Unzip unzip

printf '\nJava:\n'
java -version 2>&1 | head -n 3 || true
printf '\nNode: %s\n' "$(node --version 2>/dev/null || echo unavailable)"
printf 'Gradle: %s\n' "$(gradle --version 2>/dev/null | awk '/Gradle /{print $2; exit}' || echo unavailable)"
printf 'Architecture: %s\n' "$(uname -m)"
printf 'Android: %s\n' "$(getprop ro.build.version.release 2>/dev/null || echo unknown)"
printf 'Free storage:\n'
df -h "$HOME" | tail -n 1 || true

if command -v aapt2 >/dev/null 2>&1; then
  printf '[OK]   aapt2          %s\n' "$(command -v aapt2)"
else
  printf '[INFO] aapt2          not installed; some Android Gradle projects may need a compatible ARM build tool.\n'
fi

if [ "$fail" -eq 0 ]; then
  printf '\nCORE TOOLCHAIN READY.\n'
else
  printf '\nCORE TOOLCHAIN INCOMPLETE. Re-run setup-termux.sh.\n'
fi
exit "$fail"
