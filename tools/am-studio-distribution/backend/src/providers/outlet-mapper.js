const RULES = new Map([
  ['Spotify', single(['spotify'])],
  ['Apple Music', single(['apple music', 'applemusic'])],
  ['TikTok', single(['tiktok'])],
  ['YouTube Music', single(['youtube music', 'youtubemusic'])],
  ['Instagram / Facebook', multi(['instagram', 'facebook', 'meta'])],
  ['Amazon Music', single(['amazon music', 'amazonmusic'])],
  ['Deezer', single(['deezer'])],
  ['TIDAL', single(['tidal'])]
]);

export function mapDestinations(destinations = [], outlets = []) {
  const normalizedOutlets = (Array.isArray(outlets) ? outlets : [])
    .filter(Boolean)
    .map(outlet => ({
      id: outlet.id,
      key: text(outlet.key),
      name: text(outlet.name),
      type: text(outlet.type),
      isAiDsp: Boolean(outlet.is_ai_dsp),
      isUgcStore: Boolean(outlet.is_ugc_store),
      search: normalize(`${text(outlet.key)} ${text(outlet.name)}`)
    }))
    .filter(outlet => outlet.id !== undefined && (outlet.key || outlet.name));

  const resolved = {};
  const missing = [];
  const ambiguous = [];
  const unsupportedCanonical = [];

  for (const destination of uniqueStrings(destinations)) {
    const rule = RULES.get(destination);
    if (!rule) {
      unsupportedCanonical.push(destination);
      continue;
    }
    const candidates = normalizedOutlets.filter(outlet => rule.aliases.some(alias => outlet.search.includes(alias)));
    if (rule.mode === 'multi') {
      if (!candidates.length) missing.push(destination);
      else resolved[destination] = candidates.map(publicOutlet);
      continue;
    }
    if (candidates.length === 1) {
      resolved[destination] = [publicOutlet(candidates[0])];
    } else if (!candidates.length) {
      missing.push(destination);
    } else {
      ambiguous.push({ destination, candidates: candidates.map(publicOutlet) });
    }
  }

  return {
    ok: missing.length === 0 && ambiguous.length === 0 && unsupportedCanonical.length === 0,
    resolved,
    missing,
    ambiguous,
    unsupportedCanonical
  };
}

export function supportedCanonicalDestinations() {
  return [...RULES.keys()];
}

function single(aliases) { return { mode: 'single', aliases: aliases.map(normalize) }; }
function multi(aliases) { return { mode: 'multi', aliases: aliases.map(normalize) }; }
function text(value) { return typeof value === 'string' ? value.trim() : ''; }
function normalize(value) { return text(value).toLowerCase().replace(/[^a-z0-9]+/g, ' ').trim(); }
function uniqueStrings(values) {
  if (!Array.isArray(values)) return [];
  return [...new Set(values.map(text).filter(Boolean))];
}
function publicOutlet(outlet) {
  return {
    id: outlet.id,
    key: outlet.key,
    name: outlet.name,
    type: outlet.type,
    isAiDsp: outlet.isAiDsp,
    isUgcStore: outlet.isUgcStore
  };
}
