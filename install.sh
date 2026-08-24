#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PREFIX_BIN="${PREFIX:-/data/data/com.termux/files/usr}/bin"
ACC_HOME=${ACC_HOME:-$HOME/acc-publisher}

chmod +x "$HERE/builder.sh" "$HERE/set-key.sh" "$HERE/doctor.sh" 2>/dev/null || true
mkdir -p "$ACC_HOME"

cat > "$PREFIX_BIN/acc" <<EOF
#!/data/data/com.termux/files/usr/bin/bash
exec "$HERE/builder.sh" "\$@"
EOF
chmod +x "$PREFIX_BIN/acc"

# Create local secret template without forcing a GitHub clone during install.
if [ ! -f "$ACC_HOME/secrets.env" ]; then
  cat > "$ACC_HOME/secrets.env" <<'EOF'
# Local-only secret. Never commit this file.
ROBLOX_API_KEY='PASTE_ROBLOX_OPEN_CLOUD_KEY_HERE'
EOF
  chmod 600 "$ACC_HOME/secrets.env"
fi

echo
echo 'ACC LOCAL ROBLOX PUBLISHER INSTALLED'
echo 'Command installed: acc'
echo
echo 'Next required step:'
echo '  1) Give GitHub user balinightlife666-web access to ardarawk-cloud/ACC-Roblox-maps'
echo '  2) Run: acc setup'
echo '  3) Run: acc key'
echo '  4) Run: acc list'
echo '  5) Publish one map with: acc <map-id>'
echo '     or every READY map sequentially with: acc all'
echo
echo 'Installer will not repeatedly prompt for GitHub credentials anymore.'
