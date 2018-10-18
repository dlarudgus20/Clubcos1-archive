#include "clc1_stdlib.h"
#include "clc1_string.h"

void itoa(int i, char *buf, int radix)
{
	switch(radix)
	{
	case 10:
	default:
		DecimalToString(i, buf);
		break;
	case 16:
		HexaToString(i, buf);
	}
}

void DecimalToString(int i, char *buf)
{
	int index = 0;

	if(i == 0)
	{
		strcpy(buf, "0");
		return;
	}
	else if(i == -2147483648)
	{
		strcpy(buf, "-2147483648");
		return;
	}
	else if(i < 0)
	{
		buf[0] = '-';
		index = 1;
		i = -i;
	}

	for(; i > 0; index++)
	{
		buf[index] = '0' + i % 10;
		i /= 10;
	}
	buf[index] = '\0';

	if(buf[0] == '-')
	{
		strrev(&buf[1]);
	}
	else
	{
		strrev(buf);
	}
}

void HexaToString(int i, char *buf)
{
	unsigned u = (unsigned) i;
	int index = 0;

	if(u == 0)
	{
		strcpy(buf, "0");
		return;
	}

	for(; u > 0; index++)
	{
		if((u % 16) <= 9)
		{
			buf[index] = '0' + u % 16;
		}
		else
		{
			buf[index] = 'a' + (u % 16 - 0x0a);
		}
		u /= 16;
	}
	buf[index] = '\0';

	if(buf[0] == '-')
	{
		strrev(&buf[1]);
	}
	else
	{
		strrev(buf);
	}
}
