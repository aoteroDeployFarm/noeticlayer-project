from datetime import datetime
import psycopg


DATABASE_URL = "postgresql://noetic:noetic@localhost:5432/noeticlayer"


class MemoryService:

    def __init__(self):
        self.conn = psycopg.connect(DATABASE_URL)

    def capture_memory(
        self,
        workspace_id: str,
        title: str,
        content: str,
        memory_type: str = "idea"
    ):

        query = """
        INSERT INTO memory_items (
            workspace_id,
            type,
            title,
            raw_content,
            created_at
        )
        VALUES (%s, %s, %s, %s, %s)
        RETURNING id;
        """

        with self.conn.cursor() as cur:
            cur.execute(
                query,
                (
                    workspace_id,
                    memory_type,
                    title,
                    content,
                    datetime.utcnow()
                )
            )

            memory_id = cur.fetchone()[0]

        self.conn.commit()

        return {
            "memory_id": str(memory_id),
            "status": "stored"
        }

    def browse_recent(self, limit: int = 10):

        query = """
        SELECT
            id,
            type,
            title,
            created_at
        FROM memory_items
        ORDER BY created_at DESC
        LIMIT %s;
        """

        with self.conn.cursor() as cur:
            cur.execute(query, (limit,))
            rows = cur.fetchall()

        return rows

    def search_memory(self, keyword: str):

        query = """
        SELECT
            id,
            type,
            title,
            raw_content
        FROM memory_items
        WHERE raw_content ILIKE %s
        LIMIT 10;
        """

        with self.conn.cursor() as cur:
            cur.execute(query, (f"%{keyword}%",))
            rows = cur.fetchall()

        return rows
