import { newId, nowIso } from './domain.js';

const BUCKETS = new Set(['PENDING', 'AVAILABLE', 'HELD', 'PAID']);
const TYPES = new Set([
  'ROYALTY_RAW',
  'RECONCILIATION_MOVE',
  'ADJUSTMENT',
  'PAYOUT_RESERVE',
  'PAYOUT_SETTLEMENT',
  'REVERSAL'
]);

export class RoyaltyLedger {
  constructor(snapshot = null) {
    this.entries = [];
    this.byIdempotency = new Map();
    this.restore(snapshot);
  }

  append(input = {}) {
    const ownerId = requiredText(input.ownerId, 'LEDGER_OWNER_REQUIRED', 'ownerId is required');
    const currency = normalizeCurrency(input.currency);
    const bucket = normalizeEnum(input.bucket, BUCKETS, 'LEDGER_BUCKET_INVALID');
    const type = normalizeEnum(input.type, TYPES, 'LEDGER_TYPE_INVALID');
    const amountMinor = normalizeAmount(input.amountMinor);
    const idempotencyKey = optionalText(input.idempotencyKey);

    if (idempotencyKey && this.byIdempotency.has(idempotencyKey)) {
      return {
        duplicate: true,
        entry: structuredClone(this.byIdempotency.get(idempotencyKey))
      };
    }

    const entry = Object.freeze({
      id: newId('led'),
      ownerId,
      currency,
      bucket,
      type,
      amountMinor,
      sourceRef: optionalText(input.sourceRef),
      idempotencyKey,
      transferId: optionalText(input.transferId),
      metadata: safeMetadata(input.metadata),
      at: nowIso()
    });

    this.entries.push(entry);
    if (idempotencyKey) this.byIdempotency.set(idempotencyKey, entry);
    return { duplicate: false, entry: structuredClone(entry) };
  }

  ingestRawLine(input = {}) {
    const provider = requiredText(input.provider, 'ROYALTY_PROVIDER_REQUIRED', 'provider is required').toLowerCase();
    const statementId = requiredText(input.statementId, 'ROYALTY_STATEMENT_REQUIRED', 'statementId is required');
    const lineRef = requiredText(input.lineRef, 'ROYALTY_LINE_REF_REQUIRED', 'lineRef is required');
    const key = `royalty:${provider}:${statementId}:${lineRef}`;

    return this.append({
      ownerId: input.ownerId,
      currency: input.currency,
      bucket: 'PENDING',
      type: 'ROYALTY_RAW',
      amountMinor: input.amountMinor,
      sourceRef: `${provider}:${statementId}:${lineRef}`,
      idempotencyKey: key,
      metadata: {
        provider,
        statementId,
        lineRef,
        releaseId: optionalText(input.releaseId),
        trackId: optionalText(input.trackId),
        isrc: optionalText(input.isrc),
        upc: optionalText(input.upc),
        territory: optionalText(input.territory),
        destination: optionalText(input.destination),
        period: optionalText(input.period)
      }
    });
  }

  move(input = {}) {
    const ownerId = requiredText(input.ownerId, 'LEDGER_OWNER_REQUIRED', 'ownerId is required');
    const currency = normalizeCurrency(input.currency);
    const fromBucket = normalizeEnum(input.fromBucket, BUCKETS, 'LEDGER_BUCKET_INVALID');
    const toBucket = normalizeEnum(input.toBucket, BUCKETS, 'LEDGER_BUCKET_INVALID');
    const amountMinor = normalizePositiveAmount(input.amountMinor);
    if (fromBucket === toBucket) throw ledgerError('LEDGER_TRANSFER_BUCKET_SAME', 'Ledger transfer buckets must differ');

    const sourceRef = requiredText(input.sourceRef, 'LEDGER_SOURCE_REQUIRED', 'sourceRef is required');
    const baseKey = optionalText(input.idempotencyKey) || `move:${ownerId}:${currency}:${fromBucket}:${toBucket}:${sourceRef}`;
    const debitKey = `${baseKey}:debit`;
    const creditKey = `${baseKey}:credit`;
    const existingDebit = this.byIdempotency.get(debitKey);
    const existingCredit = this.byIdempotency.get(creditKey);

    if (existingDebit || existingCredit) {
      if (!existingDebit || !existingCredit) {
        throw ledgerError('LEDGER_TRANSFER_INCOMPLETE', 'Ledger transfer idempotency state is inconsistent', 500);
      }
      return {
        duplicate: true,
        transferId: existingDebit.transferId,
        entries: [structuredClone(existingDebit), structuredClone(existingCredit)]
      };
    }

    const transferId = newId('xfer');
    const debit = this.append({
      ownerId, currency, bucket: fromBucket, type: 'RECONCILIATION_MOVE',
      amountMinor: -amountMinor, sourceRef, idempotencyKey: debitKey, transferId,
      metadata: input.metadata
    }).entry;
    const credit = this.append({
      ownerId, currency, bucket: toBucket, type: 'RECONCILIATION_MOVE',
      amountMinor, sourceRef, idempotencyKey: creditKey, transferId,
      metadata: input.metadata
    }).entry;

    return { duplicate: false, transferId, entries: [debit, credit] };
  }

