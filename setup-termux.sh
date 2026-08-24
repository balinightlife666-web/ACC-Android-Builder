#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

PREFIX=${PREFIX:-/data/data/com.termux/files/usr}
HOME_DIR=${HOME:-/data/data/com.termux/files/home}
ACC_HOME="$HOME_DIR/acc-builder"

printf '\n== ACC Android Builder / Termux bootstrap ==\n'

pkg update -y
pkg upgrade -y

# Core build/runtime packages. Some Android projects may require extra project-specific tools.
pkg install -y git curl wget unzip zip tar nodejs-lts openjdk-17 gradle python make clang

# Optional packages; continue when unavailable on a specific Termux repository/device.
for p in aapt aapt2 apksigner; do
  pkg install -y "$p" >/dev/null 2>&1 || true
done

mkdir -p "$ACC_HOME/projects" "$ACC_HOME/output" "$ACC_HOME/logs"

cat > "$ACC_HOME/env.sh" <<'EOF'
export JAVA_HOME=${JAVA_HOME:-$PREFIX/lib/jvm/java-17-openjdk}
export PATH="$JAVA_HOME/bin:$PATH"
export ACC_HOME=${ACC_HOME:-$HOME/acc-builder}
export GRADLE_USER_HOME=${GRADLE_USER_HOME:-$ACC_HOME/.gradle}
EOF

printf '\nEnvironment created at: %s\n' "$ACC_HOME"
printf 'Next: source %s/env.sh && ./doctor.sh\n' "$ACC_HOME"
printf '\nNOTE: Android/Gradle projects can differ. The doctor/build scripts will stop with a clear error if a project requires an SDK/tool not available on this phone.\n'
