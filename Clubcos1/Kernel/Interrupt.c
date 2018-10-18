#include "Clubcos1.h"
#include "Graphic.h"

// vector == -1 --> default
void _DefaultHandler(uint64_t *rsp, int vector)
{
	if (vector != -1)
	{
		DrawStringFormat(GetBootInfo()->ScreenX - 17 * 8, 0,
				RED, "Int Vector [0x%02x]", vector);
	}
	else
	{
		DrawString(GetBootInfo()->ScreenX - 17 * 8, 0,
				RED, "Int Vector [????]");

	}
	//while (1) __asm__ __volatile__ ( "hlt ");
}
