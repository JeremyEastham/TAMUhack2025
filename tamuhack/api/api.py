from fastapi import FastAPI
from .hooks import lifespan
from .endpoints import router
import uvicorn

app = FastAPI( title = "TAMUhack 2025", version = "0.0.1", lifespan = lifespan )
app.include_router( router )


def run_server():
    uvicorn.run(
        "tamuhack.api:app",
        host = "0.0.0.0",
        port = 80,
        reload = True,
    )
