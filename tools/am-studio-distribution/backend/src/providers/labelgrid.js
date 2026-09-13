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

  async getGenres() {
    return this.request('GET', '/genres');
  }

  async getLanguages() {
    return this.request('GET', '/languages');
  }

  async getContributorRoles() {
    return this.request('GET', '/contributor-roles');
  }

  async getTerritories() {
    return this.request('GET', '/territories');
  }

  async createArtist(providerPayload) {
    return this.request('POST', '/artists', providerPayload);
  }

  async createLabel(providerPayload) {
    return this.request('POST', '/labels', providerPayload);
  }

  async createRelease(providerPayload) {
    return this.request('POST', '/releases', providerPayload);
  }

  async updateRelease(providerReleaseId, providerPayload) {
    return this.request('PATCH', `/releases/${id(providerReleaseId)}`, providerPayload);
  }

  async createTrack(providerPayload) {
    return this.request('POST', '/tracks', providerPayload);
  }

  async getTrackUploadUrl(trackId, fileType, filename) {
    return this.request('POST', `/tracks/${id(trackId)}/files/${id(fileType)}/upload-url`, {
      filename: safeFilename(filename)
    });
  }

  async registerTrackFile(trackId, fileType, providerPayload) {
    return this.request('PUT', `/tracks/${id(trackId)}/files/${id(fileType)}`, providerPayload);
  }

  async getReleaseUploadUrl(releaseId, assetType, filename) {
    return this.request('POST', `/releases/${id(releaseId)}/files/${id(assetType)}/upload-url`, {
      filename: safeFilename(filename)
    });
  }

  async registerReleaseFile(releaseId, assetType, providerPayload) {
    return this.request('PUT', `/releases/${id(releaseId)}/files/${id(assetType)}`, providerPayload);
  }

  async validateRelease(providerReleaseId) {
    return this.request('POST', `/releases/${id(providerReleaseId)}/validate`, {});
  }

  async qualityReport(providerReleaseId) {
    return this.request('GET', `/releases/${id(providerReleaseId)}/quality-report`);
  }

  async refreshQualityReport(providerReleaseId) {
    return this.request('POST', `/releases/${id(providerReleaseId)}/quality-report/refresh`, {});
  }

  async confirmReview(providerReleaseId) {
    return this.request('POST', `/releases/${id(providerReleaseId)}/confirm-review`, {});
  }

  async distribute(providerReleaseId) {
    return this.request('POST', `/releases/${id(providerReleaseId)}/distribute`, {});
  }

  async deliveryStatus(providerReleaseId) {
    return this.request('GET', `/releases/${id(providerReleaseId)}/delivery-status`);
  }

  async takedownAll(providerReleaseId) {
    return this.request('POST', `/releases/${id(providerReleaseId)}/takedown-all`, {});
  }

  async statements() {
    return this.request('GET', '/statements');
  }

  async statement(invoiceNumber) {
    return this.request('GET', `/statements/${id(invoiceNumber)}`);
  }

  async royaltyBreakdown() {
    return this.request('GET', '/royalties/breakdown');
  }

  async artificialStreams() {
    return this.request('GET', '/royalties/artificial-streams');
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

function safeFilename(value) {
  const clean = String(value || '').trim();
  if (!clean || clean.length > 255 || !/^[a-zA-Z0-9\s\-_.()]+\.[a-zA-Z0-9]+$/.test(clean)) {
    throw coded('PROVIDER_FILENAME_INVALID', 'Provider filename is invalid');
  }
  return clean;
}
