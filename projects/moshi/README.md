# MOSHI

MOSHI is an Android-first communication platform combining personal chat, communities, built-in Business Mode, and privacy-aware AI assistance in one app.

Current stage: **Phase 1 — Identity/Auth implemented; Android CI build pending repository push.**

## Product locks

- One MOSHI app for personal + business use. No separate MOSHI Business download.
- Business Mode can be enabled on the same account.
- AI Summary is a core product direction, but remains disabled until message authorization/privacy boundaries exist.
- Do not claim E2EE until a real audited E2EE implementation exists.

## Monorepo

- `android/` — Kotlin + Jetpack Compose Android app
- `backend/` — FastAPI API
- `docs/` — product/architecture/security authority
- `.github/workflows/ci.yml` — backend tests + Android debug APK build

## Backend local start

```bash
cd backend
python -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Run tests:

```bash
cd backend
pytest -q
```

## Android debug API

Android debug defaults to `http://10.0.2.2:8000`, suitable for an emulator reaching a backend running on the host. Physical-device development will use a LAN address or secure tunnel in a later environment-config step.

Release configuration intentionally points at an invalid HTTPS placeholder until a real MOSHI API hostname exists.
