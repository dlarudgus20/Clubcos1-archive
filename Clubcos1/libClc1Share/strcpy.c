#include "clc1_string.h"

char *strcpy(char *des, const char *src)
{
	int i;

	for(i = 0; src[i] != '\0'; i++)
	{
		des[i] = src[i];
	}

	des[i] = '\0';
	return des;
}
