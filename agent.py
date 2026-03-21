from dotenv import load_dotenv
import os

load_dotenv()

from typing import TypedDict
from langgraph.graph import StateGraph, END
from langchain_openai import ChatOpenAI


class AgentState(TypedDict):
    question: str
    answer: str


llm = ChatOpenAI(model="gpt-4o-mini")


def llm_node(state: AgentState):
    question = state["question"]

    response = llm.invoke(question)

    return {"answer": response.content}


def build_graph():
    builder = StateGraph(AgentState)

    builder.add_node("llm", llm_node)

    builder.set_entry_point("llm")

    builder.add_edge("llm", END)

    return builder.compile()

agent = build_graph()
