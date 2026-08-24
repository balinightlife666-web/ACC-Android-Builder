#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACC_HOME=${ACC_HOME:-$HOME/acc-publisher}
BIN="$HOME/bin"

chmod +x "$HERE/builder.sh" "$HERE/set-key.sh" "$HERE/doctor.sh" 2>/dev/null || true
mkdir -p "$BIN"

cat > "$BIN/acc" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "$HERE/builder.sh" "\$@"
EOF
chmod +x "$BIN/acc"

if ! grep -Fq 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null; then
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
fi
export PATH="$HOME/bin:$PATH"

# Prepare local publisher workspace and clone maps repo if credentials allow it.
"$HERE/builder.sh" setup

# Ask once for Roblox Open Cloud API key when not configured yet.
if [ ! -s "$ACC_HOME/secrets.env" ] || grep -q 'PASTE_ROBLOX_OPEN_CLOUD_KEY_HERE' "$ACC_HOME/secrets.env"; then
  "$HERE/set-key.sh"
fi

echo
echo 'ACC LOCAL ROBLOX PUBLISHER READY'
echo 'Commands:'
echo '  acc bbya       # BBYA Social Hub'
echo '  acc bbyavatar  # BBYAVATAR'
echo '  acc becak      # BECAK E-BIKE'
echo '  acc list       # list registered maps'
echo '  acc status     # publisher status'
echo
echo 'No GitHub-hosted Actions runner is used for these direct publishes.'
