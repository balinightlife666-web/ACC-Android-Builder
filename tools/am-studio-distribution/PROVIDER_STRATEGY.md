# AM STUDIO MUSIC DISTRIBUTION — PROVIDER STRATEGY v1.0

Date: 2026-09-09
Status: TECHNICAL TARGET SELECTED / COMMERCIAL ACCOUNT NOT YET CONTRACTED

## Decision

First technical integration target: **LabelGrid Engine API**.

Reason:
- public REST API documentation;
- sandbox environment;
- bearer-token server authentication;
- release validation and distribution endpoints;
- presigned track-file upload workflow;
- distro outlet discovery;
- webhooks;
- statements, royalties and analytics endpoints;
- white-label use case explicitly supported.

AM STUDIO remains provider-neutral. LabelGrid is an adapter, not the canonical database or app identity.

## Current commercial gate

As publicly listed in July/August 2026, LabelGrid Engine API starts at USD 139/month billed yearly for Starter API. API/sandbox access requires an active API plan; standard trial does not include API access. Sandbox may require IP allowlisting.

This is a commercial dependency and MUST NOT be represented as contracted until AM STUDIO has an active provider account and valid sandbox token.

## Provider architecture

Android APK
→ AM STUDIO API
→ canonical catalog / rights / lifecycle
→ Distribution Provider Registry
→ LabelGridAdapter (first target)
→ LabelGrid sandbox/production
→ DSPs

Provider API tokens stay server-side only.

## LabelGrid adapter scope

Implemented foundation:
- server-only bearer authentication;
- sandbox/production base URL switching;
- GET current provider user;
- list distro outlets;
- create release pass-through;
- create track pass-through;
- request track-file presigned upload URL;
- validate release;
- read quality report;
- distribute release;
- takedown-all;
- statements;
- analytics summary;
- fail-closed when token is absent.

Not yet activated:
- canonical AM STUDIO → LabelGrid field mapping;
- artist/writer/label entity mapping;
- track/release identifier mapping;
- artwork/audio transfer to provider presigned URLs;
- DSP configuration mapping;
- provider webhook verification;
- provider status reconciliation;
- royalty/statements ingestion.

## Activation gate

Do not call LabelGrid distribution endpoints from a production AM STUDIO release until all are true:
1. Paid API/sandbox account active.
2. Sandbox token stored in server secret environment/vault.
3. Required sandbox IP allowlist configured.
4. Canonical field mapping tests PASS.
5. Asset upload mapping tests PASS.
6. LabelGrid validation response normalized into AM STUDIO QC.
7. Webhook signature/secret handling verified.
8. One end-to-end sandbox release receives provider evidence.

## Alternatives retained

Revelator remains a viable enterprise alternative and supports API-driven supply chain, royalties and payments. The AM STUDIO provider registry must preserve the ability to add Revelator or another provider without changing Android canonical contracts.

## Source references

- https://api.labelgrid.com/docs/api
- https://labelgrid.com/features/music-distribution-api/
- https://labelgrid.com/pricing/
- https://help.labelgrid.com/en/developers/api-overview/
- https://api-docs.revelator.com/en/getting-started
