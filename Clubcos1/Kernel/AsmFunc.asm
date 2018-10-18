[bits 64]

[extern ClcMain]

; IA-32e ȣ��Ծ�
; rdi, rsi, rdx, rcx, r8, r9, ����
; 32��Ʈ�� ���� ���� �ݴ�

segment .text
	[global ClcEntry]
	ClcEntry:
		call ClcMain

	[global LoadGdt]	; void LoadGdt(uint16_t size, Gdt *addr);
	LoadGdt:
		mov [rsp - 10], di
		mov [rsp - 8], rsi
		lgdt [rsp - 10]
		ret

	[global LoadIdt]	; void LoadIdt(uint16_t size, Idt *addr);
	LoadIdt:
		mov [rsp - 10], di
		mov [rsp - 8], rsi
		lidt [rsp - 10]
		ret

	[global GetCr0]		; uintptr_t GetCr0();
	GetCr0:
		mov rax, cr0
		ret

	[global SetCr0]		; void SetCr0(uintptr_t cr0);
	SetCr0:
		mov cr0, rdi
		ret
