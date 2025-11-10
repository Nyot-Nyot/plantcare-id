# Setup and run the FastAPI backend (manual steps)

Follow these steps locally to create a Python virtual environment and run the backend:

1. Create virtual environment and install deps

```fish
python3 -m venv backend/.venv
backend/.venv/bin/pip install --upgrade pip
backend/.venv/bin/pip install -r backend/requirements.txt
```

2. Run the backend

```fish
backend/.venv/bin/uvicorn backend.main:app --reload --port 8001
```

3. Health check

Open in your browser or use curl:

```fish
curl http://127.0.0.1:8001/health
```

Notes:

-   Do not commit the virtual environment (`backend/.venv`) to git. Add it to `.gitignore` if needed.
-   If you need to expose the backend to other devices, change `--host` to `0.0.0.0` and ensure firewall rules allow it.
