import { coded } from '../store.js';

const PROD_BASE = 'https://api.labelgrid.com/api/public';
const SANDBOX_BASE = 'https://api-sandbox.stg.labelgrid.com/api/public';

export class LabelGridAdapter {
  constructor(options = {}) {
    this.name = 'labelgrid';
    this.environment = options.environment || process.env.LABELGRID_ENV || 'sandbox';
    this.token = options.token || process.env.LABELGRID_API_TOKEN || '';
    this.fetchImpl = options.fetchImpl || globalThis.fetch;
    this.baseUrl = this.environment === 'production' ? PROD_BASE : SANDBOX_BASE;
  }

  isConfigured() {
    return Boolean(this.token);
  }

  async getMe() {
    return this.request('GET', '/me');
  }

  async getOutlets() {
    return this.request('GET', '/distro-outlets');
  }

  async createRelease(providerPayload) {
    return this.request('POST', '/releases', providerPayload);
  }

  async createTrack(providerPayload) {
    return this.request('POST', '/tracks', providerPayload);
  }

  async getTrackUploadUrl(trackId, fileType) {
    return this.request('POST', `/tracks/${id(trackId)}/files/${id(fileType)}/upload-url`, {});
  }

  async validateRelease(providerReleaseId) {
    return this.request('POST', `/releases/${id(providerReleaseId)}/validate`, {});
  }

  async qualityReport(providerReleaseId) {
    return this.request('GET', `/releases/${id(providerReleaseId)}/quality-report`);
  }

  async distribute(providerReleaseId) {
    return this.request('POST', `/releases/${id(providerReleaseId)}/distribute`, {});
  }

  async takedownAll(providerReleaseId) {
    return this.request('POST', `/releases/${id(providerReleaseId)}/takedown-all`, {});
  }

  async statements() {
    return this.request('GET', '/statements');
  }

  async analyticsSummary() {
    return this.request('GET', '/analytics/summary');
  }

  async request(method, path, body) {
    if (!this.isConfigured()) {
      throw coded('PROVIDER_NOT_CONFIGURED', 'LabelGrid API token is not configured', 503);
    }
    if (typeof this.fetchImpl !== 'function') {
      throw coded('PROVIDER_HTTP_UNAVAILABLE', 'Fetch implementation unavailable', 500);
    }
    const headers = {
      'accept': 'application/json',
      'authorization': `Bearer ${this.token}`
    };
    const init = { method, headers };
    if (body !== undefined) {
      headers['content-type'] = 'application/json';
      init.body = JSON.stringify(body);
    }
    const response = await this.fetchImpl(this.baseUrl + path, init);
    const text = await response.text();
    let payload = {};
    try { payload = text ? JSON.parse(text) : {}; } catch { payload = { raw: text }; }
    if (!response.ok) {
      const error = coded('PROVIDER_REQUEST_FAILED', `LabelGrid request failed with HTTP ${response.status}`, 502);
      error.providerStatus = response.status;
      error.providerPayload = payload;
      throw error;
    }
    return payload;
  }
}

function id(value) {
  const clean = String(value || '').trim();
  if (!/^[A-Za-z0-9._-]+$/.test(clean)) throw coded('PROVIDER_ID_INVALID', 'Invalid provider resource id');
  return clean;
}
