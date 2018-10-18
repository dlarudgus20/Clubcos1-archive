#pragma once

typedef enum
{
	MEMORYENTRY_USABLE = 1,
	MEMORYENTRY_RESERVED = 2,
	MEMORYENTRY_ACPI_REC = 3,
	MEMORYENTRY_ACPI_NVS = 4,
	MEMORYENTRY_BADMEM = 5
} MemoryEntryType;

typedef struct tagMemoryEntry
{
	uint64_t BaseAddr, Length;
	MemoryEntryType type;
	uint32_t extattr;
} MemoryEntry;

static inline MemoryEntry *GetMemoryEntries() { return (MemoryEntry *)0x1000; }
static inline uint32_t GetMemoryEntryCount() { return *(uint32_t *)(0x1000 - 4); }

const char *MemoryEntryTypeStr(MemoryEntryType type);

uintptr_t CheckMemorySize();
