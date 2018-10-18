#include "clc1_string.h"

size_t strnlen(const char *str, size_t size)
{
	size_t i = 0;
	while (*str++ != 0 && size-- > 0) i++;
	return i;
}
