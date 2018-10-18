#pragma once

#include <stddef.h>

// inline function
static inline int isalpha(int c) { return (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z'); }
static inline int isdigit(int c) { return c >= '0' && c <= '9'; }
