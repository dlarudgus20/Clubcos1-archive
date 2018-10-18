#include "Clubcos1.h"
#include "AsmFunc.h"
#include "Graphic.h"
#include "Memory.h"
#include "Gdt.h"
#include "Idt.h"
#include "Interrupt.h"

#include <clc1_memory.h>

void PrintMemoryEntry(int x, int y);

void ClcMain()
{
	Gdt *GdtTable = (Gdt *)GDT_ADDRESS;
	Idt *IdtTable = (Idt *)IDT_ADDRESS; Idt *idt = IdtTable;

	InitNullGdt(GdtTable + 0);
	InitGdt(GdtTable + 1, MAKE_GDT_TYPE1(CODE_SEGMENT_TYPE, 1, 0, 1));
	InitGdt(GdtTable + 2, MAKE_GDT_TYPE1(DATA_SEGMENT_TYPE, 1, 0, 1));
	memset(GdtTable + 3, 0, 0xffff - 3 * sizeof(Gdt));

	LoadGdt(0xffff, GdtTable);
	for (int i = 0; i < 256; i++)
	{
		InitIdt(IdtTable + i, (uint64_t)DefaultHandler,
				KERNEL_CODE_SEGMENT, 0, 0, IDT_TYPE_INTERRUPT);
	}

	LoadIdt(256 * sizeof(Idt), IdtTable);

	DrawString(0, 100, CYAN, "Test Interrupt Start");
	__asm__ __volatile__ ( "sti" );
	__asm__ __volatile__ ( "int $0x77" );
	__asm__ __volatile__ ( "cli" );
	DrawString(0, 116, CYAN, "Test Interrupt End");

	while (1)
	{
		DrawString(0, 0, CYAN, "Clubcos1 > ");
		__asm__ __volatile__ ( "hlt" );
	}
}

void PrintMemoryEntry(int x, int y)
{
	MemoryEntry *arEntry = GetMemoryEntries();
	uint32_t szEntry = GetMemoryEntryCount();

	for (uint32_t i = 0; i < szEntry; i++)
	{
		DrawStringFormat(x, y + i * 16, CYAN,
			"[0x%016lx|0x%016lx) %s(%u) extattr:%u",
			arEntry[i].BaseAddr, arEntry[i].BaseAddr + arEntry[i].Length,
			MemoryEntryTypeStr(arEntry[i].type), arEntry[i].type, arEntry[i].extattr);
	}
}
