from core.services.memory_service import MemoryService

service = MemoryService()

workspace_id = "25cbd6eb-5aca-4cef-b519-90d58b5b86e5"

result = service.capture_memory(
    workspace_id=workspace_id,
    title="Initial Business Idea",
    content="NoeticLayer is a persistent cognition infrastructure platform.",
    memory_type="idea"
)

print("\nMemory Capture Result:")
print(result)

recent = service.browse_recent()

print("\nRecent Memories:")
for item in recent:
    print(item)

search = service.search_memory("cognition")

print("\nSearch Results:")
for item in search:
    print(item)
