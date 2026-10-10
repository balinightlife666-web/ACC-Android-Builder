import { timingSafeEqual } from 'node:crypto';
import { coded } from './store.js';

export class AuthService {
  constructor(options = {}) {
    this.mode = options.mode || process.env.AM_AUTH_MODE || 'DEV_TOKEN';
    this.devToken = options.devToken || process.env.AM_DEV_TOKEN || 'amstudio-local-dev-token';
  }

  authenticate(req) {
    if (this.mode !== 'DEV_TOKEN') {
      throw coded('AUTH_MODE_NOT_IMPLEMENTED', 'Configured auth mode is not implemented', 500);
    }
    const header = String(req.headers.authorization || '');
    const token = header.startsWith('Bearer ') ? header.slice(7).trim() : '';
    if (!token || !safeEqual(token, this.devToken)) {
      throw coded('UNAUTHORIZED', 'Valid bearer token required', 401);
    }
    return {
      id: 'usr_dev_owner',
      displayName: 'AM STUDIO Dev Owner',
      roles: ['OWNER'],
      organizationId: 'org_am_studio',
      kycState: 'NOT_CONNECTED',
      payoutEligibility: false,
      environment: 'DEV_SANDBOX'
    };
  }
}

function safeEqual(a, b) {
  const left = Buffer.from(String(a));
  const right = Buffer.from(String(b));
  if (left.length !== right.length) return false;
  return timingSafeEqual(left, right);
}
