#include "clc1_string.h"

void strrev(char *str)
{
	int i, j;
	char tmp;

	j = strlen(str) - 1;
	for(i = 0; str[i] != '\0'; i++)
	{
		if(!(i < j))
		{
			break;
		}
		tmp = str[i];
		str[i] = str[j];
		str[j] = tmp;
		j--;
	}
}