  list(ownerId) {
    const owner = requiredText(ownerId, 'LEDGER_OWNER_REQUIRED', 'ownerId is required');
    return this.entries
      .filter(entry => entry.ownerId === owner)
      .map(entry => structuredClone(entry));
  }

  wallet(ownerId) {
    const owner = requiredText(ownerId, 'LEDGER_OWNER_REQUIRED', 'ownerId is required');
    const currencies = {};
    for (const entry of this.entries) {
      if (entry.ownerId !== owner) continue;
      if (!currencies[entry.currency]) {
        currencies[entry.currency] = { PENDING: 0, AVAILABLE: 0, HELD: 0, PAID: 0, TOTAL: 0 };
      }
      currencies[entry.currency][entry.bucket] += entry.amountMinor;
      currencies[entry.currency].TOTAL += entry.amountMinor;
    }
    return { ownerId: owner, currencies };
  }

  snapshot() {
    return { schemaVersion: 1, entries: this.entries.map(entry => ({ ...entry })) };
  }

  restore(snapshot) {
    if (!snapshot || Number(snapshot.schemaVersion || 1) !== 1) return;
    const entries = Array.isArray(snapshot.entries) ? snapshot.entries : [];
    for (const raw of entries) {
      try {
        const entry = Object.freeze({
          id: requiredText(raw.id, 'LEDGER_ENTRY_ID_REQUIRED', 'ledger entry id required'),
          ownerId: requiredText(raw.ownerId, 'LEDGER_OWNER_REQUIRED', 'ownerId is required'),
          currency: normalizeCurrency(raw.currency),
          bucket: normalizeEnum(raw.bucket, BUCKETS, 'LEDGER_BUCKET_INVALID'),
          type: normalizeEnum(raw.type, TYPES, 'LEDGER_TYPE_INVALID'),
          amountMinor: normalizeAmount(raw.amountMinor),
          sourceRef: optionalText(raw.sourceRef),
          idempotencyKey: optionalText(raw.idempotencyKey),
          transferId: optionalText(raw.transferId),
          metadata: safeMetadata(raw.metadata),
          at: requiredText(raw.at, 'LEDGER_TIMESTAMP_REQUIRED', 'ledger timestamp required')
        });
        this.entries.push(entry);
        if (entry.idempotencyKey) this.byIdempotency.set(entry.idempotencyKey, entry);
      } catch {
        // Fail closed by ignoring malformed persisted ledger rows in DEV sandbox.
      }
    }
  }
}

function normalizeCurrency(value) {
  const currency = requiredText(value, 'LEDGER_CURRENCY_REQUIRED', 'currency is required').toUpperCase();
  if (!/^[A-Z]{3}$/.test(currency)) throw ledgerError('LEDGER_CURRENCY_INVALID', 'currency must be a 3-letter ISO code');
  return currency;
}

function normalizeAmount(value) {
  const amount = Number(value);
  if (!Number.isSafeInteger(amount) || amount === 0) {
    throw ledgerError('LEDGER_AMOUNT_INVALID', 'amountMinor must be a non-zero safe integer');
  }
  return amount;
}

function normalizePositiveAmount(value) {
  const amount = Number(value);
  if (!Number.isSafeInteger(amount) || amount <= 0) {
    throw ledgerError('LEDGER_AMOUNT_INVALID', 'amountMinor must be a positive safe integer');
  }
  return amount;
}

function normalizeEnum(value, allowed, code) {
  const clean = requiredText(value, code, 'ledger enum value is required').toUpperCase();
  if (!allowed.has(clean)) throw ledgerError(code, `Unsupported ledger value: ${clean}`);
  return clean;
}

function requiredText(value, code, message) {
  const clean = optionalText(value);
  if (!clean) throw ledgerError(code, message);
  return clean;
}

function optionalText(value) {
  return typeof value === 'string' ? value.trim() : '';
}

function safeMetadata(value) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return {};
  return structuredClone(value);
}

function ledgerError(code, message, status = 400) {
  const error = new Error(message);
  error.code = code;
  error.status = status;
  return error;
}
