#pragma once

#include <stddef.h>
#include <stdarg.h>

int sprintf(char *buf, const char *format, ...);
int vsprintf(char *buf, const char *format, va_list va);
