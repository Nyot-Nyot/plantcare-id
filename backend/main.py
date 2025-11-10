from fastapi import FastAPI

app = FastAPI()


@app.get("/health")
async def health_check():
    """Simple health check endpoint."""
    return {"status": "ok"}


if __name__ == "__main__":
    # Allow running directly for quick tests
    import uvicorn

    uvicorn.run("main:app", host="127.0.0.1", port=8001, reload=True)
