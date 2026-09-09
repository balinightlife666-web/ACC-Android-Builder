import test from 'node:test';
import assert from 'node:assert/strict';
import { LabelGridAdapter } from '../src/providers/labelgrid.js';
import { createProvider } from '../src/providers/index.js';

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
