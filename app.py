from dotenv import load_dotenv
import os

load_dotenv()

from fastapi import FastAPI
from agent import agent

app = FastAPI()

# # For Telemetry.
# from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
# FastAPIInstrumentor.instrument_app(app)

@app.get("/")
def home():
    APP_VERSION = os.getenv("IMAGE_TAG", "dev")
    return {"status": f"LangGraph Agent Running ver 1.0.{APP_VERSION}"}


@app.post("/ask")
def ask_agent(question: str):

    result = agent.invoke({"question": question})

    return {"answer": result["answer"]}

# http://localhost:8000/ask?question=What happened on sensex yesterday. Explain in maximum 150 words
# http://localhost:8000/ask?question=what happened on sensex on 20-March-2026? Explain in maximum 150 words
