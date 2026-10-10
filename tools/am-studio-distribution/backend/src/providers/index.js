import { LabelGridAdapter } from './labelgrid.js';
import { coded } from '../store.js';

export function createProvider(options = {}) {
  const name = options.name || process.env.AM_DISTRIBUTION_PROVIDER || 'disabled';
  if (name === 'labelgrid') {
    return new LabelGridAdapter(options.labelgrid || {});
  }
  return new DisabledProvider(name);
}

export class DisabledProvider {
  constructor(name = 'disabled') {
    this.name = name;
  }

  isConfigured() { return false; }

  async request() {
    throw coded('PROVIDER_NOT_CONFIGURED', 'No production distribution provider is configured', 503);
  }

  async getMe() { return this.request(); }
  async createRelease() { return this.request(); }
  async createTrack() { return this.request(); }
  async validateRelease() { return this.request(); }
  async distribute() { return this.request(); }
  async statements() { return this.request(); }
  async analyticsSummary() { return this.request(); }
}
