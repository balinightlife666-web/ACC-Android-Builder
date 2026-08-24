#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

TARGET="$HOME/acc-builder"
REPO_URL="https://github.com/balinightlife666-web/ACC-Android-Builder.git"

if [ -d "$TARGET/.git" ]; then
  git -C "$TARGET" pull --ff-only
else
  git clone "$REPO_URL" "$TARGET"
fi

chmod +x "$TARGET"/*.sh
cd "$TARGET"
./setup-termux.sh
cp -f builder.sh doctor.sh "$TARGET/"
chmod +x "$TARGET/builder.sh" "$TARGET/doctor.sh"

echo
echo "Installed to: $TARGET"
echo "Run: source $TARGET/env.sh"
echo "Then: $TARGET/doctor.sh"
