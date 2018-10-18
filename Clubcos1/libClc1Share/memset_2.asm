[bits 64]

segment .text
	[global memset_2]	; void *memset_2(void *ptr, uint16_t value, size_t count);
	memset_2:
		mov rax, rsi	; value
		mov rcx, rdx	; num

		cld
		rep stosw

		mov rax, rdi
		ret
