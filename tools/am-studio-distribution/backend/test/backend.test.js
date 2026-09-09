import test from 'node:test';
import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { Readable } from 'node:stream';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

import { MemoryStore } from '../src/store.js';
import { JsonFilePersistence } from '../src/persistence.js';
import { LocalAssetStorage } from '../src/storage.js';
import { AuthService } from '../src/auth.js';

function validReleasePatch(audioAssetId, artworkAssetId) {
  return {
    title: 'Foundation Test Single',
    artistName: 'AM STUDIO Test Artist',
    labelName: 'AM STUDIO',
    genre: 'Electronic',
    releaseDate: '2026-10-01',
    songwriter: 'Test Writer',
    composer: 'Test Composer',
    copyrightOwner: 'AM STUDIO Test Rights',
    rightsConfirmed: true,
    audioAssetId,
    artworkAssetId,
    destinations: ['Spotify', 'TikTok']
  };
}

function checksum(buffer) {
  return `sha256:${createHash('sha256').update(buffer).digest('hex')}`;
}

function verifyAsset(store, kind, fileName, mime, extra = {}) {
  const bytes = Buffer.from(`${kind}-${fileName}`);
  const digest = checksum(bytes);
  const session = store.createUploadSession({
    kind, fileName, mime, sizeBytes: bytes.length, checksum: digest
  });
  store.markUploaded(session.assetId, {
    checksum: digest,
    sizeBytes: bytes.length,
    storageKey: `${session.assetId}.bin`
  });
  const asset = store.completeUpload(session.assetId, {
    durationMs: kind === 'AUDIO_MASTER' ? (extra.durationMs || 180000) : 0,
    width: kind === 'ARTWORK' ? (extra.width || 3000) : 0,
    height: kind === 'ARTWORK' ? (extra.height || 3000) : 0
  });
  return asset.id;
}

test('preflight blocks incomplete release', () => {
  const store = new MemoryStore();
  const release = store.createRelease({ title: 'Incomplete' });
  const result = store.preflightRelease(release.id);
  assert.equal(result.ok, false);
  assert.equal(result.release.status, 'PREFLIGHT_REQUIRED');
  assert.ok(result.issues.length >= 5);
});

test('verified WAV + 3000 square art can reach review', () => {
  const store = new MemoryStore();
  const audioAssetId = verifyAsset(store, 'AUDIO_MASTER', 'master.wav', 'audio/wav', { durationMs: 180000 });
  const artworkAssetId = verifyAsset(store, 'ARTWORK', 'cover.png', 'image/png', { width: 3000, height: 3000 });
  const release = store.createRelease({});
  store.patchRelease(release.id, validReleasePatch(audioAssetId, artworkAssetId));
  const preflight = store.preflightRelease(release.id);
  assert.equal(preflight.ok, true);
  assert.equal(preflight.release.status, 'READY_FOR_REVIEW');
  const submitted = store.submitReview(release.id);
  assert.equal(submitted.status, 'IN_REVIEW');
});

test('server-computed checksum mismatch rejects asset', () => {
  const store = new MemoryStore();
  const expected = checksum(Buffer.from('expected'));
  const actual = checksum(Buffer.from('wrong'));
  const session = store.createUploadSession({
    kind: 'AUDIO_MASTER', fileName: 'master.flac', mime: 'audio/flac', sizeBytes: 5, checksum: expected
  });
  assert.throws(() => store.markUploaded(session.assetId, {
    checksum: actual, sizeBytes: 5, storageKey: 'bad.bin'
  }), /checksum does not match/i);
  assert.equal(store.getAsset(session.assetId).status, 'REJECTED');
});

test('release cannot be edited after submission', () => {
  const store = new MemoryStore();
  const audioAssetId = verifyAsset(store, 'AUDIO_MASTER', 'master.flac', 'audio/flac');
  const artworkAssetId = verifyAsset(store, 'ARTWORK', 'cover.jpg', 'image/jpeg', { width: 4000, height: 4000 });
  const release = store.createRelease({});
  store.patchRelease(release.id, validReleasePatch(audioAssetId, artworkAssetId));
  store.preflightRelease(release.id);
  store.submitReview(release.id);
  assert.throws(() => store.patchRelease(release.id, { title: 'Illegal edit' }), /cannot be edited/);
});

test('audit trail records sensitive state changes', () => {
  const store = new MemoryStore();
  const release = store.createRelease({ title: 'Audit' }, 'owner');
  store.patchRelease(release.id, { artistName: 'Artist' }, 'owner');
  const events = store.getAudit();
  assert.equal(events[0].action, 'RELEASE_CREATED');
  assert.equal(events[1].action, 'RELEASE_UPDATED');
  assert.equal(events[0].actor, 'owner');
});

test('json persistence survives store restart', () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'am-studio-state-'));
  const file = path.join(dir, 'state.json');
  const persistence = new JsonFilePersistence(file);
  const first = new MemoryStore({ persistence });
  const release = first.createRelease({ title: 'Persistent Single', artistName: 'Arda Test' });
  const second = new MemoryStore({ persistence: new JsonFilePersistence(file) });
  assert.equal(second.getRelease(release.id).title, 'Persistent Single');
  fs.rmSync(dir, { recursive: true, force: true });
});

test('local asset storage hashes actual uploaded bytes', async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), 'am-studio-media-'));
  const storage = new LocalAssetStorage(dir);
  const bytes = Buffer.from('real-audio-bytes');
  const asset = { id: 'ast_test', sizeBytes: bytes.length };
  const result = await storage.writeFromRequest(asset, Readable.from([bytes]));
  assert.equal(result.checksum, checksum(bytes));
  assert.equal(result.sizeBytes, bytes.length);
  assert.ok(fs.existsSync(path.join(dir, result.storageKey)));
  fs.rmSync(dir, { recursive: true, force: true });
});

test('auth boundary requires bearer token', () => {
  const auth = new AuthService({ devToken: 'secret-test-token' });
  assert.throws(() => auth.authenticate({ headers: {} }), /bearer token required/i);
  const user = auth.authenticate({ headers: { authorization: 'Bearer secret-test-token' } });
  assert.equal(user.id, 'usr_dev_owner');
  assert.ok(user.roles.includes('OWNER'));
});
