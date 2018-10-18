#include "Clubcos1.h"
#include "Idt.h"

void InitIdt(Idt *pIdt, uint64_t handler, uint16_t segment,
		uint8_t dpl, uint8_t ist, uint8_t type)
{
	pIdt->Handler_0_15 = (uint16_t)handler;
	pIdt->Handler_16_31 = (uint16_t)(handler >> 16);
	pIdt->Handler_32_63 = (uint32_t)(handler >> 32);

	pIdt->Segment = segment;

	pIdt->IST = ist;
	pIdt->DPL = dpl;
	pIdt->type = type;

	pIdt->P = 1;
	pIdt->zero1 = 0;
	pIdt->zero2 = 0;
	pIdt->zero3 = 0;
}
