#include "clc1_stdio.h"

#include <stdarg.h>
#include <stddef.h>
#include <stdint.h>
#include <stdbool.h>

#include "clc1_string.h"
#include "clc1_ctype.h"

// I refered to http://www.jbox.dk/sanos/source/lib/vsprintf.c.html

// unsupport floating point (%f, %g, %e, etc...)
#define NOFLOAT

enum
{
	ZEROPAD	= 1,
	SIGN	= 2,
	PLUS	= 4,
	SPACE	= 8,
	LEFT	= 16,
	SPECIAL	= 32,
	LARGE	= 64
};

static char *number(char *str, intptr_t num, int base, int size, int precision, int type);

static int skip_atoi(const char **s);
static bool is_length(char c);

static const char *digits = "0123456789abcdefghijklmnopqrstuvwxyz";
static const char *upper_digits = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ";

// unsupport C99
// more information : http://www.cplusplus.com/reference/cstdio/printf/
int vsprintf(char *buf, const char *fmt, va_list va)
{
	// buffer ptr
	char *str;

	// formats
	int flags, width, precision, length;

	// var
	const char *s;
	int base, len;
	int i;

	intptr_t num;

	for (str = buf; *fmt != '\0'; fmt++)
	{
		if (*fmt == '%')
		{
			// parse format flag
			flags = 0;
		flag_repeat:
			fmt++;
			switch (*fmt)
			{
			case '-': flags |= LEFT; goto flag_repeat;
			case '+': flags |= PLUS; goto flag_repeat;
			case ' ': flags |= SPACE; goto flag_repeat;
			case '#': flags |= SPECIAL; goto flag_repeat;
			case '0': flags |= ZEROPAD; goto flag_repeat;
			}

			// parse format width
			width = -1;
			if (isdigit(*fmt))
			{
				width = skip_atoi(&fmt);
			}
			else if (*fmt == '*')
			{
				fmt++;
				width = va_arg(va, int);
				if (width < 0)
				{
					width = -width;
					flags |= LEFT;
				}
			}

			// parse format precision
			precision = -1;
			if (*fmt == '.')
			{
				fmt++;
				if (isdigit(*fmt))
				{
					precision = skip_atoi(&fmt);
				}
				else if (*fmt == '*')
				{
					fmt++;
					precision = va_arg(va, int);
				}
				else if (*fmt == 's')	// %.s and %.[length]s -> precision = 0
				{
					precision = 0;
				}
				else if (is_length(*fmt) && *(fmt + 1) == 's')
				{
					fmt++;
					precision = 0;
				}

				if (precision < 0) precision = 0;
			}

			// parse format length
			length = -1;
			if (is_length(*fmt))
			{
				length = *fmt++;
			}

			base = 10;
			switch (*fmt)
			{
			case 'c':
				if (!(flags & LEFT))
					while (--width > 0) *str++ = ' ';
				*str++ = (unsigned char)va_arg(va, int);

				// if (flags & LEFT)
				while (--width > 0) *str++ = ' ';
				continue;

			case 's':
				s = va_arg(va, const char *);
				if (s == NULL) s = "<NULL>";

				len = strnlen(s, precision);
				if (!(flags & LEFT))
					while (len < width--) *str = ' ';

				for (i = 0; i < len; i++)
					*str++ = *s++;

				// if (flags & LEFT)
				while (len < width--) *str++ = ' ';
				continue;

			case 'p':
				if (width == -1)
				{
					width = 2 * sizeof(void *);
					flags |= ZEROPAD;
				}
				str = number(str, (uintptr_t)va_arg(va, void *), 16, width, precision, flags);
				continue;

			// integers -> set up flag and 'break'
			case 'd':
			case 'i':
				flags |= SIGN;
			case 'u':
				break;

			case 'o':
				base = 8;
				break;

			case 'X':
				flags |= LARGE;
			case 'x':
				base = 16;
				break;

#ifndef NOFLOAT
			case 'F':
			case 'E':
			case 'G':
			case 'g':
			case 'f':
			case 'e':
				continue;
#endif

			case 'n':
				if (length == 'l')
				{
					long *lp = va_arg(va, long *);
					*lp = (str - buf);
				}
				else if (length == 'h')
				{
					short *sp = va_arg(va, short *);
					*sp = (str - buf);
				}
				else
				{
					int *ip = va_arg(va, int *);
					*ip = (str - buf);
				}
				continue;

			case '%':
				*str++ = *fmt;
				continue;

			default:
				fmt++;
				continue;
			}

			// process integers
			if (length == 'l')
			{
				if (flags & SIGN)
					num = va_arg(va, long);
				else
					num = va_arg(va, unsigned long);
			}
			else
			{
				if (flags & SIGN)
					num = va_arg(va, int);
				else
					num = va_arg(va, unsigned int);
			}
			str = number(str, num, base, width, precision, flags);
		}
		else
		{
			*str++ = *fmt;
		}
	}

	*str = '\0';
	return str - buf;
}

static char *number(char *str, intptr_t num, int base, int size, int precision, int type)
{
	uintptr_t unum = (intptr_t)num;

	char c, sign, tmp[129];
	int i;

	const char *dig = digits;
	if (type & LARGE) dig = upper_digits;

	if (type & LEFT) type &= ~ZEROPAD;

	if (base < 2 || base > 36) return 0;

	c = (type & ZEROPAD) ? '0' : ' ';

	sign = '\0';
	if (type & SIGN)
	{
		if (num < 0)
		{
			sign = '-';
			num = -num;
			size--;
		}
		else if (type & PLUS)
		{
			sign = '+';
			size--;
		}
		else if (type & SPACE)
		{
			sign = ' ';
			size--;
		}
	}

	if (type & SPECIAL)
	{
		if (base == 16)
		{
			size -= 2;
		}
		else if (base == 8)
		{
			size -= 1;
		}
	}

	i = 0;
	if (num == 0)
	{
		tmp[i++] = '0';
	}
	else
	{
		if (type & SIGN)
		{
			do
			{
				tmp[i++] = dig[num % base];
				num = num / base;
			} while (num != 0);
		}
		else
		{
			do
			{
				tmp[i++] = dig[unum % base];
				unum = unum / base;
			} while (unum != 0);
		}
	}

	if (i > precision)
		precision = i;
	size -= precision;

	if (!(type & (ZEROPAD | LEFT)))
		while (size-- > 0) *str++ = ' ';
	if (sign != '\0')
		*str++ = sign;

	if (type & SPECIAL)
	{
		if (base == 8)
		{
			*str++ = '0';
		}
		else if (base == 16)
		{
			*str++ = '0';
			*str++ = digits['X' - 'A' + 10];
		}
	}

	if (!(type & LEFT)) while (size-- > 0) *str++ = c;
	while (i < precision--) *str++ = '0';
	while (i-- > 0) *str++ = tmp[i];
	while (size-- > 0) *str++ = ' ';

	return str;
}

static int skip_atoi(const char **s)
{
	int i = 0;
	while (isdigit(**s)) i = i*10 + *((*s)++) - '0';
	return i;
}

static bool is_length(char c)
{
	return (c == 'h' || c == 'l' || c == 'L');
}

int sprintf(char *buf, const char *format, ...)
{
	va_list va;
	int ret;

	va_start(va, format);
	ret = vsprintf(buf, format, va);
	va_end(va);

	return ret;
}
