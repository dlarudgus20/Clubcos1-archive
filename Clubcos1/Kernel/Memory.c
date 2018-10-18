#include "Clubcos1.h"
#include "Memory.h"
#include "AsmFunc.h"

const char *MemoryEntryTypeStr(MemoryEntryType type)
{
	const char *tbl[5];
	tbl[0] = "MEMORYENTRY_USABLE\0";
	tbl[1] = "MEMORYENTRY_RESERVED\0";
	tbl[2] = "MEMORYENTRY_ACPI_REC\0";
	tbl[3] = "MEMORYENTRY_ACPI_NVS\0";
	tbl[4] = "MEMORYENTRY_BADMEM\0";
	return tbl[type - 1];
}

static bool CheckMemorySizeSub(volatile uint32_t *ptr)
{
	volatile uint32_t old = *ptr;
	bool ret = false;
	*ptr = 0x1234abcd;
	*ptr ^= 0xffffffff;
	if (*ptr == ~0x1234abcd)
	{
		*ptr ^= 0xffffffff;
		if (*ptr == 0x1234abcd)
		{
			ret = true;
		}
	}
	*ptr = old;
	return ret;
}
uintptr_t CheckMemorySize()
{
	uintptr_t cr0;

	volatile uintptr_t ptr;

	cr0 = GetCr0();
	SetCr0(cr0 | 0x60000000);

	for (ptr = 0x700000; ptr < 0x30000000; ptr += 0x100000)
	{
		if (!CheckMemorySizeSub((volatile uint32_t *)ptr))
			break;
	}
	if (!CheckMemorySizeSub((volatile uint32_t *)(ptr - 4)))
	{
		ptr -= 0x100000;
	}

	SetCr0(cr0);

	return ptr;
}
