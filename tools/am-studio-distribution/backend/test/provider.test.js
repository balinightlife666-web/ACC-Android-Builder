import test from 'node:test';
import assert from 'node:assert/strict';
import { LabelGridAdapter } from '../src/providers/labelgrid.js';
import { createProvider } from '../src/providers/index.js';
import { mapDestinations } from '../src/providers/outlet-mapper.js';

test('labelgrid adapter remains disabled without server token', async () => {
  const adapter = new LabelGridAdapter({ token: '' });
  assert.equal(adapter.isConfigured(), false);
  await assert.rejects(() => adapter.getMe(), /not configured/i);
});

test('labelgrid sandbox adapter sends bearer token server-side', async () => {
  let seenUrl = '';
  let seenAuth = '';
  const fakeFetch = async (url, init) => {
    seenUrl = url;
    seenAuth = init.headers.authorization;
    return {
      ok: true,
      status: 200,
      async text() { return JSON.stringify({ id: 'provider-user' }); }
    };
  };
  const adapter = new LabelGridAdapter({ token: 'server-secret', environment: 'sandbox', fetchImpl: fakeFetch });
  const me = await adapter.getMe();
  assert.equal(me.id, 'provider-user');
  assert.match(seenUrl, /^https:\/\/api-sandbox\.stg\.labelgrid\.com\/api\/public\/me$/);
  assert.equal(seenAuth, 'Bearer server-secret');
});

test('provider registry fails closed when provider is disabled', async () => {
  const provider = createProvider({ name: 'disabled' });
  assert.equal(provider.isConfigured(), false);
  await assert.rejects(() => provider.distribute('rel_1'), /No production distribution provider/i);
});

test('labelgrid track upload-url request includes validated filename', async () => {
  let seenUrl = '';
  let seenBody = null;
  const fakeFetch = async (url, init) => {
    seenUrl = url;
    seenBody = JSON.parse(init.body);
    return {
      ok: true,
      status: 200,
      async text() { return JSON.stringify({ upload_url: 'https://upload.example', key: 'abc', expires_in: 900 }); }
    };
  };
  const adapter = new LabelGridAdapter({ token: 'secret', environment: 'sandbox', fetchImpl: fakeFetch });
  const response = await adapter.getTrackUploadUrl(123, 'stereo', 'AM Studio Master.wav');
  assert.equal(response.key, 'abc');
  assert.match(seenUrl, /\/tracks\/123\/files\/stereo\/upload-url$/);
  assert.equal(seenBody.filename, 'AM Studio Master.wav');
  await assert.rejects(() => adapter.getTrackUploadUrl(123, 'stereo', '../bad.wav'), /filename is invalid/i);
});

test('labelgrid delivery status is queried through canonical adapter method', async () => {
  let seenUrl = '';
  const fakeFetch = async (url) => {
    seenUrl = url;
    return {
      ok: true,
      status: 200,
      async text() { return JSON.stringify({ status: 'processing' }); }
    };
  };
  const adapter = new LabelGridAdapter({ token: 'secret', environment: 'sandbox', fetchImpl: fakeFetch });
  const result = await adapter.deliveryStatus(456);
  assert.equal(result.status, 'processing');
  assert.match(seenUrl, /\/releases\/456\/delivery-status$/);
});

test('dynamic outlet mapper resolves provider IDs without hard-coding them', () => {
  const outlets = [
    { id: 91, key: 'spotify', name: 'Spotify', type: 'streaming' },
    { id: 77, key: 'apple-music', name: 'Apple Music', type: 'streaming' },
    { id: 52, key: 'tiktok', name: 'TikTok', type: 'ugc', is_ugc_store: true },
    { id: 14, key: 'instagram', name: 'Instagram', type: 'ugc', is_ugc_store: true },
    { id: 15, key: 'facebook', name: 'Facebook', type: 'ugc', is_ugc_store: true }
  ];
  const mapped = mapDestinations(['Spotify', 'Apple Music', 'TikTok', 'Instagram / Facebook'], outlets);
  assert.equal(mapped.ok, true);
  assert.equal(mapped.resolved.Spotify[0].id, 91);
  assert.equal(mapped.resolved['Apple Music'][0].id, 77);
  assert.deepEqual(mapped.resolved['Instagram / Facebook'].map(item => item.id), [14, 15]);
});

test('dynamic outlet mapper fails closed on missing or ambiguous provider outlets', () => {
  const mapped = mapDestinations(['Spotify', 'YouTube Music'], [
    { id: 1, key: 'spotify-a', name: 'Spotify' },
    { id: 2, key: 'spotify-b', name: 'Spotify Premium' }
  ]);
  assert.equal(mapped.ok, false);
  assert.equal(mapped.ambiguous[0].destination, 'Spotify');
  assert.deepEqual(mapped.missing, ['YouTube Music']);
});
