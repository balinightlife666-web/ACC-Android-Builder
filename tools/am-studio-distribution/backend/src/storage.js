import fs from 'node:fs';
import path from 'node:path';
import { createHash } from 'node:crypto';
import { coded } from './store.js';

export class LocalAssetStorage {
  constructor(rootDir = process.env.AM_MEDIA_DIR || path.resolve('var/media')) {
    this.rootDir = rootDir;
  }

  async writeFromRequest(asset, req) {
    if (!asset) throw coded('ASSET_NOT_FOUND', 'Asset not found', 404);
    const maxBytes = Math.min(Math.max(asset.sizeBytes, 1), 2_000_000_000);
    fs.mkdirSync(this.rootDir, { recursive: true });
    const finalPath = path.join(this.rootDir, `${asset.id}.bin`);
    const tempPath = `${finalPath}.${process.pid}.tmp`;
    const output = fs.createWriteStream(tempPath, { flags: 'w', mode: 0o600 });
    const hash = createHash('sha256');
    let bytes = 0;

    try {
      for await (const chunk of req) {
        bytes += chunk.length;
        if (bytes > maxBytes) throw coded('UPLOAD_TOO_LARGE', 'Uploaded bytes exceed declared size', 413);
        hash.update(chunk);
        if (!output.write(chunk)) await onceDrain(output);
      }
      await closeStream(output);
      if (bytes !== asset.sizeBytes) {
        throw coded('UPLOAD_SIZE_MISMATCH', `Expected ${asset.sizeBytes} bytes but received ${bytes}`);
      }
      fs.renameSync(tempPath, finalPath);
      return {
        storageKey: path.basename(finalPath),
        sizeBytes: bytes,
        checksum: `sha256:${hash.digest('hex')}`
      };
    } catch (error) {
      try { output.destroy(); } catch {}
      try { if (fs.existsSync(tempPath)) fs.unlinkSync(tempPath); } catch {}
      throw error;
    }
  }
}

function onceDrain(stream) {
  return new Promise((resolve, reject) => {
    stream.once('drain', resolve);
    stream.once('error', reject);
  });
}

function closeStream(stream) {
  return new Promise((resolve, reject) => {
    stream.once('error', reject);
    stream.end(resolve);
  });
}
