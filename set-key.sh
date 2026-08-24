#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail
ACC_HOME=${ACC_HOME:-$HOME/acc-publisher}
SECRETS="$ACC_HOME/secrets.env"
mkdir -p "$ACC_HOME"
printf 'Paste ROBLOX Open Cloud API key (input hidden): '
IFS= read -rs KEY
echo
[ -n "$KEY" ] || { echo 'Key kosong. Batal.'; exit 1; }
printf 'ROBLOX_API_KEY=%q\n' "$KEY" > "$SECRETS"
chmod 600 "$SECRETS"
unset KEY
echo "Roblox key tersimpan lokal di HP: $SECRETS"
echo 'Key tidak dikirim ke GitHub dan tidak dimasukkan ke repo.'
