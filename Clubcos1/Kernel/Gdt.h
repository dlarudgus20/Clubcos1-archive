#pragma once

#define NULL_SEGMENT 0
#define KERNEL_CODE_SEGMENT (1 * 8)
#define KERNEL_DATA_SEGMENT (2 * 8)

#define GDT_ADDRESS 0x606000

#define MAKE_GDT_TYPE1(SegmentType,S,DPL,P) \
	((((P) << 7) & 0x80) | (((DPL) << 5) & 0x60) | (((S) << 4) & 0x10) | ((SegmentType) & 0x0f))

#define MAKE_CODE_SEGMENT(conforming,readable) ((((((conforming) << 2) & 0x04) | (((readable) << 1) & 0x02)) | 0x08) & 0x0e)
#define MAKE_DATA_SEGMENT(expdown,writable) (((((expdown) << 2) & 0x04) | (((writable) << 1) & 0x02)) & 0x06)

#define CODE_SEGMENT_TYPE MAKE_CODE_SEGMENT(0,1)
#define DATA_SEGMENT_TYPE MAKE_DATA_SEGMENT(0,1)

typedef uint8_t GdtType1;
typedef uint8_t GdtType2;

typedef struct tagGdt
{
	uint16_t Size_0_15, Address_0_15;
	uint8_t Address_16_23;

	union
	{
		struct
		{
			uint8_t SegmentType:4, S:1, DPL:2, P:1;
		};
		GdtType1 type1;
	};

	union
	{
		struct
		{
			uint8_t Size_16_19:4;
			uint8_t AVL:1, L:1, D:1, G:1;
		};
		GdtType2 type2;
	};

	uint8_t Address_24_32;
} Gdt;

void InitGdt2(Gdt *pGdt, uint32_t address, uint32_t size, GdtType1 type1);

static inline void InitGdt(Gdt *pGdt, GdtType1 type1)
{
	InitGdt2(pGdt, 0, 0xffffffff, type1);
}

static inline void InitNullGdt(Gdt *pGdt)
{
	*((uint64_t *)pGdt) = 0;
}
