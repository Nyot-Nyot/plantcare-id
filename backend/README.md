# Backend (FastAPI) — Quick start

This folder contains a minimal FastAPI app for local development.

Files:
- `main.py` — FastAPI app with a `/health` endpoint.
- `requirements.txt` — Python deps for the backend (FastAPI + Uvicorn).

Quick run (from project root):

```fish
python3 -m venv backend/.venv
backend/.venv/bin/pip install -r backend/requirements.txt
backend/.venv/bin/uvicorn backend.main:app --reload --port 8001
```

Open: http://127.0.0.1:8001/health
