[bits 64]

segment .text
	[global memset]		; void *memset(void *ptr, int value, size_t num);
	memset:
		mov rax, rsi	; value
		mov rcx, rdx	; num

		cld
		rep stosb

		mov rax, rdi
		ret
