from __future__ import annotations

from collections import defaultdict
import asyncio

from fastapi import WebSocket


class ConnectionManager:
    def __init__(self) -> None:
        self._connections: dict[str, set[WebSocket]] = defaultdict(set)
        self._lock = asyncio.Lock()

    async def connect(self, user_id: str, websocket: WebSocket) -> None:
        await websocket.accept()
        async with self._lock:
            self._connections[user_id].add(websocket)

    async def disconnect(self, user_id: str, websocket: WebSocket) -> None:
        async with self._lock:
            sockets = self._connections.get(user_id)
            if sockets is None:
                return
            sockets.discard(websocket)
            if not sockets:
                self._connections.pop(user_id, None)

    async def send_user(self, user_id: str, payload: dict[str, object]) -> bool:
        async with self._lock:
            sockets = list(self._connections.get(user_id, ()))
        delivered = False
        dead: list[WebSocket] = []
        for socket in sockets:
            try:
                await socket.send_json(payload)
                delivered = True
            except Exception:
                dead.append(socket)
        for socket in dead:
            await self.disconnect(user_id, socket)
        return delivered


manager = ConnectionManager()
