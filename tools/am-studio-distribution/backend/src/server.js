import http from 'node:http';
import { randomUUID } from 'node:crypto';
import { URL } from 'node:url';
import { MemoryStore, coded } from './store.js';
import { JsonFilePersistence } from './persistence.js';
import { AuthService } from './auth.js';
import { LocalAssetStorage } from './storage.js';

const persistence = new JsonFilePersistence();
export const store = new MemoryStore({ persistence });
export const auth = new AuthService();
export const storage = new LocalAssetStorage();

export function createServer() {
  return http.createServer(async (req, res) => {
    const requestId = `req_${randomUUID().replaceAll('-', '')}`;
    try {
      const url = new URL(req.url, 'http://localhost');
      const method = req.method || 'GET';
      const path = url.pathname;

      if (method === 'GET' && path === '/health') {
        return json(res, 200, {
          ok: true,
          service: 'am-studio-distribution-backend',
          environment: 'DEV_SANDBOX',
          persistence: 'JSON_FILE',
          mediaStorage: 'LOCAL_STREAM',
          requestId
        });
      }

      const user = auth.authenticate(req);
      const actor = user.id;

      if (method === 'GET' && path === '/v1/me') {
        return json(res, 200, { ...user, requestId });
      }
      if (method === 'POST' && path === '/v1/releases') {
        const body = await bodyJson(req);
        return json(res, 201, { release: store.createRelease(body, actor), requestId });
      }
      if (method === 'GET' && path === '/v1/releases') {
        return json(res, 200, { releases: store.listReleases(), requestId });
      }
      if (method === 'POST' && path === '/v1/uploads') {
        const body = await bodyJson(req);
        return json(res, 201, { ...store.createUploadSession(body, actor), requestId });
      }
      if (method === 'GET' && path === '/v1/admin/audit') {
        requireRole(user, 'OWNER');
        return json(res, 200, { events: store.getAudit(), requestId });
      }

      const releaseMatch = path.match(/^\/v1\/releases\/([^/]+)$/);
      if (releaseMatch) {
        const id = releaseMatch[1];
        if (method === 'GET') {
          const release = store.getRelease(id);
          if (!release) throw coded('RELEASE_NOT_FOUND', 'Release not found', 404);
          return json(res, 200, { release, requestId });
        }
        if (method === 'PATCH') {
          const body = await bodyJson(req);
          return json(res, 200, { release: store.patchRelease(id, body, actor), requestId });
        }
      }

      const preflightMatch = path.match(/^\/v1\/releases\/([^/]+)\/preflight$/);
      if (method === 'POST' && preflightMatch) {
        return json(res, 200, { ...store.preflightRelease(preflightMatch[1], actor), requestId });
      }

      const reviewMatch = path.match(/^\/v1\/releases\/([^/]+)\/submit-review$/);
      if (method === 'POST' && reviewMatch) {
        return json(res, 200, { release: store.submitReview(reviewMatch[1], actor), requestId });
      }

      const uploadContentMatch = path.match(/^\/v1\/uploads\/([^/]+)\/content$/);
      if (method === 'PUT' && uploadContentMatch) {
        const id = uploadContentMatch[1];
        const asset = store.getAsset(id);
        if (!asset) throw coded('ASSET_NOT_FOUND', 'Asset not found', 404);
        const written = await storage.writeFromRequest(asset, req);
        return json(res, 200, { asset: store.markUploaded(id, written, actor), requestId });
      }

      const uploadCompleteMatch = path.match(/^\/v1\/uploads\/([^/]+)\/complete$/);
      if (method === 'POST' && uploadCompleteMatch) {
        const body = await bodyJson(req);
        return json(res, 200, { asset: store.completeUpload(uploadCompleteMatch[1], body, actor), requestId });
      }

      throw coded('ROUTE_NOT_FOUND', 'Route not found', 404);
    } catch (error) {
      const status = Number(error?.status || 500);
      const code = error?.code || 'INTERNAL_ERROR';
      json(res, status, {
        error: {
          code,
          message: status >= 500 ? 'Internal server error' : String(error.message || code),
          requestId
        }
      });
    }
  });
}

async function bodyJson(req) {
  const chunks = [];
  let bytes = 0;
  for await (const chunk of req) {
    bytes += chunk.length;
    if (bytes > 1_000_000) throw coded('REQUEST_TOO_LARGE', 'Request body too large', 413);
    chunks.push(chunk);
  }
  if (!chunks.length) return {};
  try { return JSON.parse(Buffer.concat(chunks).toString('utf8')); }
  catch { throw coded('INVALID_JSON', 'Invalid JSON body'); }
}

function requireRole(user, role) {
  if (!Array.isArray(user?.roles) || !user.roles.includes(role)) {
    throw coded('FORBIDDEN', 'Insufficient role', 403);
  }
}

function json(res, status, payload) {
  const data = Buffer.from(JSON.stringify(payload));
  res.writeHead(status, {
    'content-type': 'application/json; charset=utf-8',
    'content-length': data.length,
    'cache-control': 'no-store',
    'x-content-type-options': 'nosniff'
  });
  res.end(data);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const port = Number(process.env.PORT || 8787);
  createServer().listen(port, '127.0.0.1', () => {
    console.log(`AM STUDIO Distribution backend DEV_SANDBOX listening on http://127.0.0.1:${port}`);
  });
}
