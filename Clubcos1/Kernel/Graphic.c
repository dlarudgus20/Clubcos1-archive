#include "Clubcos1.h"
#include "Graphic.h"

#include <clc1_stdio.h>
#include <clc1_memory.h>
#include <stdarg.h>

void DrawBoxFill(int x1, int y1, int x2, int y2, Color color)
{
	BootInfo *pbi = GetBootInfo();
	int y;

	for (y = y1; y <= y2; y++)
	{
		memset_2(&pbi->VideoMemory[pbi->ScreenX * y + x1], color, x2 - x1);
	}
}

void DrawFont(const unsigned char *font, int x, int y, Color c)
{
	int i;

	for (i = 0; i < 16; i++)
	{
		if ((font[i] & 0x80) != 0) DrawPixel(x + 0, y + i, c);
		if ((font[i] & 0x40) != 0) DrawPixel(x + 1, y + i, c);
		if ((font[i] & 0x20) != 0) DrawPixel(x + 2, y + i, c);
		if ((font[i] & 0x10) != 0) DrawPixel(x + 3, y + i, c);
		if ((font[i] & 0x08) != 0) DrawPixel(x + 4, y + i, c);
		if ((font[i] & 0x04) != 0) DrawPixel(x + 5, y + i, c);
		if ((font[i] & 0x02) != 0) DrawPixel(x + 6, y + i, c);
		if ((font[i] & 0x01) != 0) DrawPixel(x + 7, y + i, c);
	}
}

void DrawString(int x, int y, Color c, const char *str)
{
	int i;

	for(i = 0; str[i] != '\0'; i++)
	{
		DrawFont(&g_vucEnglishFont[str[i] * 16], x + (i * 8), y, c);
	}
}

void DrawStringFormat(int x, int y, Color c, const char *format, ...)
{
	char buf[1024];
	va_list va;

	va_start(va, format);
	vsprintf(buf, format, va);
	DrawString(x, y, c, buf);
	va_end(va);
}
