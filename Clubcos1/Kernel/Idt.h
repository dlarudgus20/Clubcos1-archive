#pragma once

#define IDT_ADDRESS 0x626000

enum
{
	IDT_TYPE_INTERRUPT	= 0xe,	// 1110
	IDT_TYPE_TRAP		= 0xf	// 1111
};

typedef struct tagIdt
{
	uint16_t Handler_0_15;
	uint16_t Segment;

	uint8_t IST:3, zero1:5;

	uint8_t type:4, zero2:1, DPL:2, P:1;

	uint16_t Handler_16_31;
	uint32_t Handler_32_63;

	uint32_t zero3;
} Idt;

void InitIdt(Idt *pIdt, uint64_t handler, uint16_t segment,
		uint8_t dpl, uint8_t ist, uint8_t type);
