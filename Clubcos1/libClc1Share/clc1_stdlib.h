#pragma once

#include <stddef.h>

void itoa(int i, char *buf, int radix);
void DecimalToString(int i, char *buf);
void HexaToString(int i, char *buf);

// macro function
#define max(a, b) (((a) > (b)) ? (a) : (b))
#define min(a, b) (((a) < (b)) ? (a) : (b))
#define range(a, x, b) (((x) < (a)) ? (a) : (min(x, b)))
