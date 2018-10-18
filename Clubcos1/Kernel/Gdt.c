#include "Clubcos1.h"
#include "Gdt.h"

void InitGdt2(Gdt *pGdt, uint32_t address, uint32_t size, GdtType1 type1)
{
	uint32_t Size20bit;

	pGdt->Address_0_15 = (uint16_t) address;
	pGdt->Address_16_23 = (uint8_t)((address >> 16) & 0xff);
	pGdt->Address_24_32 = (uint8_t)((address >> 24) & 0xff);

	if(size >= 0xfffff)
	{
		pGdt->G = 1;
		Size20bit = size >> 12;
	}
	else
	{
		pGdt->G = 0;
		Size20bit = size;
	}
	pGdt->Size_0_15 = (uint16_t) Size20bit;
	pGdt->Size_16_19 = (uint16_t)((Size20bit >> 16) & 0x0f);

	pGdt->type1 = type1;

	pGdt->AVL = 0;
	pGdt->L = 1;
	pGdt->D = 0;
}
