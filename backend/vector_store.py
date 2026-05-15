import chromadb
from chromadb.config import Settings as ChromaSettings
import os

CHROMA_PATH = os.path.join(os.path.dirname(__file__), "data", "chroma_db")

_client = None

def get_client():
    global _client
    if _client is None:
        _client = chromadb.PersistentClient(
            path=CHROMA_PATH,
            settings=ChromaSettings(
                anonymized_telemetry=False,
                allow_reset=True
            )
        )
    return _client

def get_or_create_collection(npc_id: str):
    client = get_client()
    return client.get_or_create_collection(
        name=f"npc_{npc_id}",
        metadata={"npc_id": npc_id}
    )

def add_memory(npc_id: str, text: str, metadata: dict = None):
    collection = get_or_create_collection(npc_id)
    memory_id = f"memory_{chromadb.utils.id_utils.generate_short_id()}"
    meta = metadata or {}
    meta["npc_id"] = npc_id

    collection.add(
        documents=[text],
        ids=[memory_id],
        metadatas=[meta]
    )
    return memory_id

def search_memories(npc_id: str, query: str, top_k: int = 5):
    collection = get_or_create_collection(npc_id)
    results = collection.query(
        query_texts=[query],
        n_results=top_k,
        include=["documents", "metadatas", "distances"]
    )

    memories = []
    if results["ids"] and results["ids"][0]:
        for i, doc_id in enumerate(results["ids"][0]):
            memories.append({
                "id": doc_id,
                "text": results["documents"][0][i],
                "metadata": results["metadatas"][0][i],
                "distance": results["distances"][0][i]
            })
    return memories

def get_all_memories(npc_id: str):
    collection = get_or_create_collection(npc_id)
    results = collection.get(
        include=["documents", "metadatas"]
    )

    memories = []
    if results["ids"]:
        for i, doc_id in enumerate(results["ids"]):
            memories.append({
                "id": doc_id,
                "text": results["documents"][i],
                "metadata": results["metadatas"][i]
            })
    return memories

def delete_memory(npc_id: str, memory_id: str):
    collection = get_or_create_collection(npc_id)
    collection.delete(ids=[memory_id])

def clear_npc_memories(npc_id: str):
    client = get_client()
    try:
        client.delete_collection(name=f"npc_{npc_id}")
    except Exception:
        pass
