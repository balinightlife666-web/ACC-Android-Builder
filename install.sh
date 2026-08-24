#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ACC_HOME=${ACC_HOME:-$HOME/acc-publisher}
TERMUX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"

chmod +x "$HERE/builder.sh" "$HERE/set-key.sh" "$HERE/doctor.sh" 2>/dev/null || true
mkdir -p "$TERMUX_BIN"

cat > "$TERMUX_BIN/acc" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "$HERE/builder.sh" "\$@"
EOF
chmod +x "$TERMUX_BIN/acc"
hash -r 2>/dev/null || true

# Prepare local publisher workspace and clone maps repo if credentials allow it.
"$HERE/builder.sh" setup

# Ask once for Roblox Open Cloud API key when not configured yet.
if [ ! -s "$ACC_HOME/secrets.env" ] || grep -q 'PASTE_ROBLOX_OPEN_CLOUD_KEY_HERE' "$ACC_HOME/secrets.env"; then
  "$HERE/set-key.sh"
fi

echo
echo 'ACC LOCAL ROBLOX PUBLISHER READY'
echo 'Commands:'
echo '  acc bbya'
echo '  acc bbyavatar'
echo '  acc becak'
echo '  acc list'
echo '  acc all'
echo '  acc status'
