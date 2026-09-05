#!/usr/bin/env bash
set -euo pipefail

SOURCE_REPO="ardarawk-cloud/ACC-Roblox-maps"
SOURCE_SHA="35ae2f14b94805cf50d143f0c91fc5c98121a40a"
UNIVERSE_ID="10745364913"
PLACE_ID="76001567401911"
PROJECT_PATH="maps/hangar-exclusive-club/default.project.json"

if [[ -z "${ROBLOX_KEY:-}" ]]; then
  echo "ROCKET_RACOON_PUBLISH credential is missing"
  exit 10
fi

work="${RUNNER_TEMP:-/tmp}/hangar-exclusive-club-v1"
rm -rf "$work"
mkdir -p "$work"

git clone -q "https://github.com/${SOURCE_REPO}.git" "$work/source"
git -C "$work/source" checkout -q "$SOURCE_SHA"
actual="$(git -C "$work/source" rev-parse HEAD)"
[[ "$actual" == "$SOURCE_SHA" ]] || { echo "Source SHA mismatch: $actual"; exit 11; }

project="$work/source/$PROJECT_PATH"
server="$work/source/maps/hangar-exclusive-club/club.server.lua"
client="$work/source/maps/hangar-exclusive-club/club.client.lua"

jq -e . "$project" >/dev/null
grep -Fq 'HangarExclusiveClub' "$project"
grep -Fq '10745364913' "$server"
grep -Fq '76001567401911' "$server"
grep -Fq 'rbxassetid://1848354536' "$server"
grep -Fq 'rbxassetid://1837879082' "$server"
grep -Fq 'Hangar Exclusive Club' "$client"
echo "HANGAR SOURCE LOCK PASS source=$actual universe=$UNIVERSE_ID place=$PLACE_ID"

mkdir -p "$work/rojo"
curl -fsSL 'https://github.com/rojo-rbx/rojo/releases/download/v7.7.0/rojo-7.7.0-linux-x86_64.zip' -o "$work/rojo.zip"
unzip -q -o "$work/rojo.zip" -d "$work/rojo"
rojo="$(find "$work/rojo" -type f -name rojo | head -n1)"
[[ -n "$rojo" ]] || { echo 'Rojo binary missing'; exit 20; }
chmod +x "$rojo"
"$rojo" --version

place="$work/hangar-exclusive-club.rbxl"
"$rojo" build "$project" -o "$place"
test -s "$place"
bytes="$(stat -c%s "$place")"
(( bytes >= 1024 )) || { echo "Generated RBXL suspiciously small: $bytes"; exit 21; }
place_sha="$(sha256sum "$place" | awk '{print $1}')"
echo "HANGAR BUILD PASS bytes=$bytes sha256=$place_sha"

url="https://apis.roblox.com/universes/v1/${UNIVERSE_ID}/places/${PLACE_ID}/versions?versionType=Published"
response="$work/publish-response.json"
http="$(curl -sS --location -o "$response" -w '%{http_code}' \
  -X POST "$url" \
  -H "x-api-key: $ROBLOX_KEY" \
  -H 'Content-Type: application/octet-stream' \
  --data-binary "@$place")"
body="$(cat "$response")"
echo "Roblox publish HTTP $http"
[[ "$http" =~ ^2[0-9][0-9]$ ]] || { echo "$body"; exit 30; }
version="$(jq -r '.versionNumber // empty' "$response")"
[[ "$version" =~ ^[0-9]+$ ]] || { echo "Missing/invalid versionNumber: $body"; exit 31; }
echo "HANGAR ROBLOX PUBLISH PASS version=$version"

mkdir -p deploy-status
published_at="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
run_id="${GITHUB_RUN_ID:-manual}"
jq -n \
  --arg status 'LIVE_PUBLISHED' \
  --arg project 'HANGAR EXCLUSIVE CLUB' \
  --arg mode 'FOUNDATION_V1_ROCKET_RACOON' \
  --arg sourceRepo "$SOURCE_REPO" \
  --arg sourceCommit "$SOURCE_SHA" \
  --arg universeId "$UNIVERSE_ID" \
  --arg placeId "$PLACE_ID" \
  --arg versionNumber "$version" \
  --arg rojoVersion '7.7.0' \
  --arg placeBytes "$bytes" \
  --arg placeSha256 "$place_sha" \
  --arg runId "$run_id" \
  --arg publishedAt "$published_at" \
  '{status:$status,project:$project,mode:$mode,sourceRepo:$sourceRepo,sourceCommit:$sourceCommit,universeId:$universeId,placeId:$placeId,versionNumber:($versionNumber|tonumber),rojoVersion:$rojoVersion,placeBytes:($placeBytes|tonumber),placeSha256:$placeSha256,runId:$runId,publishedAt:$publishedAt,previewUrl:"https://www.roblox.com/games/76001567401911"}' \
  > deploy-status/hangar-exclusive-club-foundation-v1.json
cat deploy-status/hangar-exclusive-club-foundation-v1.json

echo "HANGAR_PUBLISHED_VERSION=$version" >> "${GITHUB_ENV:-/dev/null}"

# The workflow may chmod this script before execution. Restore its tracked mode
# so the receipt commit/rebase step does not fail on an unrelated dirty mode bit.
if [[ -n "${GITHUB_WORKSPACE:-}" && -d "${GITHUB_WORKSPACE}/.git" ]]; then
  git -C "$GITHUB_WORKSPACE" checkout -- scripts/publish-hangar-exclusive-club-v1.sh || true
fi
