[bits 64]

segment .text
	; MakeIntHandler [어셈 함수 이름] [C 함수 이름] [인터럽트 번호] [에러 코드 유무]
	%macro MakeIntHandler 4
	[extern %2]
	[global %1]
	%1:
		push rbp
		push rax
		push rbx
		push rcx
		push rdx
		push rdi
		push rsi
		push r8
		push r9
		push r10
		push r11
		push r12
		push r13
		push r14
		push r15

		mov ax, ds
		push ax
		mov ax, es
		push ax
		push fs
		push gs

		mov ax, 2 * 8
		mov dx, ax
		mov es, ax
		mov fs, ax
		mov gs, ax

		mov rdi, rsp
		mov rsi, %3
		call %2

		pop gs
		pop fs
		pop ax
		mov es, ax
		pop ax
		mov ds, ax

		pop r15
		pop r14
		pop r13
		pop r12
		pop r11
		pop r10
		pop r9
		pop r8
		pop rsi
		pop rdi
		pop rdx
		pop rcx
		pop rbx
		pop rax
		pop rbp

		%if %4 != 0
		add rsp, 8
		%endif

		iretq
	%endmacro

; exception handler
MakeIntHandler IntHandler0x00, _DefaultHandler, 0x00, 0
MakeIntHandler IntHandler0x01, _DefaultHandler, 0x01, 0
MakeIntHandler IntHandler0x02, _DefaultHandler, 0x02, 0
MakeIntHandler IntHandler0x03, _DefaultHandler, 0x03, 0
MakeIntHandler IntHandler0x04, _DefaultHandler, 0x04, 0
MakeIntHandler IntHandler0x05, _DefaultHandler, 0x05, 0
MakeIntHandler IntHandler0x06, _DefaultHandler, 0x06, 0
MakeIntHandler IntHandler0x07, _DefaultHandler, 0x07, 0
MakeIntHandler IntHandler0x08, _DefaultHandler, 0x08, 1
MakeIntHandler IntHandler0x09, _DefaultHandler, 0x09, 0
MakeIntHandler IntHandler0x0a, _DefaultHandler, 0x0a, 1
MakeIntHandler IntHandler0x0b, _DefaultHandler, 0x0b, 1
MakeIntHandler IntHandler0x0c, _DefaultHandler, 0x0c, 1
MakeIntHandler IntHandler0x0d, _DefaultHandler, 0x0d, 1
MakeIntHandler IntHandler0x0e, _DefaultHandler, 0x0e, 1
MakeIntHandler IntHandler0x0f, _DefaultHandler, 0x0f, 0
MakeIntHandler IntHandler0x10, _DefaultHandler, 0x10, 0
MakeIntHandler IntHandler0x11, _DefaultHandler, 0x11, 1
MakeIntHandler IntHandler0x12, _DefaultHandler, 0x12, 0
MakeIntHandler IntHandler0x13, _DefaultHandler, 0x13, 0

; default handler
MakeIntHandler DefaultHandler, _DefaultHandler, -1, 0
